from __future__ import annotations

from copy import deepcopy
from dataclasses import replace

from app.domain import (
    ConfidenceBand,
    Conclusion,
    Domain,
    Evidence,
    EvidenceGap,
    Hypothesis,
    Investigation,
    Quest,
    SafetyLevel,
    UserMode,
    new_id,
    now,
)
from app.agent_output import AgentInvestigationPlan
from app.playbooks import playbook_for
from app.policy import evaluate_policy, sanitize_child_task
from app.quest_engine import explain_score, score_quest


HERITAGE_SOURCES = playbook_for(Domain.HERITAGE).sources


def status_from_policy(policy) -> str:
    if policy.safety_level == SafetyLevel.EMERGENCY:
        return "emergency_alert"
    if policy.safety_level == SafetyLevel.DANGER:
        return "danger_alert"
    return "blocked" if policy.blocked else "needs_evidence"


def route_domain(prompt: str) -> Domain:
    q = prompt.lower()
    if any(word in q for word in ["mosque", "fountain", "historic", "building", "inscription", "ottoman", "museum", "monument", "çeşme", "kitabe"]):
        return Domain.HERITAGE
    if any(word in q for word in ["plant", "leaf", "tree", "flower", "bird", "animal", "wildlife", "squirrel", "rodent", "fur", "tail", "paw", "mushroom"]):
        return Domain.NATURE
    if any(word in q for word in ["food", "menu", "allergen", "halal", "restaurant", "ingredient"]):
        return Domain.DINING
    return Domain.GENERAL


def parse_domain(value: str, fallback_prompt: str = "") -> Domain:
    normalized = value.strip().lower().replace("-", "_")
    aliases = {
        "historic": Domain.HERITAGE,
        "history": Domain.HERITAGE,
        "historical": Domain.HERITAGE,
        "heritage": Domain.HERITAGE,
        "nature": Domain.NATURE,
        "animal": Domain.NATURE,
        "animals": Domain.NATURE,
        "plant": Domain.NATURE,
        "wildlife": Domain.NATURE,
        "safe_dining": Domain.DINING,
        "dining": Domain.DINING,
        "food": Domain.DINING,
        "general": Domain.GENERAL,
    }
    return aliases.get(normalized, route_domain(fallback_prompt))


def infer_plan_domain(plan: AgentInvestigationPlan, fallback_prompt: str) -> Domain:
    declared = parse_domain(plan.domain)
    if declared != Domain.GENERAL:
        return declared
    combined_plan_text = " ".join(
        [
            fallback_prompt,
            plan.domain,
            plan.uncertainty_note,
            plan.selected_quest.required_feature,
            plan.selected_quest.quest_instruction,
            plan.selected_quest.safety_constraint,
            " ".join(h.label for h in plan.hypotheses),
            " ".join(h.rationale for h in plan.hypotheses),
            " ".join(plan.safety_flags),
        ]
    )
    return route_domain(combined_plan_text)


def parse_confidence(value: str) -> ConfidenceBand:
    normalized = value.strip().lower()
    if normalized in {"high", "strong"}:
        return ConfidenceBand.HIGH
    if normalized in {"medium", "moderate"}:
        return ConfidenceBand.MEDIUM
    return ConfidenceBand.LOW


def is_animal_observation(prompt: str) -> bool:
    q = prompt.lower()
    animal_terms = [
        "animal",
        "squirrel",
        "mammal",
        "wildlife",
        "rodent",
        "bird",
        "insect",
        "pet",
        "fur",
        "tail",
        "paw",
        "whisker",
    ]
    plant_terms = ["plant", "leaf", "tree", "flower", "acorn", "mushroom"]
    return any(term in q for term in animal_terms) and not (
        "plant" in q and not any(term in q for term in animal_terms[:6])
    )


