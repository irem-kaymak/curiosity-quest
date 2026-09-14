# Curiosity Quest Backend

Backend slice for the AWS Agents for Humans demo.

It exposes the Curiosity Quest evidence loop:

1. observe
2. hypothesize
3. identify missing evidence
4. guide a safe quest
5. verify new evidence
6. conclude with confidence and uncertainty

The core logic is deterministic so the pitch demo works without cloud credentials. When AWS and Strands are available, `app/agents/strands_agent.py` is the integration point for the live agent.

In live mode, Strands produces an `AgentInvestigationPlan` through Bedrock structured output. The backend maps that plan into the durable `Investigation` state, then applies its own policy and mobile-task sanitization layer before returning results to the app.

## Run

```bash
python3 -m venv .venv
. .venv/bin/activate
pip install -r requirements.txt
uvicorn app.main:app --reload --port 8000
```

For the competition Strands runtime, use Python 3.10 or newer. The Strands docs currently require Python 3.10+, use Amazon Bedrock by default, and support Pydantic structured output by passing `structured_output_model` to the agent invocation.

```bash
pip install -r requirements-strands.txt
```

This workspace can use a project-local Python installed with `uv`:

```bash
UV_CACHE_DIR=$PWD/.uv-cache UV_PYTHON_INSTALL_DIR=$PWD/.uv-python .uv-bin/uv python install 3.11
.uv-python/cpython-3.11.16-macos-x86_64-none/bin/python3.11 -m venv .venv311
. .venv311/bin/activate
pip install -r requirements-strands.txt
PYTHONPATH=. uvicorn app.main:app --host 127.0.0.1 --port 8000
```

Useful environment variables are listed in `.env.example`.

Docker:

```bash
docker build -t curiosity-quest-backend .
docker run --env-file .env -p 8000:8000 curiosity-quest-backend
```

## Test

```bash
python3 -m unittest discover -s tests
```

With the project Makefile:

```bash
make test
make demo
make runtime
make run
```

## Demo Without Server

```bash
python3 scripts/demo_flow.py
```

## API Shape

```bash
curl -X POST http://localhost:8000/investigations \
  -H 'content-type: application/json' \
  -d '{"prompt":"What is this old fountain?","user_mode":"kid"}'
```

Frontend-ready request with OCR and coarse location:

```bash
curl -X POST http://localhost:8000/investigations \
  -H 'content-type: application/json' \
  -d '{
    "prompt": "What is this old fountain?",
    "user_mode": "kid",
    "age_band": "9-12",
    "observation": {
      "image_base64": "...compressed image...",
      "ocr_text": "Historic fountain plaque",
      "coarse_location": "Istanbul old city"
    }
  }'
```

```bash
curl -X POST http://localhost:8000/demo/heritage
```

Local Flutter web origins can be changed with `CURIO_ALLOWED_ORIGINS`.

Image upload endpoint:

```bash
curl -X POST http://localhost:8000/investigations/from-image \
  -F 'prompt=What is this old fountain?' \
  -F 'user_mode=kid' \
  -F 'ocr_text=Historic fountain plaque' \
  -F 'coarse_location=Istanbul old city' \
  -F 'image=@sample.jpg;type=image/jpeg'
```

Mobile view endpoints:

```bash
curl http://localhost:8000/investigations/{investigation_id}/mobile/kid
curl http://localhost:8000/investigations/{investigation_id}/mobile/parent
```

Runtime diagnostic:

```bash
curl http://localhost:8000/agent/runtime
curl http://localhost:8000/agent/aws-readiness
```

See `NEEDS_FROM_USER.md` for the remaining decisions and credentials needed before live judging.
See `AWS_SETUP.md` for Bedrock model access and credential setup.
