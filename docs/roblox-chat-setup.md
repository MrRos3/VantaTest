# Vanta Chat 3.0 — supported implementation and setup

This replaces the public-chat/whisper fallback in NIGHTLINE 2.0. Vanta Chat has a dedicated GUI and a separate transport. No Vanta message is sent to RBXGeneral, a default whisper, Render, a browser, or an external messenger.

## Working source and scope

| Requirement | Implemented behavior |
| --- | --- |
| Dedicated participants | Players explicitly admitted to Vanta by its owned-experience server; never all server players automatically |
| EN / AR | Separate VantaEN and VantaAR TextChannels |
| Real send / receive | Roblox SendAsync and successful filtered MessageReceived events; no draft echo or seed messages |
| Identity | Roblox-authenticated Player.UserId, platform display name / username and avatar |
| Time / replies | Roblox message timestamp when available; message-ID reply metadata and recipient-filtered local quote |
| Shared reactions | Server-authorized fixed emoji reactions, versioned updates to eligible recipients; UI toolbar toggles thumbs-up |
| History | Last 150 successfully received messages in this mounted client; retained while switching rooms |
| Private friend chat | Both friends must join Vanta in this server and pass Roblox friendship/direct-chat permission checks |
| Icons | Original 96px transparent SaltyIcons PNGs, pinned source, file hashes and licenses; optional local-image loader plus published-ID fallback |
| Pulse styling | Warm charcoal/orange surfaces, compact left-aligned bubbles, colored names, avatars, timestamp space, EN/AR pill, docked composer and compact action rail |
| Presence / status | Only server-confirmed opted-in members in the avatar/friend UI. No global online count or recipient-delivery receipt |

The exact cross-game blocker: Roblox requires in-game conversations to go through TextChannel for both sending and delivery, including filtering, privacy and reporting. A public Render HTTP relay with independent accounts cannot substitute for that delivery path. Current native cross-server Global chat is same-universe, grouped by Roblox, and not a target for a custom TextChannelWindow. Thus an arbitrary cross-experience Vanta network entirely inside this GUI is not implemented. This is based on the documented APIs, not a claim that Pulse's private implementation is known. Its GUI dump contains no protocol/authentication evidence.

There is no offline mailbox, persistence across reconnects, replay of pre-join chat, or cross-server reaction service. Message bodies are not stored on the Vanta server or exported to Render. The server retains only bounded message handles / participant authorization / fixed reaction data. Hiding/deleting a bubble is local, not remote deletion. A successful SendAsync is acceptance by Roblox, not proof that a recipient saw the message. Session-local history cannot prove another participant received it.

## Install in an experience you control

1. In Studio, keep TextChatService enabled with its default TextChannels folder. Install exactly one copy of `roblox-chat/Server.server.lua` in ServerScriptService.
2. Put `chat.lua` in ReplicatedStorage as ModuleScript **VantaChatUI** and `roblox-chat/Transport.lua` there as **VantaChatTransport**. Put `roblox-chat/Client.client.lua` in StarterPlayerScripts for the supplied host. Alternatively mount into your existing VantaTest Chat tab:

   ```lua
   local storage = game:GetService("ReplicatedStorage")
   local Chat = require(storage:WaitForChild("VantaChatUI"))
   local Transport = require(storage:WaitForChild("VantaChatTransport"))
   Chat.Mount(ChatTab, { Transport = Transport.new() })
   ```

   `chat.project.json` maps these four files for Rojo. The existing `example.lua` loads the same GUI/transport plus the SaltyIcons resolver; it does not install trusted server code into someone else's game.
