--[[
    VantaTest Music Player
    Local-file music player experiment for VantaUI.

    Songs are loaded only from the executor workspace folder:
        VantaTest/Music

    No Roblox catalog audio IDs are used.
]]

local MusicPlayer = {
    WindUI = nil,
    Window = nil,
    UI = nil,
    ThemeBindings = {},
    Rows = {},
    Tracks = {},
    CurrentIndex = nil,
    Playing = false,
    Shuffle = false,
    RepeatOne = false,
    Volume = 0.65,
    ProgressDragging = false,
    VolumeDragging = false,
    Folder = "VantaTest/Music",
    CoverFolder = "VantaTest/Music/.covers",
}

local cloneref = (cloneref or clonereference or function(instance)
    return instance
end)

local SoundService = cloneref(game:GetService("SoundService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))

local CustomAsset = getcustomasset or getsynasset
local OpenFolder = openfolder or open_folder

local AUDIO_EXTENSIONS = {
    mp3 = true,
    wav = true,
    ogg = true,
}

local COVER_EXTENSIONS = { "png", "jpg", "jpeg", "webp" }

local function trim(value)
    return tostring(value or ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function normalizePath(path)
    return tostring(path or ""):gsub("\\", "/")
end

local function extension(path)
    return string.lower(path:match("%.([^%.%/]+)$") or "")
end

local function filename(path)
    path = normalizePath(path)
    return path:match("([^/]+)$") or path
end

local function stem(path)
    return filename(path):gsub("%.[^%.]+$", "")
end

local function directory(path)
    path = normalizePath(path)
    return path:match("^(.*)/[^/]+$") or ""
end

local function sanitize(value)
    local result = tostring(value or "track"):gsub("[^%w%-_]", "_")
    if #result > 72 then
        result = result:sub(1, 72)
    end
    return result
end

local function ensureFolder(path)
    if not makefolder then
        return false
    end

    local current = ""
    for part in normalizePath(path):gmatch("[^/]+") do
        current = current == "" and part or (current .. "/" .. part)
        if not isfolder or not isfolder(current) then
            pcall(makefolder, current)
        end
    end
    return true
end

local function fileExists(path)
    return isfile and pcall(isfile, path) and isfile(path)
end

local function formatTime(seconds)
    seconds = tonumber(seconds) or 0
    if seconds < 0 or seconds ~= seconds or seconds == math.huge then
        seconds = 0
    end
    seconds = math.floor(seconds + 0.5)
    return string.format("%d:%02d", math.floor(seconds / 60), seconds % 60)
end

local function syncsafe(a, b, c, d)
    return (a or 0) * 2097152 + (b or 0) * 16384 + (c or 0) * 128 + (d or 0)
end

local function bigEndian32(a, b, c, d)
    return (a or 0) * 16777216 + (b or 0) * 65536 + (c or 0) * 256 + (d or 0)
end

local function detectImageExtension(mime, bytes)
    mime = string.lower(tostring(mime or ""))
    if mime:find("png", 1, true) then
        return "png"
    elseif mime:find("jpeg", 1, true) or mime:find("jpg", 1, true) then
        return "jpg"
    elseif mime:find("webp", 1, true) then
        return "webp"
    end

    if bytes:sub(1, 8) == "\137PNG\r\n\26\n" then
        return "png"
    elseif bytes:sub(1, 2) == "\255\216" then
        return "jpg"
    elseif bytes:sub(1, 4) == "RIFF" and bytes:sub(9, 12) == "WEBP" then
        return "webp"
    end
    return "jpg"
end

local function extractEmbeddedCover(path)
    if not readfile or not writefile or extension(path) ~= "mp3" then
        return nil
    end

    local ok, data = pcall(readfile, path)
    if not ok or type(data) ~= "string" or data:sub(1, 3) ~= "ID3" or #data < 20 then
        return nil
    end

    local version = data:byte(4)
    if version ~= 3 and version ~= 4 then
        return nil
    end

    local tagSize = syncsafe(data:byte(7), data:byte(8), data:byte(9), data:byte(10))
    local tagEnd = math.min(#data, 10 + tagSize)
    local pos = 11

    while pos + 9 <= tagEnd do
        local frameId = data:sub(pos, pos + 3)
        if frameId == "\0\0\0\0" or not frameId:match("^[%u%d][%u%d][%u%d][%u%d]$") then
            break
        end

        local a, b, c, d = data:byte(pos + 4, pos + 7)
        local frameSize = version == 4 and syncsafe(a, b, c, d) or bigEndian32(a, b, c, d)
        if frameSize <= 0 or pos + 10 + frameSize - 1 > tagEnd then
            break
        end

        if frameId == "APIC" then
            local payload = data:sub(pos + 10, pos + 10 + frameSize - 1)
            local encoding = payload:byte(1) or 0
            local mimeEnd = payload:find("\0", 2, true)
            if mimeEnd then
                local mime = payload:sub(2, mimeEnd - 1)
                local descriptionStart = mimeEnd + 2
                local imageStart

                if encoding == 1 or encoding == 2 then
                    local cursor = descriptionStart
                    while cursor < #payload do
                        if payload:byte(cursor) == 0 and payload:byte(cursor + 1) == 0 then
                            imageStart = cursor + 2
                            break
                        end
                        cursor = cursor + 2
                    end
                else
                    local descriptionEnd = payload:find("\0", descriptionStart, true)
                    imageStart = descriptionEnd and (descriptionEnd + 1) or descriptionStart
                end

                if imageStart and imageStart <= #payload then
                    local imageBytes = payload:sub(imageStart)
                    if #imageBytes > 64 then
                        return imageBytes, detectImageExtension(mime, imageBytes)
                    end
                end
            end
        end

        pos = pos + 10 + frameSize
    end

    return nil
end

local function tryCustomAsset(path)
    if not CustomAsset or not path then
        return nil
    end
    local ok, asset = pcall(CustomAsset, path)
    if ok and asset then
        return asset
    end
    return nil
end

local function resolveCover(track, coverFolder)
    if track.CoverResolved then
        return track.Cover
    end
    track.CoverResolved = true

    local basePath = track.Path:gsub("%.[^%.%/]+$", "")
    for _, ext in ipairs(COVER_EXTENSIONS) do
        local candidate = basePath .. "." .. ext
        if fileExists(candidate) then
            track.Cover = tryCustomAsset(candidate)
            if track.Cover then
                return track.Cover
            end
        end
    end

    local bytes, imageExt = extractEmbeddedCover(track.Path)
    if bytes and writefile then
        ensureFolder(coverFolder)
        local coverPath = coverFolder .. "/" .. sanitize(track.Name) .. "." .. tostring(imageExt or "jpg")
        local ok = pcall(writefile, coverPath, bytes)
        if ok then
            track.Cover = tryCustomAsset(coverPath)
            if track.Cover then
                return track.Cover
            end
        end
    end

    local folder = directory(track.Path)
    for _, ext in ipairs(COVER_EXTENSIONS) do
        local candidate = folder .. "/cover." .. ext
        if fileExists(candidate) then
            track.Cover = tryCustomAsset(candidate)
            if track.Cover then
                return track.Cover
            end
        end
    end

    return nil
end

local function makeCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 10)
    corner.Parent = parent
    return corner
end

local function addPadding(parent, left, right, top, bottom)
    local padding = Instance.new("UIPadding")
    padding.PaddingLeft = UDim.new(0, left or 0)
    padding.PaddingRight = UDim.new(0, right or 0)
    padding.PaddingTop = UDim.new(0, top or 0)
    padding.PaddingBottom = UDim.new(0, bottom or 0)
    padding.Parent = parent
    return padding
end

function MusicPlayer:_bindTheme(instance, property, key)
    table.insert(self.ThemeBindings, {
        Instance = instance,
        Property = property,
        Key = key,
    })
end

function MusicPlayer:_themeValue(key, fallback)
    local theme = self.WindUI and self.WindUI.Theme
    local value = theme and theme[key]
    return value ~= nil and value or fallback
end

function MusicPlayer:ApplyTheme()
    for _, binding in ipairs(self.ThemeBindings) do
        local object = binding.Instance
        if object and object.Parent then
            local value = self:_themeValue(binding.Key)
            if value ~= nil then
                pcall(function()
                    object[binding.Property] = value
                end)
            end
        end
    end

    if self.UI and self.UI.Stroke then
        self.UI.Stroke.Color = self:_themeValue("Outline", Color3.fromRGB(90, 24, 36))
    end
    if self.UI and self.UI.MiniStroke then
        self.UI.MiniStroke.Color = self:_themeValue("Outline", Color3.fromRGB(90, 24, 36))
    end

    self:_updatePlaylistSelection()
end

function MusicPlayer:_icon(name, size, parent, zIndex)
    local holder = Instance.new("ImageLabel")
    holder.BackgroundTransparency = 1
    holder.Size = UDim2.fromOffset(size, size)
    holder.ZIndex = zIndex or 1
    holder.Parent = parent

    local creator = self.WindUI and self.WindUI.Creator
    local icon = creator and creator.Icon and creator.Icon(name)
    if icon then
        holder.Image = icon[1]
        if icon[2] then
            holder.ImageRectOffset = icon[2].ImageRectPosition
            holder.ImageRectSize = icon[2].ImageRectSize
        end
    end
    holder.ImageColor3 = self:_themeValue("Icon", Color3.fromRGB(226, 221, 224))
    self:_bindTheme(holder, "ImageColor3", "Icon")
    return holder
end

function MusicPlayer:_iconButton(parent, iconName, size, zIndex, callback)
    local button = Instance.new("TextButton")
    button.AutoButtonColor = false
    button.Text = ""
    button.BackgroundTransparency = 1
    button.Size = UDim2.fromOffset(size, size)
    button.ZIndex = zIndex or 1
    button.Parent = parent

    local hover = Instance.new("Frame")
    hover.BackgroundColor3 = self:_themeValue("Button", Color3.fromRGB(37, 16, 22))
    hover.BackgroundTransparency = 1
    hover.Size = UDim2.fromScale(1, 1)
    hover.ZIndex = button.ZIndex
    hover.Parent = button
    makeCorner(hover, math.floor(size / 3))
    self:_bindTheme(hover, "BackgroundColor3", "Button")

    local icon = self:_icon(iconName, math.floor(size * 0.48), button, button.ZIndex + 1)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.5, 0.5)

    button.MouseEnter:Connect(function()
        hover.BackgroundTransparency = 0.45
    end)
    button.MouseLeave:Connect(function()
        hover.BackgroundTransparency = 1
    end)
    button.MouseButton1Click:Connect(function()
        if self.WindUI and self.WindUI.PlaySound then
            self.WindUI:PlaySound("Click")
        end
        if callback then
            callback()
        end
    end)

    return button, icon, hover
end

function MusicPlayer:_text(parent, text, size, weight, zIndex, themeKey)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text or ""
    label.TextSize = size or 14
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextYAlignment = Enum.TextYAlignment.Center
    label.TextTruncate = Enum.TextTruncate.AtEnd
    label.ZIndex = zIndex or 1
    label.FontFace = Font.new(
        (self.WindUI and self.WindUI.Creator and self.WindUI.Creator.Font) or "rbxasset://fonts/families/GothamSSm.json",
        weight or Enum.FontWeight.Regular
    )
    local key = themeKey or "Text"
    label.TextColor3 = self:_themeValue(key, Color3.new(1, 1, 1))
    self:_bindTheme(label, "TextColor3", key)
    label.Parent = parent
    return label
end

function MusicPlayer:_setCover(imageLabel, fallbackIcon, cover)
    if cover then
        imageLabel.Image = cover
        imageLabel.Visible = true
        fallbackIcon.Visible = false
    else
        imageLabel.Image = ""
        imageLabel.Visible = false
        fallbackIcon.Visible = true
    end
end

function MusicPlayer:_notify(title, content, icon)
    if self.WindUI and self.WindUI.Notify then
        self.WindUI:Notify({
            Title = title or "Music Player",
            Content = content or "",
            Icon = icon or "music-2",
            Duration = 5,
        })
    end
end

function MusicPlayer:_refreshLibrary()
    ensureFolder("VantaTest")
    ensureFolder(self.Folder)
    ensureFolder(self.CoverFolder)

    self.Tracks = {}

    if not listfiles then
        self.UnsupportedReason = "This executor does not expose listfiles()."
        self:_renderPlaylist()
        return
    end

    local ok, files = pcall(listfiles, self.Folder)
    if not ok or type(files) ~= "table" then
        self.UnsupportedReason = "The local music folder could not be scanned."
        self:_renderPlaylist()
        return
    end

    self.UnsupportedReason = nil
    for _, rawPath in ipairs(files) do
        local path = normalizePath(rawPath)
        local ext = extension(path)
        if AUDIO_EXTENSIONS[ext] then
            table.insert(self.Tracks, {
                Path = path,
                Name = trim(stem(path)),
                Extension = ext,
                Asset = nil,
                Cover = nil,
                CoverResolved = false,
            })
        end
    end

    table.sort(self.Tracks, function(a, b)
        return string.lower(a.Name) < string.lower(b.Name)
    end)

    if self.CurrentIndex and not self.Tracks[self.CurrentIndex] then
        self.CurrentIndex = nil
        self.Playing = false
        if self.Sound then
            self.Sound:Stop()
            self.Sound.SoundId = ""
        end
    end

    self:_renderPlaylist()
    self:_updateNowPlaying()
end

function MusicPlayer:_loadTrack(index, autoPlay)
    local track = self.Tracks[index]
    if not track then
        return false
    end

    if not CustomAsset then
        self:_notify(
            "Local audio unsupported",
            "This executor needs getcustomasset() or getsynasset() to play your MP3 files.",
            "triangle-alert"
        )
        return false
    end

    if not track.Asset then
        track.Asset = tryCustomAsset(track.Path)
    end
    if not track.Asset then
        self:_notify("Couldn't load song", track.Name .. " could not be loaded as a local asset.", "triangle-alert")
        return false
    end

    self.CurrentIndex = index
    self.Sound:Stop()
    self.Sound.SoundId = track.Asset
    self.Sound.Volume = self.Volume
    self.Sound.Looped = self.RepeatOne
    self.Sound.TimePosition = 0

    if autoPlay ~= false then
        self.Sound:Play()
        self.Playing = true
    else
        self.Playing = false
    end

    task.spawn(function()
        resolveCover(track, self.CoverFolder)
        self:_updateNowPlaying()
        self:_renderPlaylist()
    end)

    self:_updateNowPlaying()
    self:_updatePlaylistSelection()
    return true
end

function MusicPlayer:_togglePlayback()
    if not self.CurrentIndex then
        if #self.Tracks > 0 then
            self:_loadTrack(1, true)
        else
            self:_notify("No songs yet", "Put MP3 files inside " .. self.Folder .. " and press refresh.", "folder-open")
        end
        return
    end

    if self.Playing then
        self.Sound:Pause()
        self.Playing = false
    else
        if self.Sound.SoundId == "" then
            self:_loadTrack(self.CurrentIndex, true)
            return
        end
        local ok = pcall(function()
            self.Sound:Resume()
        end)
        if not ok or not self.Sound.Playing then
            self.Sound:Play()
        end
        self.Playing = true
    end

    self:_updatePlayIcons()
end

function MusicPlayer:_nextTrack()
    if #self.Tracks == 0 then
        return
    end

    local nextIndex
    if self.Shuffle and #self.Tracks > 1 then
        repeat
            nextIndex = math.random(1, #self.Tracks)
        until nextIndex ~= self.CurrentIndex
    else
        nextIndex = (self.CurrentIndex or 0) + 1
        if nextIndex > #self.Tracks then
            nextIndex = 1
        end
    end
    self:_loadTrack(nextIndex, true)
end

function MusicPlayer:_previousTrack()
    if #self.Tracks == 0 then
        return
    end

    if self.Sound and self.Sound.TimePosition > 3 then
        self.Sound.TimePosition = 0
        return
    end

    local previousIndex = (self.CurrentIndex or 1) - 1
    if previousIndex < 1 then
        previousIndex = #self.Tracks
    end
    self:_loadTrack(previousIndex, true)
end

function MusicPlayer:_updatePlayIcons()
    if not self.UI then
        return
    end

    local iconName = self.Playing and "pause" or "play"
    local creator = self.WindUI and self.WindUI.Creator
    local icon = creator and creator.Icon and creator.Icon(iconName)
    for _, image in ipairs({ self.UI.PlayIcon, self.UI.MiniPlayIcon }) do
        if image and icon then
            image.Image = icon[1]
            image.ImageRectOffset = icon[2].ImageRectPosition
            image.ImageRectSize = icon[2].ImageRectSize
        end
    end
end

function MusicPlayer:_updateNowPlaying()
    if not self.UI then
        return
    end

    local track = self.CurrentIndex and self.Tracks[self.CurrentIndex]
    local title = track and track.Name or "No song selected"
    local subtitle = track and (string.upper(track.Extension) .. " • Local file") or "Drop your MP3 files into VantaTest/Music"
    local cover = track and resolveCover(track, self.CoverFolder) or nil

    self.UI.Title.Text = title
    self.UI.Subtitle.Text = subtitle
    self.UI.MiniTitle.Text = title
    self.UI.MiniSubtitle.Text = track and "Local music" or "No song selected"

    self:_setCover(self.UI.Cover, self.UI.CoverFallback, cover)
    self:_setCover(self.UI.MiniCover, self.UI.MiniCoverFallback, cover)
    self:_updatePlayIcons()
end

function MusicPlayer:_updatePlaylistSelection()
    local theme = self.WindUI and self.WindUI.Theme or {}
    local selectedColor = theme.Primary or Color3.fromRGB(161, 22, 47)
    local normalColor = theme.ElementBackground or Color3.fromRGB(21, 17, 22)

    for index, row in pairs(self.Rows) do
        if row and row.Parent then
            row.BackgroundColor3 = index == self.CurrentIndex and selectedColor or normalColor
            row.BackgroundTransparency = index == self.CurrentIndex and 0.68 or 0.46
        end
    end
end

function MusicPlayer:_renderPlaylist()
    if not self.UI or not self.UI.Playlist then
        return
    end

    for _, child in ipairs(self.UI.Playlist:GetChildren()) do
        if child.Name == "TrackRow" then
            child:Destroy()
        end
    end
    self.Rows = {}

    local empty = self.UI.Empty
    if self.UnsupportedReason then
        empty.Visible = true
        empty.Text = self.UnsupportedReason
        return
    end

    if #self.Tracks == 0 then
        empty.Visible = true
        empty.Text = "No local songs found\nAdd .mp3 files to " .. self.Folder
        return
    end

    empty.Visible = false

    for index, track in ipairs(self.Tracks) do
        local row = Instance.new("TextButton")
        row.Name = "TrackRow"
        row.Text = ""
        row.AutoButtonColor = false
        row.BackgroundColor3 = self:_themeValue("ElementBackground", Color3.fromRGB(21, 17, 22))
        row.BackgroundTransparency = 0.46
        row.Size = UDim2.new(1, -8, 0, 48)
        row.ZIndex = 324
        row.LayoutOrder = index
        row.Parent = self.UI.Playlist
        makeCorner(row, 10)
        self.Rows[index] = row

        local thumb = Instance.new("Frame")
        thumb.Size = UDim2.fromOffset(34, 34)
        thumb.Position = UDim2.new(0, 7, 0.5, 0)
        thumb.AnchorPoint = Vector2.new(0, 0.5)
        thumb.BackgroundColor3 = self:_themeValue("Button", Color3.fromRGB(37, 16, 22))
        thumb.BackgroundTransparency = 0.2
        thumb.ZIndex = 325
        thumb.Parent = row
        makeCorner(thumb, 7)
        self:_bindTheme(thumb, "BackgroundColor3", "Button")

        local thumbImage = Instance.new("ImageLabel")
        thumbImage.Size = UDim2.fromScale(1, 1)
        thumbImage.BackgroundTransparency = 1
        thumbImage.ScaleType = Enum.ScaleType.Crop
        thumbImage.ZIndex = 326
        thumbImage.Parent = thumb
        makeCorner(thumbImage, 7)

        local thumbFallback = self:_icon("music-2", 16, thumb, 326)
        thumbFallback.AnchorPoint = Vector2.new(0.5, 0.5)
        thumbFallback.Position = UDim2.fromScale(0.5, 0.5)

        local cover = resolveCover(track, self.CoverFolder)
        self:_setCover(thumbImage, thumbFallback, cover)

        local nameLabel = self:_text(row, track.Name, 13, Enum.FontWeight.Medium, 326, "Text")
        nameLabel.Position = UDim2.new(0, 50, 0, 6)
        nameLabel.Size = UDim2.new(1, -112, 0, 20)

        local typeLabel = self:_text(row, string.upper(track.Extension), 11, Enum.FontWeight.Regular, 326, "Placeholder")
        typeLabel.Position = UDim2.new(0, 50, 0, 25)
        typeLabel.Size = UDim2.new(1, -112, 0, 16)

        local more = self:_icon("more-horizontal", 15, row, 326)
        more.AnchorPoint = Vector2.new(1, 0.5)
        more.Position = UDim2.new(1, -13, 0.5, 0)

        row.MouseEnter:Connect(function()
            if index ~= self.CurrentIndex then
                row.BackgroundTransparency = 0.26
            end
        end)
        row.MouseLeave:Connect(function()
            if index ~= self.CurrentIndex then
                row.BackgroundTransparency = 0.46
            end
        end)
        row.MouseButton1Click:Connect(function()
            self:_loadTrack(index, true)
        end)
    end

    self:_updatePlaylistSelection()
end

function MusicPlayer:_setProgress(ratio)
    if not self.UI then
        return
    end
    ratio = math.clamp(tonumber(ratio) or 0, 0, 1)
    self.UI.ProgressFill.Size = UDim2.new(ratio, 0, 1, 0)
    self.UI.ProgressKnob.Position = UDim2.new(ratio, 0, 0.5, 0)
end

function MusicPlayer:_setVolumeVisual(ratio)
    if not self.UI then
        return
    end
    ratio = math.clamp(tonumber(ratio) or 0, 0, 1)
    self.UI.VolumeFill.Size = UDim2.new(ratio, 0, 1, 0)
    self.UI.VolumeKnob.Position = UDim2.new(ratio, 0, 0.5, 0)
    self.UI.VolumeText.Text = tostring(math.floor(ratio * 100 + 0.5)) .. "%"
end

function MusicPlayer:_bindSlider(bar, onChanged, dragStateKey)
    local function setFromInput(input)
        local absoluteSize = bar.AbsoluteSize.X
        if absoluteSize <= 0 then
            return
        end
        local x = input.Position.X
        local ratio = math.clamp((x - bar.AbsolutePosition.X) / absoluteSize, 0, 1)
        onChanged(ratio)
    end

    bar.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self[dragStateKey] = true
            setFromInput(input)
        end
    end)

    UserInputService.InputChanged:Connect(function(input)
        if self[dragStateKey]
            and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            setFromInput(input)
        end
    end)

    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            self[dragStateKey] = false
        end
    end)
end

function MusicPlayer:_buildPlayer(window)
    if self.UI and self.UI.Root and self.UI.Root.Parent then
        self.UI.Root:Destroy()
    end
    if self.UI and self.UI.Mini and self.UI.Mini.Parent then
        self.UI.Mini:Destroy()
    end

    self.ThemeBindings = {}

    local root = Instance.new("Frame")
    root.Name = "VantaMusicPlayer"
    root.Size = UDim2.fromOffset(480, 430)
    root.Position = UDim2.new(0.5, 150, 0.5, 0)
    root.AnchorPoint = Vector2.new(0.5, 0.5)
    root.BackgroundColor3 = self:_themeValue("Background", Color3.new(0, 0, 0))
    root.BackgroundTransparency = 0.04
    root.BorderSizePixel = 0
    root.ClipsDescendants = true
    root.Visible = false
    root.ZIndex = 300
    root.Parent = self.WindUI.ScreenGui
    makeCorner(root, 15)
    self:_bindTheme(root, "BackgroundColor3", "Background")

    local stroke = Instance.new("UIStroke")
    stroke.Thickness = 1
    stroke.Transparency = 0.45
    stroke.Color = self:_themeValue("Outline", Color3.fromRGB(90, 24, 36))
    stroke.Parent = root

    local topbar = Instance.new("Frame")
    topbar.Name = "Topbar"
    topbar.Size = UDim2.new(1, 0, 0, 44)
    topbar.BackgroundColor3 = self:_themeValue("Dialog", Color3.fromRGB(10, 7, 9))
    topbar.BackgroundTransparency = 0.12
    topbar.BorderSizePixel = 0
    topbar.Active = true
    topbar.ZIndex = 301
    topbar.Parent = root
    self:_bindTheme(topbar, "BackgroundColor3", "Dialog")

    local musicIcon = self:_icon("music-2", 20, topbar, 303)
    musicIcon.Position = UDim2.new(0, 15, 0.5, 0)
    musicIcon.AnchorPoint = Vector2.new(0, 0.5)

    local header = self:_text(topbar, "Music Player", 15, Enum.FontWeight.SemiBold, 303, "Text")
    header.Position = UDim2.new(0, 44, 0, 0)
    header.Size = UDim2.new(1, -130, 1, 0)

    local minimize = self:_iconButton(topbar, "minus", 32, 303, function()
        root.Visible = false
        if self.UI then
            self.UI.Mini.Visible = true
        end
    end)
    minimize.AnchorPoint = Vector2.new(1, 0.5)
    minimize.Position = UDim2.new(1, -42, 0.5, 0)

    local close = self:_iconButton(topbar, "x", 32, 303, function()
        root.Visible = false
        if self.UI then
            self.UI.Mini.Visible = false
        end
    end)
    close.AnchorPoint = Vector2.new(1, 0.5)
    close.Position = UDim2.new(1, -8, 0.5, 0)

    local content = Instance.new("Frame")
    content.Size = UDim2.new(1, -24, 1, -56)
    content.Position = UDim2.new(0, 12, 0, 50)
    content.BackgroundTransparency = 1
    content.ZIndex = 302
    content.Parent = root

    local coverHolder = Instance.new("Frame")
    coverHolder.Size = UDim2.fromOffset(116, 116)
    coverHolder.BackgroundColor3 = self:_themeValue("ElementBackground", Color3.fromRGB(21, 17, 22))
    coverHolder.BackgroundTransparency = 0.08
    coverHolder.ZIndex = 303
    coverHolder.Parent = content
    makeCorner(coverHolder, 13)
    self:_bindTheme(coverHolder, "BackgroundColor3", "ElementBackground")

    local cover = Instance.new("ImageLabel")
    cover.Size = UDim2.fromScale(1, 1)
    cover.BackgroundTransparency = 1
    cover.ScaleType = Enum.ScaleType.Crop
    cover.ZIndex = 304
    cover.Parent = coverHolder
    makeCorner(cover, 13)

    local coverFallback = self:_icon("disc-3", 42, coverHolder, 304)
    coverFallback.AnchorPoint = Vector2.new(0.5, 0.5)
    coverFallback.Position = UDim2.fromScale(0.5, 0.5)

    local title = self:_text(content, "No song selected", 18, Enum.FontWeight.SemiBold, 303, "Text")
    title.Position = UDim2.new(0, 132, 0, 4)
    title.Size = UDim2.new(1, -132, 0, 27)

    local subtitle = self:_text(content, "Drop your MP3 files into VantaTest/Music", 12, Enum.FontWeight.Regular, 303, "Placeholder")
    subtitle.Position = UDim2.new(0, 132, 0, 32)
    subtitle.Size = UDim2.new(1, -132, 0, 20)

    local progress = Instance.new("Frame")
    progress.Size = UDim2.new(1, -142, 0, 5)
    progress.Position = UDim2.new(0, 132, 0, 66)
    progress.BackgroundColor3 = self:_themeValue("Button", Color3.fromRGB(37, 16, 22))
    progress.BackgroundTransparency = 0.15
    progress.Active = true
    progress.ZIndex = 304
    progress.Parent = content
    makeCorner(progress, 99)
    self:_bindTheme(progress, "BackgroundColor3", "Button")

    local progressFill = Instance.new("Frame")
    progressFill.Size = UDim2.new(0, 0, 1, 0)
    progressFill.BackgroundColor3 = self:_themeValue("Primary", Color3.fromRGB(161, 22, 47))
    progressFill.BorderSizePixel = 0
    progressFill.ZIndex = 305
    progressFill.Parent = progress
    makeCorner(progressFill, 99)
    self:_bindTheme(progressFill, "BackgroundColor3", "Primary")

    local progressKnob = Instance.new("Frame")
    progressKnob.Size = UDim2.fromOffset(11, 11)
    progressKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    progressKnob.Position = UDim2.new(0, 0, 0.5, 0)
    progressKnob.BackgroundColor3 = self:_themeValue("Primary", Color3.fromRGB(161, 22, 47))
    progressKnob.BorderSizePixel = 0
    progressKnob.ZIndex = 306
    progressKnob.Parent = progress
    makeCorner(progressKnob, 99)
    self:_bindTheme(progressKnob, "BackgroundColor3", "Primary")

    local elapsed = self:_text(content, "0:00", 11, Enum.FontWeight.Regular, 303, "Placeholder")
    elapsed.Position = UDim2.new(0, 132, 0, 75)
    elapsed.Size = UDim2.fromOffset(56, 18)

    local duration = self:_text(content, "0:00", 11, Enum.FontWeight.Regular, 303, "Placeholder")
    duration.Position = UDim2.new(1, -58, 0, 75)
    duration.Size = UDim2.fromOffset(58, 18)
    duration.TextXAlignment = Enum.TextXAlignment.Right

    local controls = Instance.new("Frame")
    controls.Size = UDim2.new(1, -132, 0, 42)
    controls.Position = UDim2.new(0, 132, 0, 93)
    controls.BackgroundTransparency = 1
    controls.ZIndex = 303
    controls.Parent = content

    local shuffle = self:_iconButton(controls, "shuffle", 34, 304, function()
        self.Shuffle = not self.Shuffle
        self.UI.Shuffle.BackgroundTransparency = self.Shuffle and 0.25 or 1
    end)
    shuffle.Position = UDim2.new(0, 0, 0.5, 0)
    shuffle.AnchorPoint = Vector2.new(0, 0.5)

    local previous = self:_iconButton(controls, "skip-back", 36, 304, function()
        self:_previousTrack()
    end)
    previous.Position = UDim2.new(0.32, 0, 0.5, 0)
    previous.AnchorPoint = Vector2.new(0.5, 0.5)

    local play, playIcon, playHover = self:_iconButton(controls, "play", 42, 304, function()
        self:_togglePlayback()
    end)
    play.Position = UDim2.new(0.5, 0, 0.5, 0)
    play.AnchorPoint = Vector2.new(0.5, 0.5)
    playHover.BackgroundTransparency = 0.35

    local nextButton = self:_iconButton(controls, "skip-forward", 36, 304, function()
        self:_nextTrack()
    end)
    nextButton.Position = UDim2.new(0.68, 0, 0.5, 0)
    nextButton.AnchorPoint = Vector2.new(0.5, 0.5)

    local repeatButton, _, repeatHover = self:_iconButton(controls, "repeat-2", 34, 304, function()
        self.RepeatOne = not self.RepeatOne
        self.Sound.Looped = self.RepeatOne
        repeatHover.BackgroundTransparency = self.RepeatOne and 0.25 or 1
    end)
    repeatButton.Position = UDim2.new(1, 0, 0.5, 0)
    repeatButton.AnchorPoint = Vector2.new(1, 0.5)

    local volumeIcon = self:_icon("volume-2", 17, content, 304)
    volumeIcon.Position = UDim2.new(0, 132, 0, 145)
    volumeIcon.AnchorPoint = Vector2.new(0, 0.5)

    local volume = Instance.new("Frame")
    volume.Size = UDim2.new(1, -225, 0, 5)
    volume.Position = UDim2.new(0, 158, 0, 143)
    volume.BackgroundColor3 = self:_themeValue("Button", Color3.fromRGB(37, 16, 22))
    volume.BackgroundTransparency = 0.15
    volume.Active = true
    volume.ZIndex = 304
    volume.Parent = content
    makeCorner(volume, 99)
    self:_bindTheme(volume, "BackgroundColor3", "Button")

    local volumeFill = Instance.new("Frame")
    volumeFill.Size = UDim2.new(self.Volume, 0, 1, 0)
    volumeFill.BackgroundColor3 = self:_themeValue("Primary", Color3.fromRGB(161, 22, 47))
    volumeFill.BorderSizePixel = 0
    volumeFill.ZIndex = 305
    volumeFill.Parent = volume
    makeCorner(volumeFill, 99)
    self:_bindTheme(volumeFill, "BackgroundColor3", "Primary")

    local volumeKnob = Instance.new("Frame")
    volumeKnob.Size = UDim2.fromOffset(11, 11)
    volumeKnob.AnchorPoint = Vector2.new(0.5, 0.5)
    volumeKnob.Position = UDim2.new(self.Volume, 0, 0.5, 0)
    volumeKnob.BackgroundColor3 = self:_themeValue("Primary", Color3.fromRGB(161, 22, 47))
    volumeKnob.BorderSizePixel = 0
    volumeKnob.ZIndex = 306
    volumeKnob.Parent = volume
    makeCorner(volumeKnob, 99)
    self:_bindTheme(volumeKnob, "BackgroundColor3", "Primary")

    local volumeText = self:_text(content, "65%", 11, Enum.FontWeight.Regular, 304, "Placeholder")
    volumeText.Position = UDim2.new(1, -52, 0, 135)
    volumeText.Size = UDim2.fromOffset(52, 20)
    volumeText.TextXAlignment = Enum.TextXAlignment.Right

    local divider = Instance.new("Frame")
    divider.Size = UDim2.new(1, 0, 0, 1)
    divider.Position = UDim2.new(0, 0, 0, 166)
    divider.BackgroundColor3 = self:_themeValue("Outline", Color3.fromRGB(90, 24, 36))
    divider.BackgroundTransparency = 0.72
    divider.BorderSizePixel = 0
    divider.ZIndex = 303
    divider.Parent = content
    self:_bindTheme(divider, "BackgroundColor3", "Outline")

    local playlistTitle = self:_text(content, "Playlist", 14, Enum.FontWeight.SemiBold, 303, "Text")
    playlistTitle.Position = UDim2.new(0, 0, 0, 174)
    playlistTitle.Size = UDim2.new(1, -100, 0, 28)

    local refresh = self:_iconButton(content, "refresh-cw", 31, 304, function()
        self:_refreshLibrary()
    end)
    refresh.Position = UDim2.new(1, -38, 0, 187)
    refresh.AnchorPoint = Vector2.new(0.5, 0.5)

    local folderButton = self:_iconButton(content, "folder-open", 31, 304, function()
        if OpenFolder then
            local ok = pcall(OpenFolder, self.Folder)
            if not ok then
                self:_notify("Music folder", "Your songs folder is " .. self.Folder, "folder-open")
            end
        else
            self:_notify("Music folder", "Put your MP3 files inside " .. self.Folder, "folder-open")
        end
    end)
    folderButton.Position = UDim2.new(1, -4, 0, 187)
    folderButton.AnchorPoint = Vector2.new(1, 0.5)

    local playlist = Instance.new("ScrollingFrame")
    playlist.Size = UDim2.new(1, 0, 1, -207)
    playlist.Position = UDim2.new(0, 0, 0, 207)
    playlist.BackgroundColor3 = self:_themeValue("PanelBackground", Color3.fromRGB(5, 4, 6))
    playlist.BackgroundTransparency = 0.52
    playlist.BorderSizePixel = 0
    playlist.ScrollBarThickness = 3
    playlist.ScrollBarImageColor3 = self:_themeValue("Primary", Color3.fromRGB(161, 22, 47))
    playlist.CanvasSize = UDim2.new(0, 0, 0, 0)
    playlist.AutomaticCanvasSize = Enum.AutomaticSize.Y
    playlist.ZIndex = 303
    playlist.Parent = content
    makeCorner(playlist, 12)
    addPadding(playlist, 6, 2, 6, 6)
    self:_bindTheme(playlist, "BackgroundColor3", "PanelBackground")
    self:_bindTheme(playlist, "ScrollBarImageColor3", "Primary")

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 5)
    layout.SortOrder = Enum.SortOrder.LayoutOrder
    layout.Parent = playlist

    local empty = self:_text(playlist, "No local songs found\nAdd .mp3 files to " .. self.Folder, 12, Enum.FontWeight.Regular, 304, "Placeholder")
    empty.Name = "EmptyState"
    empty.Size = UDim2.new(1, -24, 0, 64)
    empty.Position = UDim2.new(0, 12, 0, 12)
    empty.TextWrapped = true
    empty.TextXAlignment = Enum.TextXAlignment.Center
    empty.TextYAlignment = Enum.TextYAlignment.Center

    local mini = Instance.new("Frame")
    mini.Name = "VantaMusicPlayerMini"
    mini.Size = UDim2.fromOffset(318, 58)
    mini.Position = UDim2.new(0.5, 0, 0.82, 0)
    mini.AnchorPoint = Vector2.new(0.5, 0.5)
    mini.BackgroundColor3 = self:_themeValue("Background", Color3.new(0, 0, 0))
    mini.BackgroundTransparency = 0.04
    mini.BorderSizePixel = 0
    mini.Visible = false
    mini.Active = true
    mini.ZIndex = 340
    mini.Parent = self.WindUI.ScreenGui
    makeCorner(mini, 15)
    self:_bindTheme(mini, "BackgroundColor3", "Background")

    local miniStroke = Instance.new("UIStroke")
    miniStroke.Thickness = 1
    miniStroke.Transparency = 0.45
    miniStroke.Color = self:_themeValue("Outline", Color3.fromRGB(90, 24, 36))
    miniStroke.Parent = mini

    local miniCoverHolder = Instance.new("Frame")
    miniCoverHolder.Size = UDim2.fromOffset(44, 44)
    miniCoverHolder.Position = UDim2.new(0, 7, 0.5, 0)
    miniCoverHolder.AnchorPoint = Vector2.new(0, 0.5)
    miniCoverHolder.BackgroundColor3 = self:_themeValue("ElementBackground", Color3.fromRGB(21, 17, 22))
    miniCoverHolder.BackgroundTransparency = 0.08
    miniCoverHolder.ZIndex = 341
    miniCoverHolder.Parent = mini
    makeCorner(miniCoverHolder, 10)
    self:_bindTheme(miniCoverHolder, "BackgroundColor3", "ElementBackground")

    local miniCover = Instance.new("ImageLabel")
    miniCover.Size = UDim2.fromScale(1, 1)
    miniCover.BackgroundTransparency = 1
    miniCover.ScaleType = Enum.ScaleType.Crop
    miniCover.ZIndex = 342
    miniCover.Parent = miniCoverHolder
    makeCorner(miniCover, 10)

    local miniCoverFallback = self:_icon("music-2", 19, miniCoverHolder, 342)
    miniCoverFallback.AnchorPoint = Vector2.new(0.5, 0.5)
    miniCoverFallback.Position = UDim2.fromScale(0.5, 0.5)

    local miniTitle = self:_text(mini, "No song selected", 13, Enum.FontWeight.Medium, 342, "Text")
    miniTitle.Position = UDim2.new(0, 60, 0, 8)
    miniTitle.Size = UDim2.new(1, -150, 0, 20)

    local miniSubtitle = self:_text(mini, "No song selected", 11, Enum.FontWeight.Regular, 342, "Placeholder")
    miniSubtitle.Position = UDim2.new(0, 60, 0, 27)
    miniSubtitle.Size = UDim2.new(1, -150, 0, 18)

    local miniPlay, miniPlayIcon = self:_iconButton(mini, "play", 38, 342, function()
        self:_togglePlayback()
    end)
    miniPlay.Position = UDim2.new(1, -50, 0.5, 0)
    miniPlay.AnchorPoint = Vector2.new(0.5, 0.5)

    local restore = self:_iconButton(mini, "chevron-up", 34, 342, function()
        mini.Visible = false
        root.Visible = true
    end)
    restore.Position = UDim2.new(1, -11, 0.5, 0)
    restore.AnchorPoint = Vector2.new(1, 0.5)

    self.UI = {
        Root = root,
        Mini = mini,
        Stroke = stroke,
        MiniStroke = miniStroke,
        Cover = cover,
        CoverFallback = coverFallback,
        MiniCover = miniCover,
        MiniCoverFallback = miniCoverFallback,
        Title = title,
        Subtitle = subtitle,
        MiniTitle = miniTitle,
        MiniSubtitle = miniSubtitle,
        Progress = progress,
        ProgressFill = progressFill,
        ProgressKnob = progressKnob,
        Elapsed = elapsed,
        Duration = duration,
        PlayIcon = playIcon,
        MiniPlayIcon = miniPlayIcon,
        Shuffle = shuffle:FindFirstChildOfClass("Frame"),
        Repeat = repeatHover,
        Volume = volume,
        VolumeFill = volumeFill,
        VolumeKnob = volumeKnob,
        VolumeText = volumeText,
        Playlist = playlist,
        Empty = empty,
    }

    self:_bindSlider(progress, function(ratio)
        self:_setProgress(ratio)
        local length = self.Sound and self.Sound.TimeLength or 0
        if length > 0 then
            self.Sound.TimePosition = ratio * length
        end
    end, "ProgressDragging")

    self:_bindSlider(volume, function(ratio)
        self.Volume = ratio
        self.Sound.Volume = ratio
        self:_setVolumeVisual(ratio)
    end, "VolumeDragging")

    if self.WindUI.Creator and self.WindUI.Creator.Drag then
        pcall(function()
            self.WindUI.Creator.Drag(root, { topbar })
            self.WindUI.Creator.Drag(mini, { mini })
        end)
    end

    self:_setVolumeVisual(self.Volume)
    self:_updateNowPlaying()
    self:ApplyTheme()
