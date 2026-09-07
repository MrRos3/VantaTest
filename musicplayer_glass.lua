-- VantaTest glass music-player skin.
-- Keeps the dock/minimize behavior from musicplayer_docked.lua while replacing
-- the player surface with a compact glassmorphism layout and smooth sliders.

local CACHE_BUSTER = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local DOCKED_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/musicplayer_docked.lua?v=" .. CACHE_BUSTER

local ok, source = pcall(function()
    return game:HttpGet(DOCKED_URL)
end)
assert(ok and type(source) == "string" and #source > 0, "[VantaTest Music] Could not load docked player")

local loader, loadError = loadstring(source)
assert(loader, "[VantaTest Music] Docked player compile failed: " .. tostring(loadError))

local MusicPlayer = loader()
assert(type(MusicPlayer) == "table", "[VantaTest Music] Docked player returned an invalid value")

local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local BaseApplyTheme = MusicPlayer.ApplyTheme
local BaseDrag = MusicPlayer._drag

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = parent
    return c
end

local function stroke(parent, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.Color = color
    s.Transparency = transparency or 0.6
    s.Thickness = thickness or 1
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Parent = parent
    return s
end

local function gradient(parent, topColor, bottomColor, rotation)
    local g = Instance.new("UIGradient")
    g.Rotation = rotation or 90
    g.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, topColor),
        ColorSequenceKeypoint.new(1, bottomColor),
    })
    g.Parent = parent
    return g
end

local function setZ(root, base)
    root.ZIndex = base
    for _, d in ipairs(root:GetDescendants()) do
        if d:IsA("GuiObject") then
            d.ZIndex = math.max(d.ZIndex, base + 1)
        end
    end
end

function MusicPlayer:_glassColor()
    local bg = self:_theme("Background", Color3.fromRGB(0, 0, 0))
    local panel = self:_theme("ElementBackground", Color3.fromRGB(21, 17, 22))
    return panel:Lerp(bg, 0.38)
end

