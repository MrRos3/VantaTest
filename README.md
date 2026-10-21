# VantaTest 🧪

An independent test copy of [VantaUI](https://github.com/MrRos3/VantaUI). Use this repository to experiment with components, themes, motion and styling without changing production VantaUI.

## Run the full UI laboratory

Execute in your Roblox client:

```lua
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaTest/main/example.lua?v=" .. os.time()
))()
```

The LAB showcase creates a complete window. Loading the library by itself does **not** create a window.

## What's available?

| Tab | Interactive demos |
| --- | --- |
| Home | Runtime information, button counter, notification preview and Chat shortcut |
| Chat | Telegram-inspired Vanta chat: native vector icons, EN/AR rooms, emoji tray, filtered script-only same-server messages, replies, reactions, timestamps, copy and hide |
| Buttons | Basic buttons, notification variants, locking, paragraph action buttons |
| Toggles | Switches, checkbox variant, rebindable hotkey |
| Sliders | Whole-number and fractional sliders, progress bars, volume adjustment |
| Dropdowns | Single-select, multi-select, searchable, and dynamically refreshed lists |
| Inputs | Single-line and multiline entry, color pickers, transparency |
| Themes | All 5 built-in themes, sound switch and stacked notifications |
| Layouts | Sections, paragraphs, spacers, dividers, groups, HStack and VStack |
| Advanced | Image, interactive 3D viewport, code block, component diagnostics |

### Vanta Chat LAB (experimental)

The **Chat** tab loads `chat.lua` and features Telegram-inspired rounded chat bubbles, timestamps, player avatars, reply previews, per-message actions (Reply, Copy, React ❤️ / 👍, Hide locally), and a bottom-left emoji picker. The chat, send, reply, close and emoji icons are rendered with Roblox UI shapes rather than unreliable Unicode icon glyphs.

**EN and AR (Arabic)** are UI-filtered room selections. Arabic messages align to the right. Sending attaches compact `VCHAT2|` metadata through `TextChannel:SendAsync()`, and only messages bearing this metadata appear in the Vanta Chat feed. Normal Roblox game chat is not copied into the chat tab. All displayed received messages come from Roblox's already-filtered `TextChatService.MessageReceived`. Players who run the chat in the **same Roblox server** can interact if RBXGeneral and chat permissions are enabled. **Messages are delivered through the game's public RBXGeneral channel, so players using the game's normal chat may see them too.** The Vanta Chat feed itself displays only script-tagged messages; it is not a private transport.

**Important:** This is **not global across different servers or Roblox games**. That requires an external hosted relay with authentication, text moderation/filtering, anti-spam and appropriate Roblox safety protections. None is deployed in this repository. The room counter is the number of players present in the current server, not the number using the script; EN/AR room membership is not a global presence measure.

The example bubbles are marked `PREVIEW` and give way to live script-to-script messages. Replies carry Roblox message IDs using chat metadata, so quoted previews appear when their original messages are still available locally. Emoji reactions and Hide locally are local presentation actions; they do **not** edit, unsend or propagate reactions on Roblox chat messages. Custom backgrounds and core VantaUI functionality remain unchanged.

All **18 element types currently registered** in the library are represented: Paragraph, Button, Toggle, Slider, ProgressBar, Keybind, Input, Dropdown, Code, Colorpicker, Section, Divider, Space, Image, Group, HStack, VStack, Viewport.

The Video element exists in the source tree but is deliberately **not registered** in the shipped library, so it is not included as an available control.

The lab shows component-construction failures in the executor console, and also includes a diagnostics button. Browser-previewing the source is not equivalent to a live Roblox client test.

## Import the library without a showcase window

```lua
local VantaTest = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaTest/main/main.lua?v=" .. os.time()
))()
-- Then call VantaTest:CreateWindow({ Title = "Your GUI" }) and add tabs.
```

The public loader and branding image URLs now use **MrRos3/VantaTest**. All changes here stay independent of production VantaUI.

## Style baseline

- Salty Special, AMOLED-first black and red
- Solid OLED-black lower-right notifications
- Full-height burgundy timeout overlay matching the Close Window button (#251016)
- **High-definition Crimson01 wallpaper** uses the original 1671×941 anime artwork, not an enlarged GIF frame
  - The character, hair and flowers remain completely stable and sharp
  - Native red petals and embers drift smoothly above the wallpaper without frame swaps
  - No 224×126 atlas upscaling, cropped duplicate faces or background shaking
  - The official VantaTest loader enables the animation automatically while respecting custom backgrounds
  - Cached full-resolution artwork is downloaded through existing custom-image support
- Rounded components with the compact three-dot window topbar
- Optional themes: Smoked, Dark, AMOLED and Violet
- v0.3.8 runtime; changes to `src/` trigger the GitHub build workflow for `dist/main.lua`

## Build

```bash
npm install
npm run build
```

Licensing information: [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES).
