--[[
    VantaTest executable showcase
    Loads the staging VantaUI runtime and immediately opens a test window.
]]

local VantaUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaTest/main/main.lua"
))()

assert(type(VantaUI) == "table", "[VantaTest] Failed to load VantaUI")

VantaUI:SetTheme("Vanta AMOLED")

local Window = VantaUI:CreateWindow({
    Title = "VantaTest",
    Author = "MrRos3",
    Icon = "sparkles",
    Theme = "Vanta AMOLED",
    StartupTab = "Home",
    Size = UDim2.fromOffset(760, 520),
    Resizable = true,
    HideSearchBar = false,
    ScrollBarEnabled = true,
    NewElements = true,
    Topbar = {
        Height = 44,
        ButtonsType = "Mac",
    },
    OpenButton = {
        Title = "Open VantaTest",
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
    },
    User = {
        Enabled = false,
    },
})

Window:Tag({
    Title = "TEST",
    Icon = "flask-conical",
    Border = true,
})

local Home = Window:Tab({
    Title = "Home",
    Icon = "house",
})

local Controls = Window:Tab({
    Title = "Controls",
    Icon = "sliders-horizontal",
})

local Themes = Window:Tab({
    Title = "Themes",
    Icon = "palette",
})

Home:Section({
    Title = "VantaTest",
})

Home:Button({
    Title = "VantaUI is running",
    Desc = "This window is loaded entirely from the VantaTest staging repo.",
    Icon = "circle-check",
    Callback = function()
        VantaUI:Notify({
            Title = "VantaTest",
            Content = "The staging runtime is alive 🖤",
            Icon = "sparkles",
            Duration = 3,
        })
    end,
})

Home:Button({
    Title = "Test Notification",
    Desc = "Open a VantaUI notification.",
    Icon = "bell",
    Callback = function()
        VantaUI:Notify({
            Title = "Notification Test",
            Content = "VantaTest notification works.",
            Icon = "bell",
            Duration = 4,
        })
    end,
})

Controls:Section({
    Title = "Native Controls",
    Desc = "Vanta polish preview",
    Box = true,
    BoxBorder = true,
})

Controls:Toggle({
    Title = "Test Toggle",
    Desc = "Checks the compact green Vanta toggle.",
    Value = true,
    Callback = function() end,
})

Controls:Slider({
    Title = "Test Slider",
    Value = {
        Min = 0,
        Max = 100,
        Default = 50,
    },
    Step = 1,
    Callback = function() end,
})

Controls:Dropdown({
    Title = "Test Dropdown",
    Values = { "One", "Two", "Three" },
    Value = "One",
    Callback = function() end,
})

Controls:Input({
    Title = "Test Input",
    Placeholder = "Type here...",
    Callback = function() end,
})

local function addTheme(themeName, icon)
    Themes:Button({
        Title = themeName,
        Desc = "Switch VantaTest to " .. themeName .. ".",
        Icon = icon,
        Callback = function()
            VantaUI:SetTheme(themeName)
        end,
    })
end

addTheme("Vanta AMOLED", "circle-dot")
addTheme("Vanta Dark", "moon")
addTheme("Vanta Smoked", "cloud-fog")
addTheme("Vanta Violet", "wand-sparkles")

VantaUI:Notify({
    Title = "VantaTest",
    Content = "Test window loaded successfully.",
    Icon = "flask-conical",
    Duration = 3,
})

return Window
