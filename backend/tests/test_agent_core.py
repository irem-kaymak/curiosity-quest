import unittest

from app.agent_core import add_evidence, start_investigation
from app.domain import Domain


class AgentCoreTest(unittest.TestCase):
    def test_heritage_prompt_creates_evidence_quest(self):
        inv = start_investigation("old stone fountain with inscription")
        self.assertEqual(inv.domain, Domain.HERITAGE)
        self.assertEqual(inv.status, "needs_evidence")
        self.assertGreaterEqual(len(inv.hypotheses), 2)
        self.assertIn("inscription", inv.selected_quest.instruction.lower())
        self.assertIn("strip_faces_and_plates", inv.safety_flags)

    def test_follow_up_evidence_updates_confidence_and_concludes(self):
        inv = start_investigation("old stone fountain with inscription")
        updated = add_evidence(inv, "The plaque says fountain and the arch surrounds a water basin.")
        self.assertEqual(updated.status, "concluded")
        self.assertEqual(updated.confidence_band.value, "high")
        self.assertIsNotNone(updated.conclusion)
        self.assertIn("fountain", updated.conclusion.best_hypothesis.lower())

    def test_dining_never_claims_allergen_certainty(self):
        inv = start_investigation("food photo with possible allergen")
        self.assertEqual(inv.domain, Domain.DINING)
        self.assertIn("no_medical_claim", inv.safety_flags)
        self.assertIn("cannot", inv.selected_quest.score_reason.lower())

    def test_danger_prompt_creates_parent_safety_event(self):
        inv = start_investigation("My child uploaded a photo of a knife on the table")
        self.assertEqual(inv.status, "danger_alert")
        self.assertTrue(inv.parent_gate_required)
        self.assertEqual(inv.safety_events[0].severity.value, "danger")
        self.assertIn("grown-up", inv.safety_events[0].child_message)

    def test_emergency_prompt_pauses_learning_flow(self):
        inv = start_investigation("There is smoke and fire in the kitchen")
        self.assertEqual(inv.status, "emergency_alert")
        self.assertEqual(inv.safety_events[0].severity.value, "emergency")

    def test_animal_nature_prompt_uses_animal_quest(self):
        inv = start_investigation("What animal is this squirrel with a big tail?")
        self.assertEqual(inv.domain, Domain.NATURE)
        self.assertIn("animal", inv.hypotheses[0].label.lower())
        self.assertIn("do not approach", inv.selected_quest.instruction.lower())
        self.assertNotIn("leaf underside", inv.selected_quest.instruction.lower())


if __name__ == "__main__":
    unittest.main()
