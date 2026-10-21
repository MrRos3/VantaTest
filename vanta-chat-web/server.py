"""Vanta Chat companion: invite-only, rate-limited independent web chat.
Designed for Render free-tier demo. SQLite on free Render storage is EPHEMERAL.
Not an in-game Roblox chat transport.
"""
import os
import re
import hmac
import time
import secrets
import hashlib
import sqlite3
from functools import wraps
from contextlib import contextmanager
from pathlib import Path
from flask import Flask, request, jsonify, session, send_from_directory

BASE = Path(__file__).resolve().parent
DB_PATH = os.environ.get("DB_PATH", "/tmp/vanta-chat-lab.sqlite3")
INVITE_CODE = os.environ.get("INVITE_CODE", "")
app = Flask(__name__, static_folder=str(BASE / "public"), static_url_path="")
app.config.update(
    SECRET_KEY=os.environ["SECRET_KEY"],
    SESSION_COOKIE_SECURE=True,
    SESSION_COOKIE_HTTPONLY=True,
    SESSION_COOKIE_SAMESITE="Lax",
    PERMANENT_SESSION_LIFETIME=60 * 60 * 24 * 14,
    MAX_CONTENT_LENGTH=20_000,
)
app.json.ensure_ascii = False
ROOMS = {"EN", "AR"}
LIMITS = {}
BAD_PATTERN = re.compile(
    r"(?i)(https?://|www\.|discord\.gg/|@[a-z0-9_.-]+\.[a-z]{2,}|"
    r"\b[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}\b|"
    r"\b(?:\+?\d[\d \-\(\)]{8,}\d)\b)"
)
SPAM_PATTERN = re.compile(r"(.)\1{25,}", re.DOTALL)
ABUSE_PATTERN = re.compile(r"(?i)\b(kys|kill yourself|nigger|faggot)\b")


@contextmanager
def database():
    connection = sqlite3.connect(DB_PATH, timeout=15)
    connection.row_factory = sqlite3.Row
    connection.execute("PRAGMA busy_timeout = 10000")
    connection.execute("PRAGMA foreign_keys = ON")
    try:
        with connection:
            yield connection
    finally:
        connection.close()


def initialize():
    with database() as db:
        db.execute("PRAGMA journal_mode = WAL")
        db.executescript("""
        CREATE TABLE IF NOT EXISTS users(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL UNIQUE COLLATE NOCASE,
            pass_hash TEXT NOT NULL,
            created INTEGER NOT NULL,
            last_seen INTEGER NOT NULL DEFAULT 0,
            last_room TEXT NOT NULL DEFAULT 'EN',
            banned INTEGER NOT NULL DEFAULT 0
        );
        CREATE TABLE IF NOT EXISTS messages(
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NOT NULL REFERENCES users(id),
            room TEXT NOT NULL CHECK(room IN ('EN','AR')),
            content TEXT NOT NULL,
            reply_id INTEGER REFERENCES messages(id),
            created INTEGER NOT NULL,
            deleted INTEGER NOT NULL DEFAULT 0
        );
        CREATE INDEX IF NOT EXISTS idx_room_messages ON messages(room,id);
        CREATE INDEX IF NOT EXISTS idx_user_messages ON messages(user_id,created);
        CREATE TABLE IF NOT EXISTS reports(
            message_id INTEGER NOT NULL REFERENCES messages(id),
            reporter_id INTEGER NOT NULL REFERENCES users(id),
            reason TEXT NOT NULL,
            created INTEGER NOT NULL,
            PRIMARY KEY(message_id,reporter_id)
        );
        CREATE TABLE IF NOT EXISTS blocks(
            owner INTEGER NOT NULL REFERENCES users(id),
            target INTEGER NOT NULL REFERENCES users(id),
            PRIMARY KEY(owner,target)
        );
        CREATE TABLE IF NOT EXISTS reactions(
            message_id INTEGER NOT NULL REFERENCES messages(id),
            user_id INTEGER NOT NULL REFERENCES users(id),
            emoji TEXT NOT NULL,
            PRIMARY KEY(message_id,user_id)
        );
        """)
initialize()


def reply_error(text, code=400):
    return jsonify(error=text), code


