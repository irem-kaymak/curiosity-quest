import unittest

from app.puzzles import _normalize_live_puzzle, dynamic_puzzles


class PuzzleTest(unittest.TestCase):
    def test_demo_puzzles_keep_server_shape(self):
        puzzles = dynamic_puzzles(age_band="9-12")
        self.assertGreaterEqual(len(puzzles), 3)
        self.assertIn("title", puzzles[0])
        self.assertEqual(len(puzzles[0]["choices"]), 3)
        self.assertIsInstance(puzzles[0]["correct"], int)

    def test_live_puzzle_normalization_clamps_xp(self):
        puzzle = _normalize_live_puzzle(
            {
                "title": "Which clue should an explorer check first?",
                "emoji": "🔎",
                "choices": ["Shape", "Guess forever", "Ignore clues"],
                "correct": 0,
                "explanation": "Shape is a concrete observation clue.",
                "topic": "science",
                "xp": 500,
            }
        )
        self.assertEqual(puzzle["source"], "bedrock")
        self.assertEqual(puzzle["xp"], 80)
        self.assertEqual(puzzle["choices"][0], "Shape")


if __name__ == "__main__":
    unittest.main()
