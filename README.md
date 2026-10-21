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
| Chat | Native in-window Telegram-inspired Chat LAB demo: EN/AR tabs, message bubbles, replies, emoji picker, reactions, SaltyIcons, timestamps and local send |
| Buttons | Basic buttons, notification variants, locking, paragraph action buttons |
| Toggles | Switches, checkbox variant, rebindable hotkey |
| Sliders | Whole-number and fractional sliders, progress bars, volume adjustment |
| Dropdowns | Single-select, multi-select, searchable, and dynamically refreshed lists |
| Inputs | Single-line and multiline entry, color pickers, transparency |
| Themes | All 5 built-in themes, sound switch and stacked notifications |
| Layouts | Sections, paragraphs, spacers, dividers, groups, HStack and VStack |
| Advanced | Image, interactive 3D viewport, code block, component diagnostics |

### Vanta Chat LAB (in-script preview)

The **Chat** tab runs an interactive Roblox GUI directly **inside VantaTest**. It includes English and Arabic room toggles (with right-aligned Arabic), timestamped sender/recipient bubbles, player avatar, real published Roblox asset IDs from [MrRos3/SaltyIcons](https://github.com/MrRos3/SaltyIcons), emoji tray at bottom-left, message selection, Reply, Copy, React ❤️, Hide locally, and deletion of your locally composed demo messages. The latest Pulse-inspired update adds a **150-entry bounded message history**, a **scroll-to-latest** action, and a **local @mention suggestion panel** using usernames from your current server. Mentions are only text insertion, not delivery to users.

It is a **local UI preview**, not a networked chat. Sample messages are labeled `PREVIEW`; messages you type are labeled `LOCAL` and appear only on your current client. They are not delivered to another user, game, server, or to the hosted companion. The message history disappears when the local UI is destroyed. Online counts are intentionally absent. This also does not bypass Roblox chat permissions.

An independent **web companion** from earlier experiments is available at [Vanta Chat](https://vanta-chat-lab.onrender.com), but it is not linked to this in-script GUI. It supports invite-only EN/AR chat in browsers, and its free-tier database is currently ephemeral. The source remains in [vanta-chat-web](vanta-chat-web). Integrating unrestricted web messaging into arbitrary Roblox executors would bypass Roblox's in-game communication protections, so the in-script preview is deliberately disconnected.

**No production VantaUI changes** were made.

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
