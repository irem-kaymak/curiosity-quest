# Demo Video Script

Target length: 3-5 minutes.

## 0:00-0:25 Problem

Children ask questions about the world constantly, but parents cannot always turn every question into a safe learning moment. A normal image classifier gives a label; Curio turns the moment into an investigation.

## 0:25-0:55 Who It Is For

Curiosity Quest is for families with young children. It has two child modes:

- Ages 3-6: big cards, voice-first feel, simple follow-up prompts, and playful badges.
- Ages 7-9: fuller case boards, clues, hypotheses, uncertainty, and investigation missions.

Parents get controls, safety settings, and urgent review items.

## 0:55-1:40 Working Demo: Photo Investigation

Show the child uploading a photo.

Narration:

Curio does not just say what the image is. It builds a case board: the photo, clues, a theory, Curio's finding, a next mission, and a badge. The child can answer Curio's follow-up, and that answer goes back to the AI for another dynamic response.

## 1:40-2:20 Working Demo: Text Question

Show a text-only question with no new image.

Narration:

Children can ask anything, even without a new photo. Curio answers from the current context and continues the investigation with a small safe next step.

## 2:20-3:05 Safety And Parent Layer

Show a risky prompt or image, such as a kitchen knife.

Narration:

When a child encounters a possible danger, Curio changes mode. The child sees immediate, simple safety guidance. At the same time, the backend creates a parent alert so the adult side can act quickly.

## 3:05-3:35 Dynamic Puzzle

Show puzzle time.

Narration:

Puzzle cards are generated from the backend, not static app content. Both age modes use the same dynamic puzzle pipeline, with age-appropriate presentation.

## 3:35-4:20 Architecture And AWS

Show the architecture diagram.

Narration:

The Flutter app talks to a FastAPI backend. The backend uses Amazon Bedrock for Curio reasoning and puzzle generation, Rekognition for image evidence, and Polly for voice output. Safety policy and parent notification routing run before the response reaches the child.

## 4:20-4:50 Why It Matters

Curio helps families turn curiosity into safe, evidence-based exploration. The differentiator is not just answering questions; it is the loop of investigation, child safety, parent awareness, and age-specific learning.

## Closing Line

Curiosity Quest turns "What is this?" into "Let's investigate it safely."
