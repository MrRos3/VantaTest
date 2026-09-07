-- VantaTest public music catalog layer.
-- Resolves the built-in playlist from Roblox's public Creator Store audio catalog,
-- so every executor user gets the same songs without local files/folders.

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

local AssetService = game:GetService("AssetService")

local BaseUpdate = MusicPlayer._update
local BaseRenderList = MusicPlayer._renderList
local BaseShow = MusicPlayer.Show

local CATALOG = {
    {
        Title = "Azeri Kavkaz",
        Artist = "Caucasus Dance",
        Duration = 299,
        Queries = { "Azeri Kavkaz", "Azeri Kavkaz Caucasus Dance" },
    },
    {
        Title = "I Love You So (Arabic Version - Slowed)",
        Artist = "aessy • Tom Vaulbert",
        Duration = 240,
        Queries = {
            "I Love You So Arabic Version Slowed",
            "I Love You So Arabic aessy",
            "Schnuffel I Love You So Arabic",
        },
    },
}

MusicPlayer._CatalogResolving = false
MusicPlayer._CatalogResolved = false
MusicPlayer._CatalogError = nil
MusicPlayer._CatalogMatches = {}

local function normalize(value)
    value = string.lower(tostring(value or ""))
    value = value:gsub("[%p%s]+", "")
    return value
end

local function containsNormalized(a, b)
    a, b = normalize(a), normalize(b)
    return a ~= "" and b ~= "" and (a:find(b, 1, true) ~= nil or b:find(a, 1, true) ~= nil)
end

local function resultScore(spec, audio)
    if type(audio) ~= "table" or not tonumber(audio.Id) then
        return -math.huge
    end

    local score = 0
    local wantedTitle = normalize(spec.Title)
    local title = normalize(audio.Title)
    local artist = normalize(audio.Artist)
    local wantedArtist = normalize(spec.Artist)

    if title == wantedTitle then
        score = score + 220
    elseif containsNormalized(title, wantedTitle) then
        score = score + 150
    else
        local words = 0
        for word in string.lower(spec.Title):gmatch("[%w]+") do
            if #word >= 3 and string.lower(tostring(audio.Title or "")):find(word, 1, true) then
                words = words + 1
            end
        end
        score = score + words * 14
    end

    if wantedArtist ~= "" and artist ~= "" then
        if artist == wantedArtist then
            score = score + 90
        elseif containsNormalized(artist, wantedArtist) then
            score = score + 55
        end
    end

    local duration = tonumber(audio.Duration) or 0
    if duration > 0 then
        local diff = math.abs(duration - spec.Duration)
        if diff <= 2 then
            score = score + 90
        elseif diff <= 5 then
            score = score + 65
        elseif diff <= 10 then
            score = score + 35
        elseif diff <= 20 then
            score = score + 10
        else
            score = score - math.min(80, diff)
        end
    end

    if audio.AudioType and tostring(audio.AudioType):lower():find("music", 1, true) then
        score = score + 10
    end

    return score
end

local function searchOnce(spec, query, strictTitle)
    local params = Instance.new("AudioSearchParams")
    params.MinDuration = math.max(1, spec.Duration - 12)
    params.MaxDuration = spec.Duration + 12

    if strictTitle then
        params.Title = spec.Title
    else
        params.SearchKeyword = query
    end

    local success, pages = pcall(function()
        return AssetService:SearchAudioAsync(params)
    end)

    if not success or not pages then
        return nil, tostring(pages)
    end

    local pageOk, results = pcall(function()
        return pages:GetCurrentPage()
    end)
    if not pageOk or type(results) ~= "table" then
        return nil, tostring(results)
    end

    local best, bestScore
    for _, audio in ipairs(results) do
        local score = resultScore(spec, audio)
        if not bestScore or score > bestScore then
            best = audio
            bestScore = score
        end
    end

    -- Require a strong match. A wrong song is worse than a missing one.
    if best and bestScore and bestScore >= 130 then
        return best
    end
    return nil
end

function MusicPlayer:_resolvePublicTrack(spec)
    local best, lastError = searchOnce(spec, spec.Title, true)
    if best then
        return best
    end

    for _, query in ipairs(spec.Queries or {}) do
        local found, err = searchOnce(spec, query, false)
        if found then
            return found
        end
        if err then
            lastError = err
        end
    end

    return nil, lastError
end

function MusicPlayer:_makeCatalogTrack(spec, audio)
    local id = tonumber(audio.Id)
    local soundId = "rbxassetid://" .. tostring(id)
    return {
        Name = spec.Title,
        Title = spec.Title,
        Artist = (audio.Artist and tostring(audio.Artist) ~= "") and tostring(audio.Artist) or spec.Artist,
        Path = soundId,
        Asset = soundId,
        SoundId = soundId,
        RobloxAssetId = id,
        Duration = tonumber(audio.Duration) or spec.Duration,
        Cover = "rbxthumb://type=Asset&id=" .. tostring(id) .. "&w=420&h=420",
        CatalogResult = audio,
    }
