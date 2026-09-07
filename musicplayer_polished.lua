-- VantaTest music-player polish layer.
-- Keeps the glass player intact while fixing persistent mini-player placement,
-- smooth sliders, and stable minimize/restore transitions.

local CACHE_BUSTER = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local GLASS_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/musicplayer_glass.lua?v=" .. CACHE_BUSTER

local ok, source = pcall(function()
    return game:HttpGet(GLASS_URL)
end)
assert(ok and type(source) == "string" and #source > 0, "[VantaTest Music] Could not load glass player")

local loader, loadError = loadstring(source)
assert(loader, "[VantaTest Music] Glass player compile failed: " .. tostring(loadError))

local MusicPlayer = loader()
assert(type(MusicPlayer) == "table", "[VantaTest Music] Glass player returned an invalid value")

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local MINI_SIZE = Vector2.new(224, 44)
local MINI_MARGIN = 18

MusicPlayer._MiniUserMoved = false
MusicPlayer.LastMiniPosition = nil
MusicPlayer._MiniDragStart = nil
MusicPlayer._MiniPositionBound = false
MusicPlayer._MiniTransitioning = false
MusicPlayer._RootTransitionScale = nil
MusicPlayer._MiniTransitionScale = nil

local BaseBuild = MusicPlayer._build
local BaseTargetIsUsable = MusicPlayer._targetIsUsable

local function positionDistance(a, b)
    if not a or not b then
        return 0
    end
    local dx = (a.X.Offset or 0) - (b.X.Offset or 0)
    local dy = (a.Y.Offset or 0) - (b.Y.Offset or 0)
    return math.sqrt(dx * dx + dy * dy)
end

local function ensureScale(frame, name)
    if not frame then
        return nil
    end
    local scale = frame:FindFirstChild(name)
    if not scale then
        scale = Instance.new("UIScale")
        scale.Name = name
        scale.Scale = 1
        scale.Parent = frame
    end
    return scale
end

function MusicPlayer:_targetIsUsable()
    -- The music mini-player is independent now. It no longer auto-docks to the
    -- Vanta open badge; its default home is the screen's top-right corner.
    return false
end

function MusicPlayer:_defaultMiniPosition()
    local viewport = self:_screenSize()
    return UDim2.fromOffset(
        math.max(8, math.floor(viewport.X - MINI_SIZE.X - MINI_MARGIN)),
        MINI_MARGIN
    )
end

function MusicPlayer:_miniTargetPosition()
    if self._MiniUserMoved and self.LastMiniPosition then
        return self.LastMiniPosition
    end
    return self:_defaultMiniPosition()
end

function MusicPlayer:Minimize()
    if not self.UI or self.Transitioning or self._MiniTransitioning then
        return
    end

    local root = self.UI.Root
    local mini = self.UI.Mini
    if not root or not mini then
        return
    end

    self._MiniTransitioning = true
    self.LastFullPosition = root.Position
    self.LastFullSize = root.Size

    local target = self:_miniTargetPosition()
    self.LastMiniPosition = target

    local rootScale = ensureScale(root, "MusicTransitionScale")
    local miniScale = ensureScale(mini, "MusicTransitionScale")
    self._RootTransitionScale = rootScale
    self._MiniTransitionScale = miniScale

    if self._TransitionTween then
        pcall(function() self._TransitionTween:Cancel() end)
        self._TransitionTween = nil
    end

    root.Visible = true
    root.ClipsDescendants = false
    rootScale.Scale = 1
    mini.Visible = false
    mini.Position = UDim2.fromOffset(target.X.Offset + 12, target.Y.Offset - 2)
    mini.Size = UDim2.fromOffset(MINI_SIZE.X, MINI_SIZE.Y)
    miniScale.Scale = 0.84

    local rootTween = TweenService:Create(
        rootScale,
        TweenInfo.new(0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        { Scale = 0.965 }
    )
    rootTween:Play()

    local posTween = TweenService:Create(
        root,
        TweenInfo.new(0.13, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
        {
            Position = UDim2.new(
                root.Position.X.Scale,
                root.Position.X.Offset + 8,
                root.Position.Y.Scale,
                root.Position.Y.Offset - 3
            )
        }
    )
    posTween:Play()

    task.delay(0.105, function()
        if not self.UI or not root.Parent or not mini.Parent then
            self._MiniTransitioning = false
            return
        end

        root.Visible = false
        rootScale.Scale = 1
        root.Position = self.LastFullPosition
        root.Size = self.LastFullSize

        mini.Visible = true
        mini.Position = UDim2.fromOffset(target.X.Offset + 12, target.Y.Offset - 2)
        miniScale.Scale = 0.84

        local miniMove = TweenService:Create(
            mini,
            TweenInfo.new(0.19, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            { Position = target }
        )
        local miniGrow = TweenService:Create(
            miniScale,
            TweenInfo.new(0.19, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
            { Scale = 1 }
        )
        miniMove:Play()
        miniGrow:Play()

        miniGrow.Completed:Once(function()
            self._MiniTransitioning = false
        end)
    end)
end

function MusicPlayer:Restore()
    if not self.UI or self.Transitioning or self._MiniTransitioning then
        return
    end

    local root = self.UI.Root
    local mini = self.UI.Mini
    if not root or not mini then
        return
    end

    self._MiniTransitioning = true

    local rootScale = ensureScale(root, "MusicTransitionScale")
    local miniScale = ensureScale(mini, "MusicTransitionScale")
    self._RootTransitionScale = rootScale
    self._MiniTransitionScale = miniScale

    self.LastMiniPosition = mini.Position

    local finalPosition = self.LastFullPosition or self:_topRightPosition()
    local finalSize = self.LastFullSize or UDim2.fromOffset(360, 258)

    mini.Visible = true
    miniScale.Scale = 1

    local miniShrink = TweenService:Create(
        miniScale,
        TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
        { Scale = 0.86 }
    )
    local miniMove = TweenService:Create(
        mini,
        TweenInfo.new(0.11, Enum.EasingStyle.Quint, Enum.EasingDirection.In),
        {
            Position = UDim2.fromOffset(
                mini.Position.X.Offset + 10,
                mini.Position.Y.Offset - 2
            )
        }
    )
    miniShrink:Play()
    miniMove:Play()

    task.delay(0.085, function()
        if not self.UI or not root.Parent or not mini.Parent then
            self._MiniTransitioning = false
            return
        end

        mini.Visible = false
        miniScale.Scale = 1
        if self.LastMiniPosition then
            mini.Position = self.LastMiniPosition
        end

        root.Position = UDim2.new(
            finalPosition.X.Scale,
            finalPosition.X.Offset + 10,
            finalPosition.Y.Scale,
            finalPosition.Y.Offset - 4
        )
        root.Size = finalSize
        rootScale.Scale = 0.965
        root.Visible = true
        root.ClipsDescendants = false

        local rootMove = TweenService:Create(
            root,
            TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            { Position = finalPosition }
        )
        local rootGrow = TweenService:Create(
            rootScale,
            TweenInfo.new(0.22, Enum.EasingStyle.Quint, Enum.EasingDirection.Out),
            { Scale = 1 }
        )
        rootMove:Play()
        rootGrow:Play()

        rootGrow.Completed:Once(function()
            root.Position = finalPosition
            root.Size = finalSize
            rootScale.Scale = 1
            self._MiniTransitioning = false
        end)
    end)
end

local function installSmoothSlider(slider, edgeInset)
    if not slider or slider._VantaSmoothInstalled then
        return
    end
    slider._VantaSmoothInstalled = true

    local hit = slider.Hit
    local track = slider.Track
    local fill = slider.Fill
    local knob = slider.Knob
    if not hit or not track or not fill or not knob then
        return
    end

    edgeInset = edgeInset or 5
    track.Position = UDim2.new(0, edgeInset, 0.5, 0)
    track.Size = UDim2.new(1, -(edgeInset * 2), 0, track.Size.Y.Offset)

    local knobSize = math.max(7, math.min(9, knob.Size.X.Offset))
    knob.Size = UDim2.fromOffset(knobSize, knobSize)

    slider.VisualRatio = math.clamp(slider.Ratio or 0, 0, 1)
    slider.TargetRatio = slider.VisualRatio

    local function applyVisual(ratio)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, 0, 0.5, 0)
    end

    applyVisual(slider.VisualRatio)

    function slider:Set(ratio, animate)
        ratio = math.clamp(tonumber(ratio) or 0, 0, 1)
        self.Ratio = ratio
        self.TargetRatio = ratio

        if self.Tween then
            pcall(function() self.Tween:Cancel() end)
            self.Tween = nil
        end

        if not animate or self.Dragging then
            self.VisualRatio = ratio
            applyVisual(ratio)
        end
    end

    slider._SmoothConnection = RunService.RenderStepped:Connect(function(dt)
        if slider.Dragging then
            slider.VisualRatio = slider.Ratio
            applyVisual(slider.VisualRatio)
            return
        end

        local target = slider.TargetRatio or slider.Ratio or 0
        local current = slider.VisualRatio or target
        local alpha = 1 - math.exp(-math.max(dt, 0) * 18)
        current = current + (target - current) * alpha

        if math.abs(target - current) < 0.0005 then
            current = target
        end

        slider.VisualRatio = current
        applyVisual(current)
    end)
end

function MusicPlayer:_bindMiniPositionMemory()
    if self._MiniPositionBound or not self.UI or not self.UI.Mini then
        return
    end
    self._MiniPositionBound = true

    local mini = self.UI.Mini
    local activeDragInput = nil

    mini.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            activeDragInput = input
            self._MiniDragStart = mini.Position
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if not activeDragInput then
            return
        end

        local ended = input == activeDragInput
            or (activeDragInput.UserInputType == Enum.UserInputType.MouseButton1
                and input.UserInputType == Enum.UserInputType.MouseButton1)

        if not ended then
            return
        end

        local startPosition = self._MiniDragStart
        activeDragInput = nil
        self._MiniDragStart = nil

        if positionDistance(startPosition, mini.Position) > 2 then
            self._MiniUserMoved = true
            self.LastMiniPosition = mini.Position
        end
    end)
end

function MusicPlayer:_polishGlassLayout()
    if not self.UI then
        return
    end

    local progress = self.UI.ProgressSlider
    local volume = self.UI.VolumeSlider

    if progress and progress.Hit then
        progress.Hit.Size = UDim2.fromOffset(226, 16)
        progress.Hit.Position = UDim2.fromOffset(96, 45)
        installSmoothSlider(progress, 5)
    end

    if volume and volume.Hit then
        volume.Hit.Size = UDim2.fromOffset(58, 17)
        installSmoothSlider(volume, 4)
    end

    if self.UI.Time then
        self.UI.Time.Position = UDim2.fromOffset(96, 59)
    end
    if self.UI.Duration then
        self.UI.Duration.Position = UDim2.new(1, -42, 0, 59)
    end
end

function MusicPlayer:_build()
    BaseBuild(self)
    self:_polishGlassLayout()
    self:_bindMiniPositionMemory()

    if self.UI and self.UI.Mini and not self._MiniUserMoved then
        self.UI.Mini.Position = self:_defaultMiniPosition()
    end
end

return MusicPlayer