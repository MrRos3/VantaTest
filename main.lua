--[[
    VantaUI v0.3.8
    Roblox UI library by MrRos3.

    Public production loader.
    - Loads the current dist runtime directly.
    - Applies executor compatibility repairs when needed.
    - Restores Vanta branding and Salty Special defaults.
    - Notification open/close sounds are disabled by default.
]]

local PROJECT_VERSION = "0.3.8"
local CACHE_BUSTER = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local RUNTIME_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/dist/main.lua?v=" .. CACHE_BUSTER
local BRAND_IMAGE_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/assets/vanta-brand-v2-original.jpeg?v=original-valid-20261015"
local SALTY_SPECIAL_WALLPAPER_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/assets/crimson01-hq.jpg?v=crimson01-hq-native-20261021"
local SALTY_SPECIAL_WALLPAPER_TRANSPARENCY = 0.32

local function patchRuntime(source)
    local patched = source

    patched = patched:gsub(
        "type%s+ConfigType__DARKLUA_TYPE_[%w_]+%s*=%s*{.-}%s*local",
        "local",
        1
    )

    patched = patched:gsub(
        "local%s+([%a_][%w_]*)%s+%1%s*=",
        "local %1=",
        8
    )

    patched = patched:gsub(
        "([%a_][%w_%.]*)%s*%+=%s*([^;\n]+)",
        "%1=%1+(%2)"
    )

    return patched
end

