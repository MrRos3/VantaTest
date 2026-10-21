# Pulse Chat focused UI dump findings

Source: user's `PulseChat_FOCUSED_DUMP.json`, captured from executed Pulse Hub on 2026-10-21. Only GUI hierarchy and safe properties were collected. No message bodies, textbox contents, backend endpoints, Lua callbacks, message transport, credentials or remote requests were collected.

## Observed facts

- `format`: `PulseChatFocusedUI-1`.
- `chatPageActive`: `false`. The snapshot includes an inactive/parked Chat canvas, so the GUI layout is observable but live Chat interaction was not recorded.
- `Chat > Pages > PulseChat`: direct children `Board`, `ReplyBar`, `InputShadow`, `Input`, `AttachBar`, `Mentions`, `PickAway`, `LangHint`.
- `Board` contains `Head` (58-pixel nominal height), a scrolling `List`, and additional visual controls.
- `Input` is a bottom-anchored 50-pixel composer with a `TextBox` and button controls.
- `ReplyBar` and `AttachBar` were present but **hidden and collapsed** in this snapshot.
- `Mentions` is a hidden, automatically sizing panel.
- The captured `List` uses a `UIListLayout` and has message-row `Msg` items nested with `Col` and `Bubble`; the extracted subset contains **150 each** of `Msg`, `Col` and `Bubble`. Some extracted bubbles include `Time`, `UIGradient`, `UIStroke`, `Reactions`.
- The focused extractor reported **3,626** Chat UI descendants, retaining the first **1,700** in its `elements` array, not the full page.

## Adaptation to VantaTest

- Preserve the native in-script chat; never substitute a website link for the UI.
- Retain the user-provided EN/AR room preference; Pulse's exact language data may differ.
- Use **published SaltyIcons Roblox asset IDs**, not handmade UI glyphs.
- Port three verified UI patterns: 150-entry local history cap, jump-to-latest button, interactive local @mention suggestion panel.
- Keep existing reply bar, rounded bubble styling, avatar, timestamp, reactions and emoji composer.
- **Do not invent a network protocol** from GUI data. The user wants two-way worldwide messaging, but this dump provides no evidence of Pulse's transport, authentication, moderation or Roblox permissions. VantaTest remains explicitly marked **LOCAL DEMO**. No messages travel to other users.

## Related files

- `chat.lua` in VantaTest is the in-game preview.
- `vanta-chat-web/` is an independent companion prototype, **not** connected to the in-script UI.
