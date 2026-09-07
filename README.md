# VantaUI

A polished AMOLED-first Roblox UI library by **MrRos3**.

## Loader

```lua
local cacheBuster = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local VantaUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaUI/main/main.lua?v=" .. cacheBuster
))()
```

## Vanta brand identity

VantaUI v0.3.4 automatically uses the official Vanta artwork for the window's top-left icon and keeps the minimized/open badge square and image-only. This applies even when an older script later edits the button with a title or outdated icon. The current artwork uses a versioned asset filename so executor caches cannot restore an older badge.

Custom branding remains possible with `Branding = { UseDefault = false, Image = "..." }`. Set `Branding = false` only when a script intentionally should not use Vanta branding.

## Interface sounds

VantaUI v0.3.2 enables the selected **Soft** sound style by default, with Minimal still available as an alternative. Buttons, tabs, toggles, dropdowns, sliders, inputs, notifications, and window opening or closing use the small original sounds hosted in `assets/sounds`.

Supported executors cache the sounds in `WindUI/<folder>/sounds` and load them through `getcustomasset` or `getsynasset`. Executors without downloadable asset support use a built-in Roblox fallback. Sounds can be adjusted per window:

```lua
Sounds = {
    Enabled = true,
    Preset = "Soft",
    Volume = 0.45,
    Pitch = 1,
}
```

Set `Sounds = false` to mute a window. The runtime also exposes `SetSoundEnabled`, `SetSoundVolume`, `SetSoundPitch`, and `SetSoundForEvent` for live changes.

## v0.3.5

- Windows now start on the first-created tab by default, regardless of its title.
- `StartupTab` can still select a different tab by its title or numeric position.

## v0.3.4

- Keeps default Vanta minimized branding square and image-only after any later `EditOpenButton` call.

## v0.3.3

- Official Vanta artwork is now the automatic window icon and minimized badge
- Old script icon values are replaced unless Vanta branding is explicitly disabled
- Versioned brand asset prevents stale executor image caches

## v0.3.2

- Soft GUI sound style selected as the production default
- Minimal remains available through `SetSoundPreset("Minimal")`

## v0.3.1

- Minimal GUI sound style enabled by default
- Separate cues for clicks, tabs, toggles, dropdowns, sliders, inputs, notifications, and window state
- Per-window mute, volume, pitch, and event override controls

## v0.3.0

- Public brand is **VantaUI**
- Default theme is **Vanta AMOLED**
- Startup tab defaults to **Home**
- Includes **Vanta Smoked**, **Vanta Dark**, **Vanta AMOLED**, and **Vanta Violet**
- ON toggles stay green across all built-in themes
- Compact capsule toggles and fixed dropdown second-click closing
- Runtime GUI names use the `VantaUI` brand
- Config storage defaults to `VantaUI/...`
- Notifications default to the `VantaUI` title
- Legacy theme aliases remain supported for compatibility
- GitHub Actions automatically regenerates `dist/main.lua` when source files change

## Example

```lua
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaUI/main/example.lua?v=" .. os.time()
))()
```

## Project layout

- `main.lua` - stable VantaUI public loader and customization layer
- `dist/main.lua` - compiled runtime
- `src/` - editable UI source
- `build/` - build tooling
- `example.lua` - showcase and test script
- `.github/workflows/build-gui.yml` - automatic source build

## License

VantaUI is released under the MIT License, Copyright (c) 2026 MrRos3. See [`LICENSE`](./LICENSE).

Required notices for inherited permissively licensed portions are preserved separately in [`THIRD_PARTY_NOTICES`](./THIRD_PARTY_NOTICES).