def apply_nature_subject(playbook, prompt: str):
    if not is_animal_observation(prompt):
        return playbook
    return replace(
        playbook,
        hypotheses=[
            Hypothesis(
                "Small wild animal",
                ConfidenceBand.MEDIUM,
                "The visual clues suggest an animal, but Curio should avoid exact species certainty from one photo.",
            ),
            Hypothesis(
                "Lookalike local species",
                ConfidenceBand.MEDIUM,
                "Fur color, tail shape, and body size can overlap across similar animals.",
            ),
        ],
        gap=EvidenceGap(
            "One safe-distance photo showing tail, ears, and full body shape",
            78,
            "Do not approach, touch, feed, chase, or corner any animal.",
        ),
        quest=Quest(
            "From where you are, use zoom to take one safe-distance photo showing the animal's tail, ears, and full body. Do not approach or feed it.",
            "9-12",
            "photo",
            "The animal is visible from a safe distance without interaction.",
            "Good species separation while protecting the child and the animal.",
        ),
        evidence=[
            Evidence(
                "photo",
                "user_upload",
                "Initial animal image supplied; exact species remains provisional.",
                ConfidenceBand.MEDIUM,
            )
        ],
        uncertainty="Animal observations stay cautious until safe-distance visual clues agree.",
    )


def start_investigation(prompt: str, user_mode: UserMode = UserMode.KID) -> Investigation:
    domain = route_domain(prompt)
    playbook = playbook_for(domain)
    if domain == Domain.NATURE:
        playbook = apply_nature_subject(playbook, prompt)
    quest = deepcopy(playbook.quest)
    candidate = score_quest(playbook.gap, quest)
    quest = candidate.quest
    base_score_reason = quest.score_reason
    quest.score = candidate.score
    quest.score_reason = f"{base_score_reason} {explain_score(candidate)}"
    policy = evaluate_policy(
        domain=domain,
        user_mode=user_mode,
        prompt=prompt,
        proposed_task=quest.instruction,
    )
    evidence = deepcopy(playbook.evidence)
    if domain == Domain.GENERAL:
        evidence.append(Evidence("question", "user_prompt", prompt, ConfidenceBand.LOW))

    return Investigation(
        investigation_id=new_id(),
        domain=domain,
        user_mode=user_mode,
        status=status_from_policy(policy),
        prompt=prompt,
        created_at=now(),
        hypotheses=deepcopy(playbook.hypotheses),
        evidence=evidence,
        missing_evidence=[playbook.gap],
        selected_quest=quest,
        safety_flags=policy.flags,
        policy_message=policy.message,
        parent_gate_required=policy.parent_gate_required,
        agent_trace=[
            "observe: normalized prompt, OCR, image marker, and coarse context",
            f"route: selected {domain.value} playbook",
            "hypothesize: generated ranked alternatives with confidence bands",
            f"score: selected quest with score {quest.score}",
            "policy: applied child safety and privacy rules outside the model",
        ],
        confidence_band=ConfidenceBand.MEDIUM if domain != Domain.GENERAL else ConfidenceBand.LOW,
        uncertainty_note=playbook.uncertainty,
        safety_events=[policy.safety_event] if policy.safety_event else [],
    )


def start_visual_fallback_investigation(
    prompt: str,
    user_mode: UserMode = UserMode.KID,
    *,
    reason: str = "vision model unavailable",
) -> Investigation:
    inv = start_investigation(prompt, user_mode)
    if inv.domain != Domain.GENERAL:
        inv.agent_trace.append(f"vision_fallback: {reason}")
        return inv

    inv.hypotheses = [
        Hypothesis(
            "Uploaded photo needs visual clarification",
            ConfidenceBand.LOW,
            "The image upload was received, but the live vision model did not return a reliable subject label.",
        ),
        Hypothesis(
            "Possible nature, object, food, or place observation",
            ConfidenceBand.LOW,
            "The agent needs one visible clue such as leaf shape, animal body shape, label text, or surrounding context.",
        ),
    ]
    inv.missing_evidence = [
        EvidenceGap(
            "A closer, well-lit view of the main subject and one surrounding context clue",
            68,
            "Stay in place, use zoom, and ask a grown-up before moving closer.",
        )
    ]
    quest = Quest(
        "Take one clearer photo of the main thing you want to identify, from the same safe spot, and add one word about where you saw it.",
        "9-12",
        "photo+context",
        "The subject is visible and one context clue is provided.",
        "Keeps the child safe while recovering from an uncertain vision result.",
    )
    candidate = score_quest(inv.missing_evidence[0], quest)
    quest.score = candidate.score
    quest.score_reason = f"{quest.score_reason} {explain_score(candidate)}"
    if user_mode == UserMode.KID:
        quest.instruction = sanitize_child_task(quest.instruction, Domain.GENERAL)
    inv.selected_quest = quest
    inv.evidence = [
        Evidence(
            "photo",
            "user_upload",
            "Image upload was received; live vision fallback created a safer visual clarification quest.",
            ConfidenceBand.LOW,
        )
    ]
    inv.uncertainty_note = (
        "The image reached the agent, but the live vision model did not return "
        "a reliable subject. Curio is asking for one safer, clearer clue."
    )
    inv.agent_trace.append(f"vision_fallback: {reason}")
    inv.agent_trace.append("repair: replaced generic routing with a visual clarification quest")
    return inv


