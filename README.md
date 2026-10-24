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

### Vanta Edge nameplates for every player (client-side)

Run the VantaTest showcase and open **Nameplate**. The current build creates one native Roblox `BillboardGui` on every player's character, visible **only to your client**. It reattaches when you or another player respawns, removes departed players, and keeps the controller alive under **PlayerScripts**, not the resettable **PlayerGui**. The existing topbar eye button now uses a **native eye icon** with an eye-off slash (no missing/private image assets), and stays synchronized with the Nameplate tab's Show switch.

Default appearance: approx. 230 × 64px near-black translucent plate with a subtle top-down fill gradient, thin crimson gradient stroke (`#E0173D` → `#4A0A18`), low-opacity native glow, 40px circular avatar, bright `#FF2A4D` ring, damage-sensitive status dot, crisp white GothamBold display name, **MEMBER** subtitle, compact solid VANTA badge, and a thin health indicator. The native frame uses a small rounded-corner approximation of the angled silhouette; there are **no external PNGs or other image assets**. Avatar portraits are requested via Roblox `Players:GetUserThumbnailAsync`.

The border-light sweep is a looping **four-second TweenService animation**; the glow pulses softly and the plate briefly flickers after actual Humanoid damage. At 40–60 studs the plate fades to a small name-only view. The initial maximum distance is 60 studs, adjustable in the Nameplate tab. Nameplate display, theme, text, height, scale, distance, and optional real @username are controllable live. The default Roblox name is restored when you hide the custom nameplate or unload it.

**Visibility caveat:** This is a client-side visual overlay for players you see. Other Roblox clients will not see your customization without server-side code in an experience you control. VantaUI is never modified by these changes; the old chat feature remains removed.

Stand-alone use of the no-assets module:

```lua
local nameplate = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaTest/main/nameplate.lua?v=" .. os.time()
))().new({Enabled=true, Tag="VANTA", Subtitle="MEMBER", MaxDistance=60})
-- nameplate:SetEnabled(false)
-- nameplate:Destroy()
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




