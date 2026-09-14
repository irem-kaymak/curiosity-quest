from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from app.agent_core import start_investigation
from app.domain import Domain, EvidenceGap, Quest, UserMode
from app.policy import evaluate_policy
from app.quest_engine import score_quest
from app.store import load, save


class PolicyAndStoreTest(unittest.TestCase):
    def test_policy_blocks_unsafe_child_task(self):
        result = evaluate_policy(
            domain=Domain.NATURE,
            user_mode=UserMode.KID,
            prompt="What plant is this?",
            proposed_task="Climb over the fence and touch it.",
        )
        self.assertTrue(result.blocked)
        self.assertIn("child_mode", result.flags)
        self.assertIn("no_touching", result.flags)

    def test_policy_allows_negated_safety_warnings(self):
        result = evaluate_policy(
            domain=Domain.HERITAGE,
            user_mode=UserMode.KID,
            prompt="What is this old fountain?",
            proposed_task=(
                "Photograph the inscription from a safe distance. "
                "Do not climb, do not touch it, and no private property."
            ),
        )
        self.assertFalse(result.blocked)
        self.assertIn("child_safe_distance", result.flags)

    def test_dining_requires_parent_gate(self):
        result = evaluate_policy(
            domain=Domain.DINING,
            user_mode=UserMode.KID,
            prompt="Could this contain an allergen?",
            proposed_task="Scan the menu with an adult.",
        )
        self.assertTrue(result.parent_gate_required)
        self.assertIn("adult_gate", result.flags)

    def test_quest_score_rewards_information_gain(self):
        candidate = score_quest(
            EvidenceGap("text clue", 90, "stay safe"),
            Quest("Scan the plaque", "9-12", "ocr", "text visible", "demo"),
        )
        self.assertGreater(candidate.score, 60)

    def test_sqlite_round_trip_preserves_policy_fields(self):
        with TemporaryDirectory() as tmp:
            db = Path(tmp) / "test.sqlite3"
            inv = start_investigation("old stone fountain with inscription")
            save(inv, db)
            restored = load(inv.investigation_id, db)
        self.assertIsNotNone(restored)
        self.assertEqual(restored.investigation_id, inv.investigation_id)
        self.assertEqual(restored.domain, Domain.HERITAGE)
        self.assertIn("strip_faces_and_plates", restored.safety_flags)
        self.assertFalse(restored.parent_gate_required)


if __name__ == "__main__":
    unittest.main()
