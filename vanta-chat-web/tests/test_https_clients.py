"""Real loopback HTTPS with independent cookie jars. Not Roblox integration proof."""
import http.cookiejar
import json
import os
from pathlib import Path
import ssl
import sys
import tempfile
import threading
import unittest
import urllib.error
import urllib.request
from werkzeug.serving import make_server, WSGIRequestHandler

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
os.environ.setdefault('SECRET_KEY', 'local-http-tests-only')
os.environ.setdefault('INVITE_CODE', 'VANTA-CI')
import server


class QuietTestHandler(WSGIRequestHandler):
    def log_request(self, *args, **kwargs):
        pass


class IndependentHTTPSClients(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        # Certificate verification is disabled ONLY for this self-signed loopback server.
        cls.httpd = make_server('127.0.0.1', 0, server.app, ssl_context='adhoc', request_handler=QuietTestHandler)
        cls.base = 'https://127.0.0.1:' + str(cls.httpd.server_port)
        cls.thread = threading.Thread(target=cls.httpd.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.httpd.shutdown()
        cls.thread.join(timeout=5)
        cls.httpd.server_close()

    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        server.DB_PATH = str(Path(self.temp.name) / 'independent.sqlite3')
        server.initialize()
        server.LIMITS.clear()
        self.alice, self.bob = self.client(), self.client()

    def tearDown(self):
        self.temp.cleanup()

    def client(self):
        return urllib.request.build_opener(
            urllib.request.HTTPSHandler(context=ssl._create_unverified_context()),
            urllib.request.HTTPCookieProcessor(http.cookiejar.CookieJar()))

    def request(self, client, path, body=None, csrf=None):
        headers = {'Content-Type': 'application/json'}
        if csrf is not None:
            headers['X-CSRF-Token'] = csrf
        request = urllib.request.Request(self.base + '/api/' + path,
            data=None if body is None else json.dumps(body).encode(), headers=headers)
        try:
            with client.open(request, timeout=5) as response:
                return response.status, json.load(response)
        except urllib.error.HTTPError as error:
            with error:
                return error.code, json.load(error)

    def register(self, client, name):
        status, data = self.request(client, 'account', dict(mode='register',
            username=name, password='local-strong-password-123',
            invite=server.INVITE_CODE, guidelines=True))
        self.assertEqual(status, 200, data)
        return data

    def test_real_two_way_messages_history_replies_reactions_and_csrf(self):
        alice = self.register(self.alice, 'HTTPS_Alice')
        bob = self.register(self.bob, 'HTTPS_Bob')
        self.assertNotEqual(alice['user']['id'], bob['user']['id'])
        self.assertEqual(self.request(self.client(), 'messages')[0], 401)
        self.assertEqual(self.request(self.alice, 'messages',
            {'room': 'EN', 'content': 'Denied'}, 'wrong')[0], 403)
        status, first = self.request(self.alice, 'messages',
            {'room': 'EN', 'content': 'Hello from HTTPS Alice'}, alice['csrf'])
        self.assertEqual(status, 201)
        self.assertEqual(self.request(self.bob, 'messages?room=EN')[1]['messages'][0]['content'],
            'Hello from HTTPS Alice')
        self.assertEqual(self.request(self.bob, 'messages',
            {'room': 'EN', 'content': 'Reply from HTTPS Bob', 'reply_id': first['id']}, bob['csrf'])[0], 201)
        history = self.request(self.alice, 'messages?room=EN')[1]['messages']
        self.assertEqual(history[-1]['reply_content'], 'Hello from HTTPS Alice')
        self.assertEqual(self.request(self.bob, 'react', {'id': first['id'], 'emoji': '👍'}, bob['csrf'])[0], 200)
        self.assertIn('👍', self.request(self.alice, 'messages?room=EN')[1]['messages'][0]['reactions'])
        self.assertEqual(self.request(self.alice, 'messages?room=AR')[1]['messages'], [])
        self.assertEqual(self.request(self.bob, 'messages',
            {'room': 'AR', 'content': 'مرحبا من بوب'}, bob['csrf'])[0], 201)
        self.assertEqual(self.request(self.alice, 'messages?room=AR')[1]['messages'][0]['content'], 'مرحبا من بوب')

    def test_blocks_apply_both_directions_and_hide_quoted_parent(self):
        alice = self.register(self.alice, 'Block_Alice')
        bob = self.register(self.bob, 'Block_Bob')
        third = self.client()
        carol = self.register(third, 'Block_Carol')
        _, message = self.request(self.alice, 'messages',
            {'room': 'EN', 'content': 'Alice parent'}, alice['csrf'])
        self.assertEqual(self.request(third, 'messages',
            {'room': 'EN', 'content': 'Carol reply', 'reply_id': message['id']}, carol['csrf'])[0], 201)
        self.assertEqual(self.request(self.bob, 'block', {'user_id': alice['user']['id']}, bob['csrf'])[0], 200)
        bob_history = self.request(self.bob, 'messages?room=EN')[1]['messages']
        self.assertEqual(len(bob_history), 1)
        self.assertIsNone(bob_history[0]['reply_content'])
        self.assertEqual(self.request(self.bob, 'messages',
            {'room': 'EN', 'content': 'Blocked reply', 'reply_id': message['id']}, bob['csrf'])[0], 400)
        self.assertEqual(self.request(self.bob, 'react',
            {'id': message['id'], 'emoji': '👍'}, bob['csrf'])[0], 404)
        self.assertEqual(self.request(self.bob, 'messages',
            {'room': 'AR', 'content': 'Bob private from blocked Alice'}, bob['csrf'])[0], 201)
        self.assertEqual(self.request(self.alice, 'messages?room=AR')[1]['messages'], [])

    def test_malformed_json_and_foreign_deletion_fail_closed(self):
        alice = self.register(self.alice, 'Bad_Alice')
        bob = self.register(self.bob, 'Bad_Bob')
        self.assertEqual(self.request(self.client(), 'account', ['not an object'])[0], 400)
        self.assertEqual(self.request(self.alice, 'messages',
            {'room': [], 'content': 'invalid'}, alice['csrf'])[0], 400)
        _, message = self.request(self.alice, 'messages',
            {'room': 'EN', 'content': 'Owned by Alice'}, alice['csrf'])
        self.assertEqual(self.request(self.bob, 'delete', {'id': message['id']}, bob['csrf'])[0], 403)


if __name__ == '__main__':
    unittest.main()

