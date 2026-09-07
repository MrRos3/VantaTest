-- VantaTest premium music-player presentation layer.
-- Builds on musicplayer_polished.lua without touching the proven audio/drag engine.

local CACHE_BUSTER = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local POLISHED_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/musicplayer_polished.lua?v=" .. CACHE_BUSTER

local ok, source = pcall(function()
    return game:HttpGet(POLISHED_URL)
end)
assert(ok and type(source) == "string" and #source > 0, "[VantaTest Music] Could not load polished player")

local loader, loadError = loadstring(source)
assert(loader, "[VantaTest Music] Polished player compile failed: " .. tostring(loadError))

local MusicPlayer = loader()
assert(type(MusicPlayer) == "table", "[VantaTest Music] Polished player returned an invalid value")

local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local BaseBuild = MusicPlayer._build
local BaseUpdate = MusicPlayer._update
local BaseRenderList = MusicPlayer._renderList
local BaseApplyTheme = MusicPlayer.ApplyTheme

local function corner(parent, radius)
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, radius or 10)
    c.Parent = parent
    return c
end

local function stroke(parent, color, transparency, thickness)
    local s = Instance.new("UIStroke")
    s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
    s.Color = color
    s.Transparency = transparency or 0.75
    s.Thickness = thickness or 1
    s.Parent = parent
    return s
end

local function tween(object, duration, properties, style, direction)
    if not object or not object.Parent then
        return nil
    end
    local t = TweenService:Create(
        object,
        TweenInfo.new(duration, style or Enum.EasingStyle.Quint, direction or Enum.EasingDirection.Out),
        properties
    )
    t:Play()
    return t
end

local function formatTime(seconds)
    seconds = math.max(0, tonumber(seconds) or 0)
    return string.format("%d:%02d", math.floor(seconds / 60), math.floor(seconds % 60))
end

function MusicPlayer:_premiumCoverFor(track)
    if not track then
        return nil
    end
    track.Cover = track.Cover or self:_coverFor(track)
    return track.Cover
end

