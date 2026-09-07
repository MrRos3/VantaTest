-- VantaTest experimental music-player dock layer.
-- Extends the compact player with smooth real-window minimize/restore motion,
-- badge docking that does not fight manual dragging, and top-right opening.

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

local FULL_SIZE = Vector2.new(360, 258)
local MINI_SIZE = Vector2.new(224, 44)
local DOCK_OVERLAP = 7
local SCREEN_MARGIN = 18
local TRANSITION_TIME = 0.34
local TRANSITION_INFO = TweenInfo.new(TRANSITION_TIME, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)
local FOLLOW_INFO = TweenInfo.new(0.16, Enum.EasingStyle.Quint, Enum.EasingDirection.Out)

MusicPlayer.Window = nil
MusicPlayer.DockTarget = nil
MusicPlayer.Transitioning = false
MusicPlayer.LastFullPosition = nil
MusicPlayer.LastFullSize = nil
MusicPlayer.LastDockedPosition = nil
MusicPlayer._DockWasVisible = false
MusicPlayer._LastDockTargetAbsolutePosition = nil
MusicPlayer._DockTween = nil
MusicPlayer._TransitionTween = nil

local BaseInit = MusicPlayer.Init
local BaseShow = MusicPlayer.Show
local BaseApplyTheme = MusicPlayer.ApplyTheme

function MusicPlayer:BindWindow(window)
    self.Window = window

    local openButtonMain = window and window.OpenButtonMain
    local button = openButtonMain and openButtonMain.Button
    self.DockTarget = button and button.Parent or nil

    return self
end

function MusicPlayer:SetDockTarget(target)
    self.DockTarget = target
    self._LastDockTargetAbsolutePosition = nil
    self._DockWasVisible = false
    return self
end

function MusicPlayer:_screenSize()
    local screen = self.WindUI and self.WindUI.ScreenGui
    return screen and screen.AbsoluteSize or Vector2.new(1280, 720)
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

function MusicPlayer:_topRightPosition()
    local viewport = self:_screenSize()
    local x = math.max(SCREEN_MARGIN, viewport.X - FULL_SIZE.X - SCREEN_MARGIN)
    return UDim2.fromOffset(math.floor(x), SCREEN_MARGIN)
end

function MusicPlayer:_defaultMiniPosition()
    local viewport = self:_screenSize()
    return UDim2.fromOffset(
        math.floor((viewport.X - MINI_SIZE.X) / 2),
        math.floor(viewport.Y * 0.80)
    )
end

function MusicPlayer:_dockGeometry()
    local viewport = self:_screenSize()

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

function MusicPlayer:_cancelDockTween()
    if self._DockTween then
        pcall(function()
            self._DockTween:Cancel()
        end)
        self._DockTween = nil
    end
end

function MusicPlayer:_cancelTransitionTween()
    if self._TransitionTween then
        pcall(function()
            self._TransitionTween:Cancel()
        end)
        self._TransitionTween = nil
    end
end

function MusicPlayer:_dockMiniOnce(animated)
    if not self.UI or not self.UI.Mini then
        return
    end

    local position, size, docked = self:_dockGeometry()
    if not docked then
        return
    end

    self:_cancelDockTween()

    if animated then
        local tween = TweenService:Create(self.UI.Mini, FOLLOW_INFO, {
            Position = position,
            Size = size,
        })
        self._DockTween = tween
        tween:Play()
        tween.Completed:Once(function()
            if self._DockTween == tween then
                self._DockTween = nil
            end
        end)
    else
        self.UI.Mini.Position = position
        self.UI.Mini.Size = size
    end

    self.LastDockedPosition = position
    self._LastDockTargetAbsolutePosition = self.DockTarget.AbsolutePosition
end

function MusicPlayer:ApplyTheme()
    BaseApplyTheme(self)
end

function MusicPlayer:Show()
    BaseShow(self)

    if not self.UI or not self.UI.Root then
        return
    end

    self:_cancelTransitionTween()

    local root = self.UI.Root
    local finalPosition = self:_topRightPosition()
    local finalSize = UDim2.fromOffset(FULL_SIZE.X, FULL_SIZE.Y)

    self.LastFullPosition = finalPosition
    self.LastFullSize = finalSize

    root.Visible = true
    root.ClipsDescendants = true
    root.Position = UDim2.fromOffset(finalPosition.X.Offset + 18, finalPosition.Y.Offset - 6)
    root.Size = UDim2.fromOffset(FULL_SIZE.X - 20, FULL_SIZE.Y - 14)

    local tween = TweenService:Create(root, TweenInfo.new(0.26, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        Position = finalPosition,
        Size = finalSize,
    })
    self._TransitionTween = tween
    self.Transitioning = true
    tween:Play()
    tween.Completed:Once(function()
        if self._TransitionTween == tween then
            self._TransitionTween = nil
        end
        root.ClipsDescendants = false
        self.Transitioning = false
    end)
