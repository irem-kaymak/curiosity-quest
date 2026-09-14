from __future__ import annotations

import json
from contextlib import redirect_stdout
from io import StringIO

from app.agent_core import (
    start_investigation,
    start_investigation_from_plan,
    start_visual_fallback_investigation,
)
from app.agent_output import AgentInvestigationPlan
from app.config import load_settings
from app.domain import Investigation, UserMode
from app.vision import sniff_image_format


def agent_runtime_status() -> dict[str, object]:
    settings = load_settings()
    status: dict[str, object] = {
        "demo_mode": settings.demo_mode,
        "aws_region": settings.aws_region,
        "bedrock_model_id": settings.bedrock_model_id,
        "image_pipeline": "rekognition_live_text_case_board_v7",
        "strands_installed": False,
        "bedrock_model_importable": False,
    }
    try:
        import strands  # type: ignore  # noqa: F401

        status["strands_installed"] = True
    except Exception:
        return status
    try:
        from strands.models import BedrockModel  # type: ignore  # noqa: F401

        status["bedrock_model_importable"] = True
    except Exception:
        pass
    return status


def run_curiosity_agent(prompt: str, user_mode: UserMode = UserMode.KID) -> Investigation:
    """Run the live Strands agent when available, otherwise use the demo core.

    The deterministic path is intentional: judges can see the agentic state
    machine without requiring credentials during a local demo. Replace this
    function body with Strands tools for Bedrock vision, OCR, retrieval, and
    policy checks when AWS credentials are configured.
    """
    settings = load_settings()
    if settings.demo_mode:
        return start_investigation(prompt, user_mode)

    try:
        from strands import Agent  # type: ignore
        from strands.models import BedrockModel  # type: ignore
    except Exception:
        return start_investigation(prompt, user_mode)

    model = BedrockModel(
        model_id=settings.bedrock_model_id,
        region_name=settings.aws_region,
        temperature=0.2,
    )
    agent = Agent(
        model=model,
        system_prompt=(
            "You are Curiosity Quest. Produce structured investigation plans "
            "that delay final answers until evidence is collected. Never ask a "
            "child to climb, trespass, taste unknown food or plants, approach "
            "traffic, or collect personal data."
        ),
    )
    # Strands validates this Pydantic schema through structured tool output.
    try:
        with redirect_stdout(StringIO()):
            result = agent(
                f"Plan a safe evidence quest for this mobile-app observation: {prompt}",
                structured_output_model=AgentInvestigationPlan,
            )
    except Exception:
        return start_investigation(prompt, user_mode)
    _plan = result.structured_output
    if not isinstance(_plan, AgentInvestigationPlan):
        return start_investigation(prompt, user_mode)
    return start_investigation_from_plan(prompt, _plan, user_mode)


def generate_curiosity_followup_text(
    prompt: str,
    subject: str,
    fallback_answer: str,
    fallback_question: str,
) -> tuple[str, str, str]:
    """Generate the child-facing follow-up through Bedrock when live mode is on.

    The deterministic answer is only the offline/test fallback. Production runs
    should keep Curio's language dynamic while preserving the safety envelope.
    """
    settings = load_settings()
    if settings.demo_mode:
        return fallback_answer, fallback_question, "fallback"
    last_error = ""
    try:
        import boto3  # type: ignore

        client = boto3.client("bedrock-runtime", region_name=settings.aws_region)
        answer, question, raw_text = _call_followup_model(
            client,
            settings.bedrock_model_id,
            subject,
            prompt,
            fallback_answer,
            fallback_question,
        )
        if answer and question and not _looks_like_unhelpful_followup_answer(answer):
            return answer, question, "bedrock"
        last_error = "primary model returned an empty or unhelpful answer"
        repaired_answer, repaired_question, _ = _call_followup_repair_model(
            client,
            settings.bedrock_model_id,
            subject,
            prompt,
            raw_text or answer,
            fallback_answer,
            fallback_question,
        )
        if (
            repaired_answer
            and repaired_question
            and not _looks_like_unhelpful_followup_answer(repaired_answer)
        ):
            return repaired_answer, repaired_question, "bedrock_repair"
        last_error = "repair model returned an empty or unhelpful answer"
    except Exception as exc:
        last_error = f"{type(exc).__name__}: {str(exc)[:180]}"
    raise RuntimeError(f"Live Curio AI answer unavailable: {last_error}")


