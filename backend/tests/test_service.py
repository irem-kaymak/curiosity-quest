from pathlib import Path
from tempfile import TemporaryDirectory
import unittest

from app.service import (
    ValidationError,
    append_evidence,
    create_investigation,
    get_investigation,
    parse_user_mode,
    recent_investigations,
)


class ServiceTest(unittest.TestCase):
    def test_create_get_append_flow(self):
        with TemporaryDirectory() as tmp:
            db = Path(tmp) / "service.sqlite3"
            inv = create_investigation(
                "A historic fountain with a readable inscription",
                "kid",
                db_path=db,
            )
            self.assertEqual(inv.status, "needs_evidence")
            self.assertEqual(get_investigation(inv.investigation_id, db_path=db).domain.value, "heritage")

            updated = append_evidence(
                inv.investigation_id,
                "The inscription and plaque both mention a fountain.",
                "ocr",
                db_path=db,
            )
            self.assertEqual(updated.status, "concluded")
            self.assertEqual(len(recent_investigations(db_path=db)), 1)

    def test_validation_rejects_empty_prompt_and_bad_mode(self):
        with self.assertRaises(ValidationError):
            create_investigation("   ")
        with self.assertRaises(ValidationError):
            parse_user_mode("teacher")

    def test_squirrel_follow_up_answers_without_new_image(self):
        with TemporaryDirectory() as tmp:
            db = Path(tmp) / "service.sqlite3"
            inv = create_investigation(
                "Previous visual subject: Squirrel. Curio asked: Do you know why squirrels bury some of their food? Child says: I don't know why they bury it, can you answer that?",
                "kid",
                db_path=db,
            )

            self.assertEqual(inv.status, "concluded")
            self.assertIsNotNone(inv.conclusion)
            self.assertIn("save it for later", inv.conclusion.kid_summary)
            self.assertEqual(inv.selected_quest.modality, "curiosity_question")
            self.assertIn("without asking for a new image", inv.agent_trace[0])

    def test_squirrel_hiding_place_guess_answers_without_new_image(self):
        with TemporaryDirectory() as tmp:
            db = Path(tmp) / "service.sqlite3"
            inv = create_investigation(
                "Previous visual subject: Squirrel. Curio asked: Where do you think a squirrel would hide food? Child says: could it be under the threes",
                "kid",
                db_path=db,
            )

            self.assertEqual(inv.status, "concluded")
            self.assertIn("under trees", inv.conclusion.kid_summary)
            self.assertEqual(inv.selected_quest.modality, "curiosity_question")

    def test_acorn_oak_follow_up_answers_without_new_image(self):
        with TemporaryDirectory() as tmp:
            db = Path(tmp) / "service.sqlite3"
            inv = create_investigation(
                "Previous visual subject: Acorn. Curio asked: Can you spot the cap on the acorn and the shape of the oak leaf? Child says: shape of the leaf is it has a lot of sides and the cap allows it to connect to the tree",
                "kid",
                db_path=db,
            )

            self.assertEqual(inv.status, "concluded")
            self.assertIn("Sharp field note", inv.conclusion.kid_summary)
            self.assertIn("oak/acorn", inv.conclusion.kid_summary)
            self.assertEqual(inv.selected_quest.modality, "curiosity_question")

    def test_acorn_oak_direct_child_observation_answers_without_context(self):
        with TemporaryDirectory() as tmp:
            db = Path(tmp) / "service.sqlite3"
            inv = create_investigation(
                "is the cap the hard part of the acorn which allows it to connect to the tree and the leaf shape is like like a star",
                "kid",
                db_path=db,
            )

            self.assertEqual(inv.status, "concluded")
            self.assertIn("Sharp field note", inv.conclusion.kid_summary)
            self.assertNotIn("needs", inv.hypotheses[0].label.lower())

    def test_generic_contextual_reply_continues_active_case(self):
        with TemporaryDirectory() as tmp:
            db = Path(tmp) / "service.sqlite3"
            inv = create_investigation(
                "Previous visual subject: Butterfly. Curio asked: What colors can you spot on its wings? Child says: I see orange and black near the edge",
                "kid",
                db_path=db,
            )

            self.assertEqual(inv.status, "concluded")
            self.assertIn("Butterfly wing colors", inv.conclusion.kid_summary)
            self.assertNotIn("needs", inv.hypotheses[0].label.lower())
            self.assertEqual(inv.selected_quest.modality, "curiosity_question")

    def test_rabbit_color_follow_up_answers_active_case(self):
        with TemporaryDirectory() as tmp:
            db = Path(tmp) / "service.sqlite3"
            inv = create_investigation(
                "Previous visual subject: Rabbit. Curio asked: What color do you notice on the rabbit's fur? Child says: color of the rabbit",
                "kid",
                db_path=db,
            )

            self.assertEqual(inv.status, "concluded")
            self.assertIn("Rabbit fur", inv.conclusion.kid_summary)
            self.assertNotIn("field note", inv.conclusion.kid_summary)
            self.assertEqual(inv.selected_quest.modality, "curiosity_question")

    def test_direct_rabbit_question_answers_without_image_or_context(self):
        with TemporaryDirectory() as tmp:
            db = Path(tmp) / "service.sqlite3"
            inv = create_investigation(
                "what color can a rabbit be",
                "kid",
                db_path=db,
            )

            self.assertEqual(inv.status, "concluded")
            self.assertIn("Rabbit fur", inv.conclusion.kid_summary)
            self.assertIn("without asking for a new image", inv.agent_trace[0])

    def test_contextual_horse_color_follow_up_answers_without_image(self):
        with TemporaryDirectory() as tmp:
            db = Path(tmp) / "service.sqlite3"
            inv = create_investigation(
                "Previous visual subject: Horse. Curio asked: What color do you notice on the horse, and what clue besides color can you spot? Child says: the color of the horse to determine the specie",
                "kid",
                db_path=db,
            )

            self.assertEqual(inv.status, "concluded")
            self.assertIn("Color helps describe", inv.conclusion.kid_summary)
            self.assertIn("horse", inv.conclusion.kid_summary.lower())
            self.assertNotIn("Good question. We can keep investigating with words first", inv.conclusion.kid_summary)
            self.assertEqual(inv.selected_quest.modality, "curiosity_question")

    def test_direct_horse_color_question_answers_without_context(self):
        with TemporaryDirectory() as tmp:
            db = Path(tmp) / "service.sqlite3"
            inv = create_investigation(
                "what color can a horse be",
                "kid",
                db_path=db,
            )

            self.assertEqual(inv.status, "concluded")
            self.assertIn("Color helps describe", inv.conclusion.kid_summary)
            self.assertIn("horse", inv.conclusion.kid_summary.lower())
            self.assertNotIn("clue you can check", inv.selected_quest.instruction)

    def test_dirty_horse_subject_is_cleaned_before_follow_up(self):
        with TemporaryDirectory() as tmp:
            db = Path(tmp) / "service.sqlite3"
            inv = create_investigation(
                "Previous visual subject: Horse text follow-up text follow-up. Curio asked: What part of the horse should we investigate next? Child says: legs",
                "kid",
                db_path=db,
            )

            self.assertEqual(inv.status, "concluded")
            self.assertIn("horse", inv.conclusion.kid_summary.lower())
            self.assertIn("legs", inv.conclusion.kid_summary.lower())
            self.assertNotIn("text follow-up", inv.conclusion.kid_summary.lower())
            self.assertNotIn("text follow-up", inv.selected_quest.instruction.lower())

    def test_horse_body_parts_question_answers_directly(self):
        with TemporaryDirectory() as tmp:
            db = Path(tmp) / "service.sqlite3"
            inv = create_investigation(
                "Previous visual subject: Horse. Curio asked: Which horse clue should we inspect next? Child says: I want to learn the body parts in detail",
                "kid",
                db_path=db,
            )

            self.assertEqual(inv.status, "concluded")
            self.assertIn("hooves", inv.conclusion.kid_summary.lower())
            self.assertIn("mane", inv.conclusion.kid_summary.lower())
            self.assertEqual(inv.selected_quest.modality, "curiosity_question")

    def test_direct_bird_food_question_answers_without_image(self):
        with TemporaryDirectory() as tmp:
            db = Path(tmp) / "service.sqlite3"
            inv = create_investigation(
                "what do birds eat",
                "kid",
                db_path=db,
            )

            self.assertEqual(inv.status, "concluded")
            self.assertIn("Birds eat", inv.conclusion.kid_summary)
            self.assertEqual(inv.selected_quest.modality, "curiosity_question")

    def test_text_language_learning_question_answers_without_image(self):
        with TemporaryDirectory() as tmp:
            db = Path(tmp) / "service.sqlite3"
            inv = create_investigation(
                "I want to learn how to say hello",
                "kid",
                db_path=db,
            )

            self.assertEqual(inv.status, "concluded")
            self.assertIn("Hello", inv.conclusion.kid_summary)
            self.assertNotIn("clue you can check", inv.selected_quest.instruction)
            self.assertEqual(inv.domain.value, "general")


if __name__ == "__main__":
    unittest.main()
