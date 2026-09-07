-- VantaTest music-player polish layer.
-- Keeps the glass player intact while fixing persistent mini-player placement
-- and giving progress/volume sliders inset knobs with continuous smooth motion.

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

local MINI_SIZE = Vector2.new(224, 44)

MusicPlayer._MiniUserMoved = false
MusicPlayer.LastMiniPosition = nil
MusicPlayer._MiniDragStart = nil
MusicPlayer._MiniPositionBound = false

local BaseBuild = MusicPlayer._build
local BaseMinimize = MusicPlayer.Minimize
local BaseTargetIsUsable = MusicPlayer._targetIsUsable

local function positionDistance(a, b)
    if not a or not b then
        return 0
    end
    local dx = (a.X.Offset or 0) - (b.X.Offset or 0)
    local dy = (a.Y.Offset or 0) - (b.Y.Offset or 0)
    return math.sqrt(dx * dx + dy * dy)
end

function MusicPlayer:_targetIsUsable()
    -- Once the user deliberately moves the mini-player, never let badge-follow
    -- logic pull it back to the automatic dock position again.
    if self._MiniUserMoved then
        return false
    end
    return BaseTargetIsUsable(self)
end

function MusicPlayer:Minimize()
    -- Preserve a user-selected mini-player position across restore/minimize cycles.
    if self._MiniUserMoved and self.LastMiniPosition then
        local originalDockGeometry = self._dockGeometry
        self._dockGeometry = function(this)
            return this.LastMiniPosition, UDim2.fromOffset(MINI_SIZE.X, MINI_SIZE.Y), false
        end

        BaseMinimize(self)
        self._dockGeometry = originalDockGeometry
        return
    end

    BaseMinimize(self)
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

    -- Smaller, cleaner dot that stays fully inside the slider hit area.
    local knobSize = math.max(7, math.min(9, knob.Size.X.Offset))
    knob.Size = UDim2.fromOffset(knobSize, knobSize)

    slider.VisualRatio = math.clamp(slider.Ratio or 0, 0, 1)
    slider.TargetRatio = slider.VisualRatio

    local function applyVisual(ratio)
        fill.Size = UDim2.new(ratio, 0, 1, 0)
        knob.Position = UDim2.new(ratio, 0, 0.5, 0)
    end

    applyVisual(slider.VisualRatio)

    -- Replace the per-frame tween restart with a target ratio. One render loop
    -- eases toward the target continuously, so playback progression actually glides.
    function slider:Set(ratio, animate)
        ratio = math.clamp(tonumber(ratio) or 0, 0, 1)
        self.Ratio = ratio
        self.TargetRatio = ratio

        if self.Tween then
            pcall(function()
                self.Tween:Cancel()
            end)
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
            self._DockWasVisible = false
            self._LastDockTargetAbsolutePosition = nil
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
        -- 96px left offset inside a 336px card leaves ~230px usable width.
        -- Keep a little breathing room so the bar never touches the right border.
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
end

return MusicPlayer
