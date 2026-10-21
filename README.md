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

### Vanta Chat — Roblox rooms and friend DMs

**Visible build: `PULSE STYLE 1.1`.** The existing in-window Chat tab now uses Roblox TextChatService for real same-server EN/AR rooms and friend DMs when the owned-experience server module is installed. There are no demo messages or raw draft echoes. Client-only loading reports setup/permission status.

The Pulse-inspired charcoal/orange shell, SaltyIcons, composer, replies and compact bubbles remain in supported custom-frontend mode. Platform-integrated mode embeds Roblox's native TextChannelWindow in the tab; Roblox renders its conversation and input. SaltyIcons IDs are retained, with same-asset thumbnail fallback, load diagnostics and visible text labels if an icon remains unavailable. This does not guarantee asset permissions in every experience.

**[Setup, exact limits and two-account test instructions](docs/roblox-chat-setup.md)**. Install `chat.lua` as ReplicatedStorage.VantaChatUI plus `roblox-chat/Server.server.lua`; use the supplied LocalScript host or mount the module into your existing VantaTest Chat tab. `chat.project.json` is the optional Rojo mapping.

Friend DMs require both friends in the same server and Roblox communication permission. Across-server Global remains Roblox's default tab within the same universe; it is not a guaranteed friend DM route or a custom-window target. The Render companion is separate and does not carry Roblox conversations. Reactions/hiding are local; successful send is not a recipient delivery receipt.

Automated syntax and engine-double logic tests are included. Actual Roblox visual rendering, filtering and two-account delivery must be validated in your published owned experience; they were not verified by those tests.

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

