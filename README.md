# VantaUI

A polished AMOLED-first Roblox UI library by **MrRos3**.

## Loader

```lua
local VantaUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/MrRos3/VantaTest/main/main.lua"))()
```

## Branded test showcase

Run the existing test entrypoint to see the cinematic brand intro, branded title-bar icon, and branded minimized badge:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MrRos3/VantaTest/main/test.lua"))()
```

The exact Vanta artwork is hosted at `assets/vanta-brand.jpeg`. Remote image support downloads it once into the executor's `WindUI/VantaUI/assets` cache and loads it through `getcustomasset` (or `getsynasset`).

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
loadstring(game:HttpGet("https://raw.githubusercontent.com/MrRos3/VantaTest/main/example.lua"))()
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
