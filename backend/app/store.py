from __future__ import annotations

import json
import sqlite3
from pathlib import Path
from typing import Any

from app.agent_core import start_investigation
from app.domain import (
    ConfidenceBand,
    Domain,
    Evidence,
    EvidenceGap,
    Hypothesis,
    Investigation,
    Quest,
    SafetyEvent,
    SafetyLevel,
    UserMode,
)


DB_PATH = Path(__file__).resolve().parents[1] / "curiosity_quest.sqlite3"


def connect(path: Path = DB_PATH) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.execute(
        """
        create table if not exists investigations (
            investigation_id text primary key,
            payload text not null,
            updated_at text default current_timestamp
        )
        """
    )
    return conn


def save(investigation: Investigation, path: Path = DB_PATH) -> Investigation:
    with connect(path) as conn:
        conn.execute(
            """
            insert into investigations (investigation_id, payload, updated_at)
            values (?, ?, current_timestamp)
            on conflict(investigation_id) do update set
                payload=excluded.payload,
                updated_at=current_timestamp
            """,
            (investigation.investigation_id, json.dumps(investigation.to_dict())),
        )
    return investigation


def load(investigation_id: str, path: Path = DB_PATH) -> Investigation | None:
    with connect(path) as conn:
        row = conn.execute(
            "select payload from investigations where investigation_id = ?",
            (investigation_id,),
        ).fetchone()
    if not row:
        return None
    return from_dict(json.loads(row[0]))


def list_recent(path: Path = DB_PATH, limit: int = 20) -> list[Investigation]:
    with connect(path) as conn:
        rows = conn.execute(
            """
            select payload from investigations
            order by updated_at desc
            limit ?
            """,
            (limit,),
        ).fetchall()
    return [from_dict(json.loads(row[0])) for row in rows]


def from_dict(data: dict[str, Any]) -> Investigation:
    conclusion = data.get("conclusion")
    inv = Investigation(
        investigation_id=data["investigation_id"],
        domain=Domain(data["domain"]),
        user_mode=UserMode(data["user_mode"]),
        status=data["status"],
        prompt=data["prompt"],
        created_at=data["created_at"],
        hypotheses=[
            Hypothesis(
                h["label"],
                ConfidenceBand(h["probability_band"]),
                h["rationale"],
                h.get("status", "active"),
            )
            for h in data["hypotheses"]
        ],
        evidence=[
            Evidence(
                e["type"],
                e["source"],
                e["observation"],
                ConfidenceBand(e["reliability"]),
                e["timestamp"],
            )
            for e in data["evidence"]
        ],
        missing_evidence=[
            EvidenceGap(g["required_feature"], g["expected_information_gain"], g["safety_constraint"])
            for g in data["missing_evidence"]
        ],
        selected_quest=Quest(**data["selected_quest"]),
        safety_flags=list(data["safety_flags"]),
        policy_message=data.get("policy_message", "The next task is allowed with the listed safety constraints."),
        parent_gate_required=bool(data.get("parent_gate_required", False)),
        agent_trace=list(data.get("agent_trace", [])),
        confidence_band=ConfidenceBand(data["confidence_band"]),
        uncertainty_note=data["uncertainty_note"],
        safety_events=[
            SafetyEvent(
                SafetyLevel(event["severity"]),
                event["title"],
                event["child_message"],
                event["parent_message"],
                event["recommended_action"],
                bool(event.get("notify_parent", True)),
            )
            for event in data.get("safety_events", [])
        ],
        notification_deliveries=list(data.get("notification_deliveries", [])),
    )
    if conclusion:
        from app.domain import Conclusion

        inv.conclusion = Conclusion(
            conclusion["best_hypothesis"],
            ConfidenceBand(conclusion["confidence_band"]),
            list(conclusion["alternatives"]),
            conclusion["uncertainty_note"],
            conclusion["parent_summary"],
            conclusion["kid_summary"],
            list(conclusion["sources"]),
        )
    return inv


def seed_demo(path: Path = DB_PATH) -> Investigation:
    inv = start_investigation("A child photographed an old stone fountain with an inscription.")
    return save(inv, path)
