# VantaUI

A polished AMOLED-first Roblox UI library by **MrRos3**.

## Current version

**VantaUI 0.3.8** is the only active production version in this repository.

The public loader always uses the current `dist/main.lua` runtime. The old stable-base chaining used by earlier 0.3.x builds has been removed.

## Modern UI by default

The old plain flat-card layout is retired as the default. Both the public `main.lua` loader and direct `dist/main.lua` use the Salty Special black/red theme, floral wallpaper, translucent rounded cards, compact three-dot topbar and clean sidebar without the legacy search field. The official Vanta launcher icon is automatic. Existing window/tab/element APIs, explicit backgrounds, and alternate themes remain available.

## Loader

```lua
local cacheBuster = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local VantaUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaUI/main/main.lua?v=" .. cacheBuster
))()
```

## Vanta brand identity

VantaUI automatically uses the official Vanta artwork for the window icon and minimized/open badge unless custom branding is explicitly requested.

Custom branding remains supported:

```lua
Branding = {
    UseDefault = false,
    Name = "SALTY",
    Image = "https://example.com/brand.png",
}
```

Set `Branding = false` only when a script intentionally should not use Vanta branding.

## Default theme

The production default is **Salty Special**.

Built-in themes:

- Salty Special
- Vanta Smoked
- Vanta Dark
- Vanta AMOLED
- Vanta Violet

Salty Special automatically uses the Vanta wallpaper when the window does not provide a custom background.

## Interface sounds

VantaUI keeps its interface sound system for buttons, tabs, toggles, dropdowns, sliders, inputs, and window state.

**Notification open and notification close sounds are disabled in production.** They cannot be accidentally re-enabled by a preset or by clearing sound overrides.

Sounds can still be adjusted per window:

```lua
Sounds = {
    Enabled = true,
    Preset = "Soft",
    Volume = 0.45,
    Pitch = 1,
}
```

Set `Sounds = false` to mute the entire window.

The runtime also exposes `SetSoundEnabled`, `SetSoundVolume`, `SetSoundPitch`, and `SetSoundForEvent` for live changes.

## 0.3.8 production notes

- Public loader points directly at the current runtime
- Executor compatibility repair is applied only when the raw dist runtime cannot compile directly
- Vanta branding and Salty Special defaults are restored by the public loader
- Notification and notification-close sounds are permanently muted
- Lucide icon loading uses the repaired production runtime path
- Startup tab selection supports both numeric index and title
- GitHub Actions regenerates `dist/main.lua` from `src/` changes

## Example

```lua
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaUI/main/example.lua?v=" .. os.time()
))()
```

## Project layout

- `main.lua` - current VantaUI 0.3.8 public loader and customization layer
- `dist/main.lua` - current compiled runtime
- `src/` - editable UI source
- `build/` - build tooling
- `example.lua` - showcase and test script
- `.github/workflows/build-gui.yml` - automatic source build

There are no separate legacy runtime files kept as active versions. Older releases remain only in Git history.

## License

VantaUI is released under the MIT License, Copyright (c) 2026 MrRos3. See [`LICENSE`](./LICENSE).

Required notices for inherited permissively licensed portions are preserved separately in [`THIRD_PARTY_NOTICES`](./THIRD_PARTY_NOTICES).
