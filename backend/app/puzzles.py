from __future__ import annotations

import json

from app.config import load_settings
from app.store import list_recent


def dynamic_puzzles(age_band: str = "9-12", topic: str = "mixed") -> list[dict[str, object]]:
    settings = load_settings()
    if not settings.demo_mode:
        try:
            live = _generate_live_puzzles(
                age_band,
                topic,
                settings.aws_region,
                settings.bedrock_model_id,
                _recent_case_context(),
            )
        except Exception as exc:
            raise RuntimeError(
                f"Live Curio puzzle generation unavailable: {type(exc).__name__}: {exc}"
            ) from exc
        if live:
            return live
        raise RuntimeError("Live Curio puzzle generation returned no cards.")
    older = age_band in {"7-9", "9-12", "13-15", "older", "teen"}
    base = _older_puzzles if older else _younger_puzzles
    if topic and topic != "mixed":
        filtered = [item for item in base if item["topic"] == topic]
        if filtered:
            return [_public(item) for item in filtered[:3]]
    return [_public(item) for item in base[:3]]


def _public(item: dict[str, object]) -> dict[str, object]:
    return {
        "title": item["title"],
        "emoji": item["emoji"],
        "choices": item["choices"],
        "correct": item["correct"],
        "explanation": item["explanation"],
        "topic": item["topic"],
        "xp": item["xp"],
        "source": "demo",
    }


def _generate_live_puzzles(
    age_band: str,
    topic: str,
    region: str,
    model_id: str,
    case_context: str,
) -> list[dict[str, object]]:
    import boto3  # type: ignore

    client = boto3.client("bedrock-runtime", region_name=region)
    response = client.converse(
        modelId=model_id,
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "text": (
                            "You are Curio, a child-safe puzzle maker for an investigator-style learning app. "
                            "Create 3 fresh multiple-choice puzzle cards. Keep them dynamic, playful, and age-safe. "
                            "Do not reuse squirrel/rabbit/acorn examples unless the topic asks for them. "
                            "Use the latest case context as the main source when it exists, so the cards feel connected "
                            "to the child's real investigation instead of a generic quiz deck. "
                            "Return only JSON as an array. Each item must have: "
                            "title string, emoji string, choices array of exactly 3 strings, correct integer 0-2, "
                            "explanation string, topic string, xp integer. "
                            "Questions should teach observation, reasoning, safety, language, science, nature, or history. "
                            "Vary the question style across the three cards. "
                            f"Age band: {age_band}. Topic: {topic or 'mixed'}.\n"
                            f"Latest case context:\n{case_context or 'No saved case context yet.'}"
                        )
                    }
                ],
            }
        ],
        inferenceConfig={"temperature": 0.8, "maxTokens": 1200},
    )
    text = _extract_text(response)
    data = json.loads(_json_array(text))
    if not isinstance(data, list):
        return []
    return [_normalize_live_puzzle(item) for item in data if isinstance(item, dict)][:3]


def _recent_case_context(limit: int = 5) -> str:
    try:
        investigations = list_recent(limit=limit)
    except Exception:
        return ""
    lines: list[str] = []
    for index, investigation in enumerate(investigations, start=1):
        subject = (
            investigation.conclusion.best_hypothesis
            if investigation.conclusion
            else investigation.hypotheses[0].label
            if investigation.hypotheses
            else "unknown subject"
        )
        finding = (
            investigation.conclusion.kid_summary
            if investigation.conclusion
            else investigation.uncertainty_note
        )
        lines.append(
            " | ".join(
                [
                    f"Case {index}",
                    f"domain={investigation.domain.value}",
                    f"subject={subject}",
                    f"child_question={investigation.prompt[:180]}",
                    f"finding={finding[:220]}",
                    f"next_mission={investigation.selected_quest.instruction[:180]}",
                ]
            )
        )
    return "\n".join(lines)


def _normalize_live_puzzle(item: dict[str, object]) -> dict[str, object]:
    choices = item.get("choices")
    if not isinstance(choices, list):
        choices = []
    clean_choices = [str(choice).strip() for choice in choices if str(choice).strip()][:3]
    if len(clean_choices) < 3:
        raise ValueError("live puzzle needs three choices")
    correct = item.get("correct", 0)
    if not isinstance(correct, int) or correct < 0 or correct > 2:
        correct = 0
    title = str(item.get("title", "")).strip()
    explanation = str(item.get("explanation", "")).strip()
    if not title or not explanation:
        raise ValueError("live puzzle needs title and explanation")
    xp = item.get("xp", 30)
    if not isinstance(xp, int):
        xp = 30
    return {
        "title": title,
        "emoji": str(item.get("emoji", "🔎")).strip() or "🔎",
        "choices": clean_choices,
        "correct": correct,
        "explanation": explanation,
        "topic": str(item.get("topic", "mixed")).strip() or "mixed",
        "xp": max(10, min(xp, 80)),
        "source": "bedrock",
    }


def _extract_text(response: dict) -> str:
    for block in response.get("output", {}).get("message", {}).get("content", []):
        if "text" in block:
            return block["text"]
    return ""


def _json_array(text: str) -> str:
    stripped = text.strip()
    if stripped.startswith("```"):
        stripped = stripped.strip("`")
        if stripped.lower().startswith("json"):
            stripped = stripped[4:].strip()
    start = stripped.find("[")
    end = stripped.rfind("]")
    if start >= 0 and end >= start:
        return stripped[start : end + 1]
    return stripped


_younger_puzzles: list[dict[str, object]] = [
    {
        "topic": "nature",
        "title": "Curio sees wings with colors. What clue should we check first?",
        "emoji": "🦋",
        "choices": ["Color and shape", "Shoe size", "Phone sound"],
        "correct": 0,
        "explanation": "Good explorers start with what they can safely see: color, shape, and pattern.",
        "xp": 25,
    },
    {
        "topic": "nature",
        "title": "A flower has a yellow middle and white petals. What is that?",
        "emoji": "🌼",
        "choices": ["Two useful clues", "A secret password", "A weather report"],
        "correct": 0,
        "explanation": "Two clues together make a stronger investigation than one clue alone.",
        "xp": 25,
    },
    {
        "topic": "safety",
        "title": "If Curio spots a risky object, what comes first?",
        "emoji": "🛡️",
        "choices": ["Step back and call a grown-up", "Touch it carefully", "Hide it"],
        "correct": 0,
        "explanation": "A good investigator stays safe first, then keeps exploring with help.",
        "xp": 30,
    },
]

_older_puzzles: list[dict[str, object]] = [
    {
        "topic": "nature",
        "title": "Why is one visual clue not always enough?",
        "emoji": "🔎",
        "choices": ["Lookalike species can share clues", "Photos never help", "Animals all look the same"],
        "correct": 0,
        "explanation": "Investigators compare several clues before making a strong claim.",
        "xp": 35,
    },
    {
        "topic": "nature",
        "title": "Which pair of clues makes a stronger nature case?",
        "emoji": "🌿",
        "choices": ["Shape plus where it was found", "Only a guess", "Only the app color"],
        "correct": 0,
        "explanation": "A strong case compares more than one clue before deciding.",
        "xp": 35,
    },
    {
        "topic": "safety",
        "title": "What should happen when a hazard is detected?",
        "emoji": "🛡️",
        "choices": ["Child gets safety steps and parent is notified", "The app ignores it", "Only a game badge appears"],
        "correct": 0,
        "explanation": "Curio keeps the child calm with steps while a parent alert is sent right away.",
        "xp": 40,
    },
]
