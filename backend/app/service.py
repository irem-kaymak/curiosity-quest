from __future__ import annotations

from pathlib import Path
import re

from app.agent_core import add_evidence
from app.config import load_settings
from app.agents.strands_agent import (
    generate_curiosity_followup_text,
    run_curiosity_agent,
    run_curiosity_agent_with_image,
)
from app.domain import (
    ConfidenceBand,
    Conclusion,
    Domain,
    Evidence,
    EvidenceGap,
    Hypothesis,
    Investigation,
    Quest,
    UserMode,
    new_id,
    now,
)
from app.notifications import ParentContact, dispatcher
from app.policy import evaluate_policy
from app.store import load, list_recent, save
from app.vision import (
    best_subject_label,
    curiosity_fact_and_question,
    detect_visual_labels,
    infer_risk_terms_from_labels,
)


class NotFoundError(Exception):
    pass


class ValidationError(Exception):
    pass


def parse_user_mode(value: str) -> UserMode:
    try:
        return UserMode(value)
    except ValueError as exc:
        raise ValidationError("user_mode must be 'kid' or 'parent'") from exc


def create_investigation(
    prompt: str,
    user_mode: str = "kid",
    *,
    parent_contact: ParentContact | None = None,
    db_path: Path | None = None,
) -> Investigation:
    clean_prompt = prompt.strip()
    if not clean_prompt:
        raise ValidationError("prompt is required")
    mode = parse_user_mode(user_mode)
    inv = answer_curiosity_follow_up(clean_prompt, mode) or run_curiosity_agent(clean_prompt, mode)
    enrich_safety_answer(inv)
    queue_parent_notifications(inv, parent_contact)
    return save(inv, db_path) if db_path else save(inv)


def create_investigation_from_image(
    prompt: str,
    image_bytes: bytes,
    image_format: str,
    user_mode: str = "kid",
    *,
    parent_contact: ParentContact | None = None,
    db_path: Path | None = None,
) -> Investigation:
    clean_prompt = prompt.strip()
    if not clean_prompt:
        raise ValidationError("prompt is required")
    vision = detect_visual_labels(image_bytes)
    visual_prompt = " ".join(
        part
        for part in [
            clean_prompt,
            vision.prompt_hint(),
            "Potential visual risks: " + ", ".join(infer_risk_terms_from_labels(vision.labels))
            if vision.labels and infer_risk_terms_from_labels(vision.labels)
            else "",
        ]
        if part
    )
    inv = run_curiosity_agent_with_image(
        visual_prompt,
        image_bytes,
        image_format,
        parse_user_mode(user_mode),
    )
    inv.evidence.append(
        Evidence(
            "vision_labels",
            vision.provider,
            vision.prompt_hint()
            if not vision.error
            else f"{vision.prompt_hint()} Error: {vision.error}",
            ConfidenceBand.MEDIUM if vision.labels else ConfidenceBand.LOW,
        )
    )
    inv.agent_trace.append(
        f"vision: {vision.provider} {vision.status}"
        + (f" labels={','.join(label.name for label in vision.labels[:6])}" if vision.labels else "")
        + (f" error={vision.error}" if vision.error else "")
    )
    enrich_safe_visual_answer(inv, vision.labels)
    enrich_safety_answer(inv)
    queue_parent_notifications(inv, parent_contact)
    return save(inv, db_path) if db_path else save(inv)


def get_investigation(
    investigation_id: str,
    *,
    db_path: Path | None = None,
) -> Investigation:
    inv = load(investigation_id, db_path) if db_path else load(investigation_id)
    if inv is None:
        raise NotFoundError("Investigation not found")
    return inv


def append_evidence(
    investigation_id: str,
    observation: str,
    evidence_type: str = "user_observation",
    *,
    db_path: Path | None = None,
) -> Investigation:
    clean_observation = observation.strip()
    if not clean_observation:
        raise ValidationError("observation is required")
    inv = get_investigation(investigation_id, db_path=db_path)
    updated = add_evidence(inv, clean_observation, evidence_type.strip() or "user_observation")
    queue_parent_notifications(updated)
    return save(updated, db_path) if db_path else save(updated)


def recent_investigations(*, limit: int = 20, db_path: Path | None = None) -> list[Investigation]:
    safe_limit = max(1, min(limit, 100))
    return list_recent(db_path, safe_limit) if db_path else list_recent(limit=safe_limit)


def queue_parent_notifications(
    investigation: Investigation,
    parent_contact: ParentContact | None = None,
) -> Investigation:
    if not investigation.safety_events:
        return investigation
    existing = {
        (item.get("channel"), item.get("reason"))
        for item in investigation.notification_deliveries
    }
    for delivery in dispatcher.dispatch(investigation, parent_contact):
        payload = delivery.__dict__
        key = (payload.get("channel"), payload.get("reason"))
        if key not in existing:
            investigation.notification_deliveries.append(payload)
            existing.add(key)
    return investigation