end

function MusicPlayer:_resolveCatalog()
    if self._CatalogResolving then
        return
    end

    self._CatalogResolving = true
    self._CatalogError = nil
    self.Tracks = {}
    self._CatalogMatches = {}

    for _, spec in ipairs(CATALOG) do
        local audio, err = self:_resolvePublicTrack(spec)
        if audio then
            local track = self:_makeCatalogTrack(spec, audio)
            table.insert(self.Tracks, track)
            self._CatalogMatches[spec.Title] = track
        elseif err and not self._CatalogError then
            self._CatalogError = err
        end
        task.wait()
    end

    self._CatalogResolved = true
    self._CatalogResolving = false

    if self.CurrentIndex and not self.Tracks[self.CurrentIndex] then
        self.CurrentIndex = nil
    end

    self:_renderList()
    self:_update()
end

function MusicPlayer:Refresh()
    if self._CatalogResolved then
        self:_renderList()
        self:_update()
        return
    end

    self.Tracks = {}
    if self.UI and self.UI.Empty then
        self.UI.Empty.Visible = true
        self.UI.Empty.Text = "Finding your built-in songs on Roblox…"
    end

    self:_update()

    if not self._CatalogResolving then
        task.spawn(function()
            self:_resolveCatalog()
        end)
    end
end

function MusicPlayer:_coverFor(track)
    return track and track.Cover or nil
end

function MusicPlayer:_load(index, autoplay)
    local track = self.Tracks[index]
    if not track or not track.SoundId or not self.Sound then
        return
    end

    self.CurrentIndex = index
    self.Sound:Stop()
    self.Sound.SoundId = track.SoundId
    self.Sound.Volume = self.Volume
    self.Sound.Looped = self.RepeatOne

    if autoplay ~= false then
        self.Sound:Play()
        self.Playing = true
    else
        self.Playing = false
    end

    self:_update()
    self:_renderList()
end

function MusicPlayer:_update()
    BaseUpdate(self)

    if not self.UI then
        return
    end

    local track = self.CurrentIndex and self.Tracks[self.CurrentIndex] or nil
    if track then
        if self.UI.Title then self.UI.Title.Text = track.Title or track.Name end
        if self.UI.Sub then self.UI.Sub.Text = tostring(track.Artist or "Roblox Creator Store") end
        if self.UI.MiniPremiumTitle then self.UI.MiniPremiumTitle.Text = track.Title or track.Name end
        if self.UI.MiniPremiumSub then self.UI.MiniPremiumSub.Text = tostring(track.Artist or "Roblox Creator Store") end
    elseif self._CatalogResolving then
        if self.UI.Title then self.UI.Title.Text = "Loading your songs…" end
        if self.UI.Sub then self.UI.Sub.Text = "Built into VantaTest • no folders needed" end
    elseif self._CatalogResolved and #self.Tracks == 0 then
        if self.UI.Title then self.UI.Title.Text = "Songs unavailable" end
        if self.UI.Sub then self.UI.Sub.Text = "No matching public Roblox audio was found" end
    else
        if self.UI.Title then self.UI.Title.Text = "Music Player" end
        if self.UI.Sub then self.UI.Sub.Text = "Built-in VantaTest playlist" end
    end
end

function MusicPlayer:_renderList()
    BaseRenderList(self)

    if not self.UI then
        return
    end

    if self.UI.Empty then
        if self._CatalogResolving then
            self.UI.Empty.Visible = true
            self.UI.Empty.Text = "Finding your built-in songs on Roblox…"
        elseif self._CatalogResolved and #self.Tracks == 0 then
            self.UI.Empty.Visible = true
            self.UI.Empty.Text = "Exact public Roblox versions were not found"
        elseif #self.Tracks > 0 then
            self.UI.Empty.Visible = false
        end
    end

    for index, row in ipairs(self.Rows or {}) do
        local track = self.Tracks[index]
        if row and row.Parent and track then
            local labels = {}
            for _, child in ipairs(row:GetChildren()) do
                if child:IsA("TextLabel") then
                    table.insert(labels, child)
                end
            end
            table.sort(labels, function(a, b)
                return a.Position.Y.Offset < b.Position.Y.Offset
            end)
            if labels[1] then labels[1].Text = track.Title or track.Name end
            if labels[2] then labels[2].Text = tostring(track.Artist or "Roblox Creator Store") end
        end
    end
end

function MusicPlayer:Show()
    BaseShow(self)
    if not self._CatalogResolved and not self._CatalogResolving then
        self:Refresh()
    end
end

return MusicPlayer
