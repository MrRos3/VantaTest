# VantaTest Roblox chat — setup and limits

## What changed

`chat.lua` is shared by the existing `example.lua` Chat tab and the Studio installer. Pulse-inspired warm charcoal/orange styling remains. Child controls now inherit increasing ZIndex; the composer stays within a height that follows its tab; timestamps have reserved space; narrow headers hide avatar decoration; reading older messages no longer jumps to the latest on receipt. Replies carry only a Roblox message ID in metadata, and quote only messages already received through Roblox. Reactions and hide/delete are explicitly local conveniences, not shared reactions or remote deletion.

There are no seeded messages or local raw-message echoes. EN and AR select separate **public rooms in this server**, not private language groups or worldwide networks. The Friends menu lists friends currently in this server. Opening a DM sends only a numeric UserId to the server. The server checks friendship, `CanUsersDirectChatAsync`, and channel admission, sets `SetDirectChatRequester`, and admits only the two participants. Message bodies travel exclusively through `TextChannel:SendAsync` and Roblox's receive pipeline, or through Roblox's native window. Roblox continues enforcing filtering, blocking and communication restrictions. Never use a raw-text RemoteEvent, HTTP relay, MessagingService relay or `DisplaySystemMessage` to substitute for this path.

The status indicator describes channel availability in **this server**. Successful SendAsync means accepted by Roblox, not a delivery or read receipt. A room can have no other eligible recipients. There is no offline mailbox, global friend presence, persistent transcript or guaranteed recipient delivery.

## Install in an experience you control

1. Open your owned experience in Studio. Keep TextChatService and its default channels and commands enabled. Keep Roblox's default chat/safety interface available for reporting, blocking and muting.
2. Copy `chat.lua` into a **ModuleScript named VantaChatUI in ReplicatedStorage**. Copy `roblox-chat/Server.server.lua` into a **Script in ServerScriptService**. Install exactly one copy of the server script.
3. Enable the documented **Chat & Voice Groups APIs** setting under Experience Settings → Communication if required for direct-chat permission APIs on your rollout, and accept the Roblox terms. API failure denies the DM; the module never relaxes that requirement.
4. Choose your chat mode explicitly:
   - Existing custom frontend mode: Studio `PlatformIntegratedChat` Disabled; leave `PLATFORM_INTEGRATED_CHAT = false` in the server script. The Pulse feed/composer sends through SendAsync and displays only successful received TextChatMessages.
   - Platform-integrated mode: set Studio `PlatformIntegratedChat` Enabled and set `PLATFORM_INTEGRATED_CHAT = true` in the server script. Roblox's `TextChannelWindow` provides the real message area and input **inside the Vanta Chat tab**. The surrounding Pulse header and friend/room selectors remain, but Roblox controls the conversation styling and tools. The custom bubble/composer area is hidden. Do not try to read or reconstruct hidden message content.
   Roblox's rollout property may be script-protected; the matching replicated attribute is the explicit fallback configuration. If native window creation fails, the UI reports it and does not enable a custom replacement sender. Test the chosen mode in the published experience.
5. For a Studio host, copy `roblox-chat/Client.client.lua` into a **LocalScript in StarterPlayerScripts**. This is a minimal host for the same VantaTest chat module, not a browser product. If your experience already has a VantaTest window, omit that host and mount the module in its existing tab:

   ```lua
   local Chat = require(game:GetService("ReplicatedStorage"):WaitForChild("VantaChatUI"))
   Chat.Mount(ChatTab) -- existing VantaTest tab with UIElements.ContainerFrame
   ```

   Rojo users can sync `chat.project.json` instead; it maps those same three files. The legacy `default.project.json` is not the chat installer.
6. Publish to your owned experience and test with two eligible real accounts that are friends, in the **same server**. Studio local players alone cannot prove real-account friendship, communication eligibility, filtering or delivery. No Roblox experience access/deployment was supplied during this implementation; installation and real-account validation remain owner steps.

The existing public `example.lua` loader is retained for its existing environment. It is not the Studio install path and cannot install trusted server code in someone else's experience. Loading the client alone shows setup/permission status, not a working global chat.

## SaltyIcons loading

The icon IDs in `chat.lua` match MrRos3/SaltyIcons `roblox/upload-manifest.csv`, including Send `104783825572790`, MessagesSquare `110915451876713`, and ThumbsUp `75110458023624`. They were not replaced with handmade icons or a different pack. The existing general Vanta library icon provider is separate and was not rewritten.