def enrich_safety_answer(investigation: Investigation) -> Investigation:
    if not investigation.safety_events:
        return investigation
    event = investigation.safety_events[0]
    emergency = event.severity.value == "emergency"
    investigation.status = "emergency_alert" if emergency else "danger_alert"
    investigation.confidence_band = ConfidenceBand.HIGH
    investigation.selected_quest = Quest(
        "Follow the safety protocol with a grown-up before continuing this case.",
        "9-12",
        "safety_protocol",
        "The child moves away and a parent checks the situation.",
        "Immediate safety action outranks curiosity follow-up.",
        score=100,
    )
    investigation.hypotheses = [
        Hypothesis(
            "Safety-first situation",
            ConfidenceBand.HIGH,
            "Curio detected possible danger, so the case switches from discovery mode to a child-safe action plan.",
        ),
        Hypothesis(
            "Parent review needed",
            ConfidenceBand.HIGH,
            "A trusted adult should check the real-world context before the child continues.",
        ),
    ]
    if not any(e.type == "safety_protocol" for e in investigation.evidence):
        investigation.evidence.insert(
            0,
            Evidence(
                "safety_protocol",
                "curio_policy",
                "Safety protocol opened and parent notification queued immediately.",
                ConfidenceBand.HIGH,
            ),
        )
    child_summary = (
        "Safety first. I spotted something that could be risky. Step back, do not touch it, "
        "and ask a grown-up to check with you before we keep investigating."
    )
    parent_summary = (
        "Curio detected a possible danger and switched the child flow into a step-by-step safety protocol. "
        "Parent notification is queued immediately through the configured channels."
    )
    investigation.uncertainty_note = child_summary
    investigation.conclusion = Conclusion(
        best_hypothesis="Safety protocol required",
        confidence_band=ConfidenceBand.HIGH,
        alternatives=[],
        uncertainty_note="Safety action takes priority over object identification.",
        parent_summary=parent_summary,
        kid_summary=child_summary,
        sources=["Curio safety policy", "Visual or text risk detector"],
    )
    investigation.agent_trace.append("policy: safety answer enriched for child protocol and parent alert")
    return investigation


def answer_curiosity_follow_up(prompt: str, user_mode: UserMode) -> Investigation | None:
    normalized = " ".join(prompt.lower().split())
    safety_answer = _text_safety_alert(prompt, user_mode)
    if safety_answer:
        return safety_answer
    live_text_answer = _live_text_learning_answer(prompt, normalized, user_mode)
    if live_text_answer:
        return live_text_answer
    if _answers_acorn_oak_clue_question(normalized):
        return _curiosity_answer(
            prompt,
            user_mode,
            best_hypothesis="Oak and acorn clue match",
            kid_summary=(
                "Sharp field note. Yes, those are useful clues: oak leaves often have many rounded lobes, "
                "and an acorn has a little cap where it was attached to the tree. That makes your oak/acorn "
                "idea stronger."
            ),
            parent_summary=(
                "Curio treated the child's leaf-and-cap observation as a follow-up clue in the same acorn/oak case."
            ),
            follow_up="Can you find one more oak clue nearby, like bark texture or more acorns on the ground?",
            evidence_note="The child described leaf shape and the acorn cap as follow-up evidence.",
            badge="Oak Detective",
        )
    if _asks_about_squirrel_hiding_place(normalized):
        return _curiosity_answer(
            prompt,
            user_mode,
            best_hypothesis="Squirrel hiding places",
            kid_summary=(
                "Yes, under trees is a smart guess. Squirrels often hide food in soil, "
                "leaf litter, tree roots, or little cracks nearby. They spread snacks "
                "around instead of keeping everything in one spot."
            ),
            parent_summary=(
                "Curio answered a hypothesis-style follow-up from the squirrel thread "
                "without requiring another image."
            ),
            follow_up="What clue might help a squirrel remember where it hid a snack?",
            evidence_note="The child guessed a possible squirrel food hiding place.",
            badge="Trail Tracker",
        )
    if _asks_about_squirrel_food_cache(normalized):
        return _curiosity_answer(
            prompt,
            user_mode,
            best_hypothesis="Squirrel food caching",
            kid_summary=(
                "Great detective question. Squirrels bury food to save it for later. This is called caching. "
                "When food is harder to find, they use smell and memory to find many "
                "of their hidden snacks again."
            ),
            parent_summary=(
                "Curio answered a follow-up question from the previous squirrel observation "
                "without requiring another image."
            ),
            follow_up="Where do you think a squirrel would hide food so it can find it later?",
            evidence_note="The child asked a follow-up about why squirrels bury food.",
            badge="Memory Mapper",
        )
    if _asks_what_squirrels_eat(normalized):
        return _curiosity_answer(
            prompt,
            user_mode,
            best_hypothesis="Squirrel diet",
            kid_summary=(
                "Squirrels often eat nuts, seeds, fruits, fungi, buds, and sometimes "
                "small insects. They also hide extra food so they can come back to it later."
            ),
            parent_summary=(
                "Curio answered a squirrel diet follow-up using the existing conversation context."
            ),
            follow_up="Why might hiding food be helpful in winter?",
            evidence_note="The child asked what squirrels eat.",
            badge="Wildlife Scout",
        )
    animal_answer = _animal_follow_up_answer(prompt, normalized, user_mode)
    if animal_answer:
        return animal_answer
    direct_answer = _direct_learning_answer(prompt, normalized, user_mode)
    if direct_answer:
        return direct_answer
    if _is_curio_contextual_reply(normalized):
        subject = _extract_previous_subject(prompt)
        return _curiosity_answer(
            prompt,
            user_mode,
            best_hypothesis=f"{subject} field note",
            kid_summary=(
                f"Nice investigator move. I saved your idea as a field note for the {subject.lower()} case. "
                "A good explorer does exactly this: notice a clue, make a guess, then look for one more clue "
                "that could support or change the idea."
            ),
            parent_summary=(
                "Curio accepted the child's contextual reply as part of the active investigation instead of "
                "starting a new image request."
            ),
            follow_up=f"What is one more clue you could safely check for this {subject.lower()}?",
            evidence_note="The child answered Curio's previous follow-up question.",
            badge="Field Investigator",
        )
    return None


