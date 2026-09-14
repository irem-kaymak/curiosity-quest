from __future__ import annotations

import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[1]
sys.path.insert(0, str(ROOT))

from app.agents.strands_agent import agent_runtime_status
from app.aws_readiness import aws_readiness


def main() -> None:
    print("AGENT RUNTIME")
    print(json.dumps(agent_runtime_status(), indent=2))
    print("\nAWS READINESS")
    print(json.dumps(aws_readiness(), indent=2))


if __name__ == "__main__":
    main()

