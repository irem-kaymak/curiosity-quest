from __future__ import annotations

from dataclasses import dataclass
from pathlib import Path

from app.domain import new_id
from app.notifications import ParentContact
from app.store import DB_PATH, connect


@dataclass(frozen=True)
class ParentProfile:
    parent_id: str
    parent_name: str
    child_name: str
    contact: ParentContact

    def to_dict(self) -> dict[str, object]:
        return {
            "parent_id": self.parent_id,
            "parent_name": self.parent_name,
            "child_name": self.child_name,
            "contact": self.contact.__dict__,
            "notification_channels": notification_channels(self.contact),
        }


def register_parent(
    parent_name: str,
    child_name: str,
    contact: ParentContact,
    path: Path = DB_PATH,
) -> ParentProfile:
    profile = ParentProfile(
        parent_id=new_id().replace("inv_", "parent_"),
        parent_name=parent_name.strip() or "Parent",
        child_name=child_name.strip() or "Child",
        contact=contact,
    )
    with connect(path) as conn:
        conn.execute(
            """
            create table if not exists parent_profiles (
                parent_id text primary key,
                parent_name text not null,
                child_name text not null,
                email text,
                phone text,
                push_token text,
                email_verified integer not null,
                phone_verified integer not null,
                push_enabled integer not null,
                created_at text default current_timestamp
            )
            """
        )
        conn.execute(
            """
            insert into parent_profiles (
                parent_id, parent_name, child_name, email, phone, push_token,
                email_verified, phone_verified, push_enabled
            )
            values (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (
                profile.parent_id,
                profile.parent_name,
                profile.child_name,
                contact.email,
                contact.phone,
                contact.push_token,
                int(contact.email_verified),
                int(contact.phone_verified),
                int(contact.push_enabled),
            ),
        )
    return profile


def get_parent(parent_id: str, path: Path = DB_PATH) -> ParentProfile | None:
    with connect(path) as conn:
        conn.execute(
            """
            create table if not exists parent_profiles (
                parent_id text primary key,
                parent_name text not null,
                child_name text not null,
                email text,
                phone text,
                push_token text,
                email_verified integer not null,
                phone_verified integer not null,
                push_enabled integer not null,
                created_at text default current_timestamp
            )
            """
        )
        row = conn.execute(
            """
            select parent_id, parent_name, child_name, email, phone, push_token,
                   email_verified, phone_verified, push_enabled
            from parent_profiles
            where parent_id = ?
            """,
            (parent_id,),
        ).fetchone()
    if not row:
        return None
    return ParentProfile(
        parent_id=row[0],
        parent_name=row[1],
        child_name=row[2],
        contact=ParentContact(
            email=row[3],
            phone=row[4],
            push_token=row[5],
            email_verified=bool(row[6]),
            phone_verified=bool(row[7]),
            push_enabled=bool(row[8]),
        ),
    )


def notification_channels(contact: ParentContact) -> list[dict[str, object]]:
    return [
        {
            "channel": "in_app",
            "enabled": True,
            "verified": True,
            "description": "Parent dashboard alert feed",
        },
        {
            "channel": "push",
            "enabled": contact.push_enabled and bool(contact.push_token),
            "verified": contact.push_enabled and bool(contact.push_token),
            "description": "Parent phone push notification",
        },
        {
            "channel": "email",
            "enabled": bool(contact.email),
            "verified": contact.email_verified,
            "description": "Verified parent email",
        },
        {
            "channel": "sms",
            "enabled": bool(contact.phone),
            "verified": contact.phone_verified,
            "description": "Verified parent phone for urgent alerts",
        },
    ]
