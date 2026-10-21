import os, re, time, secrets, hashlib, hmac, json
from datetime import datetime, timezone
from functools import wraps
from flask import Flask, request, jsonify, session, send_from_directory
import psycopg
from psycopg.rows import dict_row

app = Flask(__name__, static_folder="public", static_url_path="")
app.secret_key = os.environ["SECRET_KEY"]
app.config.update(SESSION_COOKIE_SECURE=True, SESSION_COOKIE_HTTPONLY=True, SESSION_COOKIE_SAMESITE="Lax", MAX_CONTENT_LENGTH=16384, PERMANENT_SESSION_LIFETIME=86400 * 14)
DATABASE_URL = os.environ["DATABASE_URL"]
VALID_ROOMS = {"EN", "AR"}

def db():
    return psycopg.connect(DATABASE_URL, row_factory=dict_row)

def init_db():
    with db() as conn:
        with conn.cursor() as cur:
            cur.execute("""CREATE TABLE IF NOT EXISTS accounts(
                id BIGSERIAL PRIMARY KEY, username VARCHAR(24) NOT NULL UNIQUE,
                password_hash TEXT NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now())""")
            cur.execute("""CREATE TABLE IF NOT EXISTS messages(
                id BIGSERIAL PRIMARY KEY, user_id BIGINT NOT NULL REFERENCES accounts(id),
                room VARCHAR(2) NOT NULL CHECK(room IN ('EN','AR')),
                content VARCHAR(1000) NOT NULL, reply_id BIGINT REFERENCES messages(id),
                created_at TIMESTAMPTZ NOT NULL DEFAULT now(), deleted BOOLEAN NOT NULL DEFAULT false)""")
            cur.execute("""CREATE TABLE IF NOT EXISTS reports(
                id BIGSERIAL PRIMARY KEY, message_id BIGINT NOT NULL REFERENCES messages(id),
                reporter_id BIGINT NOT NULL REFERENCES accounts(id),
                reason VARCHAR(160) NOT NULL, created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
                UNIQUE(message_id, reporter_id))""")
            cur.execute("""CREATE TABLE IF NOT EXISTS blocks(
                owner_id BIGINT NOT NULL REFERENCES accounts(id),
                target_id BIGINT NOT NULL REFERENCES accounts(id),
                PRIMARY KEY(owner_id,target_id))""")
            cur.execute("CREATE INDEX IF NOT EXISTS message_room_idx ON messages(room,id DESC)")
init_db()

def passhash(password, salt=None):
    salt = salt or secrets.token_bytes(16)
    digest = hashlib.pbkdf2_hmac("sha256", password.encode(), salt, 260000)
    return salt.hex()+":"+digest.hex()

def validpass(password, stored):
    try:
        salt_hex,_ = stored.split(":")
        return hmac.compare_digest(passhash(password,bytes.fromhex(salt_hex)),stored)
    except (ValueError,TypeError): return False

def body():
    return request.get_json(silent=True) or {}

def err(message, code=400):
    return jsonify(error=message),code

def auth(fn):
    @wraps(fn)
    def wrapped(*args,**kwargs):
        if not isinstance(session.get("uid"),int): return err("Sign in first",401)
        return fn(*args,**kwargs)
    return wrapped

def csrf():
    expected=session.get("csrf","")
    return bool(expected) and hmac.compare_digest(str(request.headers.get("X-CSRF-Token","")),expected)

@app.after_request
def headers(resp):
    resp.headers["Cache-Control"]="no-store"
    resp.headers["X-Content-Type-Options"]="nosniff"
    resp.headers["Referrer-Policy"]="no-referrer"
    resp.headers["X-Frame-Options"]="DENY"
    resp.headers["Content-Security-Policy"]="default-src 'self'; script-src 'self'; style-src 'self'; img-src 'self' data: https://tr.rbxcdn.com; connect-src 'self'; object-src 'none'; frame-ancestors 'none'; base-uri 'none'"
    return resp

@app.get("/")
def home():
    return send_from_directory(app.static_folder,"index.html")

@app.get("/api/health")
def health():
    return jsonify(ok=True,service="vanta-chat",storage="postgres",chat="companion-web")

@app.get("/api/me")
def me():
    if not session.get("uid"):return jsonify(user=None)
    return jsonify(user={"id":session["uid"],"name":session.get("name")},csrf=session.get("csrf"))

