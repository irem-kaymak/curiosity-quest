# About The Project

```markdown
## Inspiration

Children are naturally curious. They ask questions about animals, plants, food, places, objects, stories, and everything they notice around them. But most AI tools are not designed for children in the physical world. They can answer too confidently, miss safety context, or turn curiosity into passive screen time.

That inspired us to build Curiosity Quest: a safety-first AI companion that turns a child's question into an investigation.

The idea started from the child-facing frontend experience: a playful Curio world with age-specific interfaces, parent areas, badges, puzzles, and a friendly mascot. As we kept testing it, the biggest product lesson became clear: the app could not rely on static content. Children can ask anything. The backend had to generate real, contextual, safe responses every time.

## What it does

Curiosity Quest lets children ask questions with photos, text, and voice-oriented flows. Curio responds through a case-board format instead of a normal chat thread.

Each investigation can include:

- the child's clue or photo
- Curio's evidence-based finding
- a simple explanation of uncertainty
- a follow-up question
- a next mission
- dynamic puzzle cards
- badge and discovery progress
- parent-facing safety signals when needed

The app supports two child modes:

- Ages 3-6: a simpler, more visual experience with bigger cards, playful choices, and gentler language.
- Ages 7-9: fuller investigation cards with clues, hypotheses, confidence, puzzles, and richer reasoning.

The parent side provides oversight, controls, and a place for safety-related alerts. If Curio detects a risky moment, such as a weapon, fire, blood, unsafe food uncertainty, or an adult-gated action, the child receives immediate safe guidance and the system prepares a parent alert.

## How we built it

The app is built with a Flutter frontend and a Python FastAPI backend.

The frontend focuses on the child and parent experience: age-specific screens, case boards, puzzle views, badge moments, parent areas, and the Curio visual identity.

The backend is the agent layer. It coordinates the investigation loop, safety checks, visual evidence, dynamic answers, puzzle generation, and persistence.

We used AWS services for the live AI pipeline:

- Amazon Bedrock powers Curio's dynamic reasoning, open-ended answers, follow-up questions, and puzzle generation.
- Amazon Rekognition extracts visual evidence from uploaded photos.
- Amazon Polly is used for voice-output experiments.

The backend also includes readiness/probe endpoints, local SQLite persistence for demo investigations, deterministic fallback behavior for local demos, and age-band routing so both 3-6 and 7-9 experiences can use the same dynamic intelligence.

## Challenges we ran into

The biggest challenge was making the product dynamic without making it unsafe.

At first, some flows behaved too much like static educational cards. That was not enough. A child might upload a squirrel, a flower, a knife, a horse, a monument, or ask a text-only question like "how do I say hello?" Curio needed to handle all of those without us hardcoding examples.

We also had to move away from a normal chat feeling. For children, especially younger children, the answer should feel like an investigation portal: one card at a time, with a clear clue, finding, question, next mission, and reward.

Another challenge was balancing freedom and safety. Curio should encourage exploration, but when a situation may be dangerous, the child experience must immediately become simpler and safer while the parent side gets visibility.

## Accomplishments that we're proud of

We are proud that Curiosity Quest became more than a cute learning app. It became an agentic investigation loop for children and parents.

The app now supports photo-based and text-based questions, dynamic AI answers, age-specific experiences, puzzle generation, badges, parent controls, and safety escalation concepts. Curio does not just label an image; it asks what evidence is missing and helps the child continue safely.

We are also proud of the product direction. The frontend gives Curio a playful, childlike feeling, while the backend keeps the experience live, contextual, and safety-aware.

## What we learned

We learned that child-facing AI is not only a prompting problem. It is a product architecture problem.

The AI answer, visual design, safety logic, parent trust, age band, voice interaction, and reward system all have to work together. A technically correct answer can still feel wrong if it is too adult, too static, too confident, or not safe enough.

We also learned that curiosity works best as a loop. The best answer is not always the final answer; sometimes it is the next safe question.

## What's next

Next, we would turn the parent alert pipeline into production notifications, improve voice output and voice input, add richer child learning journals, expand localization, and create classroom, museum, and nature-exploration modes.

We would also deploy a live version, add stronger analytics for parents, and continue improving Curio's ability to adapt its language, puzzles, and missions to each child's age and learning history.
```
