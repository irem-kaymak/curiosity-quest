# Mobile API Contract

Base URL for local development:

```text
http://127.0.0.1:8000
```

For Android emulator, use:

```text
http://10.0.2.2:8000
```

## Start From Text or OCR

```http
POST /investigations
content-type: application/json
```

```json
{
  "prompt": "What is this old fountain?",
  "user_mode": "kid",
  "age_band": "9-12",
  "observation": {
    "ocr_text": "Historic fountain plaque",
    "coarse_location": "Istanbul old city"
  }
}
```

## Start From Camera Image

```http
POST /investigations/from-image
content-type: multipart/form-data
```

Fields:

- `image`: JPEG, PNG, or WebP, max 6 MB
- `prompt`: user question
- `user_mode`: `kid` or `parent`
- `ocr_text`: optional OCR extracted on-device
- `coarse_location`: optional city or area only

In live Strands mode, the backend sends the validated image bytes to Bedrock
with the prompt so the domain can be routed from the actual photo content. In
demo mode, the endpoint still validates and stores the upload, then uses the
deterministic evidence-loop fallback.

## Continue Investigation

```http
POST /investigations/{investigation_id}/evidence
content-type: application/json
```

```json
{
  "observation": "The side photo shows a water basin under the arch.",
  "evidence_type": "photo"
}
```

## Mobile Views

Use these instead of rendering the full internal state on small screens:

```http
GET /investigations/{investigation_id}/mobile/kid
GET /investigations/{investigation_id}/mobile/parent
```

## Parent Notifications

```http
GET /notifications
```

Returns parent-facing safety events derived from recent investigations. Danger
and emergency detections set the investigation status to `danger_alert` or
`emergency_alert`, pause the normal learning flow for the child, and include a
recommended parent action.

## Parent Registration And Routing

```http
POST /parents/register
content-type: application/json
```

```json
{
  "parent_name": "Irem",
  "child_name": "Elif",
  "contact": {
    "email": "parent@example.com",
    "phone": "+15551234567",
    "push_token": "device-token",
    "email_verified": true,
    "phone_verified": true,
    "push_enabled": true
  }
}
```

```http
GET /parents/{parent_id}/notification-routing
```

The routing response shows which delivery channels are enabled and verified.
The current demo queues delivery records; production adapters can connect these
records to Amazon SNS, SES, Pinpoint, or Firebase/APNs push.

## Agent Card

```http
GET /investigations/{investigation_id}/agent-card
```

Returns the compact agentic reasoning artifact for demos and judging: observe,
hypothesize, seek evidence, policy, and notify.