3. Configure **Vanta-only display** in Studio. Prefer ChatWindowConfiguration.TextChannelDisplayMode = DefaultTextChannels where the property is available. This keeps custom Vanta channels out of the default chat window. On engine versions without this setting, configure both ChatWindowConfiguration.Enabled and ChatInputBarConfiguration.Enabled = false for your owned experience's custom frontend. This changes interface visibility, not account chat permission. Admission fails closed until one of these display configurations is in place. Keep Roblox's main-menu reporting/blocking/muting tools available.
4. Choose the engine mode explicitly. With PlatformIntegratedChat Disabled, leave `PLATFORM_INTEGRATED_CHAT = false` in Server.server.lua: Pulse-style bubbles/composer use SendAsync/MessageReceived. With PlatformIntegratedChat Enabled in Studio, set that flag to true: the Vanta shell hosts a native TextChannelWindow for the selected Vanta channel, and Roblox owns conversation/input rendering. The custom actions/replies/reactions are not available in that native window; Roblox's native tools apply. Do not try to reconstruct hidden message text. Some rollouts protect the property from scripts, so the flag is the owner's explicit matching configuration.
5. Enable Chat & Voice Groups APIs / required terms in Studio Communication settings where required for permission APIs. A permission/API failure denies admission or the private chat. Never alter Roblox account restrictions to circumvent them.
6. Publish to your owned experience. The tab attempts opt-in admission when mounted. Join/Leave controls that membership. Leaving removes its TextSources and private channels. A session lease prevents an old window's delayed cleanup from removing a newly mounted session. Membership is an authenticated opt-in, not cryptographic proof of which client code someone is running; a client-visible shared secret would not establish that proof.

No owned experience ID, Studio access or eligible real test accounts were supplied for deployment. The modules are integrated and tested as source; installing them in a published Roblox experience and validating live accounts remains an owner step.

## Icons

The real artwork is included in `assets/salty-chat/` with original source links, SHA-256 hashes and licenses. It is copied from MrRos3/SaltyIcons commit b7db826820a3456fe953f0097b1924de9e04ff97, not redrawn. All 13 PNGs, including send, were decoded and checked as non-empty 96x96 RGBA images and visually inspected as a contact sheet.

`roblox-chat/IconAssets.lua` uses the existing GUI environment's optional local-image capability to load those exact PNG masks. It caches fixed filenames, validates the PNG signature, rejects unknown icon keys, and sends only static asset requests. There are no chat messages, account tokens or identities in those requests. The example passes this resolver into the GUI. If unavailable, Roblox published image IDs / same-asset thumbnails remain the fallback, with a visible label and warning on failure; a missing image is never called loaded.

Normal Roblox LocalScripts do not provide that optional filesystem/local-image API. For Studio-native deployment, upload the supplied original PNGs under the experience owner, grant required asset access and replace the corresponding ICON entries in chat.lua with usable image/texture IDs. No upload credentials were available, so native asset permission checks still require owner validation. The resolver fixes the script environment's dependency on failing Decal IDs; source tests do not establish rendering on every Roblox client.

## Security and delivery design

- Roblox authenticates Player identities passed to the membership, DM and reaction remotes. Clients do not submit author usernames or Roblox credentials.
- Message text goes only through TextChannel:SendAsync and the Roblox filtered receive pipeline. Membership and reaction remotes accept only control actions, numeric target IDs, generated message handles and fixed emoji enums; they never carry free-form conversations.
- The server gates TextSources and delivery on membership. DM admission also checks friendship, CanUserChatAsync, CanUsersDirectChatAsync, ordinary pair permissions and SetDirectChatRequester.
- Reaction changes require a known message, matching channel, an eligible viewer, membership and current communication permissions. Only fixed counts/emoji and a message handle are broadcast to eligible recipients. The callback's viewer record is an authorization envelope, not a delivery/read receipt; clients display an update only for a message they actually received.
- Rate limits: join/DM admission requests are spaced by 2 seconds, reactions by 0.5 seconds, and room messages by 4 new handles per 8 seconds / 10 per minute, in addition to Roblox's own limits. Message authorization/reaction records are bounded to 300 handles.
- Roblox handles abuse reporting, filtering, muting, blocking and account restrictions for TextChannel messages. No custom moderation dashboard, universal account ban service or anti-exploit identity attestation is claimed.

## Render backend investigation

