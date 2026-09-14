from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
from typing import Any
from uuid import uuid4


class TextEnum(str, Enum):
    pass


class Domain(TextEnum):
    HERITAGE = "heritage"
    NATURE = "nature"
    DINING = "safe_dining"
    GENERAL = "general"


class UserMode(TextEnum):
    KID = "kid"
    PARENT = "parent"


class ConfidenceBand(TextEnum):
    LOW = "low"
    MEDIUM = "medium"
    HIGH = "high"


class SafetyLevel(TextEnum):
    SAFE = "safe"
    CAUTION = "caution"
    DANGER = "danger"
    EMERGENCY = "emergency"


@dataclass
class Hypothesis:
    label: str
    probability_band: ConfidenceBand
    rationale: str
    status: str = "active"


@dataclass
class Evidence:
    type: str
    source: str
    observation: str
    reliability: ConfidenceBand
    timestamp: str = field(
        default_factory=lambda: datetime.now(timezone.utc).isoformat()
    )


@dataclass
class EvidenceGap:
    required_feature: str
    expected_information_gain: int
    safety_constraint: str


@dataclass
class Quest:
    instruction: str
    age_band: str
    modality: str
    completion_rule: str
    score_reason: str
    score: int = 0


@dataclass
class Conclusion:
    best_hypothesis: str
    confidence_band: ConfidenceBand
    alternatives: list[str]
    uncertainty_note: str
    parent_summary: str
    kid_summary: str
    sources: list[str]


@dataclass
class SafetyEvent:
    severity: SafetyLevel
    title: str
    child_message: str
    parent_message: str
    recommended_action: str
    notify_parent: bool = True


@dataclass
class Investigation:
    investigation_id: str
    domain: Domain
    user_mode: UserMode
    status: str
    prompt: str
    created_at: str
    hypotheses: list[Hypothesis]
    evidence: list[Evidence]
    missing_evidence: list[EvidenceGap]
    selected_quest: Quest
    safety_flags: list[str]
    policy_message: str
    parent_gate_required: bool
    agent_trace: list[str]
    confidence_band: ConfidenceBand
    uncertainty_note: str
    safety_events: list[SafetyEvent] = field(default_factory=list)
    notification_deliveries: list[dict[str, Any]] = field(default_factory=list)
    conclusion: Conclusion | None = None

    def to_dict(self) -> dict[str, Any]:
        def value(obj: Any) -> Any:
            if isinstance(obj, TextEnum):
                return obj.value
            if hasattr(obj, "__dataclass_fields__"):
                return {k: value(v) for k, v in obj.__dict__.items()}
            if isinstance(obj, list):
                return [value(item) for item in obj]
            return obj

        return value(self)


def new_id() -> str:
    return f"inv_{uuid4().hex[:12]}"


def now() -> str:
    return datetime.now(timezone.utc).isoformat()