def _text_safety_alert(prompt: str, user_mode: UserMode) -> Investigation | None:
    policy = evaluate_policy(
        domain=Domain.GENERAL,
        user_mode=user_mode,
        prompt=prompt,
        proposed_task=prompt,
    )
    if not policy.safety_event:
        return None
    event = policy.safety_event
    return Investigation(
        investigation_id=new_id(),
        domain=Domain.GENERAL,
        user_mode=user_mode,
        status="danger_alert",
        prompt=prompt,
        created_at=now(),
        hypotheses=[
            Hypothesis(
                event.title,
                ConfidenceBand.HIGH,
                "Safety policy detected a possible real-world risk before answering the learning question.",
            )
        ],
        evidence=[
            Evidence(
                "safety_signal",
                "text_policy",
                "The child question contains possible danger or emergency terms.",
                ConfidenceBand.HIGH,
            )
        ],
        missing_evidence=[
            EvidenceGap(
                "A grown-up should confirm the child is safe before curiosity continues.",
                100,
                "Immediate safety action outranks curiosity follow-up.",
            )
        ],
        selected_quest=Quest(
            event.child_message,
            "3-15",
            "safety_protocol",
            "Child moves away and gets a grown-up.",
            "Safety protocol takes priority over investigation.",
            score=100,
        ),
        safety_flags=policy.flags,
        policy_message=policy.message,
        parent_gate_required=policy.parent_gate_required,
        agent_trace=["policy: text safety event detected before learning answer"],
        confidence_band=ConfidenceBand.HIGH,
        uncertainty_note="Safety action takes priority over object identification.",
        safety_events=[event],
        conclusion=Conclusion(
            best_hypothesis=event.title,
            confidence_band=ConfidenceBand.HIGH,
            alternatives=[],
            uncertainty_note="Safety action takes priority over object identification.",
            parent_summary=event.parent_message,
            kid_summary=event.child_message,
            sources=["Curio safety policy", "Text risk detector"],
        ),
    )


def _animal_follow_up_answer(
    prompt: str,
    normalized: str,
    user_mode: UserMode,
) -> Investigation | None:
    subject = _extract_previous_subject(prompt)
    if subject == "mystery":
        subject = _extract_known_subject(normalized)
    subject_key = subject.lower()
    if subject_key not in _ANIMAL_FACTS:
        return None

    child_text = _extract_child_text(prompt).lower()
    combined = f"{normalized} {child_text}"
    answer = _animal_answer_payload(subject_key, combined)
    if answer:
        kid_summary, follow_up, badge, hypothesis = answer
        kid_summary, follow_up, source = generate_curiosity_followup_text(
            prompt,
            subject,
            kid_summary,
            follow_up,
        )
        return _curiosity_answer(
            prompt,
            user_mode,
            best_hypothesis=f"{subject} {hypothesis}",
            kid_summary=kid_summary,
            parent_summary=f"Curio answered a {subject_key} follow-up in the active case.",
            follow_up=follow_up,
            evidence_note=f"The child asked or answered a clue about the {subject_key}. Answer source: {source}.",
            badge=badge,
        )
    return None


