# Agents for Humans Submission Checklist

## Required

- [ ] Text description explaining:
  - [ ] what the project does
  - [ ] who it is for
  - [ ] how it works
- [ ] Public URL to source code repository
- [x] MIT license in repository root
- [x] README with setup instructions
- [x] Architecture diagram
- [ ] Demo video, maximum 5 minutes
- [ ] Demo video demonstrates the working project
- [ ] Pitch covers:
  - [ ] the problem being solved
  - [ ] who it is for
  - [ ] why it matters
- [ ] AWS Builder ID
- [ ] Optional live demo link

## Recommended Before Publishing The Repo

- [ ] Confirm `.env` is not committed.
- [ ] Confirm `backend/curiosity_quest.sqlite3` is not committed.
- [ ] Confirm `frontend/build/` is not committed.
- [ ] Add screenshots or a short GIF to the README if available.
- [ ] Replace placeholder repository/live-demo URLs in `README.md`.
- [ ] Run backend smoke checks:

```bash
curl http://127.0.0.1:8000/agent/aws-readiness
curl http://127.0.0.1:8000/agent/ai-probe
curl "http://127.0.0.1:8000/puzzles?age_band=3-6"
```

## Suggested Submission Description

Curiosity Quest is an agentic discovery app for children and parents. Instead of simply labeling a photo, Curio turns a child's question into a safe investigation: it observes clues, forms hypotheses, explains uncertainty, asks for one more safe clue, and creates a child-friendly mission. For risky situations, Curio gives immediate child-safe guidance and surfaces an alert in the parent view. The app supports ages 3-6 and 7-9 with different interfaces over the same dynamic AI backend. It uses Amazon Bedrock for reasoning and puzzle generation, Amazon Rekognition for image evidence, and Amazon Polly for voice output.