def start_investigation_from_plan(
    prompt: str,
    plan: AgentInvestigationPlan,
    user_mode: UserMode = UserMode.KID,
) -> Investigation:
    domain = infer_plan_domain(plan, prompt)
    playbook = playbook_for(domain)
    if domain == Domain.NATURE:
        playbook = apply_nature_subject(playbook, prompt)
    plan_was_generic_image = (
        domain == Domain.GENERAL
        and "image attached" in prompt.lower()
        and any("domain routing" in h.label.lower() for h in plan.hypotheses)
    )
    gap = EvidenceGap(
        "A closer, well-lit view of the main subject and one surrounding context clue"
        if plan_was_generic_image
        else plan.selected_quest.required_feature.strip()
        or playbook.gap.required_feature,
        playbook.gap.expected_information_gain,
        "Stay in place, use zoom, and ask a grown-up before moving closer."
        if plan_was_generic_image
        else plan.selected_quest.safety_constraint.strip()
        or playbook.gap.safety_constraint,
    )
    raw_quest_instruction = (
        "Take one clearer photo of the main thing you want to identify, from the same safe spot, and add one word about where you saw it."
        if plan_was_generic_image
        else plan.selected_quest.quest_instruction.strip()
        or playbook.quest.instruction
    )
    quest = Quest(
        raw_quest_instruction,
        playbook.quest.age_band,
        plan.selected_quest.modality.strip() or playbook.quest.modality,
        playbook.quest.completion_rule,
        playbook.quest.score_reason,
    )
    candidate = score_quest(gap, quest)
    quest.score = candidate.score
    quest.score_reason = f"{quest.score_reason} {explain_score(candidate)}"

    hypotheses = (
        [
            Hypothesis(
                "Uploaded photo needs visual clarification",
                ConfidenceBand.LOW,
                "The image was received, but the agent needs one clearer clue before naming the subject.",
            ),
            Hypothesis(
                "Nature, object, or place lookalike",
                ConfidenceBand.LOW,
                "A single image can be confused by crop, lighting, or background context.",
            ),
        ]
        if plan_was_generic_image
        else [
        Hypothesis(
            h.label.strip(),
            parse_confidence(h.probability_band),
            h.rationale.strip(),
        )
        for h in plan.hypotheses
        if h.label.strip()
        ]
    ) or deepcopy(playbook.hypotheses)

    policy = evaluate_policy(
        domain=domain,
        user_mode=user_mode,
        prompt=prompt,
        proposed_task=raw_quest_instruction,
    )
    if user_mode == UserMode.KID:
        quest.instruction = sanitize_child_task(quest.instruction, domain)
    plan_text = " ".join(
        [
            plan.domain,
            plan.uncertainty_note,
            plan.selected_quest.required_feature,
            plan.selected_quest.quest_instruction,
            plan.selected_quest.safety_constraint,
            " ".join(h.label for h in plan.hypotheses),
            " ".join(h.rationale for h in plan.hypotheses),
            " ".join(plan.safety_flags),
        ]
    )
    content_policy = evaluate_policy(
        domain=domain,
        user_mode=user_mode,
        prompt=f"{prompt} {plan_text}",
        proposed_task=raw_quest_instruction,
    )
    active_policy = content_policy if content_policy.safety_event else policy
    safety_flags = sorted(set(active_policy.flags + [f.strip() for f in plan.safety_flags if f.strip()]))
    evidence = deepcopy(playbook.evidence)
    if domain == Domain.GENERAL:
        evidence.append(
            Evidence(
                "photo",
                "user_upload",
                "Image upload was received, but the visible subject needs a clearer clue before a final domain is chosen.",
                ConfidenceBand.LOW,
            )
        )

    return Investigation(
        investigation_id=new_id(),
        domain=domain,
        user_mode=user_mode,
        status=status_from_policy(active_policy),
        prompt=prompt,
        created_at=now(),
        hypotheses=hypotheses,
        evidence=evidence,
        missing_evidence=[gap],
        selected_quest=quest,
        safety_flags=safety_flags,
        policy_message=active_policy.message,
        parent_gate_required=active_policy.parent_gate_required,
        agent_trace=[
            "observe: normalized prompt, OCR, image marker, and coarse context",
            "strands: received structured AgentInvestigationPlan from Bedrock",
            f"route: live plan selected {domain.value}",
            "generic image repair: converted weak visual plan into a usable evidence quest"
            if plan_was_generic_image
            else "repair: no generic image repair needed",
            f"hypothesize: mapped {len(hypotheses)} live hypotheses",
            f"score: selected live quest with score {quest.score}",
            "policy: applied child safety and privacy rules outside the model",
        ],
        confidence_band=hypotheses[0].probability_band
        if hypotheses
        else ConfidenceBand.LOW,
        uncertainty_note=plan.uncertainty_note.strip() or playbook.uncertainty,
        safety_events=[active_policy.safety_event] if active_policy.safety_event else [],
    )


