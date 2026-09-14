from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime, timezone

from app.domain import Investigation, SafetyEvent, SafetyLevel


@dataclass(frozen=True)
class ParentContact:
    email: str | None = None
    phone: str | None = None
    push_token: str | None = None
    email_verified: bool = False
    phone_verified: bool = False
    push_enabled: bool = False


@dataclass(frozen=True)
class NotificationDelivery:
    channel: str
    status: str
    target_hint: str
    reason: str
    created_at: str


class NotificationDispatcher:
    def dispatch(
        self,
        investigation: Investigation,
        contact: ParentContact | None = None,
    ) -> list[NotificationDelivery]:
        contact = contact or ParentContact()
        deliveries: list[NotificationDelivery] = []
        for event in investigation.safety_events:
            if not event.notify_parent:
                continue
            deliveries.extend(self._fanout(event, contact))
        return deliveries

    def _fanout(
        self,
        event: SafetyEvent,
        contact: ParentContact,
    ) -> list[NotificationDelivery]:
        channels = [
            self._in_app(event),
            self._push(event, contact),
            self._email(event, contact),
        ]
        if event.severity in {SafetyLevel.DANGER, SafetyLevel.EMERGENCY}:
            channels.append(self._sms(event, contact))
        return channels

    def _in_app(self, event: SafetyEvent) -> NotificationDelivery:
        return _delivery(
            "in_app",
            "queued",
            "parent_dashboard",
            f"{event.severity.value} alert saved for parent review",
        )

    def _push(self, event: SafetyEvent, contact: ParentContact) -> NotificationDelivery:
        if contact.push_enabled and contact.push_token:
            return _delivery("push", "queued", _mask(contact.push_token), event.title)
        return _delivery("push", "skipped", "no_verified_device", "Parent push token is not registered")

    def _email(self, event: SafetyEvent, contact: ParentContact) -> NotificationDelivery:
        if contact.email and contact.email_verified:
            return _delivery("email", "queued", _mask_email(contact.email), event.title)
        return _delivery("email", "skipped", "unverified_email", "Parent email is not verified")

    def _sms(self, event: SafetyEvent, contact: ParentContact) -> NotificationDelivery:
        if contact.phone and contact.phone_verified:
            return _delivery("sms", "queued", _mask_phone(contact.phone), event.title)
        return _delivery("sms", "skipped", "unverified_phone", "Parent phone is not verified")


def _delivery(channel: str, status: str, target_hint: str, reason: str) -> NotificationDelivery:
    return NotificationDelivery(
        channel=channel,
        status=status,
        target_hint=target_hint,
        reason=reason,
        created_at=datetime.now(timezone.utc).isoformat(),
    )


def _mask(value: str) -> str:
    return f"...{value[-4:]}" if len(value) > 4 else "registered"


def _mask_email(email: str) -> str:
    name, _, domain = email.partition("@")
    return f"{name[:2]}***@{domain}" if domain else "***"


def _mask_phone(phone: str) -> str:
    digits = "".join(ch for ch in phone if ch.isdigit())
    return f"***{digits[-4:]}" if len(digits) >= 4 else "***"


dispatcher = NotificationDispatcher()
