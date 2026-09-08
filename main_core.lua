--[[
    VantaUI v0.3.5
    Roblox UI library by MrRos3.

    Source: https://github.com/MrRos3/VantaTest
    License: MIT
]]

local PROJECT_VERSION = "0.3.5"
local CACHE_BUSTER = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local RUNTIME_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/refs/heads/main/dist/main.lua?v=" .. CACHE_BUSTER
local BRAND_IMAGE_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/assets/vanta-brand-v2.jpeg"
local SALTY_SPECIAL_WALLPAPER_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/assets/salty-special.png"
local MUSIC_PLAYER_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/musicplayer.lua?v=" .. CACHE_BUSTER
local SALTY_SPECIAL_WALLPAPER_TRANSPARENCY = 0.32

local ok, source = pcall(function()
    return game:HttpGet(RUNTIME_URL)
end)

assert(ok and type(source) == "string" and #source > 0, "[VantaUI] Failed to download the UI runtime")

local loader, loadError = loadstring(source)
assert(loader, "[VantaUI] Failed to compile the UI runtime: " .. tostring(loadError))

local VantaUI = loader()
assert(type(VantaUI) == "table", "[VantaUI] UI runtime returned an invalid value")

local MusicPlayer
local musicOk, musicSource = pcall(function()
    return game:HttpGet(MUSIC_PLAYER_URL)
end)
if musicOk and type(musicSource) == "string" and #musicSource > 0 then
    local musicLoader = loadstring(musicSource)
    if musicLoader then
        local loadedOk, loadedPlayer = pcall(musicLoader)
        if loadedOk and type(loadedPlayer) == "table" then
            MusicPlayer = loadedPlayer
            pcall(function()
                MusicPlayer:Init(VantaUI, { Folder = "VantaTest/Music" })
            end)
            VantaUI.MusicPlayer = MusicPlayer
        end
    end
end

VantaUI.RuntimeVersion = tostring(VantaUI.Version or PROJECT_VERSION)
VantaUI.Version = PROJECT_VERSION
VantaUI.Name = "VantaUI"
VantaUI.DefaultTheme = "Salty Special"
VantaUI.DefaultStartupTab = 1
VantaUI.TransparencyValue = 0.1

-- Keep all interface sounds except notification open/close sounds.
VantaUI:SetSoundForEvent("Notification", false)
VantaUI:SetSoundForEvent("NotificationClose", false)

VantaUI.GuiInfo = {
    Name = "VantaUI",
    Version = PROJECT_VERSION,
    Owner = "MrRos3",
    Repository = "MrRos3/VantaTest",
    Runtime = "dist/main.lua",
    License = "MIT",
}

VantaUI.Brand = {
    Name = "VantaUI",
    Owner = "MrRos3",
    Image = BRAND_IMAGE_URL,
    CacheKey = "v2",
    Accent = Color3.fromHex("#929AA7"),
    Cyan = Color3.fromHex("#5DE7FF"),
}

VantaUI.Assets = {
    Brand = BRAND_IMAGE_URL,
    SaltySpecialWallpaper = SALTY_SPECIAL_WALLPAPER_URL,
}

local VantaThemes = {
    {
        Name = "Salty Special",
        Accent = Color3.fromHex("#12070A"),
        Dialog = Color3.fromHex("#0A0709"),
        Outline = Color3.fromHex("#5A1824"),
        Text = Color3.fromHex("#FFFFFF"),
        Placeholder = Color3.fromHex("#9A9AA3"),
        Background = Color3.fromHex("#000000"),
        Button = Color3.fromHex("#251016"),
        Icon = Color3.fromHex("#E2DDE0"),
        Toggle = Color3.fromHex("#A1162F"),
        Slider = Color3.fromHex("#A1162F"),
        Checkbox = Color3.fromHex("#D23A57"),
        Primary = Color3.fromHex("#A1162F"),
        SliderIcon = Color3.fromHex("#F1E3E7"),
        PanelBackground = Color3.fromHex("#050406"),
        PanelBackgroundTransparency = 0.42,
        LabelBackground = Color3.fromHex("#0A080A"),
        LabelBackgroundTransparency = 0.08,
        ElementBackground = Color3.fromHex("#151116"),
        ElementBackgroundTransparency = 0.16,
    },
    {
        Name = "Vanta Smoked",
        Accent = Color3.fromHex("#171A20"),
        Dialog = Color3.fromHex("#121419"),
        Outline = Color3.fromHex("#FFFFFF"),
        Text = Color3.fromHex("#F5F7FA"),
        Placeholder = Color3.fromHex("#8B919C"),
        Background = Color3.fromHex("#0B0D10"),
        Button = Color3.fromHex("#282D35"),
        Icon = Color3.fromHex("#B1B7C1"),
        Toggle = Color3.fromHex("#34C759"),
        Slider = Color3.fromHex("#7C8CFF"),
        Checkbox = Color3.fromHex("#929AA7"),
        Primary = Color3.fromHex("#929AA7"),
        SliderIcon = Color3.fromHex("#B8BEC8"),
        PanelBackground = Color3.fromHex("#FFFFFF"),
        PanelBackgroundTransparency = 0.975,
        LabelBackground = Color3.fromHex("#0A0C0F"),
        LabelBackgroundTransparency = 0.16,
        ElementBackground = Color3.fromHex("#1C2027"),
        ElementBackgroundTransparency = 0,
    },
    {
        Name = "Vanta Dark",
        Accent = Color3.fromHex("#151923"),
        Dialog = Color3.fromHex("#11141C"),
        Outline = Color3.fromHex("#FFFFFF"),
        Text = Color3.fromHex("#F7F9FF"),
        Placeholder = Color3.fromHex("#98A1B3"),
        Background = Color3.fromHex("#0B0E14"),
        Button = Color3.fromHex("#242B3A"),
        Icon = Color3.fromHex("#AEB7C8"),
        Toggle = Color3.fromHex("#34C759"),
        Slider = Color3.fromHex("#7C8CFF"),
        Checkbox = Color3.fromHex("#7C8CFF"),
        Primary = Color3.fromHex("#7C8CFF"),
        SliderIcon = Color3.fromHex("#A9B2C4"),
        PanelBackground = Color3.fromHex("#FFFFFF"),
        PanelBackgroundTransparency = 0.96,
        LabelBackground = Color3.fromHex("#000000"),
        LabelBackgroundTransparency = 0.82,
        ElementBackground = Color3.fromHex("#171C27"),
        ElementBackgroundTransparency = 0,
    },
    {
        Name = "Vanta AMOLED",
        Accent = Color3.fromHex("#0A0A0D"),
        Dialog = Color3.fromHex("#08090C"),
        Outline = Color3.fromHex("#FFFFFF"),
        Text = Color3.fromHex("#FFFFFF"),
        Placeholder = Color3.fromHex("#858B98"),
        Background = Color3.fromHex("#000000"),
        Button = Color3.fromHex("#17191F"),
        Icon = Color3.fromHex("#A8AFBC"),
        Toggle = Color3.fromHex("#34C759"),
        Slider = Color3.fromHex("#7C8CFF"),
        Checkbox = Color3.fromHex("#5DE7FF"),
        Primary = Color3.fromHex("#5DE7FF"),
        SliderIcon = Color3.fromHex("#C4CAD4"),
        PanelBackground = Color3.fromHex("#FFFFFF"),
        PanelBackgroundTransparency = 0.975,
        LabelBackground = Color3.fromHex("#090A0C"),
        LabelBackgroundTransparency = 0.12,
        ElementBackground = Color3.fromHex("#0D0F14"),
        ElementBackgroundTransparency = 0,
    },
    {
        Name = "Vanta Violet",
        Accent = Color3.fromHex("#211B35"),
        Dialog = Color3.fromHex("#171323"),
        Outline = Color3.fromHex("#FFFFFF"),
        Text = Color3.fromHex("#FCF9FF"),
        Placeholder = Color3.fromHex("#A49AB5"),
        Background = Color3.fromHex("#0D0A13"),
        Button = Color3.fromHex("#2C2440"),
        Icon = Color3.fromHex("#C5B8D8"),
        Toggle = Color3.fromHex("#34C759"),
        Slider = Color3.fromHex("#7C8CFF"),
        Checkbox = Color3.fromHex("#D47CFF"),
        Primary = Color3.fromHex("#A98BFF"),
        SliderIcon = Color3.fromHex("#D7CCEA"),
        PanelBackground = Color3.fromHex("#FFFFFF"),
        PanelBackgroundTransparency = 0.965,
        LabelBackground = Color3.fromHex("#120E1B"),
        LabelBackgroundTransparency = 0.12,
        ElementBackground = Color3.fromHex("#1B1628"),
        ElementBackgroundTransparency = 0,
    },
}

local LegacyThemeNames = {
    ["Vanta Smoked"] = "Gui Smoked",
    ["Vanta Dark"] = "Gui Dark",
    ["Vanta AMOLED"] = "Gui AMOLED",
    ["Vanta Violet"] = "Gui Violet",
}

for _, theme in ipairs(VantaThemes) do
    VantaUI:AddTheme(theme)
    local legacyName = LegacyThemeNames[theme.Name]
    if legacyName then
        local legacyTheme = {}
        for key, value in pairs(theme) do
            legacyTheme[key] = value
        end
        legacyTheme.Name = legacyName
        VantaUI:AddTheme(legacyTheme)
    end
end

local ActiveWindows = setmetatable({}, { __mode = "k" })

local function applyThemeWallpaper(window, themeName)
    if not window or window.Destroyed or not window._UsesVantaThemeWallpaper then
        return
    end

    local transparency = themeName == "Salty Special" and SALTY_SPECIAL_WALLPAPER_TRANSPARENCY or 1
    window:SetBackgroundImageTransparency(transparency)
end

local BaseSetTheme = VantaUI.SetTheme
function VantaUI:SetTheme(themeName)
    local theme = BaseSetTheme(self, themeName)
    if theme then
        for window in pairs(ActiveWindows) do
            applyThemeWallpaper(window, themeName)
        end
        if MusicPlayer and MusicPlayer.ApplyTheme then
            pcall(function()
                MusicPlayer:ApplyTheme()
            end)
        end
    end
    return theme
end

local function renameRuntimeGui()
    if VantaUI.ScreenGui then
        VantaUI.ScreenGui.Name = "VantaUI"
    end
    if VantaUI.NotificationGui then
        VantaUI.NotificationGui.Name = "VantaUI/Notifications"
    end
    if VantaUI.DropdownGui then
        VantaUI.DropdownGui.Name = "VantaUI/Dropdowns"
    end
    if VantaUI.TooltipGui then
        VantaUI.TooltipGui.Name = "VantaUI/Tooltips"
    end
end

renameRuntimeGui()
VantaUI:SetTheme(VantaUI.DefaultTheme)

local function forceNotificationPosition()
    if not VantaUI.NotificationGui then
        return
    end

    local holder = VantaUI.NotificationGui:FindFirstChildWhichIsA("Frame")
    if holder then
        holder.Position = UDim2.new(1, -29, 0, 96)
        holder.Size = UDim2.new(0, 300, 1, -116)
    end
end

local function forceOpenButtonPosition(window)
    if not window or window.Destroyed then
        return
    end

    local openButtonMain = window.OpenButtonMain
    local button = openButtonMain and openButtonMain.Button
    local container = button and button.Parent
    if container then
        container.Position = UDim2.new(0.5, 0, 0, 88)
    end
end

forceNotificationPosition()

local function copyConfig(source)
    local result = {}
    if type(source) == "table" then
        for key, value in pairs(source) do
            result[key] = value
        end
    end
    return result
end

local function applyDefaultBranding(config)
    if config.Branding == false then
        if config.OpenButton == false then
            config.OpenButton = { Enabled = false }
        end
        return
    end

    local branding = copyConfig(config.Branding)
    if branding.UseDefault ~= false then
        branding.Image = BRAND_IMAGE_URL
        branding.WindowIcon = BRAND_IMAGE_URL
        branding.OpenButtonIcon = BRAND_IMAGE_URL
    end

    if branding.Name == nil then
        branding.Name = "VANTA"
    end
    if branding.Folder == nil then
        branding.Folder = "VantaUI"
    end
    if branding.IconSize == nil then
        branding.IconSize = 24
    end
    if branding.IconRadius == nil then
        branding.IconRadius = 7
    end
    if branding.OpenButtonIconRadius == nil then
        branding.OpenButtonIconRadius = 8
    end

    config.Branding = branding

    local windowBrandIcon = branding.WindowIcon or branding.Image
    if branding.UseAsWindowIcon ~= false and windowBrandIcon then
        config.Icon = windowBrandIcon
    end

    if config.OpenButton == false then
        config.OpenButton = { Enabled = false }
        return
    end

    local openButton = copyConfig(config.OpenButton)
    if openButton.Title == nil then
        openButton.Title = "Open VantaUI"
    end
    if openButton.Enabled == nil then
        openButton.Enabled = true
    end
    if openButton.Draggable == nil then
        openButton.Draggable = true
    end
    if openButton.OnlyMobile == nil then
        openButton.OnlyMobile = false
    end
    if branding.UseDefault ~= false and branding.UseAsOpenButtonIcon ~= false then
        openButton.OnlyIcon = true
    elseif openButton.OnlyIcon == nil then
        openButton.OnlyIcon = true
    end
    if openButton.CornerRadius == nil then
        openButton.CornerRadius = UDim.new(0, 11)
    end
    if openButton.StrokeThickness == nil then
        openButton.StrokeThickness = 2
    end
    if openButton.ImageZoom == nil then
        openButton.ImageZoom = 1
    end
    if openButton.Color == nil then
        openButton.Color = ColorSequence.new(Color3.fromHex("#000000"), Color3.fromHex("#000000"))
    end

    local openButtonBrandIcon = branding.OpenButtonIcon or branding.Image
    if branding.UseAsOpenButtonIcon ~= false and openButtonBrandIcon then
        openButton.Icon = openButtonBrandIcon
    end
    config.OpenButton = openButton
end

local BaseCreateWindow = VantaUI.CreateWindow
function VantaUI:CreateWindow(config)
    config = config or {}

    if config.Theme == nil then
        config.Theme = VantaUI.DefaultTheme
    end
    if config.Folder == nil then
        config.Folder = "VantaUI"
    end
    if config.NewElements == nil then
        config.NewElements = true
    end
    if config.Size == nil then
        config.Size = UDim2.fromOffset(620, 420)
    end

    applyDefaultBranding(config)

    local usesThemeWallpaper = config.Background == nil
    if usesThemeWallpaper then
        config.Background = SALTY_SPECIAL_WALLPAPER_URL
        config.BackgroundImageTransparency = config.Theme == "Salty Special"
                and SALTY_SPECIAL_WALLPAPER_TRANSPARENCY
            or 1
    end

    config.Topbar = config.Topbar or {}
    if config.Topbar.Height == nil then
        config.Topbar.Height = 44
    end
    if config.Topbar.ButtonsType == nil then
        config.Topbar.ButtonsType = "Mac"
    end

    local startupTab = config.StartupTab
    if startupTab == nil then
        startupTab = VantaUI.DefaultStartupTab
    end
    local window = BaseCreateWindow(self, config)

    window._UsesVantaThemeWallpaper = usesThemeWallpaper
    ActiveWindows[window] = true
    applyThemeWallpaper(window, config.Theme)

    local branding = config.Branding
    if type(branding) == "table"
        and branding.UseDefault ~= false
        and branding.UseAsOpenButtonIcon ~= false then
        local BaseEditOpenButton = window.EditOpenButton
        function window:EditOpenButton(openButtonConfig)
            local brandedOpenButton = copyConfig(openButtonConfig)
            brandedOpenButton.Icon = branding.OpenButtonIcon or branding.Image or BRAND_IMAGE_URL
            brandedOpenButton.OnlyIcon = true
            return BaseEditOpenButton(self, brandedOpenButton)
        end

        if window.OpenButtonMain then
            window.OpenButtonMain:SetIcon(branding.OpenButtonIcon or branding.Image or BRAND_IMAGE_URL)
        end
    end

    local BaseTab = window.Tab
    local startupTabSelected = false

    function window:Tab(tabConfig)
        tabConfig = tabConfig or {}
        local tab = BaseTab(self, tabConfig)

        local matchesStartupTab
        if type(startupTab) == "number" then
            matchesStartupTab = tab.Index == startupTab
        else
            matchesStartupTab = tostring(tabConfig.Title or "") == tostring(startupTab)
        end

        if not startupTabSelected and matchesStartupTab then
            startupTabSelected = true
            task.defer(function()
                if not self.Destroyed and tab and tab.Index then
                    self:SelectTab(tab.Index)
                end
            end)
        end

        return tab
    end

    renameRuntimeGui()
    forceOpenButtonPosition(window)
    task.defer(function()
        forceOpenButtonPosition(window)
    end)

    if MusicPlayer and config.MusicPlayer ~= false then
        pcall(function()
            local musicConfig = type(config.MusicPlayer) == "table" and config.MusicPlayer or nil
            MusicPlayer:Attach(window, musicConfig)
            if MusicPlayer.UI and MusicPlayer.UI.Repeat then
                local env = getgenv and getgenv() or _G
                if env then
                    env.repeatHover = MusicPlayer.UI.Repeat
                end
            end
        end)
    end

    return window
end

local BaseNotify = VantaUI.Notify
function VantaUI:Notify(config)
    config = config or {}
    if config.Title == nil then
        config.Title = "VantaUI"
    end
    forceNotificationPosition()
    local notification = BaseNotify(self, config)
    task.defer(forceNotificationPosition)
    return notification
end

function VantaUI:GetVantaThemes()
    return { "Salty Special", "Vanta Smoked", "Vanta Dark", "Vanta AMOLED", "Vanta Violet" }
end

function VantaUI:GetGuiThemes()
    return self:GetVantaThemes()
end

function VantaUI:GetInfo()
    return VantaUI.GuiInfo
end

return VantaUI