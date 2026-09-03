# VantaUI

A polished AMOLED-first Roblox UI library by **MrRos3**.

## Loader

```lua
local cacheBuster = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local VantaUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaTest/main/main.lua?v=" .. cacheBuster
))()
```

## Branded test showcase

Run the test entrypoint to open the `Salty Special` theme immediately with its wallpaper, branded title-bar icon, and draggable minimized badge:

```lua
local cacheBuster = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaTest/main/test.lua?v=" .. cacheBuster
))()
```

The exact Vanta artwork is hosted at `assets/vanta-brand.jpeg`, and the selected spider-lily wallpaper is hosted at `assets/salty-special.png`. Remote image support downloads each asset once into the executor's `WindUI/VantaUI/assets` cache and loads it through `getcustomasset` (or `getsynasset`).

## v0.3.0

- Public brand is **VantaUI**
- Default theme is **Salty Special**
- Startup tab defaults to **Home**
- Includes **Salty Special**, **Vanta Smoked**, **Vanta Dark**, **Vanta AMOLED**, and **Vanta Violet**
- `Salty Special` uses the selected spider-lily wallpaper behind darkened, readable panels
- Existing Vanta themes keep their green ON toggles; `Salty Special` uses restrained crimson accents
- Compact capsule toggles and fixed dropdown second-click closing
- Runtime GUI names use the `VantaUI` brand
- Config storage defaults to `VantaUI/...`
- Notifications default to the `VantaUI` title
- Legacy theme aliases remain supported for compatibility
- GitHub Actions automatically regenerates `dist/main.lua` when source files change

## Example

```lua
local cacheBuster = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaTest/main/example.lua?v=" .. cacheBuster
))()
```

## Project layout

- `main.lua` - stable VantaUI public loader and customization layer
- `dist/main.lua` - compiled runtime
- `src/` - editable UI source
- `build/` - build tooling
- `example.lua` - showcase and test script
- `test.lua` - VantaTest staging entrypoint, synchronized with the production showcase baseline
- `.github/workflows/build-gui.yml` - automatic source build

## License

VantaUI is released under the MIT License, Copyright (c) 2026 MrRos3. See [`LICENSE`](./LICENSE).

Required notices for inherited permissively licensed portions are preserved separately in [`THIRD_PARTY_NOTICES`](./THIRD_PARTY_NOTICES).
