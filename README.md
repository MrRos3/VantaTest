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

### Vanta Chat LAB (native Pulse-style UI, local preview)

**Visible build:** `PULSE STYLE 1.0`. The Chat page was visually rebuilt from the user-supplied Pulse Hub screenshot. Its compact warm-charcoal message bubbles are left-aligned and content-width (not full-width burgundy cards), with colored usernames, small avatar circles, bottom-right timestamps, an orange chat mark, rounded EN/AR filters, and a bright orange send button. The compact four-icon message toolbar replaces the previous oversized popup.

The layout includes a docked composer with an emoji tray, a read-only attachment hint, an @mention suggestion popup populated from names in the **current Roblox server only**, a reply strip, a scroll-to-latest button, and hide/delete for locally stored messages. The top headshot strip also shows only current-server players; it is **not** a global connected-user list. Icons use published [SaltyIcons](https://github.com/MrRos3/SaltyIcons) Roblox asset IDs. The 150-message history bound is for UI performance and is **not** inferred to be Pulse's own storage limit.

This is **only a local UI prototype**: demo samples are labeled `DEMO`, your own messages are labeled `LOCAL`, and no real-time chat backend is connected. Messages are not sent to other players, servers, experiences, or to the independent web companion in [vanta-chat-web](vanta-chat-web). This prototype intentionally makes no attempts to bypass Roblox's chat filtering or communication settings. UI behavior has repository syntax checks, but visual rendering must still be inspected in Roblox.

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