def add_evidence(investigation: Investigation, observation: str, evidence_type: str = "user_observation") -> Investigation:
    investigation.evidence.append(
        Evidence(evidence_type, "user_follow_up", observation, ConfidenceBand.MEDIUM)
    )
    lowered = observation.lower()
    if investigation.domain == Domain.HERITAGE and any(word in lowered for word in ["inscription", "plaque", "kitabe", "water", "fountain", "arch"]):
        investigation.hypotheses[0].probability_band = ConfidenceBand.HIGH
        investigation.hypotheses[1].status = "weakened"
        investigation.status = "concluded"
        investigation.confidence_band = ConfidenceBand.HIGH
        investigation.conclusion = Conclusion(
            "Ottoman-era public fountain",
            ConfidenceBand.HIGH,
            [h.label for h in investigation.hypotheses[1:]],
            "The conclusion is strong for a demo, but a real app should still link the exact municipal or museum record.",
            "The image, text clue, and architectural form now point to a historic public fountain. The evidence chain shows why the alternative explanations became weaker.",
            "We changed our idea because the writing and the shape gave us stronger clues.",
            HERITAGE_SOURCES,
        )
        investigation.agent_trace.append(
            "verify: new evidence strengthened the lead hypothesis and weakened an alternative"
        )
        investigation.agent_trace.append("conclude: returned parent and kid summaries")
    else:
        investigation.status = "needs_evidence"
        investigation.confidence_band = ConfidenceBand.MEDIUM
        investigation.uncertainty_note = "The new clue helps, but one more targeted observation would make the result stronger."
        investigation.agent_trace.append(
            "verify: evidence was useful but did not meet the stopping condition"
        )
    policy = evaluate_policy(
        domain=investigation.domain,
        user_mode=investigation.user_mode,
        prompt=investigation.prompt,
        proposed_task=investigation.selected_quest.instruction,
    )
    investigation.safety_flags = policy.flags
    investigation.policy_message = policy.message
    investigation.parent_gate_required = policy.parent_gate_required
    if policy.safety_event:
        investigation.safety_events.append(policy.safety_event)
        investigation.status = status_from_policy(policy)
    return investigation
