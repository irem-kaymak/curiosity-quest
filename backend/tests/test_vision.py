import unittest

from app.vision import (
    best_subject_label,
    curiosity_fact_and_question,
    infer_domain_from_labels,
    sniff_image_format,
    VisualLabel,
)
from app.domain import Domain


class VisionTest(unittest.TestCase):
    def test_sniffs_common_image_formats(self):
        self.assertEqual(sniff_image_format(b"\xff\xd8\xffdemo"), "jpeg")
        self.assertEqual(sniff_image_format(b"\x89PNG\r\n\x1a\ndemo"), "png")
        self.assertEqual(sniff_image_format(b"GIF89ademo"), "gif")
        self.assertEqual(sniff_image_format(b"RIFFxxxxWEBPdemo"), "webp")
        self.assertEqual(sniff_image_format(b"not-an-image"), "unknown")

    def test_infers_nature_from_animal_labels(self):
        labels = [VisualLabel("Squirrel", 99.0), VisualLabel("Animal", 97.0)]
        self.assertEqual(infer_domain_from_labels(labels), Domain.NATURE)

    def test_rabbit_curiosity_prompt_is_subject_specific(self):
        fact, question = curiosity_fact_and_question("Rabbit", Domain.NATURE)
        self.assertIn("rabbit", fact.lower())
        self.assertIn("color", question.lower())

    def test_horse_curiosity_prompt_is_subject_specific(self):
        fact, question = curiosity_fact_and_question("Horse", Domain.NATURE)
        self.assertIn("horses", fact.lower())
        self.assertIn("hooves", fact.lower())
        self.assertIn("color", question.lower())

    def test_best_subject_prefers_specific_flower_label(self):
        labels = [
            VisualLabel("Flower", 99.0),
            VisualLabel("Plant", 98.0),
            VisualLabel("Daisy", 92.0),
        ]
        self.assertEqual(best_subject_label(labels), "Daisy")


if __name__ == "__main__":
    unittest.main()