end

function MusicPlayer:_attachLauncher(window)
    local right = window
        and window.UIElements
        and window.UIElements.Main
        and window.UIElements.Main:FindFirstChild("Main")
        and window.UIElements.Main.Main:FindFirstChild("Topbar")
        and window.UIElements.Main.Main.Topbar:FindFirstChild("Right")
    if not right then
        return
    end

    local existing = right:FindFirstChild("VantaMusicLauncher")
    if existing then
        existing:Destroy()
    end

    local holder = Instance.new("Frame")
    holder.Name = "VantaMusicLauncher"
    holder.Size = UDim2.fromOffset(30, 30)
    holder.BackgroundTransparency = 1
    holder.LayoutOrder = 990
    holder.Parent = right

    local button = Instance.new("TextButton")
    button.Text = ""
    button.AutoButtonColor = false
    button.Size = UDim2.fromOffset(28, 28)
    button.Position = UDim2.fromScale(0.5, 0.5)
    button.AnchorPoint = Vector2.new(0.5, 0.5)
    button.BackgroundColor3 = self:_themeValue("Button", Color3.fromRGB(37, 16, 22))
    button.BackgroundTransparency = 0.72
    button.ZIndex = 9999
    button.Parent = holder
    makeCorner(button, 9)
    self:_bindTheme(button, "BackgroundColor3", "Button")

    local icon = self:_icon("music-2", 15, button, 10000)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.5, 0.5)

    button.MouseEnter:Connect(function()
        button.BackgroundTransparency = 0.45
    end)
    button.MouseLeave:Connect(function()
        button.BackgroundTransparency = 0.72
    end)
    button.MouseButton1Click:Connect(function()
        if self.UI.Mini.Visible then
            self.UI.Mini.Visible = false
            self.UI.Root.Visible = true
        else
            self.UI.Root.Visible = not self.UI.Root.Visible
        end
    end)

    self.Launcher = holder
