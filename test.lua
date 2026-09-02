--[[
    VantaTest executable showcase
    Loads the staging VantaUI runtime and immediately opens a test window.
]]

local cacheBuster = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local VantaUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaTest/main/main.lua?v=" .. cacheBuster
))()

assert(type(VantaUI) == "table", "[VantaTest] Failed to load VantaUI")

VantaUI:SetTheme("Salty Special")

local Window = VantaUI:CreateWindow({
    Title = "VantaTest",
    Author = "MrRos3",
    Theme = "Salty Special",
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
    Branding = {
        Name = "VANTA",
        Image = VantaUI.Brand.Image,
        Folder = "VantaUI",
        IconSize = 24,
        IconRadius = 7,
        OpenButtonIconRadius = 8,
        Intro = false,
    },
    OpenButton = {
        Title = "VantaTest",
        Enabled = true,
        Draggable = true,
        OnlyIcon = true,
        OnlyMobile = false,
        CornerRadius = UDim.new(0, 11),
        StrokeThickness = 2,
        ImageZoom = 1,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHex("#000000")),
            ColorSequenceKeypoint.new(1, Color3.fromHex("#000000")),
        }),
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
    TextSize = 18,
})

Home:Paragraph({
    Title = "Staging playground",
    Desc = "This window runs entirely from MrRos3/VantaTest so VantaUI changes can be tested safely before production.",
})

Home:Button({
    Title = "Test notification",
    Desc = "Confirm buttons and notification styling.",
    Callback = function()
        VantaUI:Notify({
            Title = "VantaTest",
            Content = "The staging runtime is alive 🖤",
            Duration = 4,
        })
    end,
})

Controls:Toggle({
    Title = "Vanta toggle",
    Desc = "Green ON state test.",
    Default = true,
    Callback = function() end,
})

Controls:Slider({
    Title = "Slider",
    Desc = "Test rail, fill and thumb styling.",
    Step = 1,
    Value = {
        Min = 0,
        Max = 100,
        Default = 65,
    },
    Callback = function() end,
})

Controls:Dropdown({
    Title = "Dropdown",
    Desc = "Test open, close and second-click behavior.",
    Values = { "Alpha", "Beta", "Gamma", "Delta" },
    Value = "Alpha",
    Callback = function() end,
})

Controls:Input({
    Title = "Input",
    Desc = "Test textbox styling.",
    Placeholder = "Type something...",
    Callback = function() end,
})

Themes:Button({
    Title = "Salty Special",
    Callback = function()
        VantaUI:SetTheme("Salty Special")
    end,
})

Themes:Button({
    Title = "Vanta AMOLED",
    Callback = function()
        VantaUI:SetTheme("Vanta AMOLED")
    end,
})

Themes:Button({
    Title = "Vanta Smoked",
    Callback = function()
        VantaUI:SetTheme("Vanta Smoked")
    end,
})

Themes:Button({
    Title = "Vanta Dark",
    Callback = function()
        VantaUI:SetTheme("Vanta Dark")
    end,
})

Themes:Button({
    Title = "Vanta Violet",
    Callback = function()
        VantaUI:SetTheme("Vanta Violet")
    end,
})

Window:SelectTab(1)
