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
| Home | Runtime information, button counter and notification preview |
| Nameplate | Premium overhead nameplate above your character with live theme, tag, size, height, distance and visibility controls |
| Buttons | Basic buttons, notification variants, locking, paragraph action buttons |
| Toggles | Switches, checkbox variant, rebindable hotkey |
| Sliders | Whole-number and fractional sliders, progress bars, volume adjustment |
| Dropdowns | Single-select, multi-select, searchable, and dynamically refreshed lists |
| Inputs | Single-line and multiline entry, color pickers, transparency |
| Themes | All 5 built-in themes, sound switch and stacked notifications |
| Layouts | Sections, paragraphs, spacers, dividers, groups, HStack and VStack |
| Advanced | Image, interactive 3D viewport, code block, component diagnostics |

### Vanta Owl: your own overhead nameplate 🦉

The **Nameplate** tab now renders **[owl] [your DisplayName] [owl]** above **your character only**. No other players get a Vanta plate, even if they join or respawn. The script also shuts down the earlier all-player `__VANTA_OWL_CLEANUP` executor script when available and clears stale `VantaOwlNameplate` Billboards from other heads on launch. It **never** deletes Roblox's or other games' unrelated nameplates.

**Your own owl artwork is included in the GitHub repo:** [assets/owl/vanta_owl_96.png](assets/owl/vanta_owl_96.png), a transparent 96px optimized copy of the provided black-and-white owl. No unknown Roblox asset ID or `PASTE_ID_HERE` remains. The Lua module downloads the PNG, writes `VantaTest_Owl_96.png` locally and registers it with executor `getcustomasset` or `getsynasset`. If those executor file/image APIs are unavailable, **owl emojis are displayed as fallbacks**, rather than blank icon slots. Because Roblox doesn't accept raw HTTP image URLs as `ImageLabel.Image`, showing the exact PNG in an ordinary Studio LocalScript would instead require uploading it to Roblox and putting the resulting public ID in `CONFIG.OWL_IMAGE`.

The plate has a subtle dark-crimson glow and a 1px animated border, auto sizes to the width of your current display name (minimum 200px), shows exactly two unmirrored 30px owls and a centered **14px Michroma** name, and fades/shrinks after 40 studs. There is **no avatar, VANTA tag, rank, subtitle, status dot, or health bar**.

**Name animation:** five-stop crimson gradient `#B3112F → #FF2A4D → #FF8A9E → #FF2A4D → #B3112F` over white glyphs; a **2.5s thin masked highlight shine** with a **1.5s pause** between passes (the crimson base never resets or flashes); 1px dark `#1A0008` name stroke pulsing between **0.2–0.6 transparency every 1.2s**; and a subtle **0.12s horizontal 2px white-flash glitch every randomly chosen 6–10s**. Michroma has natural tracking, so Unicode thin-space insertion is optional and disabled by default. All name effects live within the existing CanvasGroup for consistent distance fading, and all stroke/sweep tweens are canceled when the GUI is replaced or destroyed. Local PlayerRemoving also shuts down the controller.

**Controls:** eye/eye-off in the VantaTest window topbar, the matching Show nameplate switch, and size/height/distance sliders. The controller lives in PlayerScripts, follows only your CharacterAdded and CharacterRemoving, and re-creates the plate after respawn without stacking duplicates. The Crimson01 background and all unrelated UI remain unchanged. VantaUI is untouched.

Standalone script: [nameplate_standalone.lua](nameplate_standalone.lua). It uses the same owl PNG loading logic and self-only behavior as the main module.

```lua
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaTest/main/nameplate_standalone.lua?v=" .. os.time()
))()
```

### Crimson01 living wallpaper

Crimson01 remains a sharp, static high-resolution painting. A native UI overlay provides **50 lightweight animated particles**: 18 layered falling crimson petals, 17 rising embers, 10 soft halo motes, and 5 gentle twinkling lights. The closer petals have a red gradient, while the smaller sparks and floating halos create depth without obscuring the interface.

The particles are pooled once per window and updated by **one 30 FPS-capped RenderStepped connection**. The effect avoids GIF frame swaps and per-frame instance creation, does not intercept input, clips to the window, and pauses while minimized. Minimize/Close instantly hides the overlay before the shrinking animation; reopen resumes particle motion without jumping ahead, and Destroy disconnects the update connection.

### Minimize animation

The native Crimson01 petals and embers **hide immediately when the window is minimized**, instead of lingering while the 0.9-second window-collapse tween finishes. They resume when the window opens. This change only affects the animated overlay: the static wallpaper and all other window animations remain intact.

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
  - Layered native crimson petals, tiny rising embers, soft motes and twinkles animate above the wallpaper without frame swaps
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




