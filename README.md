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

### Vanta Edge: YOUR nameplate only

The **Nameplate** tab in VantaTest shows a client-side overhead `BillboardGui` above **your own Roblox character only**. No extra nameplates are created for friends, strangers, or other players. The nameplate is not replicated to other clients.

**Latest polish:** A dark `#2A0A12` health track sits **10px in from both sides**, fills crimson, measures **3px high**, and has rounded ends. The subtitle ends 4px above the bar. The status dot is offset 3px upward and rightward; the VANTA badge has a **3px radius** and 6px inset. The display name uses **GothamBold**, `TextTruncate.AtEnd`, and a width limited to the space beside the avatar. The plate is now about **230 × 72px**, slightly taller than the earlier 64px version so the 40px avatar, badge, subtitle, and full-width health bar don't collide.

The other design details remain: near-black translucent plate, native rounded-edge approximation, a gradient crimson 1px outline, restrained red halo, circular Roblox headshot (`GetUserThumbnailAsync`), bright red avatar ring, green/red damage status dot, and a **MEMBER** subtitle. The border sweeps every four seconds, the glow pulses softly, the plate flickers on real damage, and distance fading starts beyond 40 studs. There are **no custom external PNG/image dependencies**.

The controller resides under `PlayerScripts` and reconnects to **your** `CharacterAdded`/`CharacterRemoving` events to survive respawns and PlayerGui resets. It safely cleans itself up upon re-execution. The topbar eye/eye-off control is made from native UI shapes, and it stays synced with the Nameplate tab switch. Crimson01 stays unchanged. The removed chat feature stays removed. VantaUI production is not modified.

Standalone no-assets LocalScript: <https://github.com/MrRos3/VantaTest/blob/main/nameplate_standalone.lua>. Running it creates the nameplate for your character immediately, without needing the VantaTest window.

```lua
local module = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaTest/main/nameplate.lua?v=" .. os.time()
))()
local nameplate = module.new({Tag="VANTA", Subtitle="MEMBER", MaxDistance=60})
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




