from __future__ import annotations

try:
    from fastapi import FastAPI, File, Form, HTTPException, UploadFile
    from fastapi.middleware.cors import CORSMiddleware
except Exception:  # pragma: no cover
    FastAPI = None
    HTTPException = Exception

from app.accounts import get_parent, notification_channels, register_parent
from app.agent_card import agent_card
from app.config import load_settings
from app.agents.strands_agent import agent_runtime_status, generate_curiosity_followup_text
from app.aws_readiness import aws_readiness
from app.mobile_views import kid_view, parent_view
from app.notifications import ParentContact
from app.puzzles import dynamic_puzzles
from app.schemas import EvidenceRequest, ParentRegistrationRequest, StartRequest, TtsRequest
from app.service import (
    NotFoundError,
    ValidationError,
    append_evidence as append_evidence_service,
    create_investigation as create_investigation_service,
    create_investigation_from_image as create_investigation_from_image_service,
    get_investigation as get_investigation_service,
    recent_investigations,
)
from app.tts import synthesize_curio_voice
from app.uploads import UploadError, store_image_upload


if FastAPI:
    app = FastAPI(title="Curiosity Quest Agent API")
    settings = load_settings()
    app.add_middleware(
        CORSMiddleware,
        allow_origins=settings.allowed_origins,
        allow_origin_regex=r"https?://(localhost|127\.0\.0\.1)(:\d+)?",
        allow_credentials=True,
        allow_methods=["*"],
        allow_headers=["*"],
    )
else:
    app = None


