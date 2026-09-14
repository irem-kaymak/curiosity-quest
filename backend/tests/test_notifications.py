from __future__ import annotations

import unittest

from app.agent_core import start_investigation
from app.notifications import NotificationDispatcher, ParentContact


class NotificationDispatcherTest(unittest.TestCase):
    def test_unverified_parent_contact_only_queues_in_app(self) -> None:
        inv = start_investigation("There is smoke and fire in the kitchen")
        deliveries = NotificationDispatcher().dispatch(inv)
        by_channel = {delivery.channel: delivery.status for delivery in deliveries}
        self.assertEqual(by_channel["in_app"], "queued")
        self.assertEqual(by_channel["push"], "skipped")
        self.assertEqual(by_channel["email"], "skipped")
        self.assertEqual(by_channel["sms"], "skipped")

    def test_verified_parent_contact_queues_external_channels(self) -> None:
        inv = start_investigation("There is a knife beside me")
        contact = ParentContact(
            email="parent@example.com",
            phone="+15551234567",
            push_token="device-token-1234",
            email_verified=True,
            phone_verified=True,
            push_enabled=True,
        )
        deliveries = NotificationDispatcher().dispatch(inv, contact)
        queued = {delivery.channel for delivery in deliveries if delivery.status == "queued"}
        self.assertEqual(queued, {"in_app", "push", "email", "sms"})


if __name__ == "__main__":
    unittest.main()
