-- VantaTest cloud music layer for user-owned / licensed tracks.
-- Downloads catalog tracks from this repository into VantaTest/Music,
-- then lets the existing premium player load them as local custom assets.

local CACHE_BUSTER = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local REPO_RAW = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/"
local PREMIUM_URL = REPO_RAW .. "musicplayer_premium.lua?v=" .. CACHE_BUSTER
local CATALOG_URL = REPO_RAW .. "music_catalog_owned.lua?v=" .. CACHE_BUSTER

local function loadRemote(url, label)
    local ok, source = pcall(function()
        return game:HttpGet(url)
    end)
    assert(ok and type(source) == "string" and #source > 0,
        "[VantaTest Music] Could not load " .. tostring(label))

    local fn, err = loadstring(source)
    assert(fn, "[VantaTest Music] " .. tostring(label) .. " compile failed: " .. tostring(err))
    return fn()
end

local MusicPlayer = loadRemote(PREMIUM_URL, "premium player")
local Catalog = loadRemote(CATALOG_URL, "owned music catalog")

local BaseInit = MusicPlayer.Init
local BaseShow = MusicPlayer.Show
local BaseRefresh = MusicPlayer.Refresh
local BaseRenderList = MusicPlayer._renderList
local BaseUpdate = MusicPlayer._update

local function norm(path)
    return tostring(path or ""):gsub("\\", "/")
end

local function basename(path)
    return norm(path):match("([^/]+)$") or norm(path)
end

local function stem(path)
    local name = basename(path)
    return (name:gsub("%.[^%.]+$", ""))
end

local function exists(path)
    if not isfile then return false end
    local ok, value = pcall(isfile, path)
    return ok and value == true
end

local function ensure(path)
    if not makefolder then return end
    local current = ""
    for part in norm(path):gmatch("[^/]+") do
        current = current == "" and part or (current .. "/" .. part)
        local has = false
        if isfolder then
            local ok, value = pcall(isfolder, current)
            has = ok and value == true
        end
        if not has then
            pcall(makefolder, current)
        end
    end
end

local function fetchBytes(url)
    if type(url) ~= "string" or url == "" then
        return nil, "missing URL"
    end

    local Request = request or http_request or (syn and syn.request)
    if Request then
        local ok, result = pcall(Request, {
            Url = url,
            Method = "GET",
            Headers = {
                ["Cache-Control"] = "no-cache",
            },
        })

        if ok and type(result) == "table" and type(result.Body) == "string" and #result.Body > 0 then
            local code = tonumber(result.StatusCode or result.Status or 200) or 200
            if code >= 200 and code < 400 then
                return result.Body
            end
        end
    end

    local ok, body = pcall(function()
        return game:HttpGet(url)
    end)
    if ok and type(body) == "string" and #body > 0 then
        return body
    end

    return nil, "download failed"
end

local function itemAudioFile(item)
    if type(item.AudioFile) == "string" and item.AudioFile ~= "" then
        return item.AudioFile
    end
    return basename(item.AudioPath or "")
end

local function itemCoverFile(item)
    if type(item.CoverFile) == "string" and item.CoverFile ~= "" then
        return item.CoverFile
    end
    return basename(item.CoverPath or "")
end

local function itemAudioURL(item)
    if type(item.AudioURL) == "string" and item.AudioURL ~= "" then
        return item.AudioURL
    end
    if type(item.AudioPath) == "string" and item.AudioPath ~= "" then
        return REPO_RAW .. norm(item.AudioPath)
    end
    return nil
end

local function itemCoverURL(item)
    if type(item.CoverURL) == "string" and item.CoverURL ~= "" then
        return item.CoverURL
    end
    if type(item.CoverPath) == "string" and item.CoverPath ~= "" then
        return REPO_RAW .. norm(item.CoverPath)
    end
    return nil
end

function MusicPlayer:_ownedCatalogEntry(track)
    if not track then return nil end

    local trackName = tostring(track.Name or "")
    local trackPath = tostring(track.Path or "")
    local trackFile = basename(trackPath)
    local trackStem = stem(trackPath)

    for _, item in ipairs(Catalog or {}) do
        local title = tostring(item.Title or "")
        local audioFile = itemAudioFile(item)
        local audioStem = stem(audioFile)

        if trackName == title
            or trackName == audioStem
            or trackFile == audioFile
            or trackStem == audioStem
        then
            return item
        end
    end

    return nil