if app:

    @app.get("/health")
    def health() -> dict[str, object]:
        return {
            "status": "ok",
            "service": "curiosity-quest-agent-api",
            "demo_mode": load_settings().demo_mode,
        }

    @app.get("/domains")
    def domains() -> list[dict[str, str]]:
        return [
            {
                "id": "heritage",
                "label": "Historic places",
                "demo_prompt": "What is this old fountain?",
            },
            {
                "id": "nature",
                "label": "Safe nature observation",
                "demo_prompt": "What plant is this?",
            },
            {
                "id": "safe_dining",
                "label": "Safe dining communication",
                "demo_prompt": "Could this food have allergens?",
            },
        ]

    @app.get("/agent/runtime")
    def runtime() -> dict[str, object]:
        return agent_runtime_status()

    @app.get("/agent/aws-readiness")
    def aws_status() -> dict[str, object]:
        status = aws_readiness()
        settings = load_settings()
        status["polly_voice_id"] = settings.polly_voice_id
        status["polly_engine"] = settings.polly_engine
        return status

    @app.get("/agent/ai-probe")
    def ai_probe() -> dict[str, object]:
        try:
            answer, question, source = generate_curiosity_followup_text(
                "Probe: answer a child who asks what a daisy is.",
                "daisy",
                "A daisy is a flower with petals around a center.",
                "What color are the petals and the middle?",
            )
            return {
                "ok": source.startswith("bedrock"),
                "source": source,
                "answer": answer,
                "next_question": question,
            }
        except Exception as exc:
            return {
                "ok": False,
                "source": "error",
                "error_type": type(exc).__name__,
                "error": str(exc),
            }

    @app.post("/agent/tts")
    def tts(request: TtsRequest) -> dict[str, object]:
        try:
            return synthesize_curio_voice(request.text)
        except ValueError as exc:
            raise HTTPException(status_code=422, detail=str(exc))
        except RuntimeError as exc:
            raise HTTPException(status_code=503, detail=str(exc))

    @app.get("/agent/tts-probe")
    def tts_probe() -> dict[str, object]:
        settings = load_settings()
        try:
            audio = synthesize_curio_voice(
                "Hi explorer. Curio voice is ready for your discovery."
            )
            return {
                "ok": True,
                "source": audio["source"],
                "voice_id": audio["voice_id"],
                "engine": audio["engine"],
                "content_type": audio["content_type"],
                "audio_bytes": len(str(audio["audio_base64"])),
            }
        except Exception as exc:
            return {
                "ok": False,
                "source": "error",
                "voice_id": settings.polly_voice_id,
                "engine": settings.polly_engine,
                "demo_mode": settings.demo_mode,
                "error_type": type(exc).__name__,
                "error": str(exc),
            }

    @app.post("/parents/register")
    def create_parent(request: ParentRegistrationRequest) -> dict[str, object]:
        profile = register_parent(
            request.parent_name,
            request.child_name,
            request.contact.to_contact(),
        )
        return profile.to_dict()

    @app.get("/parents/{parent_id}/notification-routing")
    def parent_notification_routing(parent_id: str) -> dict[str, object]:
        profile = get_parent(parent_id)
        if profile is None:
            raise HTTPException(status_code=404, detail="Parent profile not found")
        return {
            "parent_id": parent_id,
            "channels": notification_channels(profile.contact),
        }

    @app.post("/investigations")
    def create_investigation(request: StartRequest) -> dict:
        try:
            return create_investigation_service(
                request.investigation_prompt(),
                request.user_mode,
                parent_contact=request.parent_contact.to_contact()
                if request.parent_contact
                else None,
            ).to_dict()
        except RuntimeError as exc:
            raise HTTPException(status_code=503, detail=str(exc))
        except ValidationError as exc:
            raise HTTPException(status_code=422, detail=str(exc))

    @app.post("/investigations/from-image")
    async def create_from_image(
        image: UploadFile = File(...),
        prompt: str = Form("What is this?"),
        user_mode: str = Form("kid"),
        ocr_text: str = Form(""),
        coarse_location: str = Form(""),
        parent_email: str = Form(""),
        parent_phone: str = Form(""),
        parent_push_token: str = Form(""),
        parent_email_verified: bool = Form(False),
        parent_phone_verified: bool = Form(False),
        parent_push_enabled: bool = Form(False),
    ) -> dict:
        content = await image.read()
        try:
            stored = store_image_upload(
                content=content,
                filename=image.filename or "upload",
                content_type=image.content_type or "",
            )
            enriched_prompt = " ".join(
                part
                for part in [
                    prompt.strip(),
                    "Image attached.",
                    f"Image sha256: {stored.sha256[:16]}",
                    f"OCR text: {ocr_text.strip()}" if ocr_text.strip() else "",
                    f"Coarse location: {coarse_location.strip()}" if coarse_location.strip() else "",
                ]
                if part
            )
            return create_investigation_from_image_service(
                enriched_prompt,
                content,
                image.content_type or "",
                user_mode,
                parent_contact=ParentContact(
                    email=parent_email.strip() or None,
                    phone=parent_phone.strip() or None,
                    push_token=parent_push_token.strip() or None,
                    email_verified=parent_email_verified,
                    phone_verified=parent_phone_verified,
                    push_enabled=parent_push_enabled,
                ),
            ).to_dict()
        except RuntimeError as exc:
            raise HTTPException(status_code=503, detail=str(exc))
        except UploadError as exc:
            raise HTTPException(status_code=422, detail=str(exc))
        except ValidationError as exc:
            raise HTTPException(status_code=422, detail=str(exc))

    @app.get("/investigations")
    def list_investigations(limit: int = 20) -> list[dict]:
        return [inv.to_dict() for inv in recent_investigations(limit=limit)]

    @app.get("/notifications")
    def list_notifications(limit: int = 20) -> list[dict[str, object]]:
        notifications: list[dict[str, object]] = []
        for inv in recent_investigations(limit=limit):
            for event in inv.safety_events:
                if not event.notify_parent:
                    continue
                notifications.append(
                    {
                        "id": f"{inv.investigation_id}:{event.title}",
                        "investigation_id": inv.investigation_id,
                        "severity": event.severity.value,
                        "title": event.title,
                        "message": event.parent_message,
                        "recommended_action": event.recommended_action,
                        "deliveries": inv.notification_deliveries,
                        "created_at": inv.created_at,
                        "child_prompt": inv.prompt,
                    }
                )
        return notifications[:limit]

    @app.get("/puzzles")
    def list_puzzles(age_band: str = "9-12", topic: str = "mixed") -> list[dict[str, object]]:
        try:
            return dynamic_puzzles(age_band=age_band, topic=topic)
        except RuntimeError as exc:
            raise HTTPException(status_code=503, detail=str(exc))

    @app.get("/investigations/{investigation_id}")
    def get_investigation(investigation_id: str) -> dict:
        try:
            return get_investigation_service(investigation_id).to_dict()
        except NotFoundError:
            raise HTTPException(status_code=404, detail="Investigation not found")

    @app.get("/investigations/{investigation_id}/agent-card")
    def get_agent_card(investigation_id: str) -> dict[str, object]:
        try:
            return agent_card(get_investigation_service(investigation_id))
        except NotFoundError:
            raise HTTPException(status_code=404, detail="Investigation not found")

    @app.get("/investigations/{investigation_id}/mobile/kid")
    def get_kid_view(investigation_id: str) -> dict:
        try:
            return kid_view(get_investigation_service(investigation_id))
        except NotFoundError:
            raise HTTPException(status_code=404, detail="Investigation not found")

    @app.get("/investigations/{investigation_id}/mobile/parent")
    def get_parent_view(investigation_id: str) -> dict:
        try:
            return parent_view(get_investigation_service(investigation_id))
        except NotFoundError:
            raise HTTPException(status_code=404, detail="Investigation not found")

    @app.post("/investigations/{investigation_id}/evidence")
    def append_evidence(investigation_id: str, request: EvidenceRequest) -> dict:
        try:
            return append_evidence_service(
                investigation_id,
                request.evidence_observation(),
                request.evidence_type,
            ).to_dict()
        except NotFoundError:
            raise HTTPException(status_code=404, detail="Investigation not found")
        except ValidationError as exc:
            raise HTTPException(status_code=422, detail=str(exc))

    @app.post("/demo/heritage")
    def demo_heritage() -> dict:
        inv = create_investigation_service(
            "A child photographed an old stone fountain with an inscription.",
            "kid",
        )
        return append_evidence_service(
            inv.investigation_id,
            "The plaque says fountain and the side photo shows an arch around a water basin.",
            "ocr+photo",
        ).to_dict()
