-- VantaTest zero-folder music layer.
-- Downloads the bundled catalog straight into the executor's own workspace.

local CACHE_BUSTER = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local PREMIUM_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/musicplayer_premium.lua?v=" .. CACHE_BUSTER
local CATALOG_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/music_catalog.lua?v=" .. CACHE_BUSTER

local function loadRemote(url, label)
    local ok, source = pcall(function() return game:HttpGet(url) end)
    assert(ok and type(source) == "string" and #source > 0, "[VantaTest Music] Could not load " .. label)
    local fn, err = loadstring(source)
    assert(fn, "[VantaTest Music] " .. label .. " compile failed: " .. tostring(err))
    return fn()
end

local MusicPlayer = loadRemote(PREMIUM_URL, "premium player")
local Catalog = loadRemote(CATALOG_URL, "music catalog")

local BaseInit = MusicPlayer.Init
local BaseShow = MusicPlayer.Show
local BaseRefresh = MusicPlayer.Refresh
local BaseRenderList = MusicPlayer._renderList
local BaseUpdate = MusicPlayer._update

local function norm(path)
    return tostring(path or ""):gsub("\\", "/")
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
        if not has then pcall(makefolder, current) end
    end
end

local function fetchBytes(url)
    if type(url) ~= "string" or url == "" then return nil, "missing URL" end

    local Request = request or http_request or (syn and syn.request)
    if Request then
        local ok, result = pcall(Request, {
            Url = url,
            Method = "GET",
            Headers = { ["Cache-Control"] = "no-cache" },
        })
        if ok and type(result) == "table" and type(result.Body) == "string" and #result.Body > 0 then
            local code = tonumber(result.StatusCode or result.Status or 200) or 200
            if code >= 200 and code < 400 then
                return result.Body
            end
        end
    end

    local ok, body = pcall(function() return game:HttpGet(url) end)
    if ok and type(body) == "string" and #body > 0 then return body end
    return nil, "download failed"
end

function MusicPlayer:_catalogEntry(track)
    if not track then return nil end
    for _, item in ipairs(Catalog or {}) do
        if tostring(track.Name) == tostring(item.Title) then return item end
    end
end

function MusicPlayer:_installOne(item)
    if type(item) ~= "table" or not writefile then return false end
    local root = tostring(self.Folder or "VantaTest/Music")
    ensure("VantaTest")
    ensure(root)

    local audioPath = root .. "/" .. tostring(item.AudioFile)
    local coverPath = root .. "/" .. tostring(item.CoverFile)
    local changed = false

    if not exists(audioPath) and item.AudioURL and item.AudioURL ~= "" then
        local bytes = fetchBytes(item.AudioURL)
        if bytes then
            local ok = pcall(writefile, audioPath, bytes)
            changed = changed or (ok and exists(audioPath))
        end
    end

    if not exists(coverPath) and item.CoverURL and item.CoverURL ~= "" then
        local bytes = fetchBytes(item.CoverURL)
        if bytes then
            local ok = pcall(writefile, coverPath, bytes)
            changed = changed or (ok and exists(coverPath))
        end
    end

    return changed
end

function MusicPlayer:_allBundledReady()
    local root = tostring(self.Folder or "VantaTest/Music")
    if type(Catalog) ~= "table" or #Catalog == 0 then return false end
    for _, item in ipairs(Catalog) do
        if not exists(root .. "/" .. tostring(item.AudioFile)) then return false end
    end
    return true
end

function MusicPlayer:_downloadBundledLibrary(force)
    if self._CloudDownloading then return end
    if self:_allBundledReady() and not force then return end
    self._CloudDownloading = true

    task.spawn(function()
        if self.UI and self.UI.Empty then
            self.UI.Empty.Visible = true
            self.UI.Empty.Text = "Preparing your music…"
        end

        local any = false
        for _, item in ipairs(Catalog or {}) do
            any = self:_installOne(item) or any
        end

        self._CloudDownloading = false
        BaseRefresh(self)

        if self.UI and self.UI.Empty and #self.Tracks == 0 then
            self.UI.Empty.Text = "Music host is not connected yet"
        end

        if any and self.WindUI and self.WindUI.Notify then
            self.WindUI:Notify({
                Title = "Music ready",
                Content = "Your bundled songs were installed automatically 🩵",
                Icon = "music",
                Duration = 4,
            })
        end
    end)
end

function MusicPlayer:Init(windui, config)
    BaseInit(self, windui, config)
    self:_downloadBundledLibrary(false)
    return self
end

function MusicPlayer:Show()
    BaseShow(self)
    self:_downloadBundledLibrary(false)
end

function MusicPlayer:Refresh()
    if not self:_allBundledReady() then
        self:_downloadBundledLibrary(true)
    end
    return BaseRefresh(self)
end

function MusicPlayer:_renderList()
    BaseRenderList(self)
    for index, row in ipairs(self.Rows or {}) do
        local track = self.Tracks and self.Tracks[index]
        local item = self:_catalogEntry(track)
        if row and item then
            local labels = {}
            for _, child in ipairs(row:GetChildren()) do
                if child:IsA("TextLabel") then labels[#labels + 1] = child end
            end
            table.sort(labels, function(a, b) return a.Position.Y.Offset < b.Position.Y.Offset end)
            if labels[1] then labels[1].Text = item.Title end
            if labels[2] then labels[2].Text = item.Artist end
        end
    end
end

function MusicPlayer:_update()
    BaseUpdate(self)
    if not self.UI then return end
    local track = self.CurrentIndex and self.Tracks[self.CurrentIndex] or nil
    local item = self:_catalogEntry(track)
    if not item then return end
    if self.UI.Title then self.UI.Title.Text = item.Title end
    if self.UI.Sub then self.UI.Sub.Text = item.Artist end
    if self.UI.MiniPremiumTitle then self.UI.MiniPremiumTitle.Text = item.Title end
    if self.UI.MiniPremiumSub then self.UI.MiniPremiumSub.Text = item.Artist end
end

return MusicPlayer
