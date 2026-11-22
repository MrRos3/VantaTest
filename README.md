# VantaTest

Roblox UI library by **MrRos3 (salty)**.

## Loadstring

```lua
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/MrRos3/VantaTest/main/dist/main.lua"))()
```

## Quick start

```lua
local WindUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/MrRos3/VantaTest/main/dist/main.lua"))()

local Window = WindUI:CreateWindow({
    Title = "salty hub",
    Author = "by MrRos3",
    Folder = "saltyhub",
    Icon = "solar:folder-2-bold-duotone",
})

local Tab = Window:Tab({
    Title = "Main",
    Icon = "house",
})

Tab:Button({
    Title = "Click me",
    Callback = function()
        WindUI:Notify({
            Title = "salty hub",
            Content = "Button clicked!",
        })
    end,
})

Tab:Toggle({
    Title = "Toggle",
    Callback = function(state)
        print("Toggle:", state)
    end,
})

Tab:Slider({
    Title = "Slider",
    Step = 1,
    Value = { Min = 0, Max = 100, Default = 50 },
    Callback = function(value)
        print("Slider:", value)
    end,
})
```

## Full example

Shows every element:

```lua
loadstring(game:HttpGet("https://raw.githubusercontent.com/MrRos3/VantaTest/main/main.client.lua"))()
```

## License

MIT. See [LICENSE](LICENSE).
