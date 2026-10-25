--[[
    VantaUI v0.4.0
    Roblox UI library by MrRos3.

    Public production loader.
    - Loads the current dist runtime directly.
    - Applies executor compatibility repairs when needed.
    - Restores Vanta branding and Salty Special defaults.
    - Notification open/close sounds are disabled by default.
]]

local PROJECT_VERSION = "0.4.0"
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
        Accent = Color3.fromHex("#A1162F"),
        VisualAccent = Color3.fromHex("#FF3355"),
        Dialog = Color3.fromHex("#0A0709"),
        Outline = Color3.fromHex("#5A1824"),
        Text = Color3.fromHex("#FFFFFF"),
        Placeholder = Color3.fromHex("#9A9AA3"),
        Background = Color3.fromHex("#000000"),
        Button = Color3.fromHex("#4B1C2B"),
        Icon = Color3.fromHex("#E2DDE0"),
        Toggle = Color3.fromHex("#FF3355"),
        Slider = Color3.fromHex("#FF3355"),
        Checkbox = Color3.fromHex("#D23A57"),
        Primary = Color3.fromHex("#A1162F"),
        SliderIcon = Color3.fromHex("#F1E3E7"),
        PanelBackground = Color3.fromHex("#050406"),
        PanelBackgroundTransparency = 0.42,
        LabelBackground = Color3.fromHex("#0A080A"),
        LabelBackgroundTransparency = 0.08,
        ElementBackground = Color3.fromHex("#311522"),
        ElementBackgroundTransparency = 0.06,
        -- Let the Crimson01 artwork show through; selection fades away to the right.
        TabBackgroundActive = Color3.fromHex("#A1162F"),
        TabBackgroundActiveTransparency = 0.05,
        TabBackgroundHover = Color3.fromHex("#151013"),
        TabBackgroundHoverTransparency = 0.82,
        TabSelectionFade = Color3.fromHex("#A1162F"),
        TabTitle = Color3.fromHex("#D8D2D5"),
        TabTitleActive = Color3.fromHex("#FFFFFF"),
        TabTextTransparency = 0,
        TabTextTransparencyActive = 0,
    },
    {
        Name = "Vanta Smoked",
        VisualAccent = Color3.fromHex("#B5BAC7"),
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
        VisualAccent = Color3.fromHex("#879CFF"),
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
        VisualAccent = Color3.fromHex("#5DE7FF"),
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
        VisualAccent = Color3.fromHex("#B991FF"),
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
    {
        Name = "Vanta Void",
        Accent = Color3.fromHex("#07323A"),
        VisualAccent = Color3.fromHex("#5DE7FF"),
        Dialog = Color3.fromHex("#061116"),
        Outline = Color3.fromHex("#12616E"),
        Text = Color3.fromHex("#ECFBFF"),
        Placeholder = Color3.fromHex("#799BA5"),
        Background = Color3.fromHex("#000000"),
        Button = Color3.fromHex("#081B21"),
        Icon = Color3.fromHex("#9AEFFF"),
        Toggle = Color3.fromHex("#18AFC9"),
        Slider = Color3.fromHex("#38CDE8"),
        Checkbox = Color3.fromHex("#5DE7FF"),
        Primary = Color3.fromHex("#5DE7FF"),
        SliderIcon = Color3.fromHex("#C7F7FF"),
        PanelBackground = Color3.fromHex("#03090C"),
        PanelBackgroundTransparency = 0.32,
        LabelBackground = Color3.fromHex("#071014"),
        LabelBackgroundTransparency = 0.08,
        ElementBackground = Color3.fromHex("#09171B"),
        ElementBackgroundTransparency = 0.13,
        TabBackgroundActive = Color3.fromHex("#051D24"),
        TabBackgroundActiveTransparency = 0.92,
        TabSelectionFade = Color3.fromHex("#0C697C"),
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

-- Crimson01 ambient scene: a SHARP static wallpaper with lightweight native motion.
-- 50 layered particles: falling petals, rising embers, drifting glows and soft glints.
-- One throttled RenderStepped connection per window; never animate the wallpaper.
local RunService = game:GetService("RunService")
local CRIMSON_AMBIENT_FPS = 30
local VisualDefaults = {Intensity=0.8,Density=1,ReduceMotion=false}
if VantaUI.Creator then VantaUI.Creator.PremiumReduceMotion=false end
local THEME_ACCENTS = {
    ["Salty Special"]=Color3.fromHex("#FF3355"),
    ["Vanta Smoked"]=Color3.fromHex("#B5BAC7"),
    ["Vanta Dark"]=Color3.fromHex("#879CFF"),
    ["Vanta AMOLED"]=Color3.fromHex("#5DE7FF"),
    ["Vanta Violet"]=Color3.fromHex("#B991FF"),
    ["Vanta Void"]=Color3.fromHex("#5DE7FF"),
}
local function themeAccent(name)
    return THEME_ACCENTS[name] or THEME_ACCENTS["Salty Special"]
end
-- Five-stop chrome: only the narrow ice-white band and its faint tail
-- have contrast. Theme changes touch the tail, never the steel base.
local function visualGradient(accent)
    local steel=Color3.fromRGB(35,37,45) -- #23252D
    local ice=Color3.fromRGB(234,246,255) -- #EAF6FF
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0.00,steel),
        ColorSequenceKeypoint.new(0.44,steel),
        ColorSequenceKeypoint.new(0.50,ice),
        ColorSequenceKeypoint.new(0.56,steel:Lerp(accent,0.14)),
        ColorSequenceKeypoint.new(1.00,steel),
    })
