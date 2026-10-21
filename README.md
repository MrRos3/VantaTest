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

### Vanta Chat — NIGHTLINE 2.0

The in-script Chat tab has a new black/crimson design, gradient accents, avatar friend cards, right-aligned outgoing bubbles, improved empty states, and mutually exclusive friends/emoji panels. Real SaltyIcons remain throughout.

It can now reuse the game's existing **RBXGeneral** and **RBXWhisper** channels without the Vanta server module where Roblox permits a custom frontend. Friends selects an existing private whisper or requests Roblox's built-in recipient-only whisper command. A failed private-chat request disables sending; it never switches your draft into public chat. The **Roblox UI / Restore UI** toggle switches the visible default chat interface and restores its original settings when this Chat module is destroyed. It does not replace Roblox filtering or permissions.

**Cross-game private messaging is not implemented.** A client script cannot create a supported private network with script users in unrelated games or servers. Installing this UI on both clients does not create such a route, prove that a friend uses the script, or bypass Roblox communication restrictions. The Render browser companion remains separate.

The optional owned-experience server still supplies custom Vanta EN/AR rooms and permission-gated DMs. Without those rooms, EN/AR changes typing preferences while both select the same existing server channel. Platform-integrated mode uses Roblox's native TextChannelWindow in the Vanta shell. Private whispers remain same-server.

See [setup, exact limits and testing](docs/roblox-chat-setup.md). Automated syntax/logic checks do not establish real Roblox rendering or delivery; validate in the actual experience with eligible accounts.

**VantaUI production remains unchanged.**

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