function MusicPlayer:_createGlassSlider(parent, config)
    local slider = {
        Ratio = math.clamp(config.Ratio or 0, 0, 1),
        Dragging = false,
        Tween = nil,
    }

    local hit = Instance.new("TextButton")
    hit.Name = config.Name or "Slider"
    hit.Text = ""
    hit.AutoButtonColor = false
    hit.BackgroundTransparency = 1
    hit.Size = UDim2.fromOffset(config.Width, config.HitHeight or 18)
    hit.Position = config.Position
    hit.Active = true
    hit.ZIndex = config.ZIndex or 5010
    hit.Parent = parent

    local track = Instance.new("Frame")
    track.Name = "Track"
    track.AnchorPoint = Vector2.new(0, 0.5)
    track.Position = UDim2.new(0, 0, 0.5, 0)
    track.Size = UDim2.new(1, 0, 0, config.TrackHeight or 4)
    track.BackgroundColor3 = self:_theme("ElementBackground", Color3.fromRGB(21, 17, 22))
    track.BackgroundTransparency = 0.22
    track.BorderSizePixel = 0
    track.ZIndex = hit.ZIndex
    track.Parent = hit
    corner(track, 99)

    local inner = Instance.new("Frame")
    inner.Name = "InnerHighlight"
    inner.Size = UDim2.new(1, 0, 0, 1)
    inner.Position = UDim2.fromOffset(0, 0)
    inner.BackgroundColor3 = Color3.new(1, 1, 1)
    inner.BackgroundTransparency = 0.88
    inner.BorderSizePixel = 0
    inner.ZIndex = hit.ZIndex + 1
    inner.Parent = track
    corner(inner, 99)

    local fill = Instance.new("Frame")
    fill.Name = "Fill"
    fill.Size = UDim2.new(slider.Ratio, 0, 1, 0)
    fill.BackgroundColor3 = self:_theme("Slider", Color3.fromRGB(161, 22, 47))
    fill.BorderSizePixel = 0
    fill.ZIndex = hit.ZIndex + 2
    fill.Parent = track
    corner(fill, 99)

    local knob = Instance.new("Frame")
    knob.Name = "Knob"
    knob.AnchorPoint = Vector2.new(0.5, 0.5)
    knob.Position = UDim2.new(slider.Ratio, 0, 0.5, 0)
    knob.Size = UDim2.fromOffset(config.KnobSize or 10, config.KnobSize or 10)
    knob.BackgroundColor3 = self:_theme("SliderIcon", Color3.fromRGB(241, 227, 231))
    knob.BorderSizePixel = 0
    knob.ZIndex = hit.ZIndex + 4
    knob.Parent = track
    corner(knob, 99)

    local knobStroke = stroke(knob, Color3.new(1, 1, 1), 0.55, 1)

    local glow = Instance.new("Frame")
    glow.Name = "Glow"
    glow.AnchorPoint = Vector2.new(0.5, 0.5)
    glow.Position = UDim2.fromScale(0.5, 0.5)
    glow.Size = UDim2.fromScale(1.75, 1.75)
    glow.BackgroundColor3 = self:_theme("Slider", Color3.fromRGB(161, 22, 47))
    glow.BackgroundTransparency = 0.78
    glow.BorderSizePixel = 0
    glow.ZIndex = knob.ZIndex - 1
    glow.Parent = knob
    corner(glow, 99)

    function slider:Set(ratio, animate)
        ratio = math.clamp(tonumber(ratio) or 0, 0, 1)
        self.Ratio = ratio

        if self.Tween then
            pcall(function()
                self.Tween:Cancel()
            end)
            self.Tween = nil
        end

        local targetFill = UDim2.new(ratio, 0, 1, 0)
        local targetKnob = UDim2.new(ratio, 0, 0.5, 0)

        if animate and not self.Dragging then
            local t1 = TweenService:Create(fill, TweenInfo.new(0.10, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = targetFill,
            })
            local t2 = TweenService:Create(knob, TweenInfo.new(0.10, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Position = targetKnob,
            })
            self.Tween = t2
            t1:Play()
            t2:Play()
        else
            fill.Size = targetFill
            knob.Position = targetKnob
        end
    end

    function slider:SetTheme()
        track.BackgroundColor3 = self.Owner:_theme("ElementBackground", Color3.fromRGB(21, 17, 22))
        fill.BackgroundColor3 = self.Owner:_theme("Slider", Color3.fromRGB(161, 22, 47))
        knob.BackgroundColor3 = self.Owner:_theme("SliderIcon", Color3.fromRGB(241, 227, 231))
        glow.BackgroundColor3 = self.Owner:_theme("Slider", Color3.fromRGB(161, 22, 47))
        knobStroke.Color = Color3.new(1, 1, 1)
    end

    slider.Owner = self
    slider.Hit = hit
    slider.Track = track
    slider.Fill = fill
    slider.Knob = knob
    slider.Glow = glow

    local function ratioFromX(x)
        if track.AbsoluteSize.X <= 0 then
            return slider.Ratio
        end
        return math.clamp((x - track.AbsolutePosition.X) / track.AbsoluteSize.X, 0, 1)
    end

    local function applyFromInput(input, animate)
        local ratio = ratioFromX(input.Position.X)
        slider:Set(ratio, animate)
        if config.OnChanged then
            config.OnChanged(ratio)
        end
    end

    hit.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            slider.Dragging = true
            TweenService:Create(knob, TweenInfo.new(0.10, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset((config.KnobSize or 10) + 3, (config.KnobSize or 10) + 3),
            }):Play()
            TweenService:Create(glow, TweenInfo.new(0.10, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.55,
            }):Play()
            applyFromInput(input, false)
            if config.OnDragState then
                config.OnDragState(true)
            end
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if not slider.Dragging then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseMovement
            or input.UserInputType == Enum.UserInputType.Touch then
            applyFromInput(input, false)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if not slider.Dragging then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            slider.Dragging = false
            TweenService:Create(knob, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(config.KnobSize or 10, config.KnobSize or 10),
            }):Play()
            TweenService:Create(glow, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                BackgroundTransparency = 0.78,
            }):Play()
            if config.OnDragState then
                config.OnDragState(false)
            end
        end
    end)

    hit.MouseEnter:Connect(function()
        if not slider.Dragging then
            TweenService:Create(knob, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset((config.KnobSize or 10) + 2, (config.KnobSize or 10) + 2),
            }):Play()
        end
    end)

    hit.MouseLeave:Connect(function()
        if not slider.Dragging then
            TweenService:Create(knob, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                Size = UDim2.fromOffset(config.KnobSize or 10, config.KnobSize or 10),
            }):Play()
        end
    end)

    return slider
