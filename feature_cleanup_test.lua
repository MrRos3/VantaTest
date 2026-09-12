-- VantaTest feature cleanup tester
-- Every gameplay/visual change made here is registered with the VantaTest
-- cleanup manager so pressing the red X restores the exact original state.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local Lighting = game:GetService("Lighting")
local Workspace = game:GetService("Workspace")

local LocalPlayer = Players.LocalPlayer
local Camera = Workspace.CurrentCamera

local cacheBuster = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local VantaUI = loadstring(game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaTest/main/main.lua?v=" .. cacheBuster
))()

local Window = VantaUI:CreateWindow({
    Title = "Vanta Cleanup Lab",
    Icon = VantaUI.Brand and VantaUI.Brand.Image or "flask-conical",
    Theme = "Salty Special",
    HideSearchBar = false,
    IgnoreAlerts = true,
    Branding = {
        Name = "VANTA",
        Image = VantaUI.Brand and VantaUI.Brand.Image,
        Folder = "VantaUI",
        Intro = false,
    },
    OpenButton = {
        Title = "Open Cleanup Lab",
        Enabled = true,
        Draggable = true,
        OnlyMobile = false,
        OnlyIcon = true,
        CornerRadius = UDim.new(0, 11),
        StrokeThickness = 2,
        ImageZoom = 1,
        Color = ColorSequence.new(Color3.new(0, 0, 0), Color3.new(0, 0, 0)),
    },
})

Window:Tag({
    Title = "CLEANUP TEST",
    Icon = "rotate-ccw",
    Color = Color3.fromHex("#151116"),
    Border = true,
})

local Movement = Window:Tab({
    Title = "Movement",
    Icon = "gauge",
})

local Visuals = Window:Tab({
    Title = "Visuals",
    Icon = "eye",
})

local Test = Window:Tab({
    Title = "Test",
    Icon = "flask-conical",
})

local featureState = {
    WalkSpeed = nil,
    JumpPower = nil,
    Gravity = nil,
    Fullbright = false,
    Rainbow = false,
}

local trackedHumanoids = setmetatable({}, { __mode = "k" })
local currentHighlight = nil
local rainbowConnection = nil

local originalCameraFOV = Camera and Window:TrackProperty(Camera, "FieldOfView") or nil
local originalGravity = Window:TrackProperty(Workspace, "Gravity")

local originalLighting = {
    Brightness = Window:TrackProperty(Lighting, "Brightness"),
    ClockTime = Window:TrackProperty(Lighting, "ClockTime"),
    FogEnd = Window:TrackProperty(Lighting, "FogEnd"),
    GlobalShadows = Window:TrackProperty(Lighting, "GlobalShadows"),
    Ambient = Window:TrackProperty(Lighting, "Ambient"),
    OutdoorAmbient = Window:TrackProperty(Lighting, "OutdoorAmbient"),
}

local function getHumanoid(character)
    character = character or LocalPlayer.Character
    return character and character:FindFirstChildOfClass("Humanoid") or nil
end

local function trackHumanoid(humanoid)
    if not humanoid or trackedHumanoids[humanoid] then
        return
    end

    trackedHumanoids[humanoid] = true
    Window:TrackProperties(humanoid, {
        "WalkSpeed",
        "JumpPower",
        "JumpHeight",
        "UseJumpPower",
    })
end

local function applyMovementToHumanoid(humanoid)
    if not humanoid then
        return
    end

    trackHumanoid(humanoid)

    if featureState.WalkSpeed ~= nil then
        humanoid.WalkSpeed = featureState.WalkSpeed
    end

    if featureState.JumpPower ~= nil then
        humanoid.UseJumpPower = true
        humanoid.JumpPower = featureState.JumpPower
    end
end

local function destroyRainbow()
    if rainbowConnection then
        rainbowConnection:Disconnect()
        rainbowConnection = nil
    end

    if currentHighlight then
        currentHighlight:Destroy()
        currentHighlight = nil
    end
end

local function createRainbow(character)
    destroyRainbow()

    if not featureState.Rainbow or not character then
        return
    end

    local highlight = Instance.new("Highlight")
    highlight.Name = "VantaCleanupTestHighlight"
    highlight.DepthMode = Enum.HighlightDepthMode.AlwaysOnTop
    highlight.FillTransparency = 0.45
    highlight.OutlineTransparency = 0
    highlight.Parent = character

    currentHighlight = highlight
    Window:TrackInstance(highlight)

    local started = os.clock()
    rainbowConnection = RunService.RenderStepped:Connect(function()
        if not highlight.Parent then
            return
        end

        local hue = ((os.clock() - started) * 0.18) % 1
        local color = Color3.fromHSV(hue, 0.85, 1)
        highlight.FillColor = color
        highlight.OutlineColor = color:Lerp(Color3.new(1, 1, 1), 0.32)
    end)
    Window:TrackConnection(rainbowConnection)
end

local function applyFullbright(enabled)
    featureState.Fullbright = enabled

    if enabled then
        Lighting.Brightness = 3
        Lighting.ClockTime = 14
        Lighting.FogEnd = 100000
        Lighting.GlobalShadows = false
        Lighting.Ambient = Color3.fromRGB(255, 255, 255)
        Lighting.OutdoorAmbient = Color3.fromRGB(200, 200, 200)
    else
        for propertyName, originalValue in pairs(originalLighting) do
            if originalValue ~= nil then
                pcall(function()
                    Lighting[propertyName] = originalValue
                end)
            end
        end
    end