def json_body():
    value = request.get_json(silent=True)
    return value if isinstance(value, dict) else {}


def client_key():
    return request.remote_addr or "unknown"


def throttle(key, max_calls, seconds):
    now = time.monotonic()
    sample = LIMITS.setdefault((client_key(), key), [])
    sample[:] = [v for v in sample if now - v < seconds]
    if len(sample) >= max_calls:
        return False
    sample.append(now)
    if len(LIMITS) > 5000:
        LIMITS.clear()
    return True


def derive_password(value, salt=None):
    salt = salt or secrets.token_bytes(16)
    result = hashlib.pbkdf2_hmac("sha256", value.encode("utf-8"), salt, 250_000)
    return salt.hex() + ":" + result.hex()


def verify_password(value, stored):
    try:
        salt, _digest = stored.split(":", 1)
        return hmac.compare_digest(derive_password(value, bytes.fromhex(salt)), stored)
    except (ValueError, TypeError):
        return False


def require_user(fn):
    @wraps(fn)
    def decorated(*args, **kwargs):
        user_id = session.get("user_id")
        if not isinstance(user_id, int):
            return reply_error("Sign in to Vanta Chat first.", 401)
        with database() as db:
            found = db.execute("SELECT id,name,banned FROM users WHERE id=?", (user_id,)).fetchone()
        if found is None or found["banned"]:
            session.clear()
            return reply_error("This session is not available.", 401)
        return fn(*args, **kwargs)
    return decorated


def check_csrf():
    expected = str(session.get("csrf", ""))
    submitted = str(request.headers.get("X-CSRF-Token", ""))
    return bool(expected) and hmac.compare_digest(expected, submitted)


def csrf_error():
    return reply_error("Invalid session token.", 403)


@app.after_request
def security_headers(response):
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["Referrer-Policy"] = "no-referrer"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["Cache-Control"] = "no-store"
    response.headers["Content-Security-Policy"] = (
        "default-src 'self'; script-src 'self'; style-src 'self'; "
        "img-src 'self' data:; connect-src 'self'; "
        "object-src 'none'; frame-ancestors 'none'; base-uri 'none'"
    )
    return response


@app.get("/")
def homepage():
    return send_from_directory(app.static_folder, "index.html")


@app.get("/wallpaper")
def wallpaper():
    return send_from_directory(BASE.parent / "assets", "crimson01-hq.jpg")

@app.get("/api/health")
def health():
    return jsonify(ok=True, service="vanta-chat-companion", rooms=["EN", "AR"],
                   persistence="ephemeral-free-tier", invite_only=True,
                   roblox_transport=False, roblox_filtering=False)


@app.get("/api/me")
def me():
    uid = session.get("user_id")
    if not uid:
        return jsonify(user=None)
    with database() as db:
        row = db.execute("SELECT id,name,banned FROM users WHERE id=?", (uid,)).fetchone()
    if row is None or row["banned"]:
        session.clear()
        return jsonify(user=None)
    return jsonify(user=dict(id=row["id"], name=row["name"]), csrf=session.get("csrf"))


@app.post("/api/account")
def account():
    if not throttle("auth", 12, 60):
        return reply_error("Please wait before trying again.", 429)
    obj = json_body()
    name = str(obj.get("username", "")).strip()
    password = str(obj.get("password", ""))
    mode = obj.get("mode")
    if not re.fullmatch(r"[A-Za-z0-9_]{3,24}", name) or not 10 <= len(password) <= 128:
        return reply_error("Use a 3–24 character username and password of at least 10 characters.")
    if mode not in ("register", "login"):
        return reply_error("Invalid account action.")
    with database() as db:
        row = db.execute("SELECT id,name,pass_hash,banned FROM users WHERE name=?", (name,)).fetchone()
        if mode == "register":
            if not INVITE_CODE:
                return reply_error("Registration is temporarily disabled.", 503)
            if not hmac.compare_digest(str(obj.get("invite", "")), INVITE_CODE):
                return reply_error("A valid beta invitation is required.", 403)
            if obj.get("guidelines") is not True:
                return reply_error("Please accept the community rules.")
            if not throttle("register", 4, 3600):
                return reply_error("Registration limit reached. Try later.", 429)
            if row:
                return reply_error("Username is already taken.", 409)
            now = int(time.time())
            result = db.execute(
                "INSERT INTO users(name,pass_hash,created) VALUES(?,?,?)",
                (name, derive_password(password), now)
            )
            user_id = result.lastrowid
        else:
            if not row or not verify_password(password, row["pass_hash"]):
                return reply_error("Incorrect username or password.", 401)
            if row["banned"]:
                return reply_error("Account unavailable.", 403)
            user_id = row["id"]
    session.clear()
    session.permanent = True
    session["user_id"] = int(user_id)
    session["csrf"] = secrets.token_urlsafe(30)
    return jsonify(user={"id":user_id,"name":name},csrf=session["csrf"])


