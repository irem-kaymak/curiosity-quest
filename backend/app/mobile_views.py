from __future__ import annotations

from app.domain import Investigation


def kid_view(investigation: Investigation) -> dict:
    first_hypothesis = investigation.hypotheses[0] if investigation.hypotheses else None
    safety_event = investigation.safety_events[0] if investigation.safety_events else None
    if investigation.conclusion:
        headline = investigation.conclusion.best_hypothesis
        message = investigation.conclusion.kid_summary
        next_action = "Add this to your discovery card."
    elif safety_event:
        headline = safety_event.title
        message = safety_event.child_message
        next_action = "Find a grown-up now."
    else:
        headline = first_hypothesis.label if first_hypothesis else "Let us investigate"
        message = investigation.uncertainty_note
        next_action = investigation.selected_quest.instruction

    return {
        "investigation_id": investigation.investigation_id,
        "status": investigation.status,
        "domain": investigation.domain.value,
        "headline": headline,
        "message": message,
        "confidence_language": _kid_confidence(investigation.confidence_band.value),
        "next_action": next_action,
        "safety_rule": investigation.selected_quest.completion_rule,
        "parent_gate_required": investigation.parent_gate_required,
        "safety_event": safety_event.__dict__ | {"severity": safety_event.severity.value}
        if safety_event
        else None,
        "agent_trace": investigation.agent_trace[-3:],
    }


def parent_view(investigation: Investigation) -> dict:
    return {
        "investigation_id": investigation.investigation_id,
        "status": investigation.status,
        "domain": investigation.domain.value,
        "confidence_band": investigation.confidence_band.value,
        "hypotheses": [h.__dict__ | {"probability_band": h.probability_band.value} for h in investigation.hypotheses],
        "evidence": [e.__dict__ | {"reliability": e.reliability.value} for e in investigation.evidence],
        "missing_evidence": [g.__dict__ for g in investigation.missing_evidence],
        "quest": investigation.selected_quest.__dict__,
        "safety_flags": investigation.safety_flags,
        "policy_message": investigation.policy_message,
        "parent_gate_required": investigation.parent_gate_required,
        "safety_events": [
            event.__dict__ | {"severity": event.severity.value}
            for event in investigation.safety_events
        ],
        "agent_trace": investigation.agent_trace,
        "summary": investigation.conclusion.parent_summary
        if investigation.conclusion
        else investigation.uncertainty_note,
        "sources": investigation.conclusion.sources if investigation.conclusion else [],
    }


def _kid_confidence(confidence: str) -> str:
    if confidence == "high":
        return "Strong clue"
    if confidence == "medium":
        return "Getting closer"
    return "Not sure yet"