local ok, source = pcall(function()
    return game:HttpGet(RUNTIME_URL)
end)
assert(ok and type(source) == "string" and #source > 0, "[VantaUI] Failed to download the current runtime")

local loader, loadError = loadstring(source)
if not loader then
    source = patchRuntime(source)
    loader, loadError = loadstring(source)
end
assert(loader, "[VantaUI] Failed to compile the current runtime: " .. tostring(loadError))

local runtimeOk, VantaUI = pcall(loader)
assert(runtimeOk and type(VantaUI) == "table", "[VantaUI] Current runtime returned an invalid value: " .. tostring(VantaUI))

VantaUI.RuntimeVersion = tostring(VantaUI.Version or PROJECT_VERSION)
VantaUI.Version = PROJECT_VERSION
VantaUI.Name = "VantaTest"
VantaUI.DefaultTheme = "Salty Special"
VantaUI.DefaultStartupTab = 1
VantaUI.TransparencyValue = 0.1

VantaUI.GuiInfo = {
    Name = "VantaTest",
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
    CacheKey = "v3",
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

if type(VantaUI.AddTheme) == "function" then
    for _, theme in ipairs(VantaThemes) do
        pcall(function()
            VantaUI:AddTheme(theme)
        end)

        local legacyName = LegacyThemeNames[theme.Name]
        if legacyName then
            local legacyTheme = {}
            for key, value in pairs(theme) do
                legacyTheme[key] = value
            end
            legacyTheme.Name = legacyName
            pcall(function()
                VantaUI:AddTheme(legacyTheme)
            end)
        end
    end
end

-- Notification sounds were intentionally removed from VantaUI production.
-- Keep all other interface sounds available.
if type(VantaUI.SetSoundForEvent) == "function" then
    pcall(function()
        VantaUI:SetSoundForEvent("Notification", false)
        VantaUI:SetSoundForEvent("NotificationClose", false)
    end)
end

-- Smooth GPU-friendly ambience above the SHARP, motionless Crimson01 painting.
-- Native UI particles avoid GIF frame jitter, pixelation and duplicate anime faces.
local RunService = game:GetService("RunService")
local function attachCrimsonAmbient(window)
    local main = window and window.UIElements and window.UIElements.Main
    local backdrop = main and main:FindFirstChild("Background")
    if not backdrop or backdrop:FindFirstChild("Crimson01Ambient") then return end

    local overlay = Instance.new("Frame")
    overlay.Name = "Crimson01Ambient"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.BackgroundTransparency = 1
    overlay.ClipsDescendants = true
    overlay.Active = false
    overlay.ZIndex = math.max(backdrop.ZIndex + 1, 2)
    overlay.Parent = backdrop

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = overlay

    local flecks = {}
    for i = 1, 18 do
        local petal = i <= 12
        local p = Instance.new("Frame")
        p.Name = petal and "Petal" or "Ember"
        p.BorderSizePixel = 0
        p.Active = false
        p.Size = UDim2.fromOffset(petal and (5 + i % 4 * 2) or (2 + i % 2), petal and (3 + i % 3) or 3)
        p.AnchorPoint = Vector2.new(0.5, 0.5)
        p.BackgroundColor3 = petal and Color3.fromRGB(207, 23, 46) or Color3.fromRGB(255, 75, 65)
        p.BackgroundTransparency = petal and 0.38 or 0.50
        p.ZIndex = overlay.ZIndex + 1
        p.Parent = overlay
        local round = Instance.new("UICorner")
        round.CornerRadius = UDim.new(1, 0)
        round.Parent = p
        flecks[i] = {
            item = p, petal = petal,
            phase = ((i * 29) % 47) / 47,
            x = ((i * 37) % 107) / 107,
            speed = 0.045 + i % 5 * 0.011,
            drift = (i % 2 == 0 and 1 or -1) * (0.075 + i % 4 * 0.021),
        }
    end

    local startTime = os.clock()
    local connection
    connection = RunService.RenderStepped:Connect(function()
        if window.Destroyed or not overlay.Parent then
            if connection then connection:Disconnect(); connection = nil end
            return
        end
        if window.Closed or not main.Visible then return end
        local t = os.clock() - startTime
        for _, f in ipairs(flecks) do
            local progress = (t * f.speed + f.phase) % 1
            local x = f.x + progress * f.drift + 0.012 * math.sin(t * 0.65 + f.phase * math.pi * 2)
            local y = -0.07 + progress * 1.14
            f.item.Position = UDim2.fromScale(x, y)
            f.item.Rotation = (t * (f.petal and 24 or 9) + f.phase * 360) % 360
            f.item.BackgroundTransparency = (f.petal and 0.28 or 0.42)
                + 0.42 * math.abs(2 * progress - 1)
        end
    end)
end

local ActiveWindows = setmetatable({}, { __mode = "k" })

local function applyThemeWallpaper(window, themeName)
    if not window or window.Destroyed or not window._UsesVantaThemeWallpaper then
        return
    end

    local transparency = SALTY_SPECIAL_WALLPAPER_TRANSPARENCY
    if type(window.SetBackgroundImageTransparency) == "function" then
        window:SetBackgroundImageTransparency(transparency)
    end
end

local BaseSetTheme = VantaUI.SetTheme
if type(BaseSetTheme) == "function" then
    function VantaUI:SetTheme(themeName)
        local theme = BaseSetTheme(self, themeName)
        if theme then
            for window in pairs(ActiveWindows) do
                applyThemeWallpaper(window, themeName)
            end
        end
        return theme
    end
end

local function renameRuntimeGui()
    if VantaUI.ScreenGui then
        VantaUI.ScreenGui.Name = "VantaTest"
    end
    if VantaUI.NotificationGui then
        VantaUI.NotificationGui.Name = "VantaTest/Notifications"
    end
    if VantaUI.DropdownGui then
        VantaUI.DropdownGui.Name = "VantaTest/Dropdowns"
    end
    if VantaUI.TooltipGui then
        VantaUI.TooltipGui.Name = "VantaTest/Tooltips"
    end
end

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
        branding.Folder = "VantaTest"
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
        openButton.Title = "Open VantaTest"
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

renameRuntimeGui()
if type(VantaUI.SetTheme) == "function" then
    VantaUI:SetTheme(VantaUI.DefaultTheme)
end

local BaseCreateWindow = VantaUI.CreateWindow
function VantaUI:CreateWindow(config)
    config = config or {}

    if config.Theme == nil then
        config.Theme = VantaUI.DefaultTheme
    end
    if config.Folder == nil then
        config.Folder = "VantaTest"
    end
    -- Retire legacy flat cards and the old search/sidebar presentation.
    config.NewElements = true
    config.HideSearchBar = true
    if config.Size == nil then
        config.Size = UDim2.fromOffset(620, 420)
    end

    applyDefaultBranding(config)

    local usesThemeWallpaper = config.Background == nil and config.AnimatedBackground == nil
    if usesThemeWallpaper then
        -- Draw the original full-resolution painting once. Never animate its pixels:
        -- shifting and upscaling a 224x126 GIF frame caused visible blur/shaking.
        config.Background = SALTY_SPECIAL_WALLPAPER_URL
        config.BackgroundImageTransparency = SALTY_SPECIAL_WALLPAPER_TRANSPARENCY
    end

    config.Topbar = config.Topbar or {}
    if config.Topbar.Height == nil then
        config.Topbar.Height = 44
    end
    -- Consistent compact three-dot topbar across existing script configs.
    config.Topbar.ButtonsType = "Mac"

    local startupTab = config.StartupTab
    if startupTab == nil then
        startupTab = VantaUI.DefaultStartupTab
    end

    local window = BaseCreateWindow(self, config)
    window._UsesVantaThemeWallpaper = usesThemeWallpaper
    ActiveWindows[window] = true
    applyThemeWallpaper(window, config.Theme)
    if usesThemeWallpaper then attachCrimsonAmbient(window) end

    local BaseTab = window.Tab
    local startupTabSelected = false

    if type(BaseTab) == "function" then
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
                    if not self.Destroyed and tab and tab.Index and type(self.SelectTab) == "function" then
                        self:SelectTab(tab.Index)
                    end
                end)
            end

            return tab
        end
    end

    renameRuntimeGui()
    return window
end

local BaseNotify = VantaUI.Notify
if type(BaseNotify) == "function" then
    function VantaUI:Notify(config)
        config = config or {}
        if config.Title == nil then
            config.Title = "VantaUI"
        end
        return BaseNotify(self, config)
    end
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
