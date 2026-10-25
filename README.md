# VantaTest 🧪

## High-contrast visual refresh (v0.4.x)

Salty Special now uses a high-contrast, **four-second rotating crimson squircle outline** and a larger rounded red aura. The wallpaper has stronger dark edges, a warm crimson color grade, and breathing backlight. Active sidebar tabs are filled gradient pills with one shared sliding highlight. Glass element cards have moving rounded light sheens; ON toggles show crimson tracks and white knobs with halos; sliders and buttons use brighter themed gradients. OLED notifications retain the full-height gradient countdown, icon pop, and slide-in overshoot without any left-edge stripe.

The obsolete topbar divider and gray resize arc are removed while the resize hitbox, public APIs, 50 pooled ambient particles, reduce-motion behavior, and performance rules stay intact. Source of truth is src/ and the GitHub Actions npm build automatically commits dist/main.lua. The existing example.lua showcase includes all ten tabs and theme controls. Interactive Roblox rendering still requires a live client check.

## Latest polish: invisible chrome light, faded tabs and working owl diagnostics

The window now has **no static colored border and no drop shadow**: only a narrow moving ice-white (`#EAF6FF`) highlight, which disappears completely with reduce motion. Salty Special tabs revert to a transparent selected background with a fade to the right; the shared animated selection pill now fades rather than painting a solid block. The 32px resize hit area with its 28px themed grip lives at root ZIndex 100 above window content. Owl PNG loading has multi-executor fallbacks, diagnostic status, a monochrome native fallback, and a saved Roblox image-ID override.

## v0.4.0 • Salty Special: Nightfall Edition

The laboratory now introduces a premium motion system without changing the public element APIs. The Salty Special shell has a themed rotating 2px crimson border, soft aura, glass topbar, animated Michroma title shine, wallpaper vignette and spring-style open/close scale. Active tabs gain a luminous accent strip, while element hover outlines, press-scale buttons, animated toggles, slider gradients/value bubbles, progress sweeps, dropdown transitions and OLED notification accents add tactile detail.

The existing **50 pooled Crimson01 particles** now share the same 30 FPS ambient update loop with a breathing gradient light and an occasional shooting ember recycled from the pool. The Themes showcase has **Visuals** settings for intensity, particle density and reduced motion; low-FPS fallback suppresses motion. Vanta Void adds a cyan (`#5DE7FF`) theme, and all six themes recolor premium borders and glow on live switches.

**Compatibility:** Existing calls and configuration keys remain valid. New optional `Visuals={Intensity=0.8,Density=1,ReduceMotion=false}` defaults are safe. The library exposes `SetVisualIntensity(number 0..1)`, `SetParticleDensity(number 0..1)`, `SetReduceMotion(boolean)`, and `GetVisualSettings()`. VantaUI production remains unchanged. Roblox-client rendering and executor-specific input performance need live verification.

### Changelog
- **0.4.0**: premium shell, microinteractions, six live themes, adjustable ambient visuals and reduced-motion support
- **0.3.8**: Salty Special UI lab, Crimson01 wallpaper and pooled ambient particles


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
| Themes | All 6 built-in themes, sound switch and stacked notifications |
| Layouts | Sections, paragraphs, spacers, dividers, groups, HStack and VStack |
| Advanced | Image, interactive 3D viewport, code block, component diagnostics |

### Vanta Owl: your own overhead nameplate 🦉

The **Nameplate** tab now renders **[owl] [your DisplayName] [owl]** above **your character only**. No other players get a Vanta plate, even if they join or respawn. The script also shuts down the earlier all-player `__VANTA_OWL_CLEANUP` executor script when available and clears stale `VantaOwlNameplate` Billboards from other heads on launch. It **never** deletes Roblox's or other games' unrelated nameplates.

**Your owl artwork is included:** [assets/owl/vanta_owl_96.png](assets/owl/vanta_owl_96.png), a transparent 96px black-and-white PNG. The nameplate tries `request`, `http_request`, `syn.request`, and `http.request` before `game:HttpGet`, verifies the eight-byte PNG signature, writes `VantaTest/VantaTest_Owl_96.png` or `VantaTest_Owl_96.png`, then tries `getcustomasset(path)`, `getcustomasset(path, true)`, and `getsynasset(path)`, retrying up to three times. The Nameplate tab shows the exact loader status (`download failed`, `bad PNG`, `writefile failed`, `no getcustomasset`, or `getcustomasset failed`). Without working file APIs it displays a **white Michroma V inside a white circle** instead of a colored emoji.

**Guaranteed method when the executor lacks file/custom-asset APIs:** Visit [create.roblox.com](https://create.roblox.com/), upload [`assets/owl/vanta_owl_96.png`](assets/owl/vanta_owl_96.png) as a Decal/Image, ensure the image is usable by your experience/account, and copy the image asset ID. Open the **Nameplate** tab in the `example.lua` showcase and paste either the digits or `rbxassetid://1234567890` into **Roblox owl image ID**. The change applies live via `SetOwlImage` and saves using VantaTest's config manager (`Gui/VantaTest/config/owl_image.json`) if executor file APIs are available. You can also set `CONFIG.OWL_IMAGE` in the module or pass `OWL_IMAGE` to `module.new({...})`. Roblox moderation/asset permissions and Roblox-client rendering still apply.

The nameplate is now one solid **44px-high black capsule Frame** (`#050506`, transparency 0) with fully rounded ends from `UICorner=UDim.new(0.5,0)`. A **2px white UIStroke** in Border mode has a five-stop gradient: `#5A0A1C` at 0, 0.4, 0.6 and 1, with a narrow `#FF3355` highlight at 0.5. Only that border gradient rotates 0→360° linearly every 3 seconds, forever. The frame itself has no fill gradient, extra shape frames, glow, brackets, diamonds, or dividers. A separate transparent ZIndex 2 content frame holds the existing 30px owl icons 18px from each end and the existing centered Michroma name and white-band shine. Auto width is `max(190px, 2*owlWidth + TextBounds.X + 76px)`. Fill, animated border, owls and name fade together with distance. Border/name tweens are cleaned up on respawn and PlayerRemoving; VantaUI stays untouched.

**Name animation:** Michroma 14px with a single horizontal five-stop name `UIGradient` over white glyphs: **`#FF1A3D` red at 0 and 0.35 → `#FFFFFF` white at 0.5 → `#FF1A3D` red at 0.65 and 1**. A 1.4s Sine InOut sweep travels left-to-right, resets offscreen to `Offset=(-1,0)`, and then stays fully red for 2.5s before the next sweep. The 1px `#1A0008` outline holds constant 0.3 transparency. No separate highlight layer, pulse, glitch, or color flash. The whole plate and shine fade with distance; active tweens are canceled on respawn, destruction, or local PlayerRemoving. Unicode thin-space insertion remains off by default.

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
- Optional themes: Smoked, Dark, AMOLED, Violet and Void
- v0.3.8 runtime; changes to `src/` trigger the GitHub build workflow for `dist/main.lua`

## Build

```bash
npm install
npm run build
```

Licensing information: [LICENSE](LICENSE) and [THIRD_PARTY_NOTICES](THIRD_PARTY_NOTICES).




