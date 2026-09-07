-- VantaTest experimental music-player dock layer.
-- Extends the compact player with a smooth minimize/restore morph that docks
-- beside VantaUI's draggable open badge.

local CACHE_BUSTER = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local COMPACT_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/musicplayer_compact.lua?v=" .. CACHE_BUSTER

local ok, source = pcall(function()
    return game:HttpGet(COMPACT_URL)
end)
assert(ok and type(source) == "string" and #source > 0, "[VantaTest Music] Could not load compact player")

local loader, loadError = loadstring(source)
assert(loader, "[VantaTest Music] Compact player compile failed: " .. tostring(loadError))

local MusicPlayer = loader()
assert(type(MusicPlayer) == "table", "[VantaTest Music] Compact player returned an invalid value")

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local MINI_SIZE = Vector2.new(224, 44)
local DOCK_OVERLAP = 7
local TRANSITION_TIME = 0.42
local TRANSITION_INFO = TweenInfo.new(TRANSITION_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

MusicPlayer.Window = nil
MusicPlayer.DockTarget = nil
MusicPlayer.Transitioning = false
MusicPlayer.LastFullPosition = nil
MusicPlayer.LastFullSize = nil
MusicPlayer.LastDockedPosition = nil
MusicPlayer._DockWasVisible = false

local BaseInit = MusicPlayer.Init
local BaseShow = MusicPlayer.Show
local BaseApplyTheme = MusicPlayer.ApplyTheme

local function setGuiTextTransparency(root, value)
    if not root then
        return
    end
    for _, object in ipairs(root:GetDescendants()) do
        if object:IsA("TextLabel") or object:IsA("TextButton") then
            object.TextTransparency = value
        elseif object:IsA("ImageLabel") or object:IsA("ImageButton") then
            object.ImageTransparency = value
        end
    end
end

function MusicPlayer:BindWindow(window)
    self.Window = window

    local openButtonMain = window and window.OpenButtonMain
    local button = openButtonMain and openButtonMain.Button
    self.DockTarget = button and button.Parent or nil

    return self
end

function MusicPlayer:SetDockTarget(target)
    self.DockTarget = target
    return self
end

function MusicPlayer:_targetIsUsable()
    local target = self.DockTarget
    return target
        and target.Parent ~= nil
        and target:IsA("GuiObject")
        and target.Visible
        and target.AbsoluteSize.X > 0
        and target.AbsoluteSize.Y > 0
end

function MusicPlayer:_defaultMiniPosition()
    local screen = self.WindUI and self.WindUI.ScreenGui
    local viewport = screen and screen.AbsoluteSize or Vector2.new(1280, 720)
    return UDim2.fromOffset(
        math.floor((viewport.X - MINI_SIZE.X) / 2),
        math.floor(viewport.Y * 0.80)
    )
end

function MusicPlayer:_dockGeometry()
    local screen = self.WindUI and self.WindUI.ScreenGui
    local viewport = screen and screen.AbsoluteSize or Vector2.new(1280, 720)

    if not self:_targetIsUsable() then
        return self:_defaultMiniPosition(), UDim2.fromOffset(MINI_SIZE.X, MINI_SIZE.Y), false
    end

    local target = self.DockTarget
    local targetPos = target.AbsolutePosition
    local targetSize = target.AbsoluteSize

    local xRight = targetPos.X + targetSize.X - DOCK_OVERLAP
    local xLeft = targetPos.X - MINI_SIZE.X + DOCK_OVERLAP
    local y = targetPos.Y + math.floor((targetSize.Y - MINI_SIZE.Y) / 2)

    local x
    if xRight + MINI_SIZE.X <= viewport.X - 8 then
        x = xRight
    else
        x = math.max(8, xLeft)
    end

    y = math.clamp(y, 8, math.max(8, viewport.Y - MINI_SIZE.Y - 8))

    return UDim2.fromOffset(math.floor(x), math.floor(y)), UDim2.fromOffset(MINI_SIZE.X, MINI_SIZE.Y), true
end

function MusicPlayer:_ensureTransitionShell()
    if not self.UI or self.UI.TransitionShell then
        return
    end

    local shell = Instance.new("Frame")
    shell.Name = "MusicDockTransition"
    shell.BackgroundColor3 = self:_theme("Background", Color3.fromRGB(0, 0, 0))
    shell.BackgroundTransparency = 0.03
    shell.BorderSizePixel = 0
    shell.Visible = false
    shell.ZIndex = 7000
    shell.Parent = self.WindUI.ScreenGui

    local corner = Instance.new("UICorner")
    corner.Name = "Corner"
    corner.CornerRadius = UDim.new(0, 14)
    corner.Parent = shell

    local stroke = Instance.new("UIStroke")
    stroke.Name = "Stroke"
    stroke.Color = self:_theme("Outline", Color3.fromRGB(90, 24, 36))
    stroke.Transparency = 0.7
    stroke.Thickness = 1
    stroke.Parent = shell

    self.UI.TransitionShell = shell
end

function MusicPlayer:_setMiniContentVisible(visible)
    if not self.UI or not self.UI.Mini then
        return
    end

    local mini = self.UI.Mini
    for _, child in ipairs(mini:GetChildren()) do
        if child:IsA("GuiObject") then
            child.Visible = visible
        end
    end
end

function MusicPlayer:_snapMiniToDock()
    if not self.UI or not self.UI.Mini or self.Transitioning then
        return
    end

    local position, size, docked = self:_dockGeometry()
    if docked then
        self.UI.Mini.Position = position
        self.UI.Mini.Size = size
        self.LastDockedPosition = position
    end
end

function MusicPlayer:ApplyTheme()
    BaseApplyTheme(self)
    if self.UI and self.UI.TransitionShell then
        self.UI.TransitionShell.BackgroundColor3 = self:_theme("Background", Color3.fromRGB(0, 0, 0))
        local stroke = self.UI.TransitionShell:FindFirstChild("Stroke")
        if stroke then
            stroke.Color = self:_theme("Outline", Color3.fromRGB(90, 24, 36))
        end
    end
end

function MusicPlayer:Show()
    BaseShow(self)
    self:_ensureTransitionShell()

    if self.UI and self.UI.Root then
        self.UI.Root.Size = UDim2.fromOffset(360, 258)
        if self.LastFullPosition then
            self.UI.Root.Position = self.LastFullPosition
        end
    end
end

function MusicPlayer:Minimize()
    if not self.UI or self.Transitioning then
        return
    end

    self:_ensureTransitionShell()

    local root = self.UI.Root
    local mini = self.UI.Mini
    local shell = self.UI.TransitionShell
    if not root or not mini or not shell then
        return
    end

    self.Transitioning = true
    self.LastFullPosition = root.Position
    self.LastFullSize = root.Size

    local targetPosition, targetSize = self:_dockGeometry()

    shell.Position = UDim2.fromOffset(root.AbsolutePosition.X, root.AbsolutePosition.Y)
    shell.Size = UDim2.fromOffset(root.AbsoluteSize.X, root.AbsoluteSize.Y)
    shell.BackgroundColor3 = self:_theme("Background", Color3.fromRGB(0, 0, 0))
    shell.Visible = true

    root.Visible = false
    mini.Visible = false
    mini.Size = targetSize
    mini.Position = targetPosition

    local tween = TweenService:Create(shell, TRANSITION_INFO, {
        Position = targetPosition,
        Size = targetSize,
    })
    tween:Play()

    tween.Completed:Once(function()
        shell.Visible = false
        mini.Position = targetPosition
        mini.Size = targetSize
        mini.Visible = true
        self.LastDockedPosition = targetPosition
        self.Transitioning = false
    end)
end

function MusicPlayer:Restore()
    if not self.UI or self.Transitioning then
        return
    end

    self:_ensureTransitionShell()

    local root = self.UI.Root
    local mini = self.UI.Mini
    local shell = self.UI.TransitionShell
    if not root or not mini or not shell then
        return
    end

    self.Transitioning = true

    local startPosition = UDim2.fromOffset(mini.AbsolutePosition.X, mini.AbsolutePosition.Y)
    local startSize = UDim2.fromOffset(mini.AbsoluteSize.X, mini.AbsoluteSize.Y)

    local finalPosition = self.LastFullPosition or UDim2.new(0.5, -180, 0.5, -129)
    local finalSize = self.LastFullSize or UDim2.fromOffset(360, 258)

    shell.Position = startPosition
    shell.Size = startSize
    shell.BackgroundColor3 = self:_theme("Background", Color3.fromRGB(0, 0, 0))
    shell.Visible = true
    mini.Visible = false
    root.Visible = false

    local tween = TweenService:Create(shell, TRANSITION_INFO, {
        Position = finalPosition,
        Size = finalSize,
    })
    tween:Play()

    tween.Completed:Once(function()
        shell.Visible = false
        root.Position = finalPosition
        root.Size = finalSize
        root.Visible = true
        self.Transitioning = false
    end)
end

function MusicPlayer:Init(windui, config)
    BaseInit(self, windui, config)

    RunService.RenderStepped:Connect(function()
        if not self.UI or not self.UI.Mini or not self.UI.Mini.Visible or self.Transitioning then
            return
        end

        local dockVisible = self:_targetIsUsable()
        if dockVisible then
            local position, size = self:_dockGeometry()
            local current = self.UI.Mini.Position
            local dx = math.abs(current.X.Offset - position.X.Offset)
            local dy = math.abs(current.Y.Offset - position.Y.Offset)

            -- Follow a dragged Vanta badge. A short tween makes it feel attached
            -- instead of snapping from point to point.
            if dx > 1 or dy > 1 then
                TweenService:Create(
                    self.UI.Mini,
                    TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
                    { Position = position, Size = size }
                ):Play()
            end
        end
        self._DockWasVisible = dockVisible
    end)

    return self
end

return MusicPlayer