end

function MusicPlayer:_renderList()
    if not self.UI then
        return
    end

    for _, row in ipairs(self.Rows) do
        row:Destroy()
    end
    self.Rows = {}

    self.UI.Empty.Visible = #self.Tracks == 0

    for i, track in ipairs(self.Tracks) do
        local selected = i == self.CurrentIndex

        local row = Instance.new("TextButton")
        row.Name = "Track_" .. tostring(i)
        row.Text = ""
        row.AutoButtonColor = false
        row.Size = UDim2.new(1, 0, 0, 30)
        row.BackgroundColor3 = self:_theme("ElementBackground", Color3.fromRGB(21, 17, 22))
        row.BackgroundTransparency = selected and 0.40 or 0.82
        row.BorderSizePixel = 0
        row.Parent = self.UI.List
        corner(row, 8)

        local rowStroke = stroke(row, selected and self:_theme("Outline", Color3.fromRGB(90, 24, 36)) or Color3.new(1, 1, 1), selected and 0.55 or 0.90, 1)

        local indicator = Instance.new("Frame")
        indicator.Name = "Indicator"
        indicator.AnchorPoint = Vector2.new(0, 0.5)
        indicator.Position = UDim2.fromOffset(5, 15)
        indicator.Size = UDim2.fromOffset(3, selected and 16 or 0)
        indicator.BackgroundColor3 = self:_theme("Primary", Color3.fromRGB(161, 22, 47))
        indicator.BorderSizePixel = 0
        indicator.Parent = row
        corner(indicator, 99)

        local number = self:_text(row, string.format("%02d", i), 9, false)
        number.Position = UDim2.fromOffset(15, 0)
        number.Size = UDim2.fromOffset(24, 30)
        number.TextTransparency = 0.55

        local title = self:_text(row, track.Name, 11, selected)
        title.Position = UDim2.fromOffset(43, 0)
        title.Size = UDim2.new(1, -54, 1, 0)

        row.MouseEnter:Connect(function()
            if i ~= self.CurrentIndex then
                TweenService:Create(row, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 0.66,
                }):Play()
            end
        end)

        row.MouseLeave:Connect(function()
            if i ~= self.CurrentIndex then
                TweenService:Create(row, TweenInfo.new(0.12, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
                    BackgroundTransparency = 0.82,
                }):Play()
            end
        end)

        row.MouseButton1Click:Connect(function()
            self:_load(i, true)
        end)

        table.insert(self.Rows, row)
    end
end

function MusicPlayer:_update()
    if not self.UI then
        return
    end

    local track = self.CurrentIndex and self.Tracks[self.CurrentIndex]
    local sound = self.Sound

    self.UI.Title.Text = track and track.Name or "Nothing playing"
    self.UI.Sub.Text = track and ("LOCAL • " .. string.upper(track.Path:match("%.([^%.]+)$") or "AUDIO"))
        or "Drop your songs into VantaTest/Music"

    if sound then
        self.Playing = sound.IsPlaying == true
    end

    self.UI.PlayIcon.Visible = not self.Playing
    self.UI.PauseIcon.Visible = self.Playing
    self.UI.MiniPlay.Visible = not self.Playing
    self.UI.MiniPause.Visible = self.Playing

    local position = sound and sound.TimePosition or 0
    local length = sound and sound.TimeLength or 0

    self.UI.Time.Text = timeText and timeText(position) or string.format("%d:%02d", math.floor(position / 60), math.floor(position % 60))
    self.UI.Duration.Text = timeText and timeText(length) or string.format("%d:%02d", math.floor(length / 60), math.floor(length % 60))

    local ratio = length > 0 and math.clamp(position / length, 0, 1) or 0
    if self.UI.ProgressSlider and not self.UI.ProgressSlider.Dragging then
        self.UI.ProgressSlider:Set(ratio, true)
    end

    if self.UI.VolumeSlider and not self.UI.VolumeSlider.Dragging then
        self.UI.VolumeSlider:Set(self.Volume or 0.65, true)
    end

    local cover = track and (track.Cover or self:_coverFor(track)) or nil
    if track then
        track.Cover = cover
    end

    self.UI.Cover.Image = cover or ""
    self.UI.Cover.Visible = cover ~= nil
    self.UI.CoverFallback.Visible = cover == nil
    self.UI.MiniTitle.Text = track and track.Name or "Music Player"