function MusicPlayer:_buildPremiumMini()
    if not self.UI or not self.UI.Mini or self.UI.PremiumMini then
        return
    end

    local mini = self.UI.Mini
    local z = mini.ZIndex + 3

    -- Keep the polished transition's native 224x44 geometry so animation and
    -- drag memory remain perfectly aligned.
    mini.Size = UDim2.fromOffset(224, 44)

    for _, child in ipairs(mini:GetChildren()) do
        if child:IsA("GuiObject") then
            child.Visible = false
        end
    end

    local miniCorner = mini:FindFirstChildOfClass("UICorner")
    if miniCorner then
        miniCorner.CornerRadius = UDim.new(0, 14)
    end

    local content = Instance.new("Frame")
    content.Name = "PremiumContent"
    content.BackgroundTransparency = 1
    content.Size = UDim2.fromScale(1, 1)
    content.ZIndex = z
    content.Parent = mini

    local coverBox = Instance.new("Frame")
    coverBox.Name = "MiniCoverBox"
    coverBox.Size = UDim2.fromOffset(32, 32)
    coverBox.Position = UDim2.fromOffset(6, 6)
    coverBox.BackgroundColor3 = self:_theme("ElementBackground", Color3.fromRGB(21, 17, 22))
    coverBox.BackgroundTransparency = 0.22
    coverBox.BorderSizePixel = 0
    coverBox.ZIndex = z + 1
    coverBox.Parent = content
    corner(coverBox, 8)
    stroke(coverBox, Color3.new(1, 1, 1), 0.84, 1)

    local cover = Instance.new("ImageLabel")
    cover.Name = "Cover"
    cover.BackgroundTransparency = 1
    cover.Size = UDim2.fromScale(1, 1)
    cover.ScaleType = Enum.ScaleType.Crop
    cover.ZIndex = z + 2
    cover.Parent = coverBox
    corner(cover, 8)

    local coverOld = cover:Clone()
    coverOld.Name = "CoverOld"
    coverOld.Image = ""
    coverOld.ImageTransparency = 1
    coverOld.ZIndex = z + 3
    coverOld.Parent = coverBox

    local fallback = self:_icon(coverBox, "music-2", 14)
    fallback.AnchorPoint = Vector2.new(0.5, 0.5)
    fallback.Position = UDim2.fromScale(0.5, 0.5)
    fallback.ZIndex = z + 1

    local title = self:_text(content, "Music Player", 10, true)
    title.Name = "MiniTitlePremium"
    title.Position = UDim2.fromOffset(46, 3)
    title.Size = UDim2.fromOffset(104, 17)
    title.TextTruncate = Enum.TextTruncate.AtEnd
    title.ZIndex = z + 2

    local sub = self:_text(content, "Nothing playing", 8, false)
    sub.Name = "MiniSubtitle"
    sub.Position = UDim2.fromOffset(46, 18)
    sub.Size = UDim2.fromOffset(104, 13)
    sub.TextTransparency = 0.48
    sub.TextTruncate = Enum.TextTruncate.AtEnd
    sub.ZIndex = z + 2

    local playButton = self:_button(content, "play", 26, function()
        self:TogglePlay()
    end)
    playButton.Position = UDim2.new(1, -58, 0, 9)
    playButton.BackgroundColor3 = self:_theme("Button", Color3.fromRGB(37, 16, 22))
    playButton.BackgroundTransparency = 0.28
    playButton.ZIndex = z + 4
    stroke(playButton, Color3.new(1, 1, 1), 0.86, 1)

    local playIcon = playButton:FindFirstChildOfClass("ImageLabel")
    local pauseIcon = self:_icon(playButton, "pause", 13)
    pauseIcon.AnchorPoint = Vector2.new(0.5, 0.5)
    pauseIcon.Position = UDim2.fromScale(0.5, 0.5)
    pauseIcon.Visible = false
    pauseIcon.ZIndex = z + 6

    local restore = self:_button(content, "chevron-up", 26, function()
        self:Restore()
    end)
    restore.Position = UDim2.new(1, -29, 0, 9)
    restore.ZIndex = z + 4

    local progressTrack = Instance.new("Frame")
    progressTrack.Name = "MiniProgressTrack"
    progressTrack.Size = UDim2.new(1, -114, 0, 2)
    progressTrack.Position = UDim2.fromOffset(46, 37)
    progressTrack.BackgroundColor3 = self:_theme("ElementBackground", Color3.fromRGB(21, 17, 22))
    progressTrack.BackgroundTransparency = 0.18
    progressTrack.BorderSizePixel = 0
    progressTrack.ZIndex = z + 2
    progressTrack.Parent = content
    corner(progressTrack, 99)

    local progressFill = Instance.new("Frame")
    progressFill.Name = "Fill"
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = self:_theme("Slider", Color3.fromRGB(161, 22, 47))
    progressFill.BorderSizePixel = 0
    progressFill.ZIndex = z + 3
    progressFill.Parent = progressTrack
    corner(progressFill, 99)

    self.UI.PremiumMini = content
    self.UI.MiniCover = cover
    self.UI.MiniCoverOld = coverOld
    self.UI.MiniCoverFallback = fallback
    self.UI.MiniPremiumTitle = title
    self.UI.MiniPremiumSub = sub
    self.UI.MiniPremiumPlayIcon = playIcon
    self.UI.MiniPremiumPauseIcon = pauseIcon
    self.UI.MiniProgressTrack = progressTrack
    self.UI.MiniProgressFill = progressFill
end

function MusicPlayer:_buildPremiumMainCover()
    if not self.UI or not self.UI.Cover or self.UI.CoverOld then
        return
    end

    local cover = self.UI.Cover
    local old = cover:Clone()
    old.Name = "CoverOld"
    old.Image = ""
    old.ImageTransparency = 1
    old.Visible = true
    old.ZIndex = cover.ZIndex + 1
    old.Parent = cover.Parent
    self.UI.CoverOld = old
end

function MusicPlayer:_buildPremiumVolumeIcon()
    if not self.UI or not self.UI.NowCard or self.UI.PremiumVolumeIcon then
        return
    end

    for _, d in ipairs(self.UI.NowCard:GetDescendants()) do
        if d:IsA("ImageLabel") and d.Position.X.Offset == 9 and d.Position.Y.Offset == 96 then
            d.Visible = false
        end
    end

    local icon = self:_icon(self.UI.NowCard, "volume-2", 13)
    icon.Name = "PremiumVolumeIcon"
    icon.Position = UDim2.fromOffset(9, 96)
    icon.ZIndex = self.UI.NowCard.ZIndex + 8
    self.UI.PremiumVolumeIcon = icon