def _direct_learning_answer(prompt: str, normalized: str, user_mode: UserMode) -> Investigation | None:
    child_text = _extract_child_text(prompt).lower()
    combined = f"{normalized} {child_text}"
    subject = _extract_previous_subject(prompt)
    if subject == "mystery":
        subject = _extract_known_subject(combined)
    subject_key = subject.lower()
    if subject_key in _ANIMAL_FACTS:
        answer = _animal_answer_payload(subject_key, combined)
        if answer:
            kid_summary, follow_up, badge, hypothesis = answer
            kid_summary, follow_up, source = generate_curiosity_followup_text(
                prompt,
                subject,
                kid_summary,
                follow_up,
            )
        else:
            fact = _ANIMAL_FACTS[subject_key]["fact"]
            kid_summary = f"Yes, we can keep exploring without a new photo. {fact}"
            follow_up = _ANIMAL_FACTS[subject_key]["next"]
            badge = _ANIMAL_FACTS[subject_key]["badge"]
            hypothesis = "learning question"
            kid_summary, follow_up, source = generate_curiosity_followup_text(
                prompt,
                subject,
                kid_summary,
                follow_up,
            )
        return _curiosity_answer(
            prompt,
            user_mode,
            best_hypothesis=f"{subject} {hypothesis}",
            kid_summary=kid_summary,
            parent_summary=f"Curio answered a direct {subject_key} learning question without requiring a new image.",
            follow_up=follow_up,
            evidence_note=f"The child asked a direct learning question about {subject_key}. Answer source: {source}.",
            badge=badge,
        )
    if _looks_like_open_learning_question(combined) and not _looks_like_domain_routing_question(combined):
        kid_summary, follow_up, badge = _fallback_text_learning_payload(prompt, combined, subject)
        return _curiosity_answer(
            prompt,
            user_mode,
            best_hypothesis="Open curiosity question",
            kid_summary=kid_summary,
            parent_summary="Curio kept a text-only curiosity question alive instead of asking for a new image.",
            follow_up=follow_up,
            evidence_note="The child asked a text-only curiosity question.",
            badge=badge,
            domain=Domain.GENERAL,
        )
    return None


def _live_text_learning_answer(prompt: str, normalized: str, user_mode: UserMode) -> Investigation | None:
    if load_settings().demo_mode:
        return None
    contextual = _is_curio_contextual_reply(normalized)
    direct_learning = _looks_like_open_learning_question(normalized) and not _looks_like_domain_routing_question(normalized)
    if not contextual and not direct_learning:
        return None
    subject = _extract_previous_subject(prompt)
    if subject == "mystery":
        subject = _extract_known_subject(normalized)
    if subject == "mystery":
        subject = "the child's curiosity question"
    fallback_answer, fallback_question, fallback_badge = _fallback_text_learning_payload(prompt, normalized, subject)
    kid_summary, follow_up, source = generate_curiosity_followup_text(
        prompt,
        subject,
        fallback_answer,
        fallback_question,
    )
    return _curiosity_answer(
        prompt,
        user_mode,
        best_hypothesis=f"{subject} text follow-up",
        kid_summary=kid_summary,
        parent_summary=(
            "Curio answered a text-only or active-case follow-up through the live AI path "
            "without requiring a new image."
        ),
        follow_up=follow_up,
        evidence_note=f"The child continued the investigation in text. Answer source: {source}.",
        badge=fallback_badge,
        domain=Domain.GENERAL if subject == "the child's curiosity question" else Domain.NATURE,
    )


def _fallback_text_learning_payload(prompt: str, normalized: str, subject: str = "mystery") -> tuple[str, str, str]:
    text = normalized.lower()
    subject_name = subject.strip()
    subject_key = subject_name.lower()
    if subject_key and subject_key not in {"mystery", "the child's curiosity question"}:
        subject_answer = _subject_aware_fallback_payload(subject_name, text)
        if subject_answer:
            return subject_answer
    if any(term in text for term in ["say hello", "how to say hello", "learn how to say hello", "greet", "greeting"]):
        if "spanish" in text or "espanol" in text:
            return (
                "You can say hello in Spanish by saying: Hola. For a friendly explorer greeting, you can say Hola, como estas?, which means Hello, how are you?",
                "Which language should we unlock next?",
                "Language Explorer",
            )
        if "turkish" in text or "turkce" in text:
            return (
                "You can say hello in Turkish by saying: Merhaba. A warmer everyday greeting is Selam, like saying Hi.",
                "Can you try using Merhaba in a tiny sentence?",
                "Language Explorer",
            )
        return (
            "You can say hello in English by saying: Hello. You can also say Hi for a shorter greeting, or Nice to meet you when you meet someone new.",
            "Which greeting would you use with a new friend: Hello, Hi, or Nice to meet you?",
            "Language Explorer",
        )
    if any(term in text for term in ["translate", "how do i say", "how to say"]):
        return (
            "I can help with words too, without a photo. Tell me the word or sentence and the language, and I will turn it into a tiny language mission.",
            "What language should Curio translate into?",
            "Language Explorer",
        )
    if "learn" in text:
        return (
            "Yes. We can learn this as a mini case without a picture: first get the main idea, then try one tiny example, then ask one better question.",
            "What is the first tiny example you want to try?",
            "Learning Detective",
        )
    return (
        "I can answer with words too. Tell me the exact thing you want to learn, and I will turn it into a small discovery card instead of asking for a photo.",
        "What is the question you want Curio to solve?",
        "Question Builder",
    )