end
-- White is the resting title color. Only a narrow red/white band crosses
-- the text during each existing 1.4-second shine, then parks offscreen.
local function premiumTitleGradient(red)
    local white=Color3.fromRGB(255,255,255)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0.00,white),
        ColorSequenceKeypoint.new(0.39,white),
        ColorSequenceKeypoint.new(0.45,red),
        ColorSequenceKeypoint.new(0.50,white),
        ColorSequenceKeypoint.new(0.55,red),
        ColorSequenceKeypoint.new(0.61,white),
        ColorSequenceKeypoint.new(1.00,white),
    })
end
local CRIMSON_PARTICLE_COUNTS = {
    Petal = 18,
    Ember = 17,
    Mote = 10,
    Glint = 5,
}

local function attachCrimsonAmbient(window)
    local main = window and window.UIElements and window.UIElements.Main
    local backdrop = main and main:FindFirstChild("Background")
    if not backdrop then return nil end
    local existing = backdrop:FindFirstChild("Crimson01Ambient")
    if existing then return existing end

    local overlay = Instance.new("Frame")
    overlay.Name = "Crimson01Ambient"
    overlay.Size = UDim2.fromScale(1, 1)
    overlay.Position = UDim2.fromScale(0, 0)
    overlay.BackgroundTransparency = 1
    overlay.BorderSizePixel = 0
    overlay.ClipsDescendants = true
    overlay.Active = false
    -- The window shrinks for 0.9s when minimized; all ambience hides instantly.
    overlay.Visible = not window.Closed and main.Visible
    overlay.ZIndex = math.max(backdrop.ZIndex + 1, 2)
    overlay.Parent = backdrop

    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, 16)
    corner.Parent = overlay

    local ambientLight = Instance.new("Frame")
    ambientLight.Name="CrimsonBreath"
    ambientLight.Size=UDim2.fromScale(0.68,0.84)
    ambientLight.AnchorPoint=Vector2.new(0.5,0.5)
    ambientLight.Position=UDim2.fromScale(0.58,0.48)
    ambientLight.BackgroundColor3=themeAccent(window._VantaTheme)
    ambientLight.BackgroundTransparency=0.88
    ambientLight.BorderSizePixel=0
    ambientLight.Active=false
    ambientLight.ZIndex=overlay.ZIndex
    ambientLight.Parent=overlay
    local breathingMask=Instance.new("UIGradient")
    breathingMask.Name="BreathingMask"
    breathingMask.Transparency=NumberSequence.new({
        NumberSequenceKeypoint.new(0,1),
        NumberSequenceKeypoint.new(0.25,0.9),
        NumberSequenceKeypoint.new(0.5,0.55),
        NumberSequenceKeypoint.new(0.75,0.9),
        NumberSequenceKeypoint.new(1,1),
    })
    breathingMask.Parent=ambientLight
    window._VantaAmbientLight=ambientLight
    local particles = {}
    window._VantaAmbientParticles=particles
    local slowFrames=0
    local elapsed = 0
    local frameAccumulator = 0

    -- Repeatable, independent seeds avoid bursts of particles starting together.
    local function seed(index, salt)
        return ((index * 83 + salt * 59 + (index * salt * 13)) % 257) / 257
    end

    local function spawn(kind, index)
        local salt = kind == "Petal" and 1 or kind == "Ember" and 2
            or kind == "Mote" and 3 or 4
        local a, b, c = seed(index, salt), seed(index + 7, salt + 4),
            seed(index + 23, salt + 9)
        local particle = Instance.new("Frame")
        particle.Name = kind
        particle.BackgroundTransparency = 1
        particle.BorderSizePixel = 0
        particle.Active = false
        particle.AnchorPoint = Vector2.new(0.5, 0.5)
        particle.ZIndex = overlay.ZIndex + (kind == "Petal" and 2 or 1)
        particle.Parent = overlay

        local p = {
            item = particle, kind = kind, index = index,
            phase = b, x = -0.035 + 1.07 * a, y = c,
            drift = ((index % 2 == 0) and 1 or -1) * (0.07 + b * 0.16),
            sway = 0.007 + 0.016 * c,
            rate = 0.02 + 0.024 * b,
            rotation = 10 + 24 * a,
            pulse = 1.2 + 2.2 * b,
        }

        if kind == "Petal" then
            -- Different depths: near petals are larger, brighter and a little faster.
            local near = index % 4 == 0
            local w = near and (10 + index % 3) or (4 + index % 5)
            local h = near and (6 + index % 3) or (3 + index % 3)
            particle.Size = UDim2.fromOffset(w, h)
            particle.BackgroundColor3 = near
                and Color3.fromRGB(213, 38, 63) or Color3.fromRGB(164, 24, 47)
            p.alpha = near and 0.13 or 0.38
            p.rate = near and (0.047 + b * 0.028) or (0.028 + b * 0.020)
            p.sway = 0.012 + c * 0.027
            local shape = Instance.new("UICorner")
            shape.CornerRadius = UDim.new(1, 0)
            shape.Parent = particle
            local gradient = Instance.new("UIGradient")
            gradient.Rotation = 36 + 62 * a
            gradient.Color = ColorSequence.new(
                Color3.fromRGB(248, 83, 96),
                Color3.fromRGB(99, 10, 31)
            )
            gradient.Parent = particle
        elseif kind == "Ember" then
            local bright = index % 3 == 0
            particle.Size = UDim2.fromOffset(bright and 3 or 2, bright and 4 or 3)
            particle.BackgroundColor3 = bright
                and Color3.fromRGB(255, 112, 75) or Color3.fromRGB(228, 46, 65)
            p.alpha = bright and 0.10 or 0.33
            p.rate = 0.065 + b * 0.060
            p.sway = 0.004 + c * 0.015
            local shape = Instance.new("UICorner")
            shape.CornerRadius = UDim.new(1, 0)
            shape.Parent = particle
        elseif kind == "Mote" then
            -- A low-opacity halo surrounding a small glowing center.
            particle.Size = UDim2.fromOffset(10 + index % 5 * 3, 10 + index % 5 * 3)
            particle.BackgroundColor3 = Color3.fromRGB(182, 26, 51)
            p.alpha = 0.87
            p.rate = 0.10 + b * 0.25
            p.sway = 0.018 + c * 0.035
            local outerRound = Instance.new("UICorner")
            outerRound.CornerRadius = UDim.new(1, 0)
            outerRound.Parent = particle
            local core = Instance.new("Frame")
            core.Name = "GlowCore"
            core.AnchorPoint = Vector2.new(0.5, 0.5)
            core.Position = UDim2.fromScale(0.5, 0.5)
            core.Size = UDim2.fromScale(0.23, 0.23)
            core.BorderSizePixel = 0
            core.BackgroundTransparency = 0.42
            core.BackgroundColor3 = Color3.fromRGB(255, 90, 100)
            core.Active = false
            core.ZIndex = particle.ZIndex
            core.Parent = particle
            local coreRound = Instance.new("UICorner")
            coreRound.CornerRadius = UDim.new(1, 0)
            coreRound.Parent = core
            p.core = core
        else
            -- Tiny glints pulse in place instead of streaking across the painting.
            particle.Size = UDim2.fromOffset(2 + index % 2, 2 + index % 2)
            particle.BackgroundColor3 = Color3.fromRGB(255, 129, 122)
            p.alpha = 0.59
            p.rate = 0.2 + b * 0.3
            local shape = Instance.new("UICorner")
            shape.CornerRadius = UDim.new(1, 0)
            shape.Parent = particle
        end

        -- Scatter the initial frame; no stacked particles at the origin.
        particle.Position = UDim2.fromScale(p.x, p.y)
        particles[#particles + 1] = p
    end

    -- Create a fixed pool once. No per-frame instance creation, no UI input capture.
    for _, kind in ipairs({ "Petal", "Ember", "Mote", "Glint" }) do
        for index = 1, CRIMSON_PARTICLE_COUNTS[kind] do
            spawn(kind, index)
        end
    end

    local connection
    connection = RunService.RenderStepped:Connect(function(dt)
        if window.Destroyed or not overlay.Parent then
            if connection then connection:Disconnect(); connection = nil end
            if overlay.Parent then overlay:Destroy() end
            return
        end
        local settings=window._VantaVisuals or VisualDefaults
        if window.Closed or not main.Visible or settings.ReduceMotion or window._VantaLowFPS or settings.Density<=0 then
            overlay.Visible = false
            frameAccumulator = 0
            return
        end
        overlay.Visible = true
        if tonumber(dt) and dt>0.08 then
            slowFrames=math.min(40,slowFrames+1)
        else
            slowFrames=math.max(0,slowFrames-1)
        end
        local lowFPS=slowFrames>=24
        if lowFPS~=window._VantaLowFPS then
            window._VantaLowFPS=lowFPS
            if window._VantaPremium then window._VantaPremium:Refresh() end
            if lowFPS then
                local creator=VantaUI.Creator
                for _,desc in ipairs((window.UIElements.Main):GetDescendants()) do
                    if desc.Name=="PremiumProgressSweep" then
                        desc.Enabled=false
                        local t=creator and creator.PremiumSweeps and creator.PremiumSweeps[desc]
                        if t then t:Cancel() end
                    end
                end
            end
        end
        -- Hold particles in place during minimize; never jump ahead on reopening.
        frameAccumulator = frameAccumulator + math.min(tonumber(dt) or 1 / 60, 0.075)
        if frameAccumulator < (1 / CRIMSON_AMBIENT_FPS) then return end
        elapsed = elapsed + frameAccumulator
        frameAccumulator = 0
        ambientLight.BackgroundTransparency=0.89-0.115*settings.Intensity*
            (0.5+0.5*math.sin(elapsed*0.75))
        for _, p in ipairs(particles) do
            p.item.Visible=p.index<=math.ceil(CRIMSON_PARTICLE_COUNTS[p.kind]*settings.Density)
            local t = elapsed
            local positionX, positionY, alpha
            if p.kind == "Petal" then
                local progress = (t * p.rate + p.phase) % 1
                positionX = p.x + p.drift * progress
                    + p.sway * math.sin(t * 0.85 + p.phase * 9)
                positionY = -0.10 + 1.19 * progress
                -- Fade at the very top and bottom to prevent popping.
                alpha = math.min(0.94, p.alpha +
                    0.25 * math.abs(2 * progress - 1) +
                    0.06 * math.sin(t * p.pulse + p.phase * 11))
                p.item.Rotation = (t * p.rotation + p.phase * 360) % 360
            elseif p.kind == "Ember" then
                local progress = (t * p.rate + p.phase) % 1
                positionX = p.x + p.drift * progress * 0.55
                    + p.sway * math.sin(t * 1.8 + p.phase * 8)
                positionY = 1.08 - 1.18 * progress
                alpha = math.min(0.94, p.alpha +
                    0.33 * math.abs(2 * progress - 1) +
                    0.06 * math.sin(t * p.pulse + p.phase * 7))
                p.item.Rotation = 12 * math.sin(t * 1.3 + p.phase * 8)
            elseif p.kind == "Mote" then
                positionX = p.x + p.sway * math.sin(t * p.rate + p.phase * 6)
                positionY = p.y + (p.sway * 0.65)
                    * math.cos(t * p.rate * 0.8 + p.phase * 8)
                local pulse = 0.5 + 0.5 * math.sin(t * p.pulse + p.phase * 11)
                alpha = 0.94 - 0.10 * pulse
                p.core.BackgroundTransparency = 0.73 - 0.37 * pulse
            else
                positionX = p.x + 0.009 * math.sin(t * p.rate + p.phase * 13)
                positionY = p.y + 0.009 * math.cos(t * p.rate + p.phase * 11)
                local pulse = math.max(0, math.sin(t * p.pulse + p.phase * 16))
                alpha = 0.96 - 0.43 * pulse * pulse
            end
            if p.kind=="Ember" and p.index==3 then
                local streak=elapsed%19
                if streak<0.4 then
                    p.item.Size=UDim2.fromOffset(2,17)
                    p.item.Rotation=-42
                    positionX=0.22+streak*0.75
                    positionY=0.7-streak*0.82
                    alpha=0.2
                else
                    p.item.Size=UDim2.fromOffset(3,4)
                end
            end
            p.item.Position = UDim2.fromScale(positionX, positionY)
            p.item.BackgroundTransparency = math.clamp(1-(1-alpha)*settings.Intensity,0.05,0.99)
        end
    end)
    return overlay
end


-- Shared premium window decorations. Every animation is a TweenService tween,
-- not another per-frame connection; ambient owns the only 30 FPS visual loop.
local VfxTweenService=game:GetService("TweenService")
local function attachPremiumWindow(window,theme)
    local root=window and window.UIElements and window.UIElements.Main
    local body=root and root:FindFirstChild("Main")
    local topbar=body and body:FindFirstChild("Topbar")
    if not root or not topbar then return nil end
    local settings=window._VantaVisuals
    local alive=true
    local active=setmetatable({},{__mode="k"})
    local function add(class,name,parent,props)
        local obj=Instance.new(class)
        obj.Name=name
        for k,v in pairs(props or {}) do obj[k]=v end
        if obj:IsA("GuiObject") then obj.Active=false end
        obj.Parent=parent
        return obj
    end
    local function play(obj,duration,goal,easing)
        local t=VfxTweenService:Create(obj,
            TweenInfo.new(duration,easing or Enum.EasingStyle.Sine,Enum.EasingDirection.Out),goal)
        if active[obj] then active[obj]:Cancel() end
        active[obj]=t
        t:Play()
        return t
    end
    -- Native squircle-outline image follows the window Background shape.
    -- It replaces both the square-corner UIStroke and detached halo.
    local edge=VantaUI.Creator.NewRoundFrame(window.UICorner,"Squircle-Outline",{
        Name="PremiumWindowOutline",Size=UDim2.fromScale(1,1),
        Parent=root,ZIndex=98,ImageColor3=Color3.fromRGB(255,255,255),
        ImageTransparency=0.20,Active=false,
    })
    local edgeGradient=add("UIGradient","PremiumEdgeMotion",edge,{
        Color=visualGradient(themeAccent(theme)),Rotation=0,
    })
    -- One low-opacity black squircle behind the window, with no red aura.
    local shadow=VantaUI.Creator.NewRoundFrame(window.UICorner+12,"Squircle",{
        Name="PremiumBlackShadow",Parent=root,
        Size=UDim2.new(1,28,1,28),Position=UDim2.fromScale(0.5,0.5),
        AnchorPoint=Vector2.new(0.5,0.5),Active=false,ZIndex=0,
        ImageTransparency=0.85,ImageColor3=Color3.fromRGB(0,0,0),
    })
    local scale=add("UIScale","PremiumMotionScale",root,{Scale=1})
    local glass=add("Frame","PremiumTopbarGlass",topbar,{
        Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.fromRGB(8,5,10),
        BackgroundTransparency=0.35,BorderSizePixel=0,ZIndex=topbar.ZIndex-1,
    })
    add("UIGradient","PremiumGlassGradient",glass,{
        Rotation=90,Transparency=NumberSequence.new({
            NumberSequenceKeypoint.new(0,0.17),
            NumberSequenceKeypoint.new(1,0.90),
        }),
    })
    local wallpaper=root:FindFirstChild("Background")
    local premiumClip,grade
    if wallpaper then
        -- Confine decorations to their own rounded clip; the original
        -- Background and its overhanging resize handle remain untouched.
        premiumClip=add("Frame","PremiumWallpaperClip",wallpaper,{
            Size=UDim2.fromScale(1,1),BackgroundTransparency=1,
            BorderSizePixel=0,ClipsDescendants=true,ZIndex=wallpaper.ZIndex+1,
        })
        add("UICorner","PremiumClipCorner",premiumClip,{
            CornerRadius=UDim.new(0,window.UICorner),
        })
        local vignette=add("Frame","PremiumWallpaperVignette",premiumClip,{
            Size=UDim2.fromScale(1,1),BackgroundColor3=Color3.new(0,0,0),
            BackgroundTransparency=0,BorderSizePixel=0,ZIndex=premiumClip.ZIndex,
        })
        add("UICorner","PremiumVignetteCorner",vignette,{
            CornerRadius=UDim.new(0,window.UICorner),
        })
        add("UIGradient","PremiumVerticalVignette",vignette,{
            Rotation=90,Transparency=NumberSequence.new({
                NumberSequenceKeypoint.new(0,0.50),
                NumberSequenceKeypoint.new(0.5,0.89),
                NumberSequenceKeypoint.new(1,0.19),
            }),
        })
        grade=VantaUI.Creator.NewRoundFrame(window.UICorner,"Squircle",{
            Name="PremiumCrimsonGrade",Parent=premiumClip,
            Size=UDim2.fromScale(1,1),ImageColor3=themeAccent(theme),
            ImageTransparency=0.62,Active=false,ZIndex=premiumClip.ZIndex+1,
        })
        add("UIGradient","PremiumGradeFalloff",grade,{
            Rotation=0,
            Transparency=NumberSequence.new({
                NumberSequenceKeypoint.new(0,1),
                NumberSequenceKeypoint.new(0.26,0.84),
                NumberSequenceKeypoint.new(0.53,0.53),
                NumberSequenceKeypoint.new(0.82,0.90),
                NumberSequenceKeypoint.new(1,1),
            }),
        })
        local scrim=add("Frame","PremiumSidebarScrim",premiumClip,{
            Position=UDim2.fromOffset(0,window.Topbar.Height or 44),
            Size=UDim2.new(0,(window.SideBarWidth or 200)+40,1,-(window.Topbar.Height or 44)),
            BackgroundColor3=Color3.fromRGB(0,0,0),
            BackgroundTransparency=0,BorderSizePixel=0,
            ZIndex=premiumClip.ZIndex+2,
        })
        add("UICorner","PremiumScrimCorner",scrim,{
            CornerRadius=UDim.new(0,window.UICorner),
        })
        add("UIGradient","SidebarContrastFade",scrim,{
            Rotation=0,
            Transparency=NumberSequence.new({
                NumberSequenceKeypoint.new(0.00,0.25),
                NumberSequenceKeypoint.new(0.25,0.62),
                NumberSequenceKeypoint.new(0.50,0.85),
                NumberSequenceKeypoint.new(0.75,0.97),
                NumberSequenceKeypoint.new(1.00,1.00),
            }),
        })
    end
    -- One static, rounded 28px fade over the scrolling content viewport.
    -- Existing tab containers and scrolling remain completely interactive.
    local contentBottomFade
    local contentArea=window.UIElements and window.UIElements.MainBar
    if contentArea then
        contentBottomFade=VantaUI.Creator.NewRoundFrame(window.UICorner,"Squircle",{
            Name="PremiumContentBottomFade",Parent=contentArea,
            Size=UDim2.new(1,0,0,28),Position=UDim2.new(0,0,1,-28),
            ImageColor3=Color3.fromRGB(0,0,0),ImageTransparency=0,
            ZIndex=contentArea.ZIndex+15,Active=false,
        })
        add("UIGradient","PremiumBottomDissolve",contentBottomFade,{
            Rotation=90,
            Transparency=NumberSequence.new({
                NumberSequenceKeypoint.new(0.00,1.00),
                NumberSequenceKeypoint.new(0.35,0.92),
                NumberSequenceKeypoint.new(0.70,0.50),
                NumberSequenceKeypoint.new(1.00,0.08),
            }),
        })
    end
    local title
    -- Left.Title is a Frame; prefer its actual TextLabel child.
    local left=topbar:FindFirstChild("Left")
    local holder=left and left:FindFirstChild("Title")
    local candidate=holder and holder:FindFirstChildWhichIsA("TextLabel")
    if not candidate then
        candidate=holder and holder:FindFirstChildWhichIsA("TextLabel",true)
    end
    if candidate and candidate:IsA("TextLabel") then title=candidate end
    local nameGradient
    local titleStroke
    if title then
        local fontOK=pcall(function()
            title.FontFace=Font.new("rbxasset://fonts/families/Michroma.json")
        end)
        if not fontOK then pcall(function() title.Font=Enum.Font.Michroma end) end
        title.TextSize=14
        title.TextScaled=false
        title.TextColor3=Color3.fromRGB(255,255,255)
        title.TextStrokeTransparency=1
        title.ZIndex=math.max(title.ZIndex,glass.ZIndex+2)
        titleStroke=add("UIStroke","PremiumTitleOutline",title,{
            Color=Color3.fromRGB(26,0,8),Thickness=1,Transparency=0,
            ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual,
        })
        nameGradient=add("UIGradient","PremiumTitleShine",title,{
            Color=premiumTitleGradient(themeAccent(theme)),
            Offset=Vector2.new(-1,0),Rotation=0,
        })
    end
    local rotationTween,shineTween
    local function refresh()
        if not alive then return end
        if rotationTween then rotationTween:Cancel();rotationTween=nil end
        if shineTween then shineTween:Cancel();shineTween=nil end
        if nameGradient then nameGradient.Offset=Vector2.new(-1,0) end
        local motion=not settings.ReduceMotion and not window._VantaLowFPS
            and settings.Intensity>0
        edge.ImageTransparency=0.20+0.10*(1-settings.Intensity)
        -- Shadow is static, so reduced motion never makes it disappear.
        shadow.ImageTransparency=0.85
        if grade then grade.ImageTransparency=0.84-0.30*settings.Intensity end
        if motion then
            rotationTween=VfxTweenService:Create(edgeGradient,
                TweenInfo.new(6,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,-1,false),
                {Rotation=360})
            edgeGradient.Offset=Vector2.new(0,0)
            edgeGradient.Rotation=0
            rotationTween:Play()
        else
            -- Park the narrow ice-white highlight toward the top-left corner.
            edgeGradient.Rotation=45
            edgeGradient.Offset=Vector2.new(-0.35,0)
            if nameGradient then nameGradient.Offset=Vector2.new(-1,0) end
        end
    end
    local controller={}
    function controller:Refresh() refresh() end
    function controller:UpdateTheme(nextTheme)
        local tint=themeAccent(nextTheme)
        -- Steel and ice-white never recolor; only the subtle tail picks up tint.
        edgeGradient.Color=visualGradient(tint)
        if grade then grade.ImageColor3=tint end
        if nameGradient then
            title.TextColor3=Color3.fromRGB(255,255,255)
            nameGradient.Color=premiumTitleGradient(tint)
        end
        if window._VantaAmbientLight then window._VantaAmbientLight.BackgroundColor3=tint end
        for _,p in ipairs(window._VantaAmbientParticles or {}) do
            if p.item.Parent then
                p.item.BackgroundColor3=tint
                if p.core then p.core.BackgroundColor3=tint end
            end
        end
        refresh()
    end
    function controller:Cleanup()
        if not alive then return end
        alive=false
        if rotationTween then rotationTween:Cancel() end
        if shineTween then shineTween:Cancel() end
        for _,t in pairs(active) do pcall(function() t:Cancel() end) end
        for _,object in ipairs({edge,shadow,glass,scale,premiumClip,contentBottomFade}) do
            if object and object.Parent then object:Destroy() end
        end
        if nameGradient and nameGradient.Parent then nameGradient:Destroy() end
        if titleStroke and titleStroke.Parent then titleStroke:Destroy() end
    end
    task.spawn(function()
        while alive and not window.Destroyed do
            if nameGradient and not settings.ReduceMotion and not window._VantaLowFPS and not window.Closed then
                nameGradient.Offset=Vector2.new(-1,0)
                shineTween=VfxTweenService:Create(nameGradient,
                    TweenInfo.new(1.4,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
                    {Offset=Vector2.new(1,0)})
                shineTween:Play()
                task.wait(1.4)
                if shineTween then shineTween:Cancel();shineTween=nil end
                if alive then nameGradient.Offset=Vector2.new(-1,0) end
                task.wait(2.5)
            else task.wait(0.3) end
        end
    end)
    local oldOpen,oldClose,oldDestroy=window.Open,window.Close,window.Destroy
    function window:Open(...)
        local result=oldOpen(self,...)
        if alive then
            if not settings.ReduceMotion and not window._VantaLowFPS then
                scale.Scale=0.95
                play(scale,0.32,{Scale=1.023},Enum.EasingStyle.Back)
                task.delay(0.33,function()
                    if alive and not window.Closed then
                        play(scale,0.16,{Scale=1},Enum.EasingStyle.Sine)
                    end
                end)
            else scale.Scale=1 end
            refresh()
        end
        return result
    end
    function window:Close(...)
        if shineTween then shineTween:Cancel();shineTween=nil end
        if nameGradient then nameGradient.Offset=Vector2.new(-1,0) end
        if alive and not settings.ReduceMotion then
            play(scale,0.22,{Scale=0.96},Enum.EasingStyle.Sine)
        end
        return oldClose(self,...)
    end
    function window:Destroy(...)
        controller:Cleanup()
        return oldDestroy(self,...)
    end
    window._VantaPremium=controller
    controller:UpdateTheme(theme)
    if not settings.ReduceMotion then
        scale.Scale=0.96
        play(scale,0.38,{Scale=1},Enum.EasingStyle.Back)
    end
    return controller
end

local ActiveWindows = setmetatable({}, { __mode = "k" })
function VantaUI:SetVisualIntensity(value)
    VisualDefaults.Intensity=math.clamp(tonumber(value) or 0.8,0,1)
    for window in pairs(ActiveWindows) do
        window._VantaVisuals.Intensity=VisualDefaults.Intensity
        if window._VantaPremium then window._VantaPremium:Refresh() end
    end
end
function VantaUI:SetParticleDensity(value)
    VisualDefaults.Density=math.clamp(tonumber(value) or 1,0,1)
    for window in pairs(ActiveWindows) do window._VantaVisuals.Density=VisualDefaults.Density end
end
function VantaUI:SetReduceMotion(value)
    VisualDefaults.ReduceMotion=value==true
    if VantaUI.Creator then
        VantaUI.Creator.PremiumReduceMotion=VisualDefaults.ReduceMotion
        for gradient,t in pairs(VantaUI.Creator.PremiumSweeps or {}) do
            if VisualDefaults.ReduceMotion then
                t:Cancel()
                if gradient.Parent then gradient.Enabled=false end
            else
                if gradient.Parent then
                    gradient.Enabled=true
                    t:Play()
                end
            end
        end
    end
    for window in pairs(ActiveWindows) do
        window._VantaVisuals.ReduceMotion=VisualDefaults.ReduceMotion
        if window._VantaPremium then window._VantaPremium:Refresh() end
        local root=window.UIElements and window.UIElements.Main
        if root then
            for _,desc in ipairs(root:GetDescendants()) do
                if desc.Name=="PremiumProgressSweep" and desc:IsA("UIGradient") then
                    desc.Enabled=not VisualDefaults.ReduceMotion
                end
            end
        end
    end
end
function VantaUI:GetVisualSettings()
    return {Intensity=VisualDefaults.Intensity,Density=VisualDefaults.Density,
        ReduceMotion=VisualDefaults.ReduceMotion}
end

local function applyThemeWallpaper(window, themeName)
    if not window or window.Destroyed or not window._UsesVantaThemeWallpaper then
        return
    end

    local transparency = themeName=="Salty Special"
        and SALTY_SPECIAL_WALLPAPER_TRANSPARENCY
        or themeName=="Vanta Void" and 0.68 or 0.50
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
                window._VantaTheme=themeName
                if window._VantaPremium then window._VantaPremium:UpdateTheme(themeName) end
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
    local visualSettings=type(config.Visuals)=="table" and config.Visuals or {}
    window._VantaVisuals={
        Intensity=math.clamp(tonumber(visualSettings.Intensity) or VisualDefaults.Intensity,0,1),
        Density=math.clamp(tonumber(visualSettings.Density) or VisualDefaults.Density,0,1),
        ReduceMotion=visualSettings.ReduceMotion==nil and VisualDefaults.ReduceMotion
            or visualSettings.ReduceMotion==true,
    }
    window._VantaTheme=config.Theme
    window._VantaLowFPS=false
    window._UsesVantaThemeWallpaper = usesThemeWallpaper
    ActiveWindows[window] = true
    applyThemeWallpaper(window, config.Theme)
    if usesThemeWallpaper then
        local ambient = attachCrimsonAmbient(window)
        local closeOriginal = window.Close
        if ambient and type(closeOriginal) == "function" then
            -- Hide immediately on Minimize, Toggle, Close and Destroy.
            -- The library's 0.9s shrink tween must never leave detached-looking petals.
            function window:Close(...)
                ambient.Visible = false
                return closeOriginal(self, ...)
            end
        end
    end

    attachPremiumWindow(window,config.Theme)
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
    return { "Salty Special", "Vanta Smoked", "Vanta Dark", "Vanta AMOLED", "Vanta Violet", "Vanta Void" }
end

function VantaUI:GetGuiThemes()
    return self:GetVantaThemes()
end

function VantaUI:GetInfo()
    return VantaUI.GuiInfo
end

return VantaUI
