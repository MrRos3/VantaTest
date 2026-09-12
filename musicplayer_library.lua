-- VantaTest music library entry point.
-- Keeps local executor songs, plus a built-in Roblox audio track that works
-- for everyone who runs the same script (subject to Roblox audio permissions).

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

local MarketplaceService = game:GetService("MarketplaceService")

local BUILTIN = {
    AssetId = 131870608567212,
    SoundId = "rbxassetid://131870608567212",
    Name = "Vanta Song",
    Creator = "Roblox Audio",
    Cover = "rbxthumb://type=Asset&id=131870608567212&w=420&h=420",
}

local BaseRefresh = MusicPlayer.Refresh
local BaseLoad = MusicPlayer._load
local BaseCoverFor = MusicPlayer._coverFor
local BaseUpdate = MusicPlayer._update
local BaseRenderList = MusicPlayer._renderList
local BaseInit = MusicPlayer.Init

local function makeBuiltinTrack()
    return {
        Name = BUILTIN.Name,
        Creator = BUILTIN.Creator,
        Path = "Roblox/131870608567212.audio",
        SoundId = BUILTIN.SoundId,
        AssetId = BUILTIN.AssetId,
        Cover = BUILTIN.Cover,
        IsRobloxAsset = true,
    }
end

local function findTrackByIdentity(tracks, identity)
    if not identity then
        return nil
    end
    for index, track in ipairs(tracks or {}) do
        if identity.SoundId and track.SoundId == identity.SoundId then
            return index
        end
        if identity.Path and track.Path == identity.Path then
            return index
        end
    end
    return nil
end

function MusicPlayer:_coverFor(track)
    if track and track.IsRobloxAsset then
        return track.Cover
    end
    return BaseCoverFor(self, track)
end

function MusicPlayer:_load(index, autoplay)
    local track = self.Tracks and self.Tracks[index]
    if not track or not track.IsRobloxAsset then
        return BaseLoad(self, index, autoplay)
    end

    self.CurrentIndex = index
    self.Sound:Stop()
    self.Sound.SoundId = track.SoundId
    self.Sound.Volume = self.Volume
    self.Sound.Looped = self.RepeatOne

    if autoplay ~= false then
        self.Sound:Play()
        self.Playing = self.Sound.Playing == true
    else
        self.Playing = false
    end

    self:_update()
    self:_renderList()
end

function MusicPlayer:TogglePlay()
    if not self.CurrentIndex then
        if self.Tracks and #self.Tracks > 0 then
            self:_load(1, true)
        end
        return
    end

    if self.Sound.Playing then
        self.Sound:Pause()
        self.Playing = false
    else
        local okResume = pcall(function()
            self.Sound:Resume()
        end)
        if not okResume or not self.Sound.Playing then
            self.Sound:Play()
        end
        self.Playing = self.Sound.Playing == true
    end
    self:_update()
end

function MusicPlayer:Refresh()
    local previous = nil
    if self.CurrentIndex and self.Tracks and self.Tracks[self.CurrentIndex] then
        local old = self.Tracks[self.CurrentIndex]
        previous = { Path = old.Path, SoundId = old.SoundId }
    end

    BaseRefresh(self)

    table.insert(self.Tracks, 1, makeBuiltinTrack())

    local restored = findTrackByIdentity(self.Tracks, previous)
    if restored then
        self.CurrentIndex = restored
    elseif not self.CurrentIndex or not self.Tracks[self.CurrentIndex] then
        self.CurrentIndex = nil
    end

    -- Select the built-in song without auto-playing so the player opens ready.
    if not self.CurrentIndex then
        self:_load(1, false)
    else
        self:_renderList()
        self:_update()
    end
end

function MusicPlayer:_update()
    BaseUpdate(self)

    if not self.UI then
        return
    end

    local track = self.CurrentIndex and self.Tracks and self.Tracks[self.CurrentIndex]
    if track and track.IsRobloxAsset then
        if self.UI.Title then
            self.UI.Title.Text = track.Name
        end
        if self.UI.Sub then
            self.UI.Sub.Text = (track.Creator or "Roblox Audio") .. "  •  ROBLOX"
        end
    end
end

function MusicPlayer:_renderList()
    BaseRenderList(self)

    for index, track in ipairs(self.Tracks or {}) do
        if track.IsRobloxAsset then
            local row = self.Rows and self.Rows[index]
            if row then
                for _, child in ipairs(row:GetChildren()) do
                    if child:IsA("TextLabel") and child.Text:find("LOCAL", 1, true) then
                        child.Text = "ROBLOX  •  AUDIO"
                    end
                end
            end
        end
    end
end

function MusicPlayer:Init(windui, config)
    BaseInit(self, windui, config)

    -- Resolve the real Roblox asset name/creator when that metadata is public.
    task.spawn(function()
        local success, info = pcall(function()
            return MarketplaceService:GetProductInfo(BUILTIN.AssetId, Enum.InfoType.Asset)
        end)
        if success and type(info) == "table" then
            if type(info.Name) == "string" and info.Name ~= "" then
                BUILTIN.Name = info.Name
            end
            if type(info.Creator) == "table" and type(info.Creator.Name) == "string" and info.Creator.Name ~= "" then
                BUILTIN.Creator = info.Creator.Name
            end
            if self.UI then
                self:Refresh()
            end
        end
    end)

    return self
end

return MusicPlayer
