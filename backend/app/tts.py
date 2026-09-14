from __future__ import annotations

import base64

from app.config import load_settings


def synthesize_curio_voice(text: str) -> dict[str, object]:
    clean = " ".join(text.split())
    if not clean:
        raise ValueError("Text is required for Curio voice.")
    if len(clean) > 1500:
        clean = clean[:1500]

    settings = load_settings()
    if settings.demo_mode:
        raise RuntimeError("Curio voice requires live AWS Polly access.")

    try:
        import boto3  # type: ignore

        client = boto3.client("polly", region_name=settings.aws_region)
        response = client.synthesize_speech(
            Text=clean,
            OutputFormat="mp3",
            VoiceId=settings.polly_voice_id,
            Engine=settings.polly_engine,
        )
        stream = response.get("AudioStream")
        if stream is None:
            raise RuntimeError("AWS Polly did not return an audio stream.")
        audio_bytes = stream.read()
    except Exception as exc:
        raise RuntimeError(f"Curio voice unavailable: {type(exc).__name__}: {exc}") from exc

    return {
        "ok": True,
        "source": "aws-polly",
        "voice_id": settings.polly_voice_id,
        "engine": settings.polly_engine,
        "content_type": "audio/mpeg",
        "audio_base64": base64.b64encode(audio_bytes).decode("ascii"),
    }