end

function MusicPlayer:_setPremiumVolumeIcon()
    if not self.UI or not self.UI.PremiumVolumeIcon then
        return
    end

    local ratio = math.clamp(self.Volume or 0, 0, 1)
    local name
    if ratio <= 0.01 then
        name = "volume-x"
    elseif ratio < 0.34 then
        name = "volume"
    elseif ratio < 0.67 then
        name = "volume-1"
    else
        name = "volume-2"
    end

    local data = self.WindUI.Creator.Icon(name)
    if data then
        self.UI.PremiumVolumeIcon.Image = data[1]
        if data[2] then
            self.UI.PremiumVolumeIcon.ImageRectOffset = data[2].ImageRectPosition
            self.UI.PremiumVolumeIcon.ImageRectSize = data[2].ImageRectSize
        end
    end
end

function MusicPlayer:_crossfadeCover(newCover, previousMainImage, previousMiniImage)
    if not self.UI then
        return
    end

    local cover = self.UI.Cover
    local old = self.UI.CoverOld
    local fallback = self.UI.CoverFallback

    if cover and old then
        old.Image = previousMainImage or ""
        old.ImageTransparency = 0
        old.Visible = old.Image ~= ""

        cover.Image = newCover or ""
        cover.Visible = newCover ~= nil
        cover.ImageTransparency = 1
        if fallback then
            fallback.Visible = newCover == nil
            fallback.ImageTransparency = newCover and 1 or 0
        end

        if newCover then
            tween(cover, 0.22, { ImageTransparency = 0 })
        end
        if old.Visible then
            tween(old, 0.22, { ImageTransparency = 1 })
        end
    end

    local miniCover = self.UI.MiniCover
    local miniOld = self.UI.MiniCoverOld
    local miniFallback = self.UI.MiniCoverFallback
    if miniCover and miniOld then
        miniOld.Image = previousMiniImage or miniCover.Image or ""
        miniOld.ImageTransparency = 0
        miniOld.Visible = miniOld.Image ~= ""

        miniCover.Image = newCover or ""
        miniCover.Visible = newCover ~= nil
        miniCover.ImageTransparency = 1
        if miniFallback then
            miniFallback.Visible = newCover == nil
            miniFallback.ImageTransparency = newCover and 1 or 0
        end

        if newCover then
            tween(miniCover, 0.22, { ImageTransparency = 0 })
        end
        if miniOld.Visible then
            tween(miniOld, 0.22, { ImageTransparency = 1 })
        end
    end
end