Live service inspected: **vanta-chat-lab**, srv-dbcdn7mq1p3s73d3qtmg, Frankfurt, free plan, auto-deploy from MrRos3/VantaTest main. Build: `pip install -r vanta-chat-web/requirements.txt`; start: `cd vanta-chat-web && gunicorn --workers 1 --bind 0.0.0.0:$PORT server:app`. `/api/health` was reachable and explicitly returned roblox_transport=false, roblox_filtering=false.

This Flask service already implements an independent browser-account chat with password hashing, invitation gate, secure/HttpOnly/SameSite session cookies, CSRF checks, SQLite history, polling, replies, reactions, blocking and reporting. These are not verified Roblox identities or Roblox communication permissions; the small regex denylist is not Roblox filtering. Its free ephemeral storage is not durable across restarts/deploys. No backend secrets were read or exposed, and no real-user conversations were used in tests.

The audit fixed one-way block handling, quote leakage from blocked authors, unauthorized reactions to blocked messages, malformed JSON/room payload errors, and unclosed database connections. These improve the existing independent companion. They do not connect it to the in-game GUI. An external relay would still lack the required TextChannel delivery/permission integration, even with stronger authentication or moderation.

## Tests and exact evidence limits

Run:

```sh
python -m pip install lupa==2.8 -r vanta-chat-web/requirements.txt -r vanta-chat-web/tests/requirements.txt
python -m unittest discover -s tests -p test_chat.py -v
python -m unittest discover -s vanta-chat-web/tests -v
```

Lua tests compile the GUI/example/installer/transport/icon modules with Lua 5.1. Engine doubles exercise opt-in admission, no public fallback, permission denial, same-server friend gates, rollback, session leases, rate limits, room isolation, local history, duplicate receive suppression, no raw draft echo, failed-send draft preservation, shared reaction authorization/toggling, popup exclusivity, membership-only presence and original-PNG loading/caching.

Separate tests start a real loopback HTTPS server and use independent cookie jars for Alice/Bob (plus a third client for quoted-reply authorization). They exchange actual HTTP message requests in both directions and check history, Arabic room isolation, replies, reactions, CSRF, blocking, malformed payloads and foreign deletion. Certificate verification is disabled only for this test's self-signed loopback certificate. No browser is opened.

Those HTTP tests prove the independent companion works, not that Roblox is connected. Engine doubles do not run Roblox's real filtering, permissions, rendering, transport or Studio. Do not describe either as live two-player Roblox validation.

Owner acceptance test:

1. Install in a published owned experience with two eligible real accounts in one server. Mount Vanta on Alice only. Bob must not receive its Vanta messages or appear in its opted-in UI. Mount on Bob, join EN and exchange messages both directions.
2. Switch to AR and exchange Arabic text; ensure EN messages remain separate. Verify usernames/avatars, timestamps, filtered replies, thumbs-up toggling on both clients and 150-item session history while switching rooms.
3. Leave on Bob and confirm access is removed. Test denied/blocked accounts, invalid DM targets, a departing friend, spam, failed sends, and rapid destroy/remount. No failure may send the message to public chat or assert recipient delivery.
4. Confirm Vanta messages appear only inside its tab under the selected display mode. In native engine mode, test the native window and Roblox safety tools instead of the custom renderer.
5. Verify all SaltyIcons, especially send, on the actual client; test narrow/mobile sizes, scrolling, emoji/friend/mention overlap, action rails and local hide. Validate image permissions for native Studio use.

## Official sources checked 2026-10-21

- [Chat system guidelines](https://create.roblox.com/docs/chat/guidelines)
- [TextChatService](https://create.roblox.com/docs/reference/engine/classes/TextChatService)
- [TextChannel](https://create.roblox.com/docs/reference/engine/classes/TextChannel)
- [Platform-integrated chat](https://create.roblox.com/docs/chat/platform-integrated-chat)
- [Cross-server chat](https://create.roblox.com/docs/chat/cross-server-chat)
- [SaltyIcons source manifest](https://github.com/MrRos3/SaltyIcons/blob/b7db826820a3456fe953f0097b1924de9e04ff97/roblox/upload-manifest.csv)

