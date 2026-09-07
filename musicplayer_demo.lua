-- VantaTest bundled demo layer.
-- Adds an original procedural hip-hop demo track plus a matching in-UI cover
-- so the premium music-player presentation is visible immediately.

local CACHE_BUSTER = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local PREMIUM_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/musicplayer_premium.lua?v=" .. CACHE_BUSTER

local ok, source = pcall(function()
    return game:HttpGet(PREMIUM_URL)
end)
assert(ok and type(source) == "string" and #source > 0, "[VantaTest Music] Could not load premium player")

local loader, loadError = loadstring(source)
assert(loader, "[VantaTest Music] Premium player compile failed: " .. tostring(loadError))

local MusicPlayer = loader()
assert(type(MusicPlayer) == "table", "[VantaTest Music] Premium player returned an invalid value")

local DEMO_NAME = "Midnight Bounce"
local DEMO_BPM = 92
local SAMPLE_RATE = 8000
local BEAT = 60 / DEMO_BPM
local DEMO_BARS = 4
local DEMO_SECONDS = DEMO_BARS * 4 * BEAT

local BaseInit = MusicPlayer.Init
local BaseShow = MusicPlayer.Show
local BaseUpdate = MusicPlayer._update
local BaseRenderList = MusicPlayer._renderList

local function ensureFolder(path)
    if not makefolder then
        return
    end
    local current = ""
    for part in tostring(path or ""):gsub("\\", "/"):gmatch("[^/]+") do
        current = current == "" and part or (current .. "/" .. part)
        local exists = false
        if isfolder then
            local success, value = pcall(isfolder, current)
            exists = success and value
        end
        if not exists then
            pcall(makefolder, current)
        end
    end
end

local function fileExists(path)
    if not isfile then
        return false
    end
    local success, value = pcall(isfile, path)
    return success and value
end

local function le16(value)
    value = math.floor(value)
    return string.char(value % 256, math.floor(value / 256) % 256)
end

local function le32(value)
    value = math.floor(value)
    return string.char(
        value % 256,
        math.floor(value / 256) % 256,
        math.floor(value / 65536) % 256,
        math.floor(value / 16777216) % 256
    )
end

local function clamp(value, low, high)
    if value < low then return low end
    if value > high then return high end
    return value
end

local function createDemoWav(path)
    if not writefile or fileExists(path) then
        return fileExists(path)
    end

    ensureFolder(path:match("^(.*)/[^/]+$") or "VantaTest/Music")

    local sampleCount = math.floor(DEMO_SECONDS * SAMPLE_RATE)
    local roots = { 73.42, 65.41, 58.27, 65.41 }
    local chordRoots = {
        { 146.83, 174.61, 220.00 },
        { 130.81, 164.81, 196.00 },
        { 116.54, 146.83, 174.61 },
        { 130.81, 164.81, 220.00 },
    }
    local kickOffsets = { 0, 1.5, 2.75 }
    local snareOffsets = { 1, 3 }
    local bassPattern = {
        { 0, 0.90, 1.00 },
        { 1.5, 0.55, 1.00 },
        { 2.5, 0.75, 1.50 },
        { 3.5, 0.40, 1.00 },
    }

    local seed = 1337
    local chunks = {}
    local bytes = {}

    for i = 0, sampleCount - 1 do
        local t = i / SAMPLE_RATE
        local beatGlobal = t / BEAT
        local barIndex = math.floor(beatGlobal / 4) % DEMO_BARS + 1
        local beatPos = beatGlobal % 4

        seed = (seed * 1103515245 + 12345) % 2147483648
        local noise = (seed / 1073741824) - 1
        local signal = 0

        -- Kick pattern: 1, the swung middle hit, then a late third hit.
        for _, offset in ipairs(kickOffsets) do
            local age = (beatPos - offset) * BEAT
            if age >= 0 and age < 0.24 then
                local freq = 48 + 72 * math.exp(-age * 18)
                signal = signal + math.sin(math.pi * 2 * freq * age) * math.exp(-age * 15) * 0.72
            end
        end

        -- Snare on beats 2 and 4.
        for _, offset in ipairs(snareOffsets) do
            local age = (beatPos - offset) * BEAT
            if age >= 0 and age < 0.17 then
                local env = math.exp(-age * 20)
                signal = signal + noise * env * 0.24
                signal = signal + math.sin(math.pi * 2 * 185 * age) * math.exp(-age * 28) * 0.08
            end
        end

        -- Eighth-note hats with a small swing on every second hit.
        local eighthIndex = math.floor(beatGlobal * 2)
        local hatBeat = eighthIndex * 0.5
        local swing = eighthIndex % 2 == 1 and (0.04 * BEAT) or 0
        local hatAge = t - (hatBeat * BEAT + swing)
        if hatAge >= 0 and hatAge < 0.055 then
            signal = signal + noise * math.exp(-hatAge * 62) * 0.075
        end

        -- Four-note 808-style bass phrase per bar.
        for _, note in ipairs(bassPattern) do
            local age = (beatPos - note[1]) * BEAT
            local noteLength = note[2] * BEAT
            if age >= 0 and age < noteLength then
                local freq = roots[barIndex] * note[3]
                local env = (1 - math.exp(-age * 28)) * math.exp(-age / math.max(noteLength * 0.9, 0.01))
                signal = signal + math.sin(math.pi * 2 * freq * age) * env * 0.20
                signal = signal + math.sin(math.pi * 4 * freq * age) * env * 0.035
            end
        end

        -- Dark, quiet chord bed underneath the drums.
        local chord = chordRoots[barIndex]
        local chordMix = 0
        for _, freq in ipairs(chord) do
            chordMix = chordMix + math.sin(math.pi * 2 * freq * t)
        end
        signal = signal + (chordMix / #chord) * 0.055

        signal = signal / (1 + math.abs(signal))
        local sample = math.floor(clamp(128 + signal * 108, 0, 255) + 0.5)
        bytes[#bytes + 1] = string.char(sample)

        if #bytes >= 2048 then
            chunks[#chunks + 1] = table.concat(bytes)
            bytes = {}
        end
    end

    if #bytes > 0 then
        chunks[#chunks + 1] = table.concat(bytes)
    end

    local pcm = table.concat(chunks)
    local dataSize = #pcm
    local header = table.concat({
        "RIFF",
        le32(36 + dataSize),
        "WAVE",
        "fmt ",
        le32(16),
        le16(1),
        le16(1),
        le32(SAMPLE_RATE),
        le32(SAMPLE_RATE),
        le16(1),
        le16(8),
        "data",
        le32(dataSize),
    })

    local success = pcall(writefile, path, header .. pcm)
    return success and fileExists(path)
end

local function ensureDemoTrack(self)
    local demoPath = tostring(self.Folder or "VantaTest/Music") .. "/" .. DEMO_NAME .. ".wav"
    if fileExists(demoPath) then
        return true
    end

    if self._DemoGenerating then
        local deadline = os.clock() + 4
        repeat
            task.wait()
        until fileExists(demoPath) or not self._DemoGenerating or os.clock() >= deadline
        return fileExists(demoPath)
    end

    self._DemoGenerating = true
    local success = createDemoWav(demoPath)
    self._DemoGenerating = false
    return success
end

local function addCorner(parent, radius)
    local corner = Instance.new("UICorner")
    corner.CornerRadius = UDim.new(0, radius or 8)
    corner.Parent = parent
    return corner
end

local function makeCover(parent, size, compact)
    local cover = Instance.new("Frame")
    cover.Name = "MidnightBounceCover"
    cover.BackgroundColor3 = Color3.fromRGB(17, 8, 28)
    cover.BorderSizePixel = 0
    cover.Size = size or UDim2.fromScale(1, 1)
    cover.ZIndex = (parent.ZIndex or 1) + 15
    cover.Parent = parent
    addCorner(cover, compact and 7 or 10)

    local gradient = Instance.new("UIGradient")
    gradient.Rotation = 125
    gradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(35, 10, 52)),
        ColorSequenceKeypoint.new(0.52, Color3.fromRGB(104, 24, 138)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(12, 8, 20)),
    })
    gradient.Parent = cover

    local ring = Instance.new("Frame")
    ring.AnchorPoint = Vector2.new(0.5, 0.5)
    ring.Position = UDim2.fromScale(0.5, compact and 0.43 or 0.40)
    ring.Size = compact and UDim2.fromOffset(18, 18) or UDim2.fromOffset(40, 40)
    ring.BackgroundTransparency = 1
    ring.BorderSizePixel = 0
    ring.ZIndex = cover.ZIndex + 1
    ring.Parent = cover
    addCorner(ring, 99)

    local ringStroke = Instance.new("UIStroke")
    ringStroke.Color = Color3.fromRGB(229, 162, 255)
    ringStroke.Transparency = 0.08
    ringStroke.Thickness = compact and 1.5 or 2
    ringStroke.Parent = ring

    local center = Instance.new("Frame")
    center.AnchorPoint = Vector2.new(0.5, 0.5)
    center.Position = UDim2.fromScale(0.5, 0.5)
    center.Size = compact and UDim2.fromOffset(7, 7) or UDim2.fromOffset(14, 14)
    center.Rotation = 45
    center.BackgroundColor3 = Color3.fromRGB(244, 192, 255)
    center.BorderSizePixel = 0
    center.ZIndex = ring.ZIndex + 1
    center.Parent = ring
    addCorner(center, 2)

    if not compact then
        local title = Instance.new("TextLabel")
        title.Name = "CoverTitle"
        title.BackgroundTransparency = 1
        title.Size = UDim2.new(1, -8, 0, 24)
        title.Position = UDim2.new(0, 4, 1, -29)
        title.Text = "MIDNIGHT\nBOUNCE"
        title.TextColor3 = Color3.new(1, 1, 1)
        title.TextSize = 9
        title.TextWrapped = true
        title.Font = Enum.Font.GothamBold
        title.ZIndex = cover.ZIndex + 2
        title.Parent = cover
    end

    return cover
end

function MusicPlayer:_isDemoTrack(track)
    return track and tostring(track.Name) == DEMO_NAME
end

function MusicPlayer:_decorateDemoCovers()
    if not self.UI then
        return
    end

    if self.UI.Cover and not self.UI.DemoMainCover then
        local parent = self.UI.Cover.Parent
        local cover = makeCover(parent, UDim2.fromScale(1, 1), false)
        cover.Visible = false
        self.UI.DemoMainCover = cover
    end

    if self.UI.MiniCover and not self.UI.DemoMiniCover then
        local parent = self.UI.MiniCover.Parent
        local cover = makeCover(parent, UDim2.fromScale(1, 1), true)
        cover.Visible = false
        self.UI.DemoMiniCover = cover
    end
end

function MusicPlayer:_decorateDemoRows()
    for index, row in ipairs(self.Rows or {}) do
        local track = self.Tracks and self.Tracks[index]
        if row and row.Parent and self:_isDemoTrack(track) and not row:FindFirstChild("MidnightBounceRowCover") then
            local cover = makeCover(row, UDim2.fromOffset(28, 28), true)
            cover.Name = "MidnightBounceRowCover"
            cover.Position = UDim2.fromOffset(5, 5)
            cover.ZIndex = row.ZIndex + 20
        end
    end
end

function MusicPlayer:_renderList()
    BaseRenderList(self)
    self:_decorateDemoRows()
end

function MusicPlayer:_update()
    BaseUpdate(self)

    if not self.UI then
        return
    end

    self:_decorateDemoCovers()

    local track = self.CurrentIndex and self.Tracks[self.CurrentIndex] or nil
    local demo = self:_isDemoTrack(track)

    if self.UI.DemoMainCover then
        self.UI.DemoMainCover.Visible = demo
    end
    if self.UI.DemoMiniCover then
        self.UI.DemoMiniCover.Visible = demo
    end

    if demo then
        if self.UI.Cover then self.UI.Cover.Visible = false end
        if self.UI.CoverFallback then self.UI.CoverFallback.Visible = false end
        if self.UI.MiniCover then self.UI.MiniCover.Visible = false end
        if self.UI.MiniCoverFallback then self.UI.MiniCoverFallback.Visible = false end

        if self.UI.Sub then
            self.UI.Sub.Text = "VANTA ORIGINAL  •  HIP-HOP  •  92 BPM"
        end
        if self.UI.MiniPremiumSub then
            local position = self.Sound and self.Sound.TimePosition or 0
            local length = self.Sound and self.Sound.TimeLength or 0
            self.UI.MiniPremiumSub.Text = string.format("%d:%02d  /  %d:%02d", math.floor(position / 60), math.floor(position % 60), math.floor(length / 60), math.floor(length % 60))
        end
    end
end

function MusicPlayer:Init(windui, config)
    BaseInit(self, windui, config)

    task.spawn(function()
        ensureDemoTrack(self)
    end)

    return self
end

function MusicPlayer:Show()
    ensureDemoTrack(self)
    BaseShow(self)

    if not self.CurrentIndex then
        for index, track in ipairs(self.Tracks or {}) do
            if self:_isDemoTrack(track) then
                self:_load(index, false)
                break
            end
        end
    end

    self:_decorateDemoCovers()
    self:_decorateDemoRows()
    self:_update()
end

return MusicPlayer