function MusicPlayer:_renderList()
    if not self.UI or not self.UI.List then
        return BaseRenderList(self)
    end

    for _, row in ipairs(self.Rows or {}) do
        if row and row.Parent then
            row:Destroy()
        end
    end
    self.Rows = {}

    if self._PremiumEqualizerConnection then
        self._PremiumEqualizerConnection:Disconnect()
        self._PremiumEqualizerConnection = nil
    end

    self.UI.Empty.Visible = #self.Tracks == 0
    local activeBars = nil

    for i, track in ipairs(self.Tracks) do
        local selected = i == self.CurrentIndex
        local row = Instance.new("TextButton")
        row.Name = "Track_" .. tostring(i)
        row.Text = ""
        row.AutoButtonColor = false
        row.Size = UDim2.new(1, 0, 0, 38)
        row.BackgroundColor3 = self:_theme("ElementBackground", Color3.fromRGB(21, 17, 22))
        row.BackgroundTransparency = selected and 0.44 or 0.84
        row.BorderSizePixel = 0
        row.Parent = self.UI.List
        corner(row, 9)
        stroke(row, selected and self:_theme("Outline", Color3.fromRGB(90, 24, 36)) or Color3.new(1, 1, 1), selected and 0.56 or 0.92, 1)

        local coverBox = Instance.new("Frame")
        coverBox.Size = UDim2.fromOffset(28, 28)
        coverBox.Position = UDim2.fromOffset(5, 5)
        coverBox.BackgroundColor3 = self:_theme("ElementBackground", Color3.fromRGB(21, 17, 22))
        coverBox.BackgroundTransparency = 0.25
        coverBox.BorderSizePixel = 0
        coverBox.Parent = row
        corner(coverBox, 7)

        local cover = Instance.new("ImageLabel")
        cover.BackgroundTransparency = 1
        cover.Size = UDim2.fromScale(1, 1)
        cover.ScaleType = Enum.ScaleType.Crop
        cover.Image = self:_premiumCoverFor(track) or ""
        cover.Visible = cover.Image ~= ""
        cover.Parent = coverBox
        corner(cover, 7)

        if not cover.Visible then
            local icon = self:_icon(coverBox, "music-2", 12)
            icon.AnchorPoint = Vector2.new(0.5, 0.5)
            icon.Position = UDim2.fromScale(0.5, 0.5)
        end

        local title = self:_text(row, track.Name, 10, selected)
        title.Position = UDim2.fromOffset(42, 5)
        title.Size = UDim2.new(1, -86, 0, 17)
        title.TextTruncate = Enum.TextTruncate.AtEnd

        local ext = string.upper(track.Path:match("%.([^%.]+)$") or "AUDIO")
        local sub = self:_text(row, "LOCAL  •  " .. ext, 8, false)
        sub.Position = UDim2.fromOffset(42, 20)
        sub.Size = UDim2.new(1, -86, 0, 13)
        sub.TextTransparency = 0.58

        if selected then
            local eq = Instance.new("Frame")
            eq.Name = "Equalizer"
            eq.BackgroundTransparency = 1
            eq.Size = UDim2.fromOffset(26, 18)
            eq.Position = UDim2.new(1, -33, 0.5, -9)
            eq.Parent = row

            local bars = {}
            for b = 1, 3 do
                local bar = Instance.new("Frame")
                bar.AnchorPoint = Vector2.new(0.5, 1)
                bar.Position = UDim2.new(0, 5 + (b - 1) * 7, 1, 0)
                bar.Size = UDim2.fromOffset(3, 5 + b * 2)
                bar.BackgroundColor3 = self:_theme("Primary", Color3.fromRGB(161, 22, 47))
                bar.BorderSizePixel = 0
                bar.Parent = eq
                corner(bar, 99)
                table.insert(bars, bar)
            end
            activeBars = bars
        end

        row.MouseEnter:Connect(function()
            if i ~= self.CurrentIndex then
                tween(row, 0.12, { BackgroundTransparency = 0.68 })
            end
        end)
        row.MouseLeave:Connect(function()
            if i ~= self.CurrentIndex then
                tween(row, 0.12, { BackgroundTransparency = 0.84 })
            end
        end)
        row.MouseButton1Click:Connect(function()
            self:_load(i, true)
            task.defer(function()
                if self.UI then
                    self:_renderList()
                end
            end)
        end)

        table.insert(self.Rows, row)
    end

    if activeBars then
        local phase = 0
        self._PremiumEqualizerConnection = RunService.RenderStepped:Connect(function(dt)
            if not activeBars[1] or not activeBars[1].Parent then
                return
            end
            phase = phase + dt * 7
            for index, bar in ipairs(activeBars) do
                local playingScale = self.Playing and 1 or 0.25
                local height = 5 + math.abs(math.sin(phase + index * 1.7)) * 9 * playingScale
                bar.Size = UDim2.fromOffset(3, height)
            end
        end)
    end
end

function MusicPlayer:_updatePremiumMiniOnly()
    if not self.UI or not self.UI.Mini or not self.UI.Mini.Visible then
        return
    end

    local sound = self.Sound
    if sound then
        self.Playing = sound.Playing == true
    end

    local track = self.CurrentIndex and self.Tracks[self.CurrentIndex] or nil
    local position = sound and sound.TimePosition or 0
    local length = sound and sound.TimeLength or 0
    local ratio = length > 0 and math.clamp(position / length, 0, 1) or 0

    if self.UI.MiniProgressFill then
        local current = self.UI.MiniProgressFill.Size.X.Scale
        self.UI.MiniProgressFill.Size = UDim2.new(current + (ratio - current) * 0.20, 0, 1, 0)
    end

    if self.UI.MiniPremiumTitle then
        self.UI.MiniPremiumTitle.Text = track and track.Name or "Music Player"
    end
    if self.UI.MiniPremiumSub then
        self.UI.MiniPremiumSub.Text = track and (formatTime(position) .. "  •  " .. formatTime(length)) or "Nothing playing"
    end
    if self.UI.MiniPremiumPlayIcon then
        self.UI.MiniPremiumPlayIcon.Visible = not self.Playing
    end
    if self.UI.MiniPremiumPauseIcon then
        self.UI.MiniPremiumPauseIcon.Visible = self.Playing
    end

    if self._PremiumMiniLastIndex ~= self.CurrentIndex then
        local previousMini = self.UI.MiniCover and self.UI.MiniCover.Image or ""
        local newCover = self:_premiumCoverFor(track)
        self:_crossfadeCover(newCover, self.UI.Cover and self.UI.Cover.Image or "", previousMini)
        self._PremiumMiniLastIndex = self.CurrentIndex
        self._PremiumLastCover = newCover
    end