end

local initialHumanoid = getHumanoid()
if initialHumanoid then
    trackHumanoid(initialHumanoid)
end

local characterConnection = LocalPlayer.CharacterAdded:Connect(function(character)
    local humanoid = character:WaitForChild("Humanoid", 8)
    if humanoid then
        applyMovementToHumanoid(humanoid)
    end

    if featureState.Rainbow then
        task.defer(createRainbow, character)
    end
end)
Window:TrackConnection(characterConnection)

local currentHumanoid = initialHumanoid
local defaultWalkSpeed = currentHumanoid and currentHumanoid.WalkSpeed or 16
local defaultJumpPower = currentHumanoid and currentHumanoid.JumpPower or 50
local defaultFOV = Camera and Camera.FieldOfView or 70
local defaultGravity = Workspace.Gravity

local WalkSpeedSlider = Movement:Slider({
    Title = "Walk Speed",
    Desc = "Change your local character speed.",
    Step = 1,
    Value = {
        Min = 0,
        Max = 100,
        Default = math.floor(defaultWalkSpeed + 0.5),
    },
    Callback = function(value)
        featureState.WalkSpeed = value
        local humanoid = getHumanoid()
        if humanoid then
            trackHumanoid(humanoid)
            humanoid.WalkSpeed = value
        end
    end,
})

local JumpPowerSlider = Movement:Slider({
    Title = "Jump Power",
    Desc = "Forces JumpPower mode while this test is active.",
    Step = 1,
    Value = {
        Min = 0,
        Max = 150,
        Default = math.floor(defaultJumpPower + 0.5),
    },
    Callback = function(value)
        featureState.JumpPower = value
        local humanoid = getHumanoid()
        if humanoid then
            trackHumanoid(humanoid)
            humanoid.UseJumpPower = true
            humanoid.JumpPower = value
        end
    end,
})

local GravitySlider = Movement:Slider({
    Title = "World Gravity",
    Desc = "A very obvious cleanup test. X restores the original gravity.",
    Step = 1,
    Value = {
        Min = 0,
        Max = 300,
        Default = math.floor(defaultGravity + 0.5),
    },
    Callback = function(value)
        featureState.Gravity = value
        Workspace.Gravity = value
    end,
})

local FOVSlider = Visuals:Slider({
    Title = "Camera FOV",
    Desc = "Changes the current camera field of view.",
    Step = 1,
    Value = {
        Min = 40,
        Max = 120,
        Default = math.floor(defaultFOV + 0.5),
    },
    Callback = function(value)
        local camera = Workspace.CurrentCamera
        if camera then
            if camera ~= Camera then
                Camera = camera
                Window:TrackProperty(Camera, "FieldOfView")
            end
            camera.FieldOfView = value
        end
    end,
})

local FullbrightToggle = Visuals:Toggle({
    Title = "Fullbright",
    Desc = "Turns the map bright and removes shadows/fog locally.",
    Value = false,
    Callback = function(value)
        applyFullbright(value)
    end,
})

local RainbowToggle = Visuals:Toggle({
    Title = "Rainbow Highlight",
    Desc = "Tests both Instance cleanup and RenderStepped disconnection.",
    Value = false,
    Callback = function(value)
        featureState.Rainbow = value
        if value then
            createRainbow(LocalPlayer.Character)
        else
            destroyRainbow()
        end
    end,
})

Test:Paragraph({
    Title = "Red X cleanup test",
    Desc = "Change several features, then press the red X. Speed, jump, gravity, FOV, lighting, the rainbow Highlight, and every test connection should be restored/destroyed.",
})

Test:Button({
    Title = "Apply obvious test preset",
    Desc = "Sets multiple features at once so cleanup is easy to verify.",
    Icon = "flask-conical",
    Callback = function()
        WalkSpeedSlider:Set(36)
        JumpPowerSlider:Set(90)
        GravitySlider:Set(95)
        FOVSlider:Set(105)
        FullbrightToggle:Set(true)
        RainbowToggle:Set(true)

        VantaUI:Notify({
            Title = "Cleanup test armed",
            Content = "Now press the red X. Everything above should return to its original state.",
            Icon = "rotate-ccw",
        })
    end,
})

Test:Button({
    Title = "Show current values",
    Desc = "Quick check before closing the UI.",
    Icon = "activity",
    Callback = function()
        local humanoid = getHumanoid()
        local camera = Workspace.CurrentCamera
        VantaUI:Notify({
            Title = "Current test state",
            Content = string.format(
                "Speed %s • Jump %s • Gravity %.0f • FOV %.0f",
                humanoid and tostring(math.floor(humanoid.WalkSpeed + 0.5)) or "?",
                humanoid and tostring(math.floor(humanoid.JumpPower + 0.5)) or "?",
                Workspace.Gravity,
                camera and camera.FieldOfView or 0
            ),
            Icon = "activity",
        })
    end,
})

-- Runs last because cleanup is LIFO. Useful in the executor console to prove
-- every earlier reset completed before VantaUI destroys itself.
Window:RegisterCleanup(function()
    print("[VantaTest] Feature cleanup complete; original state restored.")
end)

return Window