def _subject_aware_fallback_payload(subject: str, text: str) -> tuple[str, str, str] | None:
    name = subject.lower()
    article = "an" if name[:1] in "aeiou" else "a"
    if any(term in text for term in ["color", "colour", "white", "brown", "black", "gray", "grey", "orange", "red", "yellow"]):
        color = _first_color(text)
        observed = f"If you see {color}, write that as the first clue. " if color else ""
        return (
            observed
            + f"Color helps describe {article} {name}, but it usually is not enough by itself. A stronger investigation compares color with shape, body parts, movement, and where you saw it.",
            f"Which clue should we compare next for the {name}: shape, body parts, movement, or place?",
            "Field Colorist",
        )
    if any(term in text for term in ["eat", "eats", "food", "feed", "snack", "yer", "beslen"]):
        return (
            f"We can ask what {name}s eat without a new photo. The safest answer is to treat it as a research clue: different kinds may eat different foods, so Curio should compare the animal group, habitat, and trusted facts before deciding.",
            f"What clue do you have about where this {name} lives or what it was doing?",
            "Food Clue Scout",
        )
    if any(term in text for term in ["where", "live", "home", "nest", "burrow", "hide", "nerede", "yaşar"]):
        return (
            f"Where {article} {name} lives depends on the kind and the place. A good investigator checks habitat clues: ground, trees, water, shelter, weather, and whether it is wild or cared for by people.",
            f"What habitat clue can you spot around the {name}?",
            "Habitat Mapper",
        )
    if any(term in text for term in ["why", "how", "what", "can you answer", "bilmiyorum", "neden", "nasıl", "nasil", "ne "]):
        return (
            f"Let's turn this into a mini case about {article} {name}. Curio can answer with words first, then compare the idea with one safe clue you noticed.",
            f"Which clue about the {name} should we check next: shape, color, movement, place, or sound?",
            "Case Thinker",
        )
    return None


