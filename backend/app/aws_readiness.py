from __future__ import annotations

import os

from app.config import load_settings


def aws_readiness() -> dict[str, object]:
    settings = load_settings()
    result: dict[str, object] = {
        "region": settings.aws_region,
        "bedrock_model_id": settings.bedrock_model_id,
        "demo_mode": settings.demo_mode,
        "has_env_access_key": bool(os.getenv("AWS_ACCESS_KEY_ID")),
        "has_env_secret_key": bool(os.getenv("AWS_SECRET_ACCESS_KEY")),
        "has_bedrock_api_key": bool(os.getenv("AWS_BEARER_TOKEN_BEDROCK")),
        "boto3_installed": False,
        "credentials_discoverable": False,
        "rekognition_labels_ready": False,
        "notes": [],
    }

    try:
        import boto3  # type: ignore

        result["boto3_installed"] = True
        session = boto3.Session(region_name=settings.aws_region)
        credentials = session.get_credentials()
        result["credentials_discoverable"] = credentials is not None
        result["rekognition_labels_ready"] = credentials is not None
    except Exception as exc:
        result["notes"] = [f"boto3 credential check skipped: {type(exc).__name__}"]

    notes = list(result["notes"])
    if settings.demo_mode:
        notes.append("Set CURIO_DEMO_MODE=false to allow live Strands and Bedrock calls.")
    if not result["credentials_discoverable"] and not result["has_bedrock_api_key"]:
        notes.append("Configure AWS credentials or AWS_BEARER_TOKEN_BEDROCK before live judging.")
    if not result["credentials_discoverable"]:
        notes.append(
            "Photo understanding needs AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY for Rekognition labels."
        )
    result["notes"] = notes
    return result