end

function MusicPlayer:_build()
    if self.UI then
        return
    end

    local parent = self.WindUI.ScreenGui
    local z = 5000

    local root = Instance.new("Frame")
    root.Name = "VantaGlassMusicPlayer"
    root.Size = UDim2.fromOffset(360, 258)
    root.Position = UDim2.new(0.5, -180, 0.5, -129)
    root.BackgroundColor3 = self:_glassColor()
    root.BackgroundTransparency = 0.16
    root.BorderSizePixel = 0
    root.Visible = false
    root.ClipsDescendants = false
    root.ZIndex = z
    root.Parent = parent
    corner(root, 15)

    local rootStroke = stroke(root, self:_theme("Outline", Color3.fromRGB(90, 24, 36)), 0.52, 1)
    rootStroke.Name = "GlassStroke"

    local glassGradient = gradient(
        root,
        self:_theme("ElementBackground", Color3.fromRGB(21, 17, 22)):Lerp(Color3.new(1, 1, 1), 0.045),
        self:_theme("Background", Color3.new(0, 0, 0)),
        115
    )
    glassGradient.Name = "GlassGradient"

    local sheen = Instance.new("Frame")
    sheen.Name = "TopSheen"
    sheen.Size = UDim2.new(1, -24, 0, 1)
    sheen.Position = UDim2.fromOffset(12, 1)
    sheen.BackgroundColor3 = Color3.new(1, 1, 1)
    sheen.BackgroundTransparency = 0.68
    sheen.BorderSizePixel = 0
    sheen.ZIndex = z + 2
    sheen.Parent = root
    local sheenGradient = Instance.new("UIGradient")
    sheenGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.22, 0.15),
        NumberSequenceKeypoint.new(0.78, 0.15),
        NumberSequenceKeypoint.new(1, 1),
    })
    sheenGradient.Parent = sheen

    local top = Instance.new("Frame")
    top.Name = "Topbar"
    top.Size = UDim2.new(1, 0, 0, 38)
    top.BackgroundTransparency = 1
    top.Active = true
    top.ZIndex = z + 3
    top.Parent = root

    local musicIcon = self:_icon(top, "music-2", 15)
    musicIcon.Position = UDim2.fromOffset(13, 11)
    musicIcon.ZIndex = z + 4

    local topTitle = self:_text(top, "Music Player", 12, true)
    topTitle.Position = UDim2.fromOffset(36, 0)
    topTitle.Size = UDim2.new(1, -108, 1, 0)
    topTitle.ZIndex = z + 4

    local minimize = self:_button(top, "minus", 25, function()
        self:Minimize()
    end)
    minimize.Position = UDim2.new(1, -58, 0, 6)
    minimize.ZIndex = z + 4

    local close = self:_button(top, "x", 25, function()
        root.Visible = false
    end)
    close.Position = UDim2.new(1, -29, 0, 6)
    close.ZIndex = z + 4

    local nowCard = Instance.new("Frame")
    nowCard.Name = "NowPlayingGlass"
    nowCard.Size = UDim2.new(1, -24, 0, 124)
    nowCard.Position = UDim2.fromOffset(12, 40)
    nowCard.BackgroundColor3 = self:_theme("ElementBackground", Color3.fromRGB(21, 17, 22))
    nowCard.BackgroundTransparency = 0.58
    nowCard.BorderSizePixel = 0
    nowCard.ZIndex = z + 2
    nowCard.Parent = root
    corner(nowCard, 12)
    stroke(nowCard, Color3.new(1, 1, 1), 0.88, 1)
    gradient(nowCard, Color3.new(1, 1, 1):Lerp(self:_glassColor(), 0.96), self:_glassColor(), 120)

    local coverBox = Instance.new("Frame")
    coverBox.Name = "CoverCard"
    coverBox.Size = UDim2.fromOffset(76, 76)
    coverBox.Position = UDim2.fromOffset(8, 8)
    coverBox.BackgroundColor3 = self:_theme("ElementBackground", Color3.fromRGB(21, 17, 22))
    coverBox.BackgroundTransparency = 0.32
    coverBox.BorderSizePixel = 0
    coverBox.ZIndex = z + 4
    coverBox.Parent = nowCard
    corner(coverBox, 11)
    stroke(coverBox, Color3.new(1, 1, 1), 0.82, 1)

    local cover = Instance.new("ImageLabel")
    cover.Name = "Cover"
    cover.BackgroundTransparency = 1
    cover.Size = UDim2.fromScale(1, 1)
    cover.ScaleType = Enum.ScaleType.Crop
    cover.ZIndex = z + 5
    cover.Parent = coverBox
    corner(cover, 11)

    local coverFallback = self:_icon(coverBox, "disc-3", 29)
    coverFallback.AnchorPoint = Vector2.new(0.5, 0.5)
    coverFallback.Position = UDim2.fromScale(0.5, 0.5)
    coverFallback.ZIndex = z + 5

    local title = self:_text(nowCard, "Nothing playing", 14, true)
    title.Position = UDim2.fromOffset(96, 7)
    title.Size = UDim2.new(1, -106, 0, 22)
    title.ZIndex = z + 5

    local sub = self:_text(nowCard, "Drop your songs into VantaTest/Music", 9, false)
    sub.Position = UDim2.fromOffset(96, 27)
    sub.Size = UDim2.new(1, -106, 0, 16)
    sub.TextTransparency = 0.48
    sub.ZIndex = z + 5

    local time = self:_text(nowCard, "0:00", 9, false)
    time.Position = UDim2.fromOffset(96, 58)
    time.Size = UDim2.fromOffset(32, 14)
    time.TextTransparency = 0.50
    time.ZIndex = z + 5

    local duration = self:_text(nowCard, "0:00", 9, false)
    duration.Position = UDim2.new(1, -42, 0, 58)
    duration.Size = UDim2.fromOffset(32, 14)
    duration.TextXAlignment = Enum.TextXAlignment.Right
    duration.TextTransparency = 0.50
    duration.ZIndex = z + 5

    local progressSlider
    progressSlider = self:_createGlassSlider(nowCard, {
        Name = "ProgressSlider",
        Width = 244,
        Position = UDim2.fromOffset(96, 45),
        Ratio = 0,
        KnobSize = 10,
        TrackHeight = 4,
        HitHeight = 16,
        ZIndex = z + 6,
        OnChanged = function(ratio)
            if self.Sound and self.Sound.TimeLength > 0 then
                self.Sound.TimePosition = self.Sound.TimeLength * ratio
            end
        end,
    })

    local controls = Instance.new("Frame")
    controls.Name = "Controls"
    controls.BackgroundTransparency = 1
    controls.Size = UDim2.fromOffset(244, 36)
    controls.Position = UDim2.fromOffset(96, 73)
    controls.ZIndex = z + 5
    controls.Parent = nowCard

    local shuffle = self:_button(controls, "shuffle", 28, function()
        self.Shuffle = not self.Shuffle
        self:_updateModeButtons()
    end)
    shuffle.Position = UDim2.fromOffset(0, 4)
    shuffle.ZIndex = z + 6

    local previous = self:_button(controls, "skip-back", 28, function()
        self:Previous()
    end)
    previous.Position = UDim2.fromOffset(44, 4)
    previous.ZIndex = z + 6

    local play = self:_button(controls, "play", 36, function()
        self:TogglePlay()
    end)
    play.Position = UDim2.fromOffset(89, 0)
    play.BackgroundColor3 = self:_theme("Button", Color3.fromRGB(37, 16, 22))
    play.BackgroundTransparency = 0.28
    play.ZIndex = z + 6
    stroke(play, Color3.new(1, 1, 1), 0.84, 1)

    local playIcon = play:FindFirstChildOfClass("ImageLabel")
    local pauseIcon = self:_icon(play, "pause", 17)
    pauseIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    pauseIcon.Position = UDim2.fromScale(0.5, 0.5)
    pauseIcon.Visible = false
    pauseIcon.ZIndex = z + 8

    local nextButton = self:_button(controls, "skip-forward", 28, function()
        self:Next()
    end)
    nextButton.Position = UDim2.fromOffset(137, 4)
    nextButton.ZIndex = z + 6

    local repeatButton = self:_button(controls, "repeat-2", 28, function()
        self.RepeatOne = not self.RepeatOne
        if self.Sound then
            self.Sound.Looped = self.RepeatOne
        end
        self:_updateModeButtons()
    end)
    repeatButton.Position = UDim2.fromOffset(181, 4)
    repeatButton.ZIndex = z + 6

    local volumeIcon = self:_icon(nowCard, "volume-2", 13)
    volumeIcon.Position = UDim2.fromOffset(9, 96)
    volumeIcon.ZIndex = z + 6

    local volumeSlider
    volumeSlider = self:_createGlassSlider(nowCard, {
        Name = "VolumeSlider",
        Width = 55,
        Position = UDim2.fromOffset(28, 91),
        Ratio = self.Volume or 0.65,
        KnobSize = 9,
        TrackHeight = 4,
        HitHeight = 17,
        ZIndex = z + 6,
        OnChanged = function(ratio)
            self.Volume = ratio
            if self.Sound then
                self.Sound.Volume = ratio
            end
        end,
    })

    local divider = Instance.new("Frame")
    divider.Name = "Divider"
    divider.Size = UDim2.new(1, -24, 0, 1)
    divider.Position = UDim2.fromOffset(12, 171)
    divider.BackgroundColor3 = Color3.new(1, 1, 1)
    divider.BackgroundTransparency = 0.88
    divider.BorderSizePixel = 0
    divider.ZIndex = z + 2
    divider.Parent = root

    local playlistHeader = self:_text(root, "Playlist", 11, true)
    playlistHeader.Position = UDim2.fromOffset(14, 177)
    playlistHeader.Size = UDim2.fromOffset(80, 22)
    playlistHeader.ZIndex = z + 4

    local refresh = self:_button(root, "refresh-cw", 24, function()
        self:Refresh()
    end)
    refresh.Position = UDim2.new(1, -62, 0, 176)
    refresh.ZIndex = z + 5

    local folder = self:_button(root, "folder-open", 24, function()
        if OpenFolder then
            pcall(OpenFolder, self.Folder)
        end
    end)
    folder.Position = UDim2.new(1, -34, 0, 176)
    folder.ZIndex = z + 5

    local listCard = Instance.new("Frame")
    listCard.Name = "PlaylistGlass"
    listCard.Size = UDim2.new(1, -24, 0, 52)
    listCard.Position = UDim2.fromOffset(12, 202)
    listCard.BackgroundColor3 = self:_theme("ElementBackground", Color3.fromRGB(21, 17, 22))
    listCard.BackgroundTransparency = 0.74
    listCard.BorderSizePixel = 0
    listCard.ZIndex = z + 2
    listCard.Parent = root
    corner(listCard, 10)
    stroke(listCard, Color3.new(1, 1, 1), 0.90, 1)

    local list = Instance.new("ScrollingFrame")
    list.Name = "List"
    list.BackgroundTransparency = 1
    list.BorderSizePixel = 0
    list.ScrollBarThickness = 2
    list.ScrollBarImageTransparency = 0.45
    list.Size = UDim2.new(1, -10, 1, -8)
    list.Position = UDim2.fromOffset(5, 4)
    list.CanvasSize = UDim2.new()
    list.AutomaticCanvasSize = Enum.AutomaticSize.Y
    list.ZIndex = z + 4
    list.Parent = listCard

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 3)
    layout.Parent = list

    local empty = self:_text(list, "No songs yet  •  add MP3 files to VantaTest/Music", 9, false)
    empty.Size = UDim2.new(1, 0, 0, 38)
    empty.TextXAlignment = Enum.TextXAlignment.Center
    empty.TextTransparency = 0.48
    empty.ZIndex = z + 5

    local mini = Instance.new("Frame")
    mini.Name = "VantaGlassMusicMini"
    mini.Size = UDim2.fromOffset(224, 44)
    mini.Position = UDim2.new(0.5, -112, 0.82, 0)
    mini.BackgroundColor3 = self:_glassColor()
    mini.BackgroundTransparency = 0.15
    mini.BorderSizePixel = 0
    mini.Visible = false
    mini.ZIndex = z + 20
    mini.Parent = parent
    corner(mini, 14)
    local miniStroke = stroke(mini, self:_theme("Outline", Color3.fromRGB(90, 24, 36)), 0.54, 1)
    miniStroke.Name = "GlassStroke"
    gradient(mini, self:_theme("ElementBackground", Color3.fromRGB(21, 17, 22)), self:_theme("Background", Color3.new(0, 0, 0)), 100)

    local miniIcon = self:_icon(mini, "music-2", 13)
    miniIcon.Position = UDim2.fromOffset(11, 15)
    miniIcon.ZIndex = z + 22

    local miniTitle = self:_text(mini, "Music Player", 10, true)
    miniTitle.Position = UDim2.fromOffset(32, 0)
    miniTitle.Size = UDim2.new(1, -92, 1, 0)
    miniTitle.ZIndex = z + 22

    local miniPlay = self:_button(mini, "play", 28, function()
        self:TogglePlay()
    end)
    miniPlay.Position = UDim2.new(1, -61, 0, 8)
    miniPlay.ZIndex = z + 22
    local miniPlayIcon = miniPlay:FindFirstChildOfClass("ImageLabel")

    local miniPause = self:_icon(miniPlay, "pause", 14)
    miniPause.AnchorPoint = Vector2.new(0.5, 0.5)
    miniPause.Position = UDim2.fromScale(0.5, 0.5)
    miniPause.Visible = false
    miniPause.ZIndex = z + 24

    local restore = self:_button(mini, "chevron-up", 28, function()
        self:Restore()
    end)
    restore.Position = UDim2.new(1, -31, 0, 8)
    restore.ZIndex = z + 22

    self.UI = {
        Root = root,
        Mini = mini,
        Title = title,
        Sub = sub,
        Cover = cover,
        CoverFallback = coverFallback,
        Time = time,
        Duration = duration,
        PlayIcon = playIcon,
        PauseIcon = pauseIcon,
        List = list,
        Empty = empty,
        MiniTitle = miniTitle,
        MiniPlay = miniPlayIcon,
        MiniPause = miniPause,
        ProgressSlider = progressSlider,
        VolumeSlider = volumeSlider,
        ShuffleButton = shuffle,
        RepeatButton = repeatButton,
        RootStroke = rootStroke,
        MiniStroke = miniStroke,
        GlassGradient = glassGradient,
        NowCard = nowCard,
        CoverBox = coverBox,
        ListCard = listCard,
    }

    function self:_updateModeButtons()
        if not self.UI then
            return
        end
        local onColor = self:_theme("Primary", Color3.fromRGB(161, 22, 47))
        local offColor = self:_theme("Button", Color3.fromRGB(37, 16, 22))

        self.UI.ShuffleButton.BackgroundColor3 = self.Shuffle and onColor or offColor
        self.UI.ShuffleButton.BackgroundTransparency = self.Shuffle and 0.55 or 1
        self.UI.RepeatButton.BackgroundColor3 = self.RepeatOne and onColor or offColor
        self.UI.RepeatButton.BackgroundTransparency = self.RepeatOne and 0.55 or 1
    end

    if BaseDrag then
        BaseDrag(self, root, top)
        BaseDrag(self, mini, mini)
    end

    setZ(root, z)
    setZ(mini, z + 20)

    self:ApplyTheme()
    self:_updateModeButtons()
