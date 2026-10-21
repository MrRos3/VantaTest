import os
import sys
import tempfile
import unittest

ROOT = os.path.dirname(os.path.dirname(__file__))
sys.path.insert(0, ROOT)
os.environ.setdefault("SECRET_KEY", "ci-testing-only-secret-key")
os.environ.setdefault("INVITE_CODE", "VANTA-CI")
os.environ["DB_PATH"] = os.path.join(tempfile.mkdtemp(), "messages.sqlite3")
from server import app


class ChatSmokeTest(unittest.TestCase):
    def setUp(self):
        self.alice = app.test_client()
        self.bob = app.test_client()

    def register(self, client, username):
        resp = client.post("/api/account", json={
            "mode": "register", "username": username,
            "password": "long-safe-password-123",
            "invite": "VANTA-CI", "guidelines": True
        })
        self.assertEqual(resp.status_code, 200, resp.get_json())
        return resp.get_json()

    def post(self, client, path, data, csrf):
        return client.post("/api/" + path, json=data, headers={"X-CSRF-Token": csrf})

    def test_everything(self):
        self.assertEqual(self.alice.get("/api/health").status_code, 200)
        self.assertEqual(self.alice.get("/").status_code, 200)
        self.assertEqual(self.alice.get("/icons/social/send.svg").status_code, 200)
        self.assertEqual(self.alice.get("/wallpaper").status_code, 200)
        alice = self.register(self.alice, "Beta_Alice")
        bob = self.register(self.bob, "Beta_Bob")
        forbidden = self.post(self.alice,"messages",{"room":"EN","content":"Hi"}, "wrong")
        self.assertEqual(forbidden.status_code, 403)
        one = self.post(self.alice, "messages",{"room":"EN","content":"Hello world 🌹"},alice["csrf"])
        self.assertEqual(one.status_code,201,one.get_json())
        mid = one.get_json()["id"]
        english = self.bob.get("/api/messages?room=EN").get_json()
        self.assertEqual(english["messages"][-1]["content"], "Hello world 🌹")
        self.assertEqual(self.bob.get("/api/messages?room=AR").get_json()["messages"],[])
        reply = self.post(self.bob, "messages", {"room":"EN","content":"Hi back 🤍","reply_id":mid},bob["csrf"])
        self.assertEqual(reply.status_code,201)
        reaction = self.post(self.bob,"react",{"id":mid,"emoji":"❤️"},bob["csrf"])
        self.assertEqual(reaction.status_code,200)
        inbox = self.alice.get("/api/messages?room=EN").get_json()["messages"]
        self.assertEqual(inbox[-1]["reply_content"],"Hello world 🌹")
        self.assertIn("❤️",inbox[0]["reactions"])
        arabic = self.post(self.alice,"messages",{"room":"AR","content":"هلا والله يا حلو"},alice["csrf"])
        self.assertEqual(arabic.status_code,201,arabic.get_json())
        self.assertEqual(self.bob.get("/api/messages?room=AR").get_json()["messages"][-1]["content"],"هلا والله يا حلو")
        abuse = self.post(self.alice,"messages",{"room":"EN","content":"https://example.com"},alice["csrf"])
        self.assertEqual(abuse.status_code,400)
        report = self.post(self.bob,"report",{"id":mid},bob["csrf"])
        self.assertEqual(report.status_code,200)
        block = self.post(self.bob,"block",{"user_id":alice["user"]["id"]},bob["csrf"])
        self.assertEqual(block.status_code,200)
        self.assertFalse(any(m["user_id"]==alice["user"]["id"] for m in self.bob.get("/api/messages?room=EN").get_json()["messages"]))
        delete = self.post(self.alice,"delete",{"id":mid},alice["csrf"])
        self.assertEqual(delete.status_code,200)
        self.assertFalse(any(m["id"]==mid for m in self.alice.get("/api/messages?room=EN").get_json()["messages"]))


if __name__ == "__main__":
    unittest.main()