@app.post("/api/logout")
@require_user
def logout():
    if not check_csrf(): return csrf_error()
    session.clear()
    return jsonify(ok=True)


def message_rows(db, room, after, user_id):
    rows = db.execute("""
        SELECT m.id,m.user_id,u.name author,m.room,m.content,m.reply_id,m.created,
               parent.content reply_content,pu.name reply_author,
               (SELECT GROUP_CONCAT(r.emoji,' ') FROM reactions r WHERE r.message_id=m.id) reactions
        FROM messages m JOIN users u ON m.user_id=u.id
        LEFT JOIN messages parent ON m.reply_id=parent.id AND parent.deleted=0
          AND NOT EXISTS(SELECT 1 FROM blocks b WHERE
              (b.owner=:viewer AND b.target=parent.user_id) OR
              (b.target=:viewer AND b.owner=parent.user_id))
        LEFT JOIN users pu ON parent.user_id=pu.id
        WHERE m.room=:room AND m.id>:after AND m.deleted=0
          AND NOT EXISTS(SELECT 1 FROM blocks b WHERE
              (b.owner=:viewer AND b.target=m.user_id) OR
              (b.target=:viewer AND b.owner=m.user_id))
          AND (SELECT count(*) FROM reports rpt WHERE rpt.message_id=m.id) < 2
        ORDER BY m.id DESC LIMIT 80
    """,
        {"room": room, "after": after, "viewer": user_id}).fetchall()
    return [dict(x) for x in reversed(rows)]


@app.get("/api/messages")
@require_user
def list_messages():
    room = request.args.get("room", "EN")
    if room not in ROOMS: return reply_error("Invalid room.")
    try: after = max(0, int(request.args.get("after", "0")))
    except (ValueError, TypeError): return reply_error("Invalid message cursor.")
    now = int(time.time())
    with database() as db:
        db.execute("UPDATE users SET last_seen=?,last_room=? WHERE id=?", (now, room, session["user_id"]))
        presence = db.execute(
            "SELECT count(*) n FROM users WHERE last_seen>? AND last_room=? AND banned=0",
            (now - 70, room)
        ).fetchone()["n"]
        rows = message_rows(db, room, after, session["user_id"])
    return jsonify(messages=rows,online=presence,room=room)


@app.post("/api/messages")
@require_user
def post_message():
    if not check_csrf(): return csrf_error()
    if not throttle("send-burst", 4, 8):
        return reply_error("Too many messages. Wait a moment.", 429)
    obj = json_body()
    content = obj.get("content")
    room = obj.get("room")
    if not isinstance(room, str) or room not in ROOMS or not isinstance(content, str):
        return reply_error("Invalid room or message.")
    content = content.strip()
    if not 1 <= len(content) <= 500 or len(content.encode("utf-8")) > 1800:
        return reply_error("Messages must be between 1 and 500 characters.")
    if BAD_PATTERN.search(content) or ABUSE_PATTERN.search(content) or SPAM_PATTERN.search(content):
        return reply_error("Message blocked by the beta safety filter: no links, contact details or abusive language.")
    if any(ord(ch) < 32 and ch not in "\n\t" for ch in content):
        return reply_error("Unsupported message characters.")
    reply_id = obj.get("reply_id")
    if reply_id is not None:
        try: reply_id = int(reply_id)
        except (ValueError, TypeError): return reply_error("Invalid reply.")
    now = int(time.time())
    with database() as db:
        count = db.execute(
            "SELECT count(*) n FROM messages WHERE user_id=? AND created>?",
            (session["user_id"], now - 60)
        ).fetchone()["n"]
        if count >= 10: return reply_error("You reached the 10 messages/minute limit.", 429)
        if reply_id is not None:
            parent = db.execute(
                "SELECT 1 FROM messages m WHERE id=? AND room=? AND deleted=0 "
                "AND NOT EXISTS(SELECT 1 FROM blocks b WHERE "
                "(b.owner=? AND b.target=m.user_id) OR (b.target=? AND b.owner=m.user_id))",
                (reply_id, room, session["user_id"], session["user_id"])
            ).fetchone()
            if not parent: return reply_error("Reply message is no longer available.")
        mid = db.execute(
            "INSERT INTO messages(user_id,room,content,reply_id,created) VALUES(?,?,?,?,?)",
            (session["user_id"],room,content,reply_id,now)
        ).lastrowid
    return jsonify(ok=True,id=mid),201


