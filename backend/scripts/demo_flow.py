from __future__ import annotations

import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from app.agent_core import add_evidence, start_investigation


def main() -> None:
    inv = start_investigation("A child photographed an old stone fountain with an inscription.")
    print("START")
    print(json.dumps(inv.to_dict(), indent=2))
    print("\nAFTER NEW EVIDENCE")
    inv = add_evidence(
        inv,
        "The plaque says fountain and the side photo shows a water basin under the arch.",
        "ocr+photo",
    )
    print(json.dumps(inv.to_dict(), indent=2))


if __name__ == "__main__":
    main()