_ANIMAL_FACTS = {
    "rabbit": {
        "fact": "Rabbits often have soft fur, long ears, a small round tail, and strong back legs for hopping.",
        "eat": "Rabbits mostly eat grass, hay, leafy plants, and some vegetables. Their teeth keep growing, so chewing fibrous plants helps wear them down.",
        "home": "Wild rabbits often live in burrows or hidden grassy places, and pet rabbits need a safe, quiet shelter.",
        "color": "Rabbit fur can be white, brown, gray, black, or mixed. Color is a good description clue, but ears, tail, body shape, and hopping are stronger rabbit clues.",
        "next": "Can you spot one more rabbit clue: long ears, round tail, or hopping legs?",
        "badge": "Rabbit Ranger",
    },
    "bird": {
        "fact": "Birds have feathers, beaks, wings, and lightweight bodies that help many of them fly.",
        "eat": "Birds eat different foods: seeds, fruit, nectar, fish, insects, or tiny animals depending on the species.",
        "home": "Many birds build nests in trees, ledges, reeds, or safe hidden places.",
        "color": "Bird colors can help with camouflage, warning, or attracting a mate, but beak shape and wing pattern are also important clues.",
        "next": "Which clue would you check next: beak, wing, tail, or sound?",
        "badge": "Feather Detective",
    },
    "cat": {
        "fact": "Cats are mammals with whiskers, sharp hearing, soft paws, and flexible bodies.",
        "eat": "Cats are carnivores, so their bodies are built to eat meat-based food.",
        "home": "Pet cats live with people, while wild or stray cats look for sheltered, quiet places.",
        "color": "Cats can have many coat colors and patterns, like tabby stripes, black, white, orange, gray, or mixed patches.",
        "next": "What clue would you compare next: whiskers, ears, tail, or paw shape?",
        "badge": "Whisker Watcher",
    },
    "dog": {
        "fact": "Dogs are mammals with strong noses, expressive ears, and many different body shapes.",
        "eat": "Dogs are omnivores, which means many can eat meat and some plant-based foods, but pets need safe dog food from an adult.",
        "home": "Pet dogs live with people and need safe shelter, water, movement, and care.",
        "color": "Dogs can have black, brown, white, gray, golden, or mixed coats. Shape, size, ears, and tail are also useful clues.",
        "next": "What clue would you compare next: nose, ears, tail, or paw size?",
        "badge": "Paw Detective",
    },
    "butterfly": {
        "fact": "Butterflies have wings covered in tiny scales, and they often drink nectar from flowers.",
        "eat": "Adult butterflies usually drink nectar. Caterpillars eat leaves before they transform.",
        "home": "Butterflies are often found near flowers, sunny gardens, meadows, or host plants for their caterpillars.",
        "color": "Butterfly wing colors and patterns can help them hide, warn predators, or attract mates.",
        "next": "Are the wing colors the same on both sides?",
        "badge": "Wing Pattern Scout",
    },
    "squirrel": {
        "fact": "Squirrels are small mammals with sharp claws, bushy tails, and a habit of storing food.",
        "eat": "Squirrels often eat nuts, seeds, fruits, fungi, buds, and sometimes small insects.",
        "home": "Many squirrels live in tree nests, hollows, or nearby hidden spots with good cover.",
        "color": "Squirrel fur can be gray, red-brown, black, or mixed depending on the kind and place.",
        "body": "A squirrel's bushy tail helps with balance and signaling. Its small paws and sharp claws help it climb trees and hold food.",
        "next": "What clue might help a squirrel remember where it hid a snack?",
        "badge": "Wildlife Scout",
    },
    "horse": {
        "fact": "Horses are large mammals with hooves, a mane, a tail, and strong legs for running.",
        "eat": "Horses mostly eat grass and hay. Their flat teeth help grind plants, and an adult should always choose safe food for a horse.",
        "home": "Many horses live in fields, paddocks, or stables where they have space, shelter, water, and care.",
        "color": "Horse coats can be brown, black, white, gray, chestnut, golden, or mixed. Color helps describe a horse, but legs, hooves, mane, tail, and body shape are stronger clues.",
        "body": "Great clue. A horse has long strong legs, hard hooves, a mane along the neck, a tail, large ears, and a long face. Those body parts help it run, balance, listen, and graze.",
        "next": "Which horse clue should we inspect next: hooves, mane, tail, ears, or body shape?",
        "badge": "Horse Detective",
    },
}


def _animal_answer_payload(subject: str, text: str) -> tuple[str, str, str, str] | None:
    facts = _ANIMAL_FACTS[subject]
    if _has_any_term(
        text,
        ["body", "body part", "body parts", "legs", "leg", "mane", "tail", "hoof", "hooves", "ear", "ears"],
    ):
        body_detail = facts.get("body", facts["fact"])
        color = _first_color(text)
        observed = f"I noticed your color clue too: {color}. " if color else ""
        return (
            observed + body_detail,
            facts["next"],
            facts["badge"],
            "body clue",
        )
    if any(term in text for term in ["color", "colour", "white", "brown", "black", "gray", "grey", "orange", "red", "yellow"]):
        color = _first_color(text)
        observed = f"The {subject} looks {color} from your clue. " if color else ""
        return (
            observed + facts["color"],
            facts["next"],
            facts["badge"],
            "color clue",
        )
    if any(term in text for term in ["eat", "eats", "food", "feed", "snack", "beslen", "yer"]):
        return (
            facts["eat"],
            facts["next"],
            facts["badge"],
            "diet question",
        )
    if any(term in text for term in ["where", "live", "home", "nest", "burrow", "hide", "nerede", "yaşar"]):
        return (
            facts["home"],
            facts["next"],
            facts["badge"],
            "habitat question",
        )
    if any(term in text for term in ["why", "how", "what", "can you answer", "bilmiyorum", "neden", "nasıl", "ne "]):
        return (
            facts["fact"],
            facts["next"],
            facts["badge"],
            "learning question",
        )
    return None


def _has_any_term(text: str, terms: list[str]) -> bool:
    return any(re.search(rf"(^|\W){re.escape(term)}($|\W)", text) for term in terms)


def _extract_known_subject(text: str) -> str:
    aliases = {
        "rabbit": ["rabbit", "bunny", "tavsan", "tavşan"],
        "bird": ["bird", "birds", "kuş", "kus"],
        "cat": ["cat", "kedi"],
        "dog": ["dog", "köpek", "kopek"],
        "butterfly": ["butterfly", "butterflies", "kelebek"],
        "squirrel": ["squirrel", "squirrels", "sincap"],
        "horse": ["horse", "horses", "pony", "ponies"],
    }
    for subject, words in aliases.items():
        if any(re.search(rf"(^|\W){re.escape(word)}($|\W)", text) for word in words):
            return subject
    return "mystery"


