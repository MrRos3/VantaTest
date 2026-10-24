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

### Nameplate above your head

Open the new **Nameplate** tab in the VantaTest showcase. It immediately creates a native `BillboardGui` above your own character's head, with a floating OLED/crimson card, genuine Roblox display name, @username, profile thumbnail, and customizable 18-character tag.

- Show/hide the overhead nameplate.
- Switch between **Crimson**, **OLED** and **Steel** palettes.
- Edit the upper tag without changing or impersonating your Roblox identity.
- Show/hide @username, change nameplate size (70–140%), height (1.5–4.5 studs) and max visible distance (30–150 studs).
- Reattach automatically when your character respawns. Running the loader again destroys the previous nameplate controller instead of stacking duplicates; the default Roblox overhead name is restored when disabled or removed.

Only **your Roblox client** can see this version of the nameplate. For other players to see it in a game you own, its creation must be performed in the game's server-authorized scripts. It does not replicate into unrelated Roblox games.

The nameplate can also be used without the full VantaTest showcase:

```lua
local module = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaTest/main/nameplate.lua?v=" .. os.time()
))()
local nameplate = module.new({Tag="VANTA",Style="Crimson"})
-- Later: nameplate:SetEnabled(false) or nameplate:Destroy()
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




