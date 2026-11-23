# SaltyUI

Roblox UI library by **Salty**.

## Loadstring

```lua
local SaltyUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/MrRos3/VantaTest/main/main.lua"))()
```

## Quick start

```lua
local SaltyUI = loadstring(game:HttpGet("https://raw.githubusercontent.com/MrRos3/VantaTest/main/main.lua"))()

local Window = SaltyUI:CreateWindow({
    Title = "salty hub",
    Author = "Salty",
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
        SaltyUI:Notify({
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

## Licensing

See the [project license](LICENSE) and [third-party notices](THIRD_PARTY_NOTICES).
