from __future__ import annotations

import unittest

from app.agent_card import agent_card
from app.agent_core import start_investigation


class AgentCardTest(unittest.TestCase):
    def test_agent_card_exposes_decision_loop(self) -> None:
        inv = start_investigation("What is this old fountain?")
        card = agent_card(inv)
        self.assertEqual(card["status"], "needs_evidence")
        steps = [step["step"] for step in card["agentic_loop"]]
        self.assertEqual(steps, ["observe", "hypothesize", "seek_evidence", "policy", "notify"])
        self.assertIn("why_original", card)

    def test_agent_card_includes_safety_event_and_deliveries(self) -> None:
        inv = start_investigation("There is smoke and fire near the stove")
        inv.notification_deliveries.append(
            {"channel": "sms", "status": "queued", "target_hint": "***4567", "reason": "Emergency"}
        )
        card = agent_card(inv)
        notify = card["agentic_loop"][-1]["output"]
        self.assertEqual(notify["safety_event"]["severity"], "emergency")
        self.assertEqual(notify["deliveries"][0]["channel"], "sms")


if __name__ == "__main__":
    unittest.main()
