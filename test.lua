--[[
    VantaTest executable showcase
    Loads the staging VantaUI runtime and immediately opens a test window.
]]

local function playVantaEdgeIntro()
    local TweenService = game:GetService("TweenService")
    local CoreGui = game:GetService("CoreGui")
    local parent = (gethui and gethui()) or CoreGui

    local old = parent:FindFirstChild("VantaEdgeIntro")
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "VantaEdgeIntro"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 1000000
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = parent

    local root = Instance.new("CanvasGroup")
    root.Name = "Root"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    root.BorderSizePixel = 0
    root.GroupTransparency = 0
    root.Parent = gui

    local aura = Instance.new("Frame")
    aura.Size = UDim2.fromOffset(170, 170)
    aura.Position = UDim2.fromScale(0.5, 0.5)
    aura.AnchorPoint = Vector2.new(0.5, 0.5)
    aura.BackgroundColor3 = Color3.fromRGB(124, 140, 255)
    aura.BackgroundTransparency = 0.94
    aura.BorderSizePixel = 0
    aura.Parent = root
    local auraCorner = Instance.new("UICorner")
    auraCorner.CornerRadius = UDim.new(1, 0)
    auraCorner.Parent = aura
    local auraScale = Instance.new("UIScale")
    auraScale.Scale = 0.5
    auraScale.Parent = aura

    local center = Instance.new("Frame")
    center.Size = UDim2.fromOffset(360, 190)
    center.Position = UDim2.fromScale(0.5, 0.5)
    center.AnchorPoint = Vector2.new(0.5, 0.5)
    center.BackgroundTransparency = 1
    center.Parent = root
    local centerScale = Instance.new("UIScale")
    centerScale.Scale = 0.88
    centerScale.Parent = center

    local sweep = Instance.new("Frame")
    sweep.Size = UDim2.fromOffset(0, 1)
    sweep.Position = UDim2.new(0.5, 0, 0.5, -24)
    sweep.AnchorPoint = Vector2.new(0.5, 0.5)
    sweep.BackgroundColor3 = Color3.fromRGB(130, 145, 255)
    sweep.BackgroundTransparency = 0.22
    sweep.BorderSizePixel = 0
    sweep.Parent = center
    local sweepGradient = Instance.new("UIGradient")
    sweepGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.2, 0.25),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(0.8, 0.25),
        NumberSequenceKeypoint.new(1, 1),
    })
    sweepGradient.Parent = sweep

    local mark = Instance.new("Frame")
    mark.Size = UDim2.fromOffset(58, 58)
    mark.Position = UDim2.new(0.5, 0, 0, 18)
    mark.AnchorPoint = Vector2.new(0.5, 0)
    mark.BackgroundColor3 = Color3.fromRGB(10, 11, 15)
    mark.BackgroundTransparency = 0
    mark.BorderSizePixel = 0
    mark.Rotation = -7
    mark.Parent = center
    local markCorner = Instance.new("UICorner")
    markCorner.CornerRadius = UDim.new(0, 17)
    markCorner.Parent = mark
    local markStroke = Instance.new("UIStroke")
    markStroke.Color = Color3.fromRGB(145, 156, 255)
    markStroke.Thickness = 1
    markStroke.Transparency = 1
    markStroke.Parent = mark
    local markScale = Instance.new("UIScale")
    markScale.Scale = 0.55
    markScale.Parent = mark

    local letter = Instance.new("TextLabel")
    letter.Size = UDim2.fromScale(1, 1)
    letter.BackgroundTransparency = 1
    letter.Text = "V"
    letter.TextColor3 = Color3.fromRGB(242, 244, 255)
    letter.TextTransparency = 1
    letter.TextSize = 26
    letter.Font = Enum.Font.GothamBold
    letter.Parent = mark

    local title = Instance.new("TextLabel")
    title.Size = UDim2.fromOffset(300, 38)
    title.Position = UDim2.new(0.5, 0, 0, 90)
    title.AnchorPoint = Vector2.new(0.5, 0)
    title.BackgroundTransparency = 1
    title.Text = "VANTA"
    title.TextColor3 = Color3.fromRGB(244, 245, 250)
    title.TextTransparency = 1
    title.TextSize = 27
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Parent = center
    local titleGradient = Instance.new("UIGradient")
    titleGradient.Offset = Vector2.new(-1, 0)
    titleGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(205, 209, 225)),
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(173, 184, 255)),
    })
    titleGradient.Parent = title

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.fromOffset(300, 20)
    sub.Position = UDim2.new(0.5, 0, 0, 126)
    sub.AnchorPoint = Vector2.new(0.5, 0)
    sub.BackgroundTransparency = 1
    sub.Text = "EDGE  //  TEST LAB"
    sub.TextColor3 = Color3.fromRGB(145, 149, 165)
    sub.TextTransparency = 1
    sub.TextSize = 10
    sub.Font = Enum.Font.GothamMedium
    sub.TextXAlignment = Enum.TextXAlignment.Center
    sub.Parent = center

    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(150, 2)
    track.Position = UDim2.new(0.5, 0, 0, 160)
    track.AnchorPoint = Vector2.new(0.5, 0)
    track.BackgroundColor3 = Color3.fromRGB(25, 27, 34)
    track.BackgroundTransparency = 0.2
    track.BorderSizePixel = 0
    track.Parent = center
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(129, 142, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    TweenService:Create(auraScale, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Scale = 1 }):Play()
    TweenService:Create(aura, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundTransparency = 0.975 }):Play()
    TweenService:Create(centerScale, TweenInfo.new(0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Scale = 1 }):Play()
    TweenService:Create(sweep, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(330, 1) }):Play()
    TweenService:Create(markScale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
    TweenService:Create(mark, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Rotation = 0 }):Play()
    TweenService:Create(markStroke, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Transparency = 0.28 }):Play()
    TweenService:Create(letter, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()

    task.wait(0.28)
    TweenService:Create(title, TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        TextTransparency = 0,
        Position = UDim2.new(0.5, 0, 0, 86),
    }):Play()
    TweenService:Create(titleGradient, TweenInfo.new(0.85, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Offset = Vector2.new(1, 0) }):Play()
    TweenService:Create(sub, TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { TextTransparency = 0.15 }):Play()
    TweenService:Create(fill, TweenInfo.new(0.92, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 1, 0) }):Play()

    task.wait(1.02)
    TweenService:Create(centerScale, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Scale = 1.035 }):Play()
    TweenService:Create(root, TweenInfo.new(0.48, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { GroupTransparency = 1 }):Play()
    task.wait(0.5)
    gui:Destroy()
end

playVantaEdgeIntro()

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
    Content = "Vanta Edge preview loaded successfully.",
    Icon = "flask-conical",
    Duration = 3,
})

return Window