def _looks_like_open_learning_question(text: str) -> bool:
    return any(
        term in text
        for term in [
            "why ",
            "how ",
            "what ",
            "where ",
            "color",
            "colour",
            "eat",
            "eats",
            "food",
            "live",
            "legs",
            "body",
            "part",
            "hoof",
            "hooves",
            "mane",
            "tail",
            "learn",
            "translate",
            "can you answer",
            "neden ",
            "nasıl ",
            "nasil ",
            "ne ",
            "nerede ",
        ]
    )


def _looks_like_domain_routing_question(text: str) -> bool:
    if any(term in text for term in ["what is this", "what's this", "what is in this", "image attached"]):
        return True
    return any(
        term in text
        for term in [
            "fountain",
            "historic",
            "history",
            "inscription",
            "museum",
            "monument",
            "allergen",
            "ingredient",
            "menu",
            "food photo",
            "plant",
            "leaf",
            "tree",
            "flower",
        ]
    )


def _extract_child_text(prompt: str) -> str:
    marker = "Child says:"
    if marker not in prompt:
        return prompt
    return prompt.split(marker, 1)[1].strip()


def _first_color(text: str) -> str:
    for color in ["white", "brown", "black", "gray", "grey", "orange", "red", "yellow", "green"]:
        if color in text:
            return "gray" if color == "grey" else color
    return ""


def _is_curio_contextual_reply(text: str) -> bool:
    return "curio asked:" in text and "child says:" in text and "previous visual subject:" in text


def _extract_previous_subject(prompt: str) -> str:
    marker = "Previous visual subject:"
    if marker not in prompt:
        return "mystery"
    after_marker = prompt.split(marker, 1)[1].strip()
    subject = after_marker.split(".", 1)[0].strip()
    return _clean_subject_label(subject) or "mystery"


def _clean_subject_label(subject: str) -> str:
    cleaned = " ".join(subject.strip().split())
    if not cleaned:
        return ""
    lowered = cleaned.lower()
    for suffix in [
        " text follow-up",
        " learning question",
        " color clue",
        " body clue",
        " diet question",
        " habitat question",
        " field note",
    ]:
        while lowered.endswith(suffix):
            cleaned = cleaned[: -len(suffix)].strip()
            lowered = cleaned.lower()
    known = _extract_known_subject(cleaned.lower())
    return known.title() if known != "mystery" else cleaned


def _answers_acorn_oak_clue_question(text: str) -> bool:
    has_context = any(term in text for term in ["acorn", "oak", "leaf", "leaves", "cap"])
    has_curio_prompt = "curio asked:" in text or "can you spot" in text
    has_child_observation = any(
        term in text
        for term in ["shape", "sides", "star", "hard part", "lobe", "lobes", "connect", "connected", "tree", "three", "cap"]
    )
    strong_acorn_observation = "acorn" in text and "cap" in text and any(
        term in text for term in ["leaf", "tree", "three", "shape", "star", "connect"]
    )
    return has_context and has_child_observation and (has_curio_prompt or strong_acorn_observation)


def _asks_about_squirrel_food_cache(text: str) -> bool:
    has_squirrel_context = "squirrel" in text or "previous visual subject: squirrel" in text
    has_cache_terms = any(term in text for term in ["bury", "buries", "hidden", "hide", "cache"])
    has_food_context = any(term in text for term in ["food", "snack", "nuts", "their food", "why they"])
    return has_cache_terms and (has_squirrel_context or has_food_context)


def _asks_about_squirrel_hiding_place(text: str) -> bool:
    has_squirrel_context = "squirrel" in text or "curio asked:" in text
    asks_place = any(term in text for term in ["under", "tree", "trees", "threes", "roots", "soil", "where"])
    return has_squirrel_context and asks_place and any(
        term in text for term in ["hide", "hid", "bury", "buried", "food", "snack", "could it be"]
    )


def _asks_what_squirrels_eat(text: str) -> bool:
    has_squirrel_context = "squirrel" in text or "previous visual subject: squirrel" in text
    return has_squirrel_context and any(
        phrase in text
        for phrase in ["what do they eat", "what does it eat", "what do squirrels eat", "what food"]
    )