def _call_followup_model(
    client,
    model_id: str,
    subject: str,
    prompt: str,
    fallback_answer: str,
    fallback_question: str,
) -> tuple[str, str, str]:
    response = client.converse(
        modelId=model_id,
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "text": (
                            "You are Curio, a child-safe investigator buddy. "
                            "The child may be answering your previous question or asking a new text-only question. "
                            "First answer the child's actual words directly. Do not say you need a clearer observation, "
                            "do not ask for a new photo, and do not give a generic process answer unless safety requires it. "
                            "Use 2-4 short kid-friendly sentences, then one playful investigation question. "
                            "Keep animal distance and safety rules. Return only JSON with keys answer, next_question. "
                            f"Known subject: {subject}. "
                            f"If unsure, adapt this safe answer: {fallback_answer} "
                            f"Use this style for the next question: {fallback_question} "
                            f"Child/context prompt: {prompt}"
                        )
                    }
                ],
            }
        ],
        inferenceConfig={"temperature": 0.45, "maxTokens": 500},
    )
    text = _extract_text(response)
    payload = _json_payload_or_text(text, fallback_question)
    return (
        str(payload.get("answer", "")).strip(),
        str(payload.get("next_question", "")).strip(),
        text,
    )


def _call_followup_repair_model(
    client,
    model_id: str,
    subject: str,
    prompt: str,
    rejected_text: str,
    fallback_answer: str,
    fallback_question: str,
) -> tuple[str, str, str]:
    response = client.converse(
        modelId=model_id,
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "text": (
                            "Rewrite a failed Curio answer. Return only JSON with keys answer and next_question. "
                            "The answer must directly answer the child using the known subject and context. "
                            "Do not mention follow-up text, metadata, labels, JSON, prompts, domain routing, or needing a photo. "
                            "Use the fallback only as factual grounding, but write a fresh child-friendly answer. "
                            f"Known subject: {subject}. "
                            f"Child/context prompt: {prompt}. "
                            f"Rejected answer: {rejected_text}. "
                            f"Grounding answer: {fallback_answer}. "
                            f"Grounding next question: {fallback_question}."
                        )
                    }
                ],
            }
        ],
        inferenceConfig={"temperature": 0.35, "maxTokens": 500},
    )
    text = _extract_text(response)
    payload = _json_payload_or_text(text, fallback_question)
    return (
        str(payload.get("answer", "")).strip(),
        str(payload.get("next_question", "")).strip(),
        text,
    )


def _looks_like_unhelpful_followup_answer(answer: str) -> bool:
    text = " ".join(answer.lower().split())
    return any(
        phrase in text
        for phrase in [
            "we can keep investigating with words first",
            "i will answer what we know",
            "answer what we know, then",
            "needs a clearer observation",
            "before choosing a domain",
            "add one photo",
            "upload a photo",
            "text follow-up text follow-up",
            "good question about the horse text follow-up",
            "what part of the horse text follow-up",
        ]
    )


def _json_payload_or_text(text: str, fallback_question: str) -> dict[str, str]:
    try:
        payload = json.loads(_json_object(text))
        if isinstance(payload, dict):
            return {
                "answer": str(payload.get("answer", "")).strip(),
                "next_question": str(payload.get("next_question", "")).strip(),
            }
    except Exception:
        pass
    cleaned = " ".join(text.strip().split())
    if not cleaned:
        return {"answer": "", "next_question": ""}
    question_start = cleaned.rfind("?")
    if question_start >= 0:
        before = cleaned[: question_start + 1]
        sentences = before.rsplit(".", 1)
        if len(sentences) == 2 and "?" in sentences[1]:
            return {
                "answer": sentences[0].strip() or cleaned,
                "next_question": sentences[1].strip(),
            }
    return {"answer": cleaned, "next_question": fallback_question}


def run_curiosity_agent_with_image(
    prompt: str,
    image_bytes: bytes,
    image_format: str,
    user_mode: UserMode = UserMode.KID,
) -> Investigation:
    settings = load_settings()
    fallback_prompt = f"{prompt} Image attached."
    if settings.demo_mode:
        return start_visual_fallback_investigation(fallback_prompt, user_mode, reason="demo mode")

    try:
        from strands import Agent  # type: ignore
        from strands.models import BedrockModel  # type: ignore
    except Exception:
        return _run_bedrock_image_plan_or_fallback(
            prompt,
            fallback_prompt,
            image_bytes,
            image_format,
            user_mode,
            reason="strands import unavailable",
        )

    model = BedrockModel(
        model_id=settings.bedrock_model_id,
        region_name=settings.aws_region,
        temperature=0.2,
    )
    agent = Agent(
        model=model,
        system_prompt=(
            "You are Curiosity Quest. Look at the image and produce a structured "
            "investigation plan for a child-safe mobile learning app. Identify "
            "the broad domain from the actual image content: heritage for old "
            "buildings and monuments, nature for animals or plants, safe_dining "
            "for food, or general otherwise. Do not force the example fountain "
            "domain unless the image actually shows a fountain or historic place. "
            "If a visible subject can reasonably be categorized, choose the "
            "closest domain instead of general: squirrels, pets, insects, birds, "
            "trees, flowers, leaves, and mushrooms are nature. Use general only "
            "for blank, unreadable, abstract, or truly ambiguous images. "
            "Never ask a child to climb, trespass, taste unknown food or plants, "
            "approach traffic, or collect personal data."
        ),
    )
    image_prompt = (
        "Plan a safe evidence quest for this uploaded mobile-app image. "
        f"User question: {prompt}. First infer what the image appears to show, "
        "then choose the correct domain and next evidence quest. Return general "
        "only if the image content itself is not interpretable."
    )
    content = [
        {"text": image_prompt},
        {
            "image": {
                "format": _image_format_for_payload(image_format, image_bytes),
                "source": {"bytes": image_bytes},
            }
        },
    ]
    try:
        with redirect_stdout(StringIO()):
            result = agent(content, structured_output_model=AgentInvestigationPlan)
    except Exception as exc:
        return _run_bedrock_image_plan_or_fallback(
            prompt,
            fallback_prompt,
            image_bytes,
            image_format,
            user_mode,
            reason=f"strands image call failed: {type(exc).__name__}",
        )
    _plan = result.structured_output
    if not isinstance(_plan, AgentInvestigationPlan):
        return _run_bedrock_image_plan_or_fallback(
            prompt,
            fallback_prompt,
            image_bytes,
            image_format,
            user_mode,
            reason="strands returned no structured image plan",
        )
    return start_investigation_from_plan(fallback_prompt, _plan, user_mode)