@app.post("/api/react")
@require_user
def react():
    if not check_csrf(): return csrf_error()
    obj = json_body()
    try: mid = int(obj.get("id"))
    except (ValueError, TypeError): return reply_error("Invalid message ID.")
    emoji = obj.get("emoji")
    if emoji not in ("❤️","👍","😂","🔥","🌹"): return reply_error("Invalid reaction.")
    with database() as db:
        found = db.execute(
            "SELECT 1 FROM messages m WHERE id=? AND deleted=0 "
            "AND NOT EXISTS(SELECT 1 FROM blocks b WHERE "
            "(b.owner=? AND b.target=m.user_id) OR (b.target=? AND b.owner=m.user_id))",
            (mid, session["user_id"], session["user_id"])).fetchone()
        if not found: return reply_error("Message not available.",404)
        db.execute(
            "INSERT INTO reactions(message_id,user_id,emoji) VALUES(?,?,?) "
            "ON CONFLICT(message_id,user_id) DO UPDATE SET emoji=excluded.emoji",
            (mid,session["user_id"],emoji)
        )
    return jsonify(ok=True)


@app.post("/api/report")
@require_user
def report():
    if not check_csrf(): return csrf_error()
    obj = json_body()
    try: mid = int(obj.get("id"))
    except (ValueError, TypeError): return reply_error("Invalid message ID.")
    with database() as db:
        found = db.execute("SELECT 1 FROM messages WHERE id=? AND deleted=0",(mid,)).fetchone()
        if not found: return reply_error("Message not available.",404)
        db.execute(
            "INSERT OR IGNORE INTO reports(message_id,reporter_id,reason,created) VALUES(?,?,?,?)",
            (mid,session["user_id"],"Community report",int(time.time()))
        )
    return jsonify(ok=True)


@app.post("/api/block")
@require_user
def block():
    if not check_csrf(): return csrf_error()
    obj = json_body()
    try: target = int(obj.get("user_id"))
    except (ValueError, TypeError): return reply_error("Invalid user.")
    if target == session["user_id"]: return reply_error("You cannot block yourself.")
    with database() as db:
        found = db.execute("SELECT 1 FROM users WHERE id=?",(target,)).fetchone()
        if not found: return reply_error("User does not exist.",404)
        db.execute(
            "INSERT OR IGNORE INTO blocks(owner,target) VALUES(?,?)",
            (session["user_id"],target)
        )
    return jsonify(ok=True)


@app.post("/api/delete")
@require_user
def delete_message():
    if not check_csrf(): return csrf_error()
    obj = json_body()
    try: mid = int(obj.get("id"))
    except (ValueError, TypeError): return reply_error("Invalid message ID.")
    with database() as db:
        affected = db.execute(
            "UPDATE messages SET deleted=1 WHERE id=? AND user_id=?",
            (mid,session["user_id"])
        ).rowcount
    if not affected: return reply_error("You cannot delete this message.",403)
    return jsonify(ok=True)


if __name__ == "__main__":
    app.run(host="0.0.0.0", port=int(os.environ.get("PORT","10000")))