def _curiosity_answer(
    prompt: str,
    user_mode: UserMode,
    *,
    best_hypothesis: str,
    kid_summary: str,
    parent_summary: str,
    follow_up: str,
    evidence_note: str,
    badge: str = "Nature Explorer",
    domain: Domain = Domain.NATURE,
) -> Investigation:
    return Investigation(
        investigation_id=new_id(),
        domain=domain,
        user_mode=user_mode,
        status="concluded",
        prompt=prompt,
        created_at=now(),
        hypotheses=[
            Hypothesis(
                best_hypothesis,
                ConfidenceBand.HIGH,
                "The child asked a direct follow-up connected to the current nature topic.",
            )
        ],
        evidence=[
            Evidence(
                "conversation",
                "user_follow_up",
                evidence_note,
                ConfidenceBand.HIGH,
            )
        ],
        missing_evidence=[
            EvidenceGap(
                "No extra photo is needed for this follow-up question.",
                0,
                "Keep observing wildlife from a safe distance.",
            )
        ],
        selected_quest=Quest(
            follow_up,
            "9-12",
            "curiosity_question",
            "The child answers or asks another safe question.",
            "Keeps the conversation going after answering the child's question.",
            score=80,
        ),
        safety_flags=["child_mode", "safe_wildlife_distance"],
        policy_message=f"Badge earned: {badge}. The follow-up answer is allowed and does not require a new image.",
        parent_gate_required=False,
        agent_trace=["conversation: answered curiosity follow-up without asking for a new image"],
        confidence_band=ConfidenceBand.HIGH,
        uncertainty_note=kid_summary,
        conclusion=Conclusion(
            best_hypothesis=best_hypothesis,
            confidence_band=ConfidenceBand.HIGH,
            alternatives=[],
            uncertainty_note="General educational nature answer, not a species certification.",
            parent_summary=parent_summary,
            kid_summary=kid_summary,
            sources=["Curio nature knowledge", "Prior conversation context"],
        ),
    )


def enrich_safe_visual_answer(investigation: Investigation, labels) -> Investigation:
    if investigation.safety_events or not labels:
        return investigation
    subject = best_subject_label(labels)
    if not subject:
        return investigation

    kid_subject = subject.lower()
    fact, curiosity_question = curiosity_fact_and_question(subject, investigation.domain)
    fallback_kid_summary = (
        f"This looks like a {kid_subject}. {fact}"
        if subject[0].lower() not in "aeiou"
        else f"This looks like an {kid_subject}. {fact}"
    )
    kid_summary = fallback_kid_summary
    source = "fallback"
    if not load_settings().demo_mode:
        label_context = ", ".join(
            f"{label.name} ({label.confidence:.0f}%)" for label in labels[:8]
        )
        kid_summary, curiosity_question, source = generate_curiosity_followup_text(
            (
                f"Uploaded image case. Visual subject: {subject}. "
                f"Visual labels: {label_context}. "
                f"Current app domain: {investigation.domain.value}. "
                "Create the first child-facing case-board finding and one curiosity mission."
            ),
            subject,
            fallback_kid_summary,
            curiosity_question,
        )
    parent_summary = (
        f"Curio used visual labels to make a cautious first identification: {subject}. "
        f"The answer stays provisional and invites a safe follow-up question instead of ending the interaction. "
        f"Answer source: {source}."
    )
    investigation.conclusion = Conclusion(
        best_hypothesis=subject,
        confidence_band=ConfidenceBand.MEDIUM,
        alternatives=[h.label for h in investigation.hypotheses if h.label != subject][:3],
        uncertainty_note="Visual labels are helpful but not a certified species or safety identification.",
        parent_summary=parent_summary,
        kid_summary=kid_summary,
        sources=["AWS Rekognition visual labels", "Curio child-safety policy"],
    )
    investigation.status = "concluded"
    investigation.confidence_band = ConfidenceBand.MEDIUM
    investigation.uncertainty_note = kid_summary
    investigation.selected_quest = Quest(
        curiosity_question,
        investigation.selected_quest.age_band,
        "curiosity_question",
        "The child answers or asks another safe question.",
        "Keeps the learning loop alive after a cautious visual identification.",
        score=investigation.selected_quest.score,
    )
    if investigation.hypotheses:
        investigation.hypotheses[0].label = subject
        investigation.hypotheses[0].rationale = (
            "The visual label evidence points here, but Curio keeps the wording cautious."
        )
    badge = _dynamic_visual_badge(subject, investigation.domain, bool(investigation.safety_events))
    investigation.policy_message = (
        f"Badge earned: {badge}. Visual case-board finding generated from the live image context."
    )
    investigation.agent_trace.append(f"curiosity: generated follow-up about {subject} via {source}")
    return investigation


def _dynamic_visual_badge(subject: str, domain: Domain, safety_case: bool = False) -> str:
    clean = " ".join(part for part in subject.strip().split() if part).title()
    if safety_case:
        return "Safety Captain"
    if not clean or clean == "Unknown":
        clean = "Clue"
    if domain == Domain.HERITAGE:
        return f"{clean} Detective"
    if domain == Domain.DINING:
        return f"{clean} Safety Scout"
    if domain == Domain.GENERAL:
        return f"{clean} Explorer"
    return f"{clean} Scout"