end

function MusicPlayer:Open()
    if self.UI then
        self.UI.Mini.Visible = false
        self.UI.Root.Visible = true
    end
end

function MusicPlayer:Close()
    if self.UI then
        self.UI.Root.Visible = false
        self.UI.Mini.Visible = false
    end
end

function MusicPlayer:Refresh()
    self:_refreshLibrary()
end

function MusicPlayer:Init(windUI, config)
    self.WindUI = windUI
    config = type(config) == "table" and config or {}
    self.Folder = config.Folder or self.Folder
    self.CoverFolder = config.CoverFolder or (self.Folder .. "/.covers")

    if not self.Sound or not self.Sound.Parent then
        self.Sound = Instance.new("Sound")
        self.Sound.Name = "VantaTest_LocalMusic"
        self.Sound.Volume = self.Volume
        self.Sound.Parent = SoundService

        self.Sound.Ended:Connect(function()
            if not self.RepeatOne then
                self:_nextTrack()
            end
        end)
    end

    if not self.HeartbeatConnection then
        self.HeartbeatConnection = RunService.Heartbeat:Connect(function()
            if not self.UI or not self.Sound then
                return
            end

            local now = os.clock()
            if now - (self.LastUiUpdate or 0) < 0.08 then
                return
            end
            self.LastUiUpdate = now

            if self.Playing and not self.Sound.Playing and not self.Sound.IsPaused then
                self.Playing = false
                self:_updatePlayIcons()
            end

            local length = tonumber(self.Sound.TimeLength) or 0
            local position = tonumber(self.Sound.TimePosition) or 0
            if not self.ProgressDragging then
                self:_setProgress(length > 0 and (position / length) or 0)
            end
            self.UI.Elapsed.Text = formatTime(position)
            self.UI.Duration.Text = formatTime(length)
        end)
    end

    return self
end

function MusicPlayer:Attach(window, config)
    self.Window = window
    config = type(config) == "table" and config or {}
    if config.Folder then
        self.Folder = config.Folder
        self.CoverFolder = config.CoverFolder or (self.Folder .. "/.covers")
    end

    self:_buildPlayer(window)
    self:_attachLauncher(window)
    self:_refreshLibrary()
    return self
end

return MusicPlayer