end

function MusicPlayer:_update()
    local previousIndex = self._PremiumLastIndex
    local previousCover = self._PremiumLastCover
    local previousMainImage = self.UI and self.UI.Cover and self.UI.Cover.Image or ""
    local previousMiniImage = self.UI and self.UI.MiniCover and self.UI.MiniCover.Image or ""

    BaseUpdate(self)

    if not self.UI then
        return
    end

    local track = self.CurrentIndex and self.Tracks[self.CurrentIndex] or nil
    local cover = self:_premiumCoverFor(track)

    if self.CurrentIndex ~= previousIndex or cover ~= previousCover then
        self:_crossfadeCover(cover, previousMainImage, previousMiniImage)
        self._PremiumLastIndex = self.CurrentIndex
        self._PremiumMiniLastIndex = self.CurrentIndex
        self._PremiumLastCover = cover
        task.defer(function()
            if self.UI then
                self:_renderList()
            end
        end)
    end

    local position = self.Sound and self.Sound.TimePosition or 0
    local length = self.Sound and self.Sound.TimeLength or 0
    local ratio = length > 0 and math.clamp(position / length, 0, 1) or 0

    if self.UI.MiniProgressFill then
        local current = self.UI.MiniProgressFill.Size.X.Scale
        self.UI.MiniProgressFill.Size = UDim2.new(current + (ratio - current) * 0.22, 0, 1, 0)
    end

    if self.UI.MiniPremiumTitle then
        self.UI.MiniPremiumTitle.Text = track and track.Name or "Music Player"
    end
    if self.UI.MiniPremiumSub then
        self.UI.MiniPremiumSub.Text = track and (formatTime(position) .. "  •  " .. formatTime(length)) or "Nothing playing"
    end
    if self.UI.MiniPremiumPlayIcon then
        self.UI.MiniPremiumPlayIcon.Visible = not self.Playing
    end
    if self.UI.MiniPremiumPauseIcon then
        self.UI.MiniPremiumPauseIcon.Visible = self.Playing
    end

    self:_setPremiumVolumeIcon()
end

function MusicPlayer:_build()
    BaseBuild(self)
    self:_buildPremiumMainCover()
    self:_buildPremiumMini()
    self:_buildPremiumVolumeIcon()
    self:_setPremiumVolumeIcon()

    if self.UI and self.UI.Mini and not self._MiniUserMoved then
        self.UI.Mini.Position = self:_defaultMiniPosition()
    end

    if not self._PremiumMiniUpdateConnection then
        self._PremiumMiniUpdateConnection = RunService.RenderStepped:Connect(function()
            if self.UI and self.UI.Mini and self.UI.Mini.Visible then
                self:_updatePremiumMiniOnly()
            end
        end)
    end
end

function MusicPlayer:ApplyTheme()
    BaseApplyTheme(self)
    if not self.UI then
        return
    end

    local primary = self:_theme("Slider", Color3.fromRGB(161, 22, 47))
    local element = self:_theme("ElementBackground", Color3.fromRGB(21, 17, 22))

    if self.UI.MiniProgressFill then
        self.UI.MiniProgressFill.BackgroundColor3 = primary
    end
    if self.UI.MiniProgressTrack then
        self.UI.MiniProgressTrack.BackgroundColor3 = element
    end
    if self.UI.PremiumVolumeIcon then
        self.UI.PremiumVolumeIcon.ImageColor3 = self:_theme("Icon", Color3.fromRGB(226, 221, 224))
    end

    if self.Rows and #self.Rows > 0 then
        task.defer(function()
            if self.UI then
                self:_renderList()
            end
        end)
    end
end

return MusicPlayer
