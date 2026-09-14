from __future__ import annotations

from dataclasses import dataclass

from app.domain import ConfidenceBand, Domain, Evidence, EvidenceGap, Hypothesis, Quest


@dataclass(frozen=True)
class DomainPlaybook:
    domain: Domain
    sources: list[str]
    hypotheses: list[Hypothesis]
    gap: EvidenceGap
    quest: Quest
    evidence: list[Evidence]
    uncertainty: str


PLAYBOOKS = {
    Domain.HERITAGE: DomainPlaybook(
        domain=Domain.HERITAGE,
        sources=[
            "Local heritage registry allowlist",
            "Museum or municipality plaque OCR",
            "Architectural feature checklist",
        ],
        hypotheses=[
            Hypothesis(
                "Ottoman-era public fountain",
                ConfidenceBand.MEDIUM,
                "The visible stonework and arch-like form suggest a civic water structure, but the inscription is not verified yet.",
            ),
            Hypothesis(
                "Later-period restoration or replica",
                ConfidenceBand.LOW,
                "Fresh stone or missing weathering could mean the structure was restored or rebuilt.",
            ),
            Hypothesis(
                "Religious or municipal facade detail",
                ConfidenceBand.LOW,
                "A single cropped view can confuse a fountain niche with a facade element.",
            ),
        ],
        gap=EvidenceGap(
            "Readable inscription or plaque plus a side-angle view of the arch and basin",
            86,
            "Do not climb, enter traffic, or cross barriers. Use zoom instead of getting too close.",
        ),
        quest=Quest(
            "Take one zoomed photo of the inscription or nearby information plaque, then one side photo showing the arch and basin.",
            "9-12",
            "photo+ocr",
            "At least one text clue or one side-angle architectural clue is visible.",
            "High information gain, low effort, and safe distance from the structure.",
        ),
        evidence=[
            Evidence(
                "photo",
                "user_upload",
                "Initial image starts the hypothesis set but does not show enough text or side geometry.",
                ConfidenceBand.MEDIUM,
            )
        ],
        uncertainty="We need one more clue before naming the structure confidently.",
    ),
    Domain.NATURE: DomainPlaybook(
        domain=Domain.NATURE,
        sources=[
            "Local species checklist",
            "Season and coarse-region filter",
            "Non-contact plant observation guide",
        ],
        hypotheses=[
            Hypothesis(
                "Common local plant",
                ConfidenceBand.MEDIUM,
                "Leaf shape is plausible, but one image is not enough for a safe identification.",
            ),
            Hypothesis(
                "Lookalike species",
                ConfidenceBand.MEDIUM,
                "Several plants share similar leaf outlines.",
            ),
        ],
        gap=EvidenceGap(
            "Leaf underside, stem texture, and flower or fruit if present",
            78,
            "Do not touch, taste, pick, or disturb the plant.",
        ),
        quest=Quest(
            "Photograph the leaf underside and stem without touching the plant.",
            "9-12",
            "photo",
            "A second non-contact detail photo is available.",
            "Good species separation with a strong safety rule.",
        ),
        evidence=[
            Evidence("photo", "user_upload", "Initial plant image supplied.", ConfidenceBand.MEDIUM)
        ],
        uncertainty="Nature results stay cautious until multiple safe observations agree.",
    ),
    Domain.DINING: DomainPlaybook(
        domain=Domain.DINING,
        sources=[
            "Menu OCR",
            "Restaurant allergen statement",
            "Adult-confirmed ingredient note",
        ],
        hypotheses=[
            Hypothesis(
                "Visible ingredients only",
                ConfidenceBand.MEDIUM,
                "The image can show likely visible items, not preparation details.",
            ),
            Hypothesis(
                "Hidden allergen or cross-contact unknown",
                ConfidenceBand.MEDIUM,
                "Oil, sauces, utensils, and kitchen practices cannot be verified visually.",
            ),
        ],
        gap=EvidenceGap(
            "Menu OCR or staff statement about allergens and preparation",
            82,
            "Do not make allergy, health, halal, or safety decisions from the image alone.",
        ),
        quest=Quest(
            "Scan the menu allergen line or ask an adult to confirm ingredients with staff.",
            "9-12",
            "ocr+adult",
            "A menu or adult-confirmed statement is captured.",
            "Visual evidence cannot settle hidden ingredients.",
        ),
        evidence=[
            Evidence(
                "photo",
                "user_upload",
                "Food image supplied; hidden ingredients remain unknown.",
                ConfidenceBand.LOW,
            )
        ],
        uncertainty="We can separate seen, stated, and unknown information.",
    ),
    Domain.GENERAL: DomainPlaybook(
        domain=Domain.GENERAL,
        sources=["User-provided clue"],
        hypotheses=[
            Hypothesis(
                "Needs domain routing",
                ConfidenceBand.LOW,
                "The prompt does not identify enough context for a specialized investigation.",
            )
        ],
        gap=EvidenceGap(
            "One concrete photo, text clue, or location context",
            60,
            "Avoid personal data and unsafe movement.",
        ),
        quest=Quest(
            "Add one photo or clue that shows what you want to investigate.",
            "9-12",
            "photo_or_text",
            "A focused clue is provided.",
            "The next clue lets the agent choose the right domain.",
        ),
        evidence=[],
        uncertainty="The agent needs a clearer observation before choosing a domain.",
    ),
}


def playbook_for(domain: Domain) -> DomainPlaybook:
    return PLAYBOOKS[domain]

