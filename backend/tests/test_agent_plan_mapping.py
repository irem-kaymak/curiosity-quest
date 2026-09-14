import unittest

from app.agent_core import infer_plan_domain, start_investigation_from_plan
from app.agent_output import AgentInvestigationPlan, HypothesisPlan, QuestPlan
from app.agents.strands_agent import _normalize_image_format
from app.domain import Domain


class AgentPlanMappingTest(unittest.TestCase):
    def test_live_plan_is_mapped_into_investigation_state(self):
        plan = AgentInvestigationPlan(
            domain="heritage",
            hypotheses=[
                HypothesisPlan(
                    label="Seljuk-era fountain",
                    probability_band="medium",
                    rationale="The carved stone and inscription style suggest a pre-Ottoman structure.",
                ),
                HypothesisPlan(
                    label="Ottoman-era restoration",
                    probability_band="low",
                    rationale="Some visible elements could be later restoration work.",
                ),
            ],
            selected_quest=QuestPlan(
                required_feature="A readable inscription date",
                quest_instruction="Use zoom to photograph the inscription from a safe distance.",
                modality="photo+ocr",
                safety_constraint="Stay with an adult and do not cross barriers.",
            ),
            uncertainty_note="The date and inscription are needed before a final identification.",
            safety_flags=["no climbing", "privacy minimization"],
        )

        investigation = start_investigation_from_plan(
            "What is this old fountain?",
            plan,
        )

        self.assertEqual(investigation.domain, Domain.HERITAGE)
        self.assertEqual(investigation.hypotheses[0].label, "Seljuk-era fountain")
        self.assertIn("inscription", investigation.selected_quest.instruction)
        self.assertNotIn("ask staff", investigation.selected_quest.instruction.lower())
        self.assertTrue(
            any("structured AgentInvestigationPlan" in step for step in investigation.agent_trace)
        )
        self.assertIn("child_mode", investigation.safety_flags)

    def test_unsafe_live_plan_is_blocked_by_policy(self):
        plan = AgentInvestigationPlan(
            domain="nature",
            hypotheses=[
                HypothesisPlan(
                    label="Unknown plant",
                    probability_band="low",
                    rationale="More evidence is needed.",
                )
            ],
            selected_quest=QuestPlan(
                required_feature="Leaf texture",
                quest_instruction="Climb over the fence and touch it.",
                modality="photo",
                safety_constraint="Be careful.",
            ),
            uncertainty_note="Unsafe task should not pass.",
            safety_flags=[],
        )

        investigation = start_investigation_from_plan("What plant is this?", plan)
        self.assertEqual(investigation.status, "blocked")
        self.assertIn("no_touching", investigation.safety_flags)

    def test_image_format_is_normalized_for_bedrock(self):
        self.assertEqual(_normalize_image_format("image/jpeg"), "jpeg")
        self.assertEqual(_normalize_image_format("jpg"), "jpeg")
        self.assertEqual(_normalize_image_format("image/png"), "png")

    def test_general_live_plan_can_be_repaired_from_visual_terms(self):
        plan = AgentInvestigationPlan(
            domain="general",
            hypotheses=[
                HypothesisPlan(
                    label="Possible squirrel",
                    probability_band="medium",
                    rationale="The uploaded image appears to show fur and a tail.",
                )
            ],
            selected_quest=QuestPlan(
                required_feature="Tail and face shape",
                quest_instruction="Take one clearer photo from where you are.",
                modality="photo",
                safety_constraint="Do not approach or feed wildlife.",
            ),
            uncertainty_note="The animal might be a lookalike species.",
            safety_flags=["wildlife_distance"],
        )

        self.assertEqual(infer_plan_domain(plan, "What is this? Image attached."), Domain.NATURE)

    def test_generic_image_plan_gets_usable_visual_quest(self):
        plan = AgentInvestigationPlan(
            domain="general",
            hypotheses=[
                HypothesisPlan(
                    label="Needs domain routing",
                    probability_band="low",
                    rationale="The prompt does not identify enough context.",
                )
            ],
            selected_quest=QuestPlan(
                required_feature="One concrete clue",
                quest_instruction="Add one photo or clue.",
                modality="photo_or_text",
                safety_constraint="Avoid personal data.",
            ),
            uncertainty_note="The agent needs a clearer observation before choosing a domain.",
            safety_flags=["child_mode"],
        )

        investigation = start_investigation_from_plan("What is this? Image attached.", plan)
        self.assertEqual(investigation.domain, Domain.GENERAL)
        self.assertIn("clearer photo", investigation.selected_quest.instruction.lower())
        self.assertNotEqual(investigation.hypotheses[0].label, "Needs domain routing")
        self.assertTrue(any("generic image repair" in step for step in investigation.agent_trace))


if __name__ == "__main__":
    unittest.main()
