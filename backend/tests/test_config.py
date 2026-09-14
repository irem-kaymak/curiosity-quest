from __future__ import annotations

import os
import tempfile
import unittest
from pathlib import Path

from app.config import load_dotenv


class ConfigTests(unittest.TestCase):
    def test_load_dotenv_sets_missing_values(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            env_file = Path(tmp) / ".env"
            env_file.write_text("CURIO_TEST_VALUE=from_file\n", encoding="utf-8")
            os.environ.pop("CURIO_TEST_VALUE", None)

            load_dotenv(env_file)

            self.assertEqual(os.environ["CURIO_TEST_VALUE"], "from_file")
            os.environ.pop("CURIO_TEST_VALUE", None)

    def test_load_dotenv_keeps_existing_environment(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            env_file = Path(tmp) / ".env"
            env_file.write_text("CURIO_TEST_VALUE=from_file\n", encoding="utf-8")
            os.environ["CURIO_TEST_VALUE"] = "already_set"

            load_dotenv(env_file)

            self.assertEqual(os.environ["CURIO_TEST_VALUE"], "already_set")
            os.environ.pop("CURIO_TEST_VALUE", None)


if __name__ == "__main__":
    unittest.main()
