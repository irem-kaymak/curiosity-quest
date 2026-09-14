from __future__ import annotations

from app.domain import Investigation


def agent_card(investigation: Investigation) -> dict[str, object]:
    event = investigation.safety_events[0] if investigation.safety_events else None
    return {
        "investigation_id": investigation.investigation_id,
        "status": investigation.status,
        "domain": investigation.domain.value,
        "headline": event.title if event else _lead_hypothesis(investigation),
        "agentic_loop": [
            {
                "step": "observe",
                "output": investigation.evidence[0].observation
                if investigation.evidence
                else investigation.prompt,
            },
            {
                "step": "hypothesize",
                "output": [
                    {
                        "label": h.label,
                        "confidence": h.probability_band.value,
                        "status": h.status,
                    }
                    for h in investigation.hypotheses
                ],
            },
            {
                "step": "seek_evidence",
                "output": {
                    "missing_feature": investigation.missing_evidence[0].required_feature
                    if investigation.missing_evidence
                    else "",
                    "quest": investigation.selected_quest.instruction,
                    "quest_score": investigation.selected_quest.score,
                },
            },
            {
                "step": "policy",
                "output": {
                    "message": investigation.policy_message,
                    "flags": investigation.safety_flags,
                    "parent_gate_required": investigation.parent_gate_required,
                },
            },
            {
                "step": "notify",
                "output": {
                    "safety_event": event.__dict__ | {"severity": event.severity.value}
                    if event
                    else None,
                    "deliveries": investigation.notification_deliveries,
                },
            },
        ],
        "why_original": [
            "The agent delays final answers until useful evidence is collected.",
            "Child guidance and parent guidance are separated in the backend state.",
            "Safety events can fan out to in-app, push, email, and SMS channels.",
        ],
    }


def _lead_hypothesis(investigation: Investigation) -> str:
    if investigation.hypotheses:
        return investigation.hypotheses[0].label
    return "Curio investigation"