end

function MusicPlayer:Minimize()
    if not self.UI or self.Transitioning then
        return
    end

    local root = self.UI.Root
    local mini = self.UI.Mini
    if not root or not mini then
        return
    end

    self:_cancelTransitionTween()
    self:_cancelDockTween()

    self.Transitioning = true
    self.LastFullPosition = root.Position
    self.LastFullSize = root.Size

    local targetPosition, targetSize, docked = self:_dockGeometry()

    root.Visible = true
    root.ClipsDescendants = true
    mini.Visible = false

    local tween = TweenService:Create(root, TRANSITION_INFO, {
        Position = targetPosition,
        Size = targetSize,
    })
    self._TransitionTween = tween
    tween:Play()

    tween.Completed:Once(function()
        if self._TransitionTween == tween then
            self._TransitionTween = nil
        end

        root.Visible = false
        root.ClipsDescendants = false
        root.Position = self.LastFullPosition or self:_topRightPosition()
        root.Size = self.LastFullSize or UDim2.fromOffset(FULL_SIZE.X, FULL_SIZE.Y)

        mini.Position = targetPosition
        mini.Size = targetSize
        mini.Visible = true

        self.LastDockedPosition = targetPosition
        self._DockWasVisible = docked
        self._LastDockTargetAbsolutePosition = docked and self.DockTarget.AbsolutePosition or nil
        self.Transitioning = false
    end)
end

function MusicPlayer:Restore()
    if not self.UI or self.Transitioning then
        return
    end

    local root = self.UI.Root
    local mini = self.UI.Mini
    if not root or not mini then
        return
    end

    self:_cancelTransitionTween()
    self:_cancelDockTween()
    self.Transitioning = true

    local startPosition = UDim2.fromOffset(mini.AbsolutePosition.X, mini.AbsolutePosition.Y)
    local startSize = UDim2.fromOffset(mini.AbsoluteSize.X, mini.AbsoluteSize.Y)
    local finalPosition = self.LastFullPosition or self:_topRightPosition()
    local finalSize = self.LastFullSize or UDim2.fromOffset(FULL_SIZE.X, FULL_SIZE.Y)

    mini.Visible = false

    -- Animate the real player, not a blank shell. Its contents are already
    -- present and reveal naturally as the clipped frame expands.
    root.Position = startPosition
    root.Size = startSize
    root.ClipsDescendants = true
    root.Visible = true

    local tween = TweenService:Create(root, TRANSITION_INFO, {
        Position = finalPosition,
        Size = finalSize,
    })
    self._TransitionTween = tween
    tween:Play()

    tween.Completed:Once(function()
        if self._TransitionTween == tween then
            self._TransitionTween = nil
        end
        root.Position = finalPosition
        root.Size = finalSize
        root.ClipsDescendants = false
        root.Visible = true
        self.Transitioning = false
    end)
end

function MusicPlayer:Init(windui, config)
    BaseInit(self, windui, config)

    RunService.RenderStepped:Connect(function()
        if not self.UI or not self.UI.Mini or not self.UI.Mini.Visible or self.Transitioning then
            self._DockWasVisible = false
            self._LastDockTargetAbsolutePosition = nil
            return
        end

        local dockVisible = self:_targetIsUsable()

        if dockVisible then
            local targetPosition = self.DockTarget.AbsolutePosition

            if not self._DockWasVisible then
                -- Dock once when the badge first appears. After that, manual
                -- mini-player dragging is respected instead of being overwritten.
                self:_dockMiniOnce(true)
            elseif self._LastDockTargetAbsolutePosition then
                -- If the badge itself is dragged, move the mini-player by the
                -- same delta. This keeps their relative placement without
                -- recalculating and snapping the mini-player back.
                local delta = targetPosition - self._LastDockTargetAbsolutePosition
                if math.abs(delta.X) > 0.25 or math.abs(delta.Y) > 0.25 then
                    local current = self.UI.Mini.Position
                    self.UI.Mini.Position = UDim2.new(
                        current.X.Scale,
                        current.X.Offset + delta.X,
                        current.Y.Scale,
                        current.Y.Offset + delta.Y
                    )
                end
            end

            self._LastDockTargetAbsolutePosition = targetPosition
        else
            self._LastDockTargetAbsolutePosition = nil
        end

        self._DockWasVisible = dockVisible
    end)

    return self
end

return MusicPlayer
