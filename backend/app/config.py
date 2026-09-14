from __future__ import annotations

from dataclasses import dataclass
import os
from pathlib import Path


@dataclass(frozen=True)
class Settings:
    allowed_origins: list[str]
    demo_mode: bool
    aws_region: str
    bedrock_model_id: str
    polly_voice_id: str
    polly_engine: str


def load_settings() -> Settings:
    load_dotenv()
    origins = os.getenv(
        "CURIO_ALLOWED_ORIGINS",
        "http://localhost:3000,http://localhost:5173,http://localhost:8000,http://localhost:8080",
    )
    return Settings(
        allowed_origins=[origin.strip() for origin in origins.split(",") if origin.strip()],
        demo_mode=os.getenv("CURIO_DEMO_MODE", "true").lower() != "false",
        aws_region=os.getenv("AWS_REGION", os.getenv("AWS_DEFAULT_REGION", "us-east-2")),
        bedrock_model_id=os.getenv(
            "CURIO_BEDROCK_MODEL_ID",
            "global.anthropic.claude-sonnet-4-5-20250929-v1:0",
        ),
        polly_voice_id=os.getenv("CURIO_POLLY_VOICE_ID", "Ivy"),
        polly_engine=os.getenv("CURIO_POLLY_ENGINE", "neural"),
    )


def load_dotenv(path: str | Path = ".env") -> None:
    env_path = Path(path)
    if not env_path.is_absolute():
        env_path = Path.cwd() / env_path
    if not env_path.exists():
        return
    for raw_line in env_path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        key = key.strip()
        if not key or key in os.environ:
            continue
        value = value.strip().strip('"').strip("'")
        os.environ[key] = value
