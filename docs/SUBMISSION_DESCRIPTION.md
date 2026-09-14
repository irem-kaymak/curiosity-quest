# Submission Description

Curiosity Quest is a safety-first investigation agent for children and parents. It started from a playful Flutter child experience with age-specific screens, a Curio mascot, badges, puzzles, and parent areas. As we tested it, the main product insight became obvious: children can ask anything, so the experience cannot depend on static educational cards.

Curio now turns children's photos, text questions, and voice-oriented interactions into dynamic case boards. Instead of simply labeling an image, Curio observes clues, explains what it knows, points out uncertainty, asks for one safe next clue, and rewards the child with a badge or puzzle moment.

The backend is a FastAPI agent layer that powers the live investigation loop. It uses Amazon Bedrock for dynamic reasoning and puzzle generation, Amazon Rekognition for visual evidence, and Amazon Polly for voice-output experiments. It also includes age-band routing, safety checks, parent alert payloads, and local SQLite persistence for demo investigations.

The app supports two child experiences: ages 3-6 get a simpler, more visual and voice-friendly flow, while ages 7-9 get richer case boards with clues, hypotheses, confidence, puzzles, and follow-up missions. Parents get controls and safety visibility.

Curiosity Quest matters because child-facing AI should not just answer questions. It should help children practice curiosity safely: observe, wonder, investigate, and know when to involve a grown-up.