On 2026-10-21, unauthenticated asset delivery for the send ID required authentication. Roblox's thumbnail endpoint identified its image as a **Decal**, with state Completed; the chat mark thumbnail returned Pending. Those observations do not prove that either texture will load in a particular experience. Image controls now preload the existing asset ID and try `rbxthumb://type=Asset` for that same published SaltyIcons asset if needed, with a delayed fallback for slow preloads. Text action labels appear if both paths fail, and loaded images replace the labels when available. This is a visible error fallback, not a fabricated icon.

If a particular asset remains inaccessible/moderated in your experience, the owner must fix its asset permissions or upload the **original white transparent 96px PNG from SaltyIcons**, grant the experience access where required, and update the corresponding ICON entry with the usable **image/texture ID**. Neither an ID being listed in GitHub nor a successful preload in an engine double proves live rendering. Check Roblox Output and ContentProvider warnings.

## Across servers

Roblox documents native Global chat across servers in the **same universe**, grouping users by age/language/occupancy (about 200 per channel). It does not promise that a specific friend will be in the same global group, and private servers disable Global. Enable/inspect it through Creator Dashboard → Audience → Communication Settings. Use Roblox's default Global tab: the documented platform-integrated API **does not allow Global as a custom TextChannelWindow target**. Accordingly, this implementation does not label its EN/AR rooms as cross-server and does not build a relay to simulate cross-server DMs. Arbitrary worldwide friend DMs across unrelated experiences are outside the supported architecture here.

## Render investigation

Confirmed service: `vanta-chat-lab`, service `srv-dbcdn7mq1p3s73d3qtmg`, Frankfurt, `https://vanta-chat-lab.onrender.com`, GitHub MrRos3/VantaTest main with auto-deploy. Build: `pip install -r vanta-chat-web/requirements.txt`; start: `cd vanta-chat-web && gunicorn --workers 1 --bind 0.0.0.0:$PORT server:app`. The live `/api/health` responded successfully before this change.

The code is an independent Flask browser companion with its own password accounts, invitation gate, CSRF tokens, SQLite, polling, reports/blocks and a small regex denylist. These are not Roblox identities, communication permissions or Roblox chat filtering. Its SQLite data on the configured free ephemeral filesystem can disappear on restart/deploy. The Roblox UI does not call this service. Health metadata now explicitly declares `roblox_transport: false` and `roblox_filtering: false`. Existing web functionality remains separate. Do not put Roblox draft messages, account cookies, or personal conversation logs into it.

## Verification and acceptance checklist

Automated checks: Lua 5.1 syntax for chat/example/installer; engine-double logic tests for server absence, sending without local echo, filtered receive/deduplication, denied send preserving drafts, DM permission denial/rate limit/nonfriends/missing targets, failed admission cleanup, player departure cleanup and the native-window branch. These tests do **not** run Roblox filtering, render the UI, or simulate a real network. The separate Flask test exercises two-account send/receive/reply, EN/AR isolation, CSRF, blocking, reporting and deletion. Live health proves only companion reachability.

Run locally/CI:

```sh
python -m pip install lupa==2.8 -r vanta-chat-web/requirements.txt
python -m unittest discover -s tests -p test_chat.py -v
python -m unittest discover -s vanta-chat-web/tests -v
```

Owner acceptance test:

1. In a published server, Alice sends an EN message and Bob sees the **Roblox-filtered** result; Bob replies and Alice sees it. Test Arabic and emoji in AR and room isolation.
2. Both open Friends and select one another. Exchange DM messages both directions; a third player must not receive them. Re-open the same DM from the other participant. Test unfriended, blocked, ineligible and departed recipients; none should silently become public chat.
3. Test Roblox communication-disabled/read-only accounts without changing their settings to circumvent restrictions. Confirm denial/failure status and preserved drafts. Use Roblox's reporting/blocking/muting tools.
4. Check real SaltyIcons, EN/AR header, composer, text/timestamps and replies at desktop, 390px and narrow mobile widths. Resize, scroll upward while messages arrive, jump latest, switch tabs, and remount/destroy without duplicate reception. In native mode test the native window's input and safety tools instead of custom bubbles.
5. Test cross-server using the **default Roblox Global tab** in two public servers of this universe. Do not treat lack of pairing as a bug in Vanta DMs or build a relay around it.

## Official references checked on 2026-10-21

- [TextChatService](https://create.roblox.com/docs/reference/engine/classes/TextChatService)
- [TextChannel](https://create.roblox.com/docs/reference/engine/classes/TextChannel)
- [Chat system guidelines](https://create.roblox.com/docs/chat/guidelines)
- [Cross-server chat](https://create.roblox.com/docs/chat/cross-server-chat)
- [Platform-integrated chat](https://create.roblox.com/docs/chat/platform-integrated-chat) (documentation currently says it becomes required in May 2027)
- [SaltyIcons upload manifest](https://github.com/MrRos3/SaltyIcons/blob/main/roblox/upload-manifest.csv)

