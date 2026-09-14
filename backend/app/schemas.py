from __future__ import annotations

from typing import Optional

from pydantic import BaseModel, Field

from app.notifications import ParentContact


class ParentContactInput(BaseModel):
    email: Optional[str] = Field(default=None, max_length=160)
    phone: Optional[str] = Field(default=None, max_length=40)
    push_token: Optional[str] = Field(default=None, max_length=400)
    email_verified: bool = False
    phone_verified: bool = False
    push_enabled: bool = False

    def to_contact(self) -> ParentContact:
        return ParentContact(
            email=self.email,
            phone=self.phone,
            push_token=self.push_token,
            email_verified=self.email_verified,
            phone_verified=self.phone_verified,
            push_enabled=self.push_enabled,
        )


class ObservationInput(BaseModel):
    text: Optional[str] = Field(default=None, max_length=2000)
    image_base64: Optional[str] = Field(
        default=None,
        description="Optional compressed image payload.",
    )
    ocr_text: Optional[str] = Field(default=None, max_length=4000)
    coarse_location: Optional[str] = Field(
        default=None,
        max_length=120,
        description="City/area-level context only. Do not send precise child location.",
    )
    captured_at: Optional[str] = Field(default=None, max_length=80)

    def summary(self) -> str:
        parts = []
        if self.text:
            parts.append(self.text.strip())
        if self.ocr_text:
            parts.append(f"OCR text: {self.ocr_text.strip()}")
        if self.coarse_location:
            parts.append(f"Coarse location: {self.coarse_location.strip()}")
        if self.image_base64:
            parts.append("Image attached.")
        return " ".join(part for part in parts if part)


class StartRequest(BaseModel):
    prompt: str = Field(default="", max_length=2000)
    user_mode: str = "kid"
    age_band: str = Field(default="9-12", max_length=20)
    observation: Optional[ObservationInput] = None
    parent_contact: Optional[ParentContactInput] = None

    def investigation_prompt(self) -> str:
        observation_summary = self.observation.summary() if self.observation else ""
        return " ".join(part for part in [self.prompt.strip(), observation_summary] if part)


class EvidenceRequest(BaseModel):
    observation: str = Field(max_length=4000)
    evidence_type: str = Field(default="user_observation", max_length=80)
    ocr_text: Optional[str] = Field(default=None, max_length=4000)

    def evidence_observation(self) -> str:
        if self.ocr_text:
            return f"{self.observation.strip()} OCR text: {self.ocr_text.strip()}"
        return self.observation.strip()


class ParentRegistrationRequest(BaseModel):
    parent_name: str = Field(default="", max_length=120)
    child_name: str = Field(default="", max_length=120)
    contact: ParentContactInput


class TtsRequest(BaseModel):
    text: str = Field(default="", max_length=2000)