end

function MusicPlayer:ApplyTheme()
    BaseApplyTheme(self)

    if not self.UI then
        return
    end

    local glass = self:_glassColor()
    local outline = self:_theme("Outline", Color3.fromRGB(90, 24, 36))
    local element = self:_theme("ElementBackground", Color3.fromRGB(21, 17, 22))
    local background = self:_theme("Background", Color3.new(0, 0, 0))

    self.UI.Root.BackgroundColor3 = glass
    self.UI.Mini.BackgroundColor3 = glass
    self.UI.NowCard.BackgroundColor3 = element
    self.UI.CoverBox.BackgroundColor3 = element
    self.UI.ListCard.BackgroundColor3 = element

    if self.UI.RootStroke then
        self.UI.RootStroke.Color = outline
    end
    if self.UI.MiniStroke then
        self.UI.MiniStroke.Color = outline
    end
    if self.UI.GlassGradient then
        self.UI.GlassGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, element:Lerp(Color3.new(1, 1, 1), 0.045)),
            ColorSequenceKeypoint.new(1, background),
        })
    end

    if self.UI.ProgressSlider then
        self.UI.ProgressSlider:SetTheme()
    end
    if self.UI.VolumeSlider then
        self.UI.VolumeSlider:SetTheme()
    end

    self:_updateModeButtons()
end

return MusicPlayer