end

function MusicPlayer:_installOwnedTrack(item)
    if type(item) ~= "table" or not writefile then
        return false
    end

    local root = tostring(self.Folder or "VantaTest/Music")
    ensure("VantaTest")
    ensure(root)

    local audioFile = itemAudioFile(item)
    local audioURL = itemAudioURL(item)
    if audioFile == "" or not audioURL then
        return false
    end

    local audioPath = root .. "/" .. audioFile
    local changed = false

    if not exists(audioPath) then
        local bytes = fetchBytes(audioURL)
        if bytes then
            local ok = pcall(writefile, audioPath, bytes)
            changed = changed or (ok and exists(audioPath))
        end
    end

    local coverFile = itemCoverFile(item)
    local coverURL = itemCoverURL(item)
    if coverFile ~= "" and coverURL then
        local coverPath = root .. "/" .. coverFile
        if not exists(coverPath) then
            local bytes = fetchBytes(coverURL)
            if bytes then
                local ok = pcall(writefile, coverPath, bytes)
                changed = changed or (ok and exists(coverPath))
            end
        end
    end

    return changed
end

function MusicPlayer:_ownedLibraryReady()
    if type(Catalog) ~= "table" or #Catalog == 0 then
        return true
    end

    local root = tostring(self.Folder or "VantaTest/Music")
    for _, item in ipairs(Catalog) do
        local audioFile = itemAudioFile(item)
        if audioFile == "" or not exists(root .. "/" .. audioFile) then
            return false
        end
    end

    return true
end

function MusicPlayer:_downloadOwnedLibrary(force)
    if self._OwnedCloudDownloading then
        return
    end
    if self:_ownedLibraryReady() and not force then
        return
    end

    self._OwnedCloudDownloading = true

    task.spawn(function()
        if self.UI and self.UI.Empty and type(Catalog) == "table" and #Catalog > 0 then
            self.UI.Empty.Visible = true
            self.UI.Empty.Text = "Preparing Vanta music…"
        end

        local any = false
        for _, item in ipairs(Catalog or {}) do
            any = self:_installOwnedTrack(item) or any
        end

        self._OwnedCloudDownloading = false
        BaseRefresh(self)

        if any and self.WindUI and self.WindUI.Notify then
            self.WindUI:Notify({
                Title = "Music ready",
                Content = "VantaTest downloaded your music library.",
                Icon = "music",
                Duration = 4,
            })
        end
    end)
end

function MusicPlayer:Init(windui, config)
    BaseInit(self, windui, config)
    self:_downloadOwnedLibrary(false)
    return self
end

function MusicPlayer:Show()
    BaseShow(self)
    self:_downloadOwnedLibrary(false)
end

function MusicPlayer:Refresh()
    self:_downloadOwnedLibrary(false)
    return BaseRefresh(self)
end

function MusicPlayer:_renderList()
    BaseRenderList(self)

    for index, row in ipairs(self.Rows or {}) do
        local track = self.Tracks and self.Tracks[index]
        local item = self:_ownedCatalogEntry(track)
        if row and item then
            local labels = {}
            for _, child in ipairs(row:GetChildren()) do
                if child:IsA("TextLabel") then
                    labels[#labels + 1] = child
                end
            end

            table.sort(labels, function(a, b)
                return a.Position.Y.Offset < b.Position.Y.Offset
            end)

            if labels[1] and item.Title then
                labels[1].Text = item.Title
            end
            if labels[2] and item.Artist then
                labels[2].Text = item.Artist
            end
        end
    end
end

function MusicPlayer:_update()
    BaseUpdate(self)
    if not self.UI then return end

    local track = self.CurrentIndex and self.Tracks[self.CurrentIndex] or nil
    local item = self:_ownedCatalogEntry(track)
    if not item then return end

    if self.UI.Title and item.Title then self.UI.Title.Text = item.Title end
    if self.UI.Sub and item.Artist then self.UI.Sub.Text = item.Artist end
    if self.UI.MiniPremiumTitle and item.Title then self.UI.MiniPremiumTitle.Text = item.Title end
    if self.UI.MiniPremiumSub and item.Artist then self.UI.MiniPremiumSub.Text = item.Artist end
end

return MusicPlayer
