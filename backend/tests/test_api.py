import unittest

from fastapi.testclient import TestClient

from app.main import app


PNG_BYTES = b"\x89PNG\r\n\x1a\n\x00\x00\x00\rIHDRdemo"


class ApiTest(unittest.TestCase):
    def setUp(self):
        self.client = TestClient(app)

    def test_health_and_domains(self):
        health = self.client.get("/health")
        self.assertEqual(health.status_code, 200)
        self.assertEqual(health.json()["status"], "ok")

        domains = self.client.get("/domains")
        self.assertEqual(domains.status_code, 200)
        self.assertEqual(domains.json()[0]["id"], "heritage")

        runtime = self.client.get("/agent/runtime")
        self.assertEqual(runtime.status_code, 200)
        self.assertIn("demo_mode", runtime.json())

        readiness = self.client.get("/agent/aws-readiness")
        self.assertEqual(readiness.status_code, 200)
        self.assertIn("credentials_discoverable", readiness.json())
        self.assertEqual(readiness.json()["polly_voice_id"], "Ivy")
        self.assertEqual(readiness.json()["polly_engine"], "neural")

    def test_tts_rejects_empty_text(self):
        response = self.client.post("/agent/tts", json={"text": "  "})
        self.assertEqual(response.status_code, 422)

    def test_tts_probe_reports_voice_status(self):
        response = self.client.get("/agent/tts-probe")
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertIn("ok", payload)
        self.assertEqual(payload["voice_id"], "Ivy")

    def test_puzzles_are_server_backed(self):
        response = self.client.get("/puzzles?age_band=13-15")
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertGreaterEqual(len(payload), 3)
        self.assertIn("title", payload[0])
        self.assertIn("choices", payload[0])
        self.assertIn("correct", payload[0])

    def test_parent_registration_exposes_notification_routing(self):
        created = self.client.post(
            "/parents/register",
            json={
                "parent_name": "Irem",
                "child_name": "Elif",
                "contact": {
                    "email": "parent@example.com",
                    "phone": "+15551234567",
                    "push_token": "device-token-1234",
                    "email_verified": True,
                    "phone_verified": True,
                    "push_enabled": True,
                },
            },
        )
        self.assertEqual(created.status_code, 200)
        parent_id = created.json()["parent_id"]

        routing = self.client.get(f"/parents/{parent_id}/notification-routing")
        self.assertEqual(routing.status_code, 200)
        channels = {item["channel"]: item for item in routing.json()["channels"]}
        self.assertTrue(channels["push"]["enabled"])
        self.assertTrue(channels["email"]["verified"])

    def test_create_and_append_evidence(self):
        created = self.client.post(
            "/investigations",
            json={
                "prompt": "What is this old fountain?",
                "user_mode": "kid",
                "observation": {
                    "ocr_text": "Old fountain plaque",
                    "coarse_location": "Istanbul old city",
                },
            },
        )
        self.assertEqual(created.status_code, 200)
        payload = created.json()
        self.assertEqual(payload["domain"], "heritage")
        self.assertEqual(payload["status"], "needs_evidence")

        updated = self.client.post(
            f"/investigations/{payload['investigation_id']}/evidence",
            json={
                "observation": "The side photo shows a water basin under the arch.",
                "evidence_type": "photo",
            },
        )
        self.assertEqual(updated.status_code, 200)
        self.assertEqual(updated.json()["status"], "concluded")

    def test_empty_prompt_is_validation_error(self):
        response = self.client.post("/investigations", json={"prompt": " "})
        self.assertEqual(response.status_code, 422)

    def test_create_from_image(self):
        response = self.client.post(
            "/investigations/from-image",
            data={
                "prompt": "What is this old fountain?",
                "user_mode": "kid",
                "ocr_text": "Fountain plaque",
                "coarse_location": "Istanbul",
            },
            files={"image": ("sample.png", PNG_BYTES, "image/png")},
        )
        self.assertEqual(response.status_code, 200)
        payload = response.json()
        self.assertEqual(payload["domain"], "heritage")
        self.assertIn("Image sha256", payload["prompt"])

    def test_mobile_views(self):
        created = self.client.post(
            "/investigations",
            json={"prompt": "What is this old fountain?", "user_mode": "kid"},
        ).json()
        kid = self.client.get(
            f"/investigations/{created['investigation_id']}/mobile/kid"
        )
        parent = self.client.get(
            f"/investigations/{created['investigation_id']}/mobile/parent"
        )
        self.assertEqual(kid.status_code, 200)
        self.assertEqual(parent.status_code, 200)
        self.assertIn("next_action", kid.json())
        self.assertIn("agent_trace", kid.json())
        self.assertIn("evidence", parent.json())

    def test_notifications_include_safety_events(self):
        created = self.client.post(
            "/investigations",
            json={"prompt": "I see smoke and fire near the stove", "user_mode": "kid"},
        )
        self.assertEqual(created.status_code, 200)
        self.assertEqual(created.json()["status"], "emergency_alert")

        notifications = self.client.get("/notifications")
        self.assertEqual(notifications.status_code, 200)
        payload = notifications.json()
        self.assertGreaterEqual(len(payload), 1)
        self.assertEqual(payload[0]["severity"], "emergency")
        self.assertIn("immediately", payload[0]["message"].lower())
        deliveries = payload[0]["deliveries"]
        self.assertTrue(any(item["channel"] == "in_app" for item in deliveries))
        self.assertTrue(any(item["channel"] == "sms" for item in deliveries))

    def test_text_only_danger_question_routes_to_parent_alert(self):
        created = self.client.post(
            "/investigations",
            json={
                "prompt": "I see a sharp knife and fire, what should I do?",
                "user_mode": "kid",
                "age_band": "3-6",
                "parent_contact": {
                    "email": "parent@example.com",
                    "phone": "+15551234567",
                    "push_token": "device-token-1234",
                    "email_verified": True,
                    "phone_verified": True,
                    "push_enabled": True,
                },
            },
        )
        self.assertEqual(created.status_code, 200)
        payload = created.json()
        self.assertIn(payload["status"], {"danger_alert", "emergency_alert"})
        self.assertTrue(payload["safety_events"])
        self.assertTrue(payload["parent_gate_required"])
        self.assertIn("parent_notify", payload["safety_flags"])
        self.assertTrue(payload["notification_deliveries"])

    def test_verified_parent_contact_queues_external_deliveries(self):
        created = self.client.post(
            "/investigations",
            json={
                "prompt": "There is a knife beside me",
                "user_mode": "kid",
                "parent_contact": {
                    "email": "parent@example.com",
                    "phone": "+15551234567",
                    "push_token": "device-token-1234",
                    "email_verified": True,
                    "phone_verified": True,
                    "push_enabled": True,
                },
            },
        )
        self.assertEqual(created.status_code, 200)
        payload = created.json()
        self.assertEqual(payload["status"], "danger_alert")
        self.assertEqual(payload["selected_quest"]["modality"], "safety_protocol")
        self.assertIn("Safety first", payload["conclusion"]["kid_summary"])
        queued = {
            item["channel"]
            for item in payload["notification_deliveries"]
            if item["status"] == "queued"
        }
        self.assertEqual(queued, {"in_app", "push", "email", "sms"})

        card = self.client.get(f"/investigations/{payload['investigation_id']}/agent-card")
        self.assertEqual(card.status_code, 200)
        self.assertEqual(card.json()["agentic_loop"][-1]["step"], "notify")


if __name__ == "__main__":
    unittest.main()
