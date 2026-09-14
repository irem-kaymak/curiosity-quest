from __future__ import annotations

from dataclasses import dataclass
import re

from app.domain import Domain, SafetyEvent, SafetyLevel, UserMode


@dataclass(frozen=True)
class PolicyResult:
    flags: list[str]
    blocked: bool
    parent_gate_required: bool
    message: str
    safety_level: SafetyLevel
    safety_event: SafetyEvent | None = None


DANGEROUS_TERMS = {
    "climb",
    "cross traffic",
    "taste",
    "eat it",
    "touch it",
    "private property",
    "water edge",
}

SAFETY_NEGATIONS = (
    r"do not\s+{term}",
    r"don't\s+{term}",
    r"never\s+{term}",
    r"no\s+{term}",
    r"without\s+{term}",
)

PII_TERMS = {"face", "license plate", "home address", "phone number"}

EMERGENCY_TERMS = {
    "fire",
    "flame",
    "smoke",
    "gas leak",
    "burning",
    "blood",
    "gun",
    "weapon",
    "unconscious",
}

DANGER_TERMS = {
    "knife",
    "blade",
    "scissors",
    "broken glass",
    "socket",
    "electric wire",
    "chemical",
    "medicine bottle",
    "pills",
}


def evaluate_policy(
    *,
    domain: Domain,
    user_mode: UserMode,
    prompt: str,
    proposed_task: str,
) -> PolicyResult:
    text = f"{prompt} {proposed_task}".lower()
    flags = ["privacy_minimization"]

    if user_mode == UserMode.KID:
        flags.append("child_mode")
        flags.append("strip_faces_and_plates")

    if any(term in text for term in PII_TERMS):
        flags.append("strip_faces_plates_addresses")

    if domain == Domain.HERITAGE:
        flags.extend(["child_safe_distance", "no_private_property"])
    elif domain == Domain.NATURE:
        flags.extend(["no_touching", "no_edibility_claim"])
    elif domain == Domain.DINING:
        flags.extend(["adult_gate", "no_medical_claim", "no_halal_certainty"])

    safety_level, safety_event = _detect_safety_event(text)
    if safety_event:
        flags.extend(["parent_notify", f"safety_{safety_level.value}"])

    blocked = _contains_unsafe_instruction(proposed_task)
    parent_gate_required = domain == Domain.DINING or (
        user_mode == UserMode.KID
        and (
            any(term in text for term in ["allergen", "health", "medicine"])
            or safety_level in {SafetyLevel.DANGER, SafetyLevel.EMERGENCY}
        )
    )

    if safety_level == SafetyLevel.EMERGENCY:
        message = "Emergency risk detected. Pause the learning flow and alert a trusted adult immediately."
    elif safety_level == SafetyLevel.DANGER:
        message = "Potential danger detected. Keep the child away from the item and notify a parent."
    elif blocked:
        message = "The proposed task was blocked because it could encourage unsafe real-world action."
    elif parent_gate_required:
        message = "Continue with an adult because this topic may affect health, food safety, or permissions."
    else:
        message = "The next task is allowed with the listed safety constraints."

    return PolicyResult(
        flags=sorted(set(flags)),
        blocked=blocked,
        parent_gate_required=parent_gate_required,
        message=message,
        safety_level=safety_level,
        safety_event=safety_event,
    )


def _contains_unsafe_instruction(task: str) -> bool:
    text = task.lower()
    normalized = text
    for term in DANGEROUS_TERMS:
        pattern_term = re.escape(term)
        for template in SAFETY_NEGATIONS:
            normalized = re.sub(template.format(term=pattern_term), "", normalized)
    return any(term in normalized for term in DANGEROUS_TERMS)


def _detect_safety_event(text: str) -> tuple[SafetyLevel, SafetyEvent | None]:
    if any(term in text for term in EMERGENCY_TERMS):
        return SafetyLevel.EMERGENCY, SafetyEvent(
            SafetyLevel.EMERGENCY,
            "Emergency risk detected",
            "Step away now and call a grown-up. If there is fire, smoke, blood, or a weapon, leave the area if you can do so safely.",
            "Curio detected possible emergency content in your child's question or uploaded image. Check on them immediately and contact emergency services if needed.",
            "Immediate parent check-in. Escalate to emergency services if the situation is real.",
        )
    if any(term in text for term in DANGER_TERMS):
        return SafetyLevel.DANGER, SafetyEvent(
            SafetyLevel.DANGER,
            "Potential danger nearby",
            "Put the device down, move away from it, and ask a grown-up for help.",
            "Curio detected a potentially dangerous object or situation, such as a sharp item, chemical, medicine, or electrical risk.",
            "Parent should review the image/question and confirm the child is safe.",
        )
    return SafetyLevel.SAFE, None


def sanitize_child_task(task: str, domain: Domain) -> str:
    cleaned = " ".join(task.strip().split())
    if not cleaned:
        return cleaned

    # Keep mobile child tasks short and physical-world safe.
    first_sentence = cleaned.split(".")[0].strip()
    if domain == Domain.HERITAGE:
        return (
            "Use zoom to photograph the inscription or nearby information plaque, "
            "then take one side photo from a safe distance."
        )
    if domain == Domain.NATURE:
        if any(
            term in cleaned.lower()
            for term in ["animal", "squirrel", "wildlife", "bird", "insect", "tail", "ears"]
        ):
            return (
                "Use zoom from where you are to look at the animal. "
                "Do not approach, touch, chase, or feed it."
            )
        return "Take one close photo of the leaf and stem without touching the plant."
    if domain == Domain.DINING:
        return "Ask an adult to scan the menu allergen line or confirm ingredients with staff."
    return first_sentence[:220]