@app.post("/api/account")
def account():
    payload=body()
    username=str(payload.get("username","")).strip()
    password=str(payload.get("password",""))
    mode=payload.get("mode")
    if not re.fullmatch(r"[A-Za-z0-9_]{3,24}",username) or len(password)<10 or len(password)>128:
        return err("Username 3-24 letters/numbers; password at least 10 characters")
    if mode not in ("login","register"):return err("Invalid mode")
    with db() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT id,username,password_hash FROM accounts WHERE lower(username)=lower(%s)",(username,))
            user=cur.fetchone()
            if mode=="register":
                if user:return err("Username is taken",409)
                cur.execute("INSERT INTO accounts(username,password_hash) VALUES(%s,%s) RETURNING id,username",(username,passhash(password)))
                user=cur.fetchone()
            elif not user or not validpass(password,user["password_hash"]):
                return err("Invalid username or password",401)
    session.clear()
    session.permanent=True
    session["uid"]=int(user["id"])
    session["name"]=user["username"]
    session["csrf"]=secrets.token_urlsafe(32)
    return jsonify(user={"id":session["uid"],"name":session["name"]},csrf=session["csrf"])

@app.post("/api/logout")
@auth
def logout():
    if not csrf():return err("Invalid session token",403)
    session.clear()
    return jsonify(ok=True)

@app.get("/api/messages")
@auth
def messages():
    room=request.args.get("room","EN")
    if room not in VALID_ROOMS:return err("Unknown room")
    try:after=max(0,int(request.args.get("after","0")))
    except ValueError:return err("Invalid cursor")
    with db() as conn:
        with conn.cursor() as cur:
            cur.execute("""SELECT m.id,m.user_id,u.username AS author,m.room,m.content,m.reply_id,m.created_at
              FROM messages m JOIN accounts u ON u.id=m.user_id
              WHERE m.room=%s AND m.id>%s AND NOT m.deleted
                AND m.user_id NOT IN (SELECT target_id FROM blocks WHERE owner_id=%s)
              ORDER BY m.id DESC LIMIT 80""",(room,after,session["uid"]))
            rows=cur.fetchall()
    for row in rows:row["created_at"]=row["created_at"].isoformat()
    return jsonify(messages=list(reversed(rows)))

@app.post("/api/messages")
@auth
def post_message():
    if not csrf():return err("Invalid session token",403)
    obj=body()
    room=obj.get("room","EN")
    content=obj.get("content","")
    if room not in VALID_ROOMS or not isinstance(content,str) or not 1<=len(content.strip())<=700:
        return err("Choose a room and send 1-700 characters")
    content=content.strip()
    if any(ord(c)<32 and c not in "\n\t" for c in content):return err("Invalid characters")
    reply_id=obj.get("reply_id")
    if reply_id is not None:
        try:reply_id=int(reply_id)
        except (ValueError,TypeError):return err("Invalid reply")
    with db() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT count(*) AS n FROM messages WHERE user_id=%s AND created_at>now()-interval '1 minute'",(session["uid"],))
            if cur.fetchone()["n"]>=12:return err("Slow down: 12 messages per minute",429)
            if reply_id is not None:
                cur.execute("SELECT 1 FROM messages WHERE id=%s AND room=%s AND NOT deleted",(reply_id,room))
                if not cur.fetchone():return err("Reply target is unavailable")
            cur.execute("INSERT INTO messages(user_id,room,content,reply_id) VALUES(%s,%s,%s,%s) RETURNING id",
                       (session["uid"],room,content,reply_id))
            mid=cur.fetchone()["id"]
    return jsonify(ok=True,id=mid),201

@app.post("/api/report")
@auth
def report():
    if not csrf():return err("Invalid session token",403)
    obj=body()
    try:mid=int(obj.get("id"))
    except (ValueError,TypeError):return err("Invalid message")
    reason=str(obj.get("reason","Abusive content"))[:160]
    with db() as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1 FROM messages WHERE id=%s",(mid,))
            if not cur.fetchone():return err("Message missing",404)
            cur.execute("INSERT INTO reports(message_id,reporter_id,reason) VALUES(%s,%s,%s) ON CONFLICT DO NOTHING",
                        (mid,session["uid"],reason))
    return jsonify(ok=True)

@app.post("/api/block")
@auth
def block():
    if not csrf():return err("Invalid session token",403)
    obj=body()
    try:target=int(obj.get("user_id"))
    except (ValueError,TypeError):return err("Invalid user")
    if target==session["uid"]:return err("Cannot block yourself")
    with db() as conn:
        with conn.cursor() as cur:
            cur.execute("INSERT INTO blocks(owner_id,target_id) SELECT %s,id FROM accounts WHERE id=%s ON CONFLICT DO NOTHING",(session["uid"],target))
    return jsonify(ok=True)

if __name__=="__main__":
    app.run(host="0.0.0.0",port=int(os.environ.get("PORT","10000")))
