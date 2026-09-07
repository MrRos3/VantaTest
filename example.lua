local cacheBuster = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local VantaUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaTest/main/main.lua?v=" .. cacheBuster
))()

local CompactMusic = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaTest/main/musicplayer_polished.lua?v=" .. cacheBuster
))()
CompactMusic:Init(VantaUI, { Folder = "VantaTest/Music" })

local Window = VantaUI:CreateWindow({
    Title = "VantaUI Showcase",
    Icon = VantaUI.Brand.Image,
    Theme = "Salty Special",
    HideSearchBar = false,
    MusicPlayer = false,
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
        Title = "Open VantaUI",
        Icon = VantaUI.Brand.Image,
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        OnlyIcon = true,
        CornerRadius = UDim.new(0, 11),
        StrokeThickness = 2,
        ImageZoom = 1,
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromHex("#000000")),
            ColorSequenceKeypoint.new(1, Color3.fromHex("#000000")),
        }),
    },
})

-- Music mini-player is independent from VantaUI's normal open badge.
CompactMusic:BindWindow(Window)

-- Add a real music-note button directly to VantaUI's topbar.
-- This intentionally bypasses the Mac traffic-light button helper so the
-- music player always appears as a normal icon instead of becoming a 4th dot.
local function createMusicTopbarButton()
    local windowRoot = Window.UIElements and Window.UIElements.Main
    local main = windowRoot and windowRoot:FindFirstChild("Main")
    local topbar = main and main:FindFirstChild("Topbar")
    local right = topbar and topbar:FindFirstChild("Right")
    assert(right, "[VantaTest] Could not find VantaUI topbar right container")

    local container = Instance.new("Frame")
    container.Name = "MusicPlayerButton"
    container.Size = UDim2.fromOffset(28, 28)
    container.BackgroundTransparency = 1
    container.LayoutOrder = -100
    container.Parent = right

    local button = Instance.new("TextButton")
    button.Name = "Button"
    button.Text = ""
    button.AutoButtonColor = false
    button.BackgroundTransparency = 1
    button.Size = UDim2.fromScale(1, 1)
    button.Parent = container

    local hover = Instance.new("Frame")
    hover.Name = "Hover"
    hover.Size = UDim2.fromScale(1, 1)
    hover.BackgroundColor3 = VantaUI.Theme.Button
    hover.BackgroundTransparency = 1
    hover.BorderSizePixel = 0
    hover.ZIndex = 0
    hover.Parent = button

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 8)
    corner.Parent = hover

    local iconData = VantaUI.Creator.Icon("music") or VantaUI.Creator.Icon("music-2")
    if iconData then
        local icon = Instance.new("ImageLabel")
        icon.Name = "Icon"
        icon.BackgroundTransparency = 1
        icon.Size = UDim2.fromOffset(16, 16)
        icon.AnchorPoint = Vector2.new(0.5, 0.5)
        icon.Position = UDim2.fromScale(0.5, 0.5)
        icon.Image = iconData[1]
        if iconData[2] then
            icon.ImageRectOffset = iconData[2].ImageRectPosition
            icon.ImageRectSize = iconData[2].ImageRectSize
        end
        icon.ImageColor3 = VantaUI.Theme.Icon
        icon.ZIndex = 2
        icon.Parent = button
    else
        local fallback = Instance.new("TextLabel")
        fallback.Name = "IconFallback"
        fallback.BackgroundTransparency = 1
        fallback.Size = UDim2.fromScale(1, 1)
        fallback.Text = "♫"
        fallback.TextSize = 17
        fallback.TextColor3 = VantaUI.Theme.Icon
        fallback.FontFace = Font.new(VantaUI.Creator.Font, Enum.FontWeight.Medium)
        fallback.ZIndex = 2
        fallback.Parent = button
    end

    button.MouseEnter:Connect(function()
        hover.BackgroundColor3 = VantaUI.Theme.Button
        hover.BackgroundTransparency = 0.35
    end)
    button.MouseLeave:Connect(function()
        hover.BackgroundTransparency = 1
    end)
    button.MouseButton1Click:Connect(function()
        VantaUI:PlaySound("Click")
        if CompactMusic.UI and CompactMusic.UI.Mini and CompactMusic.UI.Mini.Visible then
            CompactMusic:Restore()
        elseif CompactMusic.UI and CompactMusic.UI.Root and CompactMusic.UI.Root.Visible then
            CompactMusic.UI.Root.Visible = false
        else
            CompactMusic:Show()
        end
    end)

    return container
end

local MusicTopbarButton = createMusicTopbarButton()

Window:Tag({
    Title = "v" .. VantaUI.Version,
    Icon = "github",
    Color = Color3.fromHex("#151116"),
    Border = true,
})

local Home = Window:Tab({ Title = "Home", Icon = "house" })
local Themes = Window:Tab({ Title = "Themes", Icon = "palette" })
local About = Window:Tab({ Title = "About", Icon = "info" })

Home:Button({
    Title = "VantaUI is alive",
    Desc = "This window is loaded from the VantaTest experimental loader.",
    Icon = "sparkles",
    Callback = function()
        VantaUI:Notify({
            Content = "VantaTest polished glass music-player build is running 🎵",
            Icon = "music",
        })
    end,
})

Home:Button({
    Title = "Runtime info",
    Desc = "Shows the current VantaUI runtime version.",
    Icon = "package",
    Callback = function()
        local info = VantaUI:GetInfo()
        VantaUI:Notify({
            Title = "VantaUI Runtime",
            Content = "VantaUI " .. tostring(info.Version) .. " • runtime " .. tostring(VantaUI.RuntimeVersion or info.Version),
            Icon = "package",
        })
    end,
})

local function addThemeButton(themeName, icon)
    Themes:Button({
        Title = themeName,
        Desc = "Switch the whole interface to " .. themeName .. ".",
        Icon = icon,
        Callback = function()
            VantaUI:SetTheme(themeName)
            CompactMusic:ApplyTheme()
            local button = MusicTopbarButton and MusicTopbarButton:FindFirstChild("Button")
            if button then
                local hover = button:FindFirstChild("Hover")
                local musicIcon = button:FindFirstChild("Icon") or button:FindFirstChild("IconFallback")
                if hover then hover.BackgroundColor3 = VantaUI.Theme.Button end
                if musicIcon then
                    if musicIcon:IsA("ImageLabel") then
                        musicIcon.ImageColor3 = VantaUI.Theme.Icon
                    else
                        musicIcon.TextColor3 = VantaUI.Theme.Icon
                    end
                end
            end
            VantaUI:Notify({ Content = "Theme changed to " .. themeName, Icon = icon })
        end,
    })
end

addThemeButton("Salty Special", "sparkles")
addThemeButton("Vanta Smoked", "cloud-fog")
addThemeButton("Vanta Dark", "moon")
addThemeButton("Vanta AMOLED", "circle-dot")
addThemeButton("Vanta Violet", "wand-sparkles")

About:Button({
    Title = "VantaUI",
    Desc = "Custom Roblox UI library by MrRos3.",
    Icon = "github",
    Callback = function()
        VantaUI:Notify({ Content = "VantaUI • built by MrRos3 🖤", Icon = "heart" })
    end,
})