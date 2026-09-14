from __future__ import annotations

from typing import List

from pydantic import BaseModel, Field


class HypothesisPlan(BaseModel):
    label: str = Field(description="Candidate answer label.")
    probability_band: str = Field(description="low, medium, or high.")
    rationale: str = Field(description="Evidence-based reason for this hypothesis.")


class QuestPlan(BaseModel):
    required_feature: str = Field(description="The missing clue that would reduce uncertainty.")
    quest_instruction: str = Field(description="Safe real-world task for the user.")
    modality: str = Field(description="photo, ocr, audio, text, or a combination.")
    safety_constraint: str = Field(description="Plain safety rule before doing the task.")


class AgentInvestigationPlan(BaseModel):
    domain: str = Field(description="heritage, nature, safe_dining, or general.")
    hypotheses: List[HypothesisPlan]
    selected_quest: QuestPlan
    uncertainty_note: str
    safety_flags: List[str]

