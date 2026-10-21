# Vanta Chat companion web

A hosted independent chat website for adult participants, separate from Roblox's in-game TextChatService. **Do not inject this service as an unfiltered in-game chat.** Users can open the hosted website separately.

## Features
- Separate EN/AR rooms, RTL Arabic messages, replies, timestamps, emojis
- Registration with PBKDF2 password hashing and secure signed cookie sessions
- Postgres history, message rate limiting, report and block controls
- Public community messages (not end-to-end encrypted), two-second polling
- HTTP headers and CSRF checks to protect sessions

## Operational safety and limitations
- The service cannot certify users are adults or link usernames to Roblox identities.
- Reports are stored and **require administrator review**; reporting alone does not remove content.
- Blocking is per account.
- No content moderation/automated filtering is implemented. **Do not open this chat to the public until an effective moderation and abuse-response process is in place.**
- Render's free Postgres expires in 30 days; back up or upgrade before expiration.
- HTTPS is provided by Render; deploy requires SECRET_KEY and DATABASE_URL set only as service environment secrets.
- This is a companion website, not a private in-game Roblox chat nor globally connected Roblox clients.

## Launch
```
gunicorn -w 2 -b 0.0.0.0:$PORT server:app
```
Render root repository: VantaTest. Build: `pip install -r vanta-chat-web/requirements.txt`. Start: `cd vanta-chat-web && gunicorn -b 0.0.0.0:$PORT server:app`.
