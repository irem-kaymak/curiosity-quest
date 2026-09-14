from __future__ import annotations

from dataclasses import dataclass

from app.domain import EvidenceGap, Quest


@dataclass(frozen=True)
class QuestCandidate:
    quest: Quest
    information_gain: int
    user_effort: int
    safety_risk: int
    technical_risk: int

    @property
    def score(self) -> int:
        return (
            self.information_gain
            - self.user_effort
            - self.safety_risk
            - self.technical_risk
        )


def score_quest(gap: EvidenceGap, quest: Quest) -> QuestCandidate:
    effort = 12 if "photo" in quest.modality else 8
    safety = 8 if "adult" in quest.modality else 4
    technical = 9 if "ocr" in quest.modality else 5
    return QuestCandidate(
        quest=quest,
        information_gain=gap.expected_information_gain,
        user_effort=effort,
        safety_risk=safety,
        technical_risk=technical,
    )


def explain_score(candidate: QuestCandidate) -> str:
    return (
        f"QuestScore {candidate.score}: information gain "
        f"{candidate.information_gain}, effort {candidate.user_effort}, "
        f"safety risk {candidate.safety_risk}, technical risk {candidate.technical_risk}."
    )