def _run_bedrock_image_plan_or_fallback(
    prompt: str,
    fallback_prompt: str,
    image_bytes: bytes,
    image_format: str,
    user_mode: UserMode,
    *,
    reason: str,
) -> Investigation:
    try:
        return _run_bedrock_image_plan(prompt, fallback_prompt, image_bytes, image_format, user_mode)
    except Exception as exc:
        return start_visual_fallback_investigation(
            fallback_prompt,
            user_mode,
            reason=f"{reason}; direct bedrock failed: {type(exc).__name__}",
        )


def _run_bedrock_image_plan(
    prompt: str,
    fallback_prompt: str,
    image_bytes: bytes,
    image_format: str,
    user_mode: UserMode,
) -> Investigation:
    settings = load_settings()
    import boto3  # type: ignore

    client = boto3.client("bedrock-runtime", region_name=settings.aws_region)
    response = client.converse(
        modelId=settings.bedrock_model_id,
        messages=[
            {
                "role": "user",
                "content": [
                    {
                        "text": (
                            "You are Curiosity Quest, a child-safe mobile learning agent. "
                            "Look at the uploaded image and return only JSON matching this schema: "
                            "{"
                            '"domain":"heritage|nature|safe_dining|general",'
                            '"hypotheses":[{"label":"...","probability_band":"low|medium|high","rationale":"..."}],'
                            '"selected_quest":{"required_feature":"...","quest_instruction":"...","modality":"photo|ocr|photo+context","safety_constraint":"..."},'
                            '"uncertainty_note":"...",'
                            '"safety_flags":["..."]'
                            "}. "
                            "Choose nature for animals, squirrels, leaves, flowers, trees, acorns, or mushrooms. "
                            "Choose heritage for old buildings, monuments, fountains, or inscriptions. "
                            "Choose safe_dining for food, menus, allergens, or ingredients. "
                            "Use general only for blank, unreadable, abstract, or truly ambiguous images. "
                            "Never ask a child to touch, taste, climb, trespass, or approach danger. "
                            f"User question: {prompt}"
                        )
                    },
                    {
                        "image": {
                            "format": _image_format_for_payload(image_format, image_bytes),
                            "source": {"bytes": image_bytes},
                        }
                    },
                ],
            }
        ],
        inferenceConfig={"temperature": 0.1, "maxTokens": 1200},
    )
    text = _extract_text(response)
    plan = AgentInvestigationPlan.model_validate_json(_json_object(text))
    investigation = start_investigation_from_plan(fallback_prompt, plan, user_mode)
    investigation.agent_trace.append("bedrock: direct image converse fallback produced plan")
    return investigation


def _extract_text(response: dict) -> str:
    for block in response.get("output", {}).get("message", {}).get("content", []):
        if "text" in block:
            return block["text"]
    return ""


def _json_object(text: str) -> str:
    stripped = text.strip()
    if stripped.startswith("```"):
        stripped = stripped.strip("`")
        if stripped.lower().startswith("json"):
            stripped = stripped[4:].strip()
    start = stripped.find("{")
    end = stripped.rfind("}")
    if start >= 0 and end >= start:
        stripped = stripped[start : end + 1]
    json.loads(stripped)
    return stripped


def _normalize_image_format(content_type_or_format: str) -> str:
    value = content_type_or_format.lower().strip()
    if "/" in value:
        value = value.split("/", 1)[1]
    if value == "jpg":
        return "jpeg"
    if value in {"png", "jpeg", "gif", "webp"}:
        return value
    return "jpeg"


def _image_format_for_payload(content_type_or_format: str, image_bytes: bytes) -> str:
    sniffed = sniff_image_format(image_bytes)
    if sniffed != "unknown":
        return sniffed
    return _normalize_image_format(content_type_or_format)
