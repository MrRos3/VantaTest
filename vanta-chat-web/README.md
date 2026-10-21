# Vanta Chat LAB companion (beta)

Independent **companion website**, not injected into Roblox or a replacement for the platform's TextChatService.

- Separate invite-only accounts, EN / AR public community rooms, emoji reactions, replies, block, report and self-delete.
- Real SaltyIcons SVG assets bundled with the project; no generated/handmade icons.
- Basic server-side filtering for links/contact details, some severe abuse patterns, user rate limits, invitation requirement, report auto-hide after two unique reports, and session/CSRF protections.
- Not end-to-end encrypted, not private 1:1 messaging, not for sharing personal contact information.
- **Beta moderation is limited** and automatic word rules are not a substitute for human review. Reports are recorded in the local database; two distinct reports hide a message.
- Database is SQLite under `/tmp` on Render **free tier, which is ephemeral**. Accounts, messages, reports and blocks are lost when the instance's filesystem resets. Do not treat this as permanent storage. The previously provisioned PostgreSQL database has not been connected because connection credentials are not available via the current integration.
- You can sign up with a private invite code only. Set SECRET_KEY and INVITE_CODE on the Render service (never commit either to GitHub).
- The service is hosted externally and should be opened as a standalone web chat; it is not an in-game relay.

## Deployment

Render build: `pip install -r vanta-chat-web/requirements.txt`
Render start: `cd vanta-chat-web && gunicorn --workers 1 --bind 0.0.0.0:$PORT server:app`

## Icons

Copyright and licensing for SaltyIcons (a collection of Lucide-derived artwork) are documented in [MrRos3/SaltyIcons](https://github.com/MrRos3/SaltyIcons), including ISC/MIT notices.
