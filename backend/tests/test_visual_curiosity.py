import unittest

from app.agent_core import start_investigation
from app.domain import Domain
from app.service import enrich_safe_visual_answer, enrich_safety_answer
from app.vision import VisualLabel


class VisualCuriosityTest(unittest.TestCase):
    def test_squirrel_label_creates_curiosity_follow_up(self):
        inv = start_investigation("What animal is this?")
        inv.domain = Domain.NATURE
        enrich_safe_visual_answer(
            inv,
            [
                VisualLabel("Animal", 99),
                VisualLabel("Mammal", 99),
                VisualLabel("Squirrel", 98),
            ],
        )

        self.assertEqual(inv.status, "concluded")
        self.assertIsNotNone(inv.conclusion)
        self.assertEqual(inv.conclusion.best_hypothesis, "Squirrel")
        self.assertIn("This looks like a squirrel", inv.conclusion.kid_summary)
        self.assertNotIn("Do you know why", inv.conclusion.kid_summary)
        self.assertIn("bury", inv.selected_quest.instruction.lower())

    def test_safety_event_skips_curiosity_follow_up(self):
        inv = start_investigation("There is a knife beside me")
        enrich_safe_visual_answer(inv, [VisualLabel("Knife", 99)])
        enrich_safety_answer(inv)

        self.assertEqual(inv.status, "danger_alert")
        self.assertIsNotNone(inv.conclusion)
        self.assertIn("Safety first", inv.conclusion.kid_summary)
        self.assertEqual(inv.selected_quest.modality, "safety_protocol")


if __name__ == "__main__":
    unittest.main()
