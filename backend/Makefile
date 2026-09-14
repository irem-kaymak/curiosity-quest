.PHONY: test demo runtime run run-strands

test:
	PYTHONPATH=. python -m unittest discover -s tests

demo:
	PYTHONPATH=. python scripts/demo_flow.py

runtime:
	PYTHONPATH=. python scripts/check_runtime.py

run:
	PYTHONPATH=. uvicorn app.main:app --host 127.0.0.1 --port 8000

run-strands:
	PYTHONPATH=. CURIO_DEMO_MODE=false uvicorn app.main:app --host 127.0.0.1 --port 8000
