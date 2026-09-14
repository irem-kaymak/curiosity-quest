# AWS Builder Post Draft

Suggested title:

Agents for Humans: Building Curiosity Quest, a Safety-First Investigation Agent for Kids

## Draft

Children ask hundreds of questions about the world around them. A standard AI image app can label a photo, but families often need something more useful: a safe, age-appropriate learning loop.

For the Agents for Humans Hackathon, I built Curiosity Quest, a Flutter and FastAPI app where a child can upload a photo or ask a question and Curio turns it into an investigation.

Curio does five things:

1. observes the child’s question or image,
2. forms hypotheses,
3. explains what it knows and what is still uncertain,
4. asks for one safe next clue,
5. alerts a parent immediately when the situation may be risky.

The child experience has two age modes. Ages 3-6 get large playful cards, simple follow-up prompts, and badge feedback. Ages 7-9 get a fuller case board with clues, theory, Curio finding, and next mission. Both modes use the same dynamic backend.

AWS is central to the build:

- Amazon Bedrock powers Curio's reasoning and dynamic puzzle cards.
- Amazon Rekognition provides visual evidence labels.
- Amazon Polly supports Curio's voice output.
- The backend keeps a safety policy layer in front of child-facing responses and parent notifications.

The most important product lesson was that a child learning agent should not only answer. It should slow the moment down just enough to make curiosity safer and more meaningful.

Curiosity Quest turns "What is this?" into "Let's investigate it safely."
