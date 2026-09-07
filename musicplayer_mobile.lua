-- VantaTest mobile/executor music discovery layer.
-- Finds user-provided tracks anywhere inside the executor-accessible workspace,
-- copies them into VantaTest/Music, and keeps premium presentation intact.

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

local BaseRefresh = MusicPlayer.Refresh
local BaseRenderList = MusicPlayer._renderList
local BaseUpdate = MusicPlayer._update

local TRACK_INFO = {
    ["azeri kavkaz"] = {
        title = "Azeri Kavkaz",
        artist = "Caucasus Dance",
    },
    ["i love you so (arabic version - slowed)"] = {
        title = "I Love You So (Arabic Version - Slowed)",
        artist = "aessy • Tom Vaulbert",
    },
}

local WANTED_FILES = {
    ["azeri kavkaz.mp3"] = true,
    ["azeri kavkaz.png"] = true,
    ["i love you so (arabic version - slowed).mp3"] = true,
    ["i love you so (arabic version - slowed).png"] = true,
}

local function norm(path)
    return tostring(path or ""):gsub("\\", "/"):gsub("/+", "/")
end

local function basename(path)
    return norm(path):match("([^/]+)$") or norm(path)
end

local function stem(path)
    return basename(path):gsub("%.[^%.]+$", "")
end

local function lower(value)
    return string.lower(tostring(value or ""))
end

local function existsFile(path)
    if not isfile then return false end
    local okFile, value = pcall(isfile, path)
    return okFile and value == true
end

local function existsFolder(path)
    if not isfolder then return false end
    local okFolder, value = pcall(isfolder, path)
    return okFolder and value == true
end

local function ensureFolder(path)
    if not makefolder then return end
    local current = ""
    for part in norm(path):gmatch("[^/]+") do
        current = current == "" and part or (current .. "/" .. part)
        if not existsFolder(current) then
            pcall(makefolder, current)
        end
    end
end

local function safeList(path)
    if not listfiles then return nil end
    local okList, files = pcall(listfiles, path)
    if okList and type(files) == "table" then
        return files
    end
    return nil
end

local function copyFile(sourcePath, destinationPath)
    if not readfile or not writefile or existsFile(destinationPath) then
        return existsFile(destinationPath)
    end
    local okRead, bytes = pcall(readfile, sourcePath)
    if not okRead or type(bytes) ~= "string" then
        return false
    end
    local okWrite = pcall(writefile, destinationPath, bytes)
    return okWrite and existsFile(destinationPath)
end

function MusicPlayer:_discoverUserTracks()
    if self._DiscoveryRunning or not listfiles then
        return 0
    end
    self._DiscoveryRunning = true

    local targetFolder = norm(self.Folder or "VantaTest/Music")
    ensureFolder("VantaTest")
    ensureFolder(targetFolder)

    local found = {}
    local visited = {}
    local scanned = 0
    local MAX_SCANNED = 600
    local MAX_DEPTH = 4

    local roots = {
        targetFolder,
        "VantaTest",
        "VantaTest_Music_Pack",
        "VantaTest_Music_Pack/VantaTest",
        "VantaTest_Music_Pack/VantaTest/Music",
        "workspace",
        "scripts",
        "autoexec",
        ".",
        "",
    }

    local function walk(path, depth)
        if scanned >= MAX_SCANNED or depth > MAX_DEPTH then return end
        local key = norm(path)
        if visited[key] then return end
        visited[key] = true

        local entries = safeList(path)
        if not entries then return end

        for _, rawPath in ipairs(entries) do
            if scanned >= MAX_SCANNED then break end
            scanned += 1

            local candidate = norm(rawPath)
            local fileName = lower(basename(candidate))
            if WANTED_FILES[fileName] and not found[fileName] then
                found[fileName] = candidate
            elseif depth < MAX_DEPTH and existsFolder(candidate) then
                local lowerPath = lower(candidate)
                if not lowerPath:find("cache", 1, true)
                    and not lowerPath:find("logs", 1, true)
                    and not lowerPath:find("workspace/vantatest/music", 1, true) then
                    walk(candidate, depth + 1)
                end
            end
        end
    end

    for _, root in ipairs(roots) do
        walk(root, 0)
        if scanned >= MAX_SCANNED then break end
    end

    local imported = 0
    for fileName, sourcePath in pairs(found) do
        local destination = targetFolder .. "/" .. basename(sourcePath)
        if norm(sourcePath) ~= norm(destination) then
            if copyFile(sourcePath, destination) then
                imported += 1
            end
        elseif existsFile(destination) then
            imported += 1
        end
    end

    self._DiscoveryRunning = false
    self._LastDiscoveryCount = imported
    return imported
end

function MusicPlayer:_applyKnownTrackMetadata()
    for _, track in ipairs(self.Tracks or {}) do
        local info = TRACK_INFO[lower(stem(track.Path or track.Name))]
        if info then
            track.Name = info.title
            track.Artist = info.artist
        end
    end
end

function MusicPlayer:Refresh()
    -- First try the normal folder. If the expected tracks are missing, search
    -- the executor sandbox and import them automatically, then refresh again.
    BaseRefresh(self)
    self:_applyKnownTrackMetadata()

    local hasKnown = false
    for _, track in ipairs(self.Tracks or {}) do
        if TRACK_INFO[lower(stem(track.Path or track.Name))] then
            hasKnown = true
            break
        end
    end

    if not hasKnown then
        local imported = self:_discoverUserTracks()
        if imported > 0 then
            BaseRefresh(self)
            self:_applyKnownTrackMetadata()
        end
    end

    if self.UI and self.UI.Empty and #(self.Tracks or {}) == 0 then
        self.UI.Empty.Text = "No songs found — put the MP3s inside your executor workspace/VantaTest/Music"
    end
end

function MusicPlayer:_renderList()
    BaseRenderList(self)

    -- Replace generic LOCAL • MP3 subtitles with the artist for known tracks.
    for index, row in ipairs(self.Rows or {}) do
        local track = self.Tracks and self.Tracks[index]
        if row and track and track.Artist then
            for _, child in ipairs(row:GetChildren()) do
                if child:IsA("TextLabel") and child.Text and child.Text:find("LOCAL", 1, true) then
                    child.Text = track.Artist
                    break
                end
            end
        end
    end
end

function MusicPlayer:_update()
    BaseUpdate(self)

    local track = self.CurrentIndex and self.Tracks[self.CurrentIndex] or nil
    if track and track.Artist and self.UI then
        if self.UI.Sub then
            self.UI.Sub.Text = track.Artist .. "  •  LOCAL MP3"
        end
    end
end

return MusicPlayer
