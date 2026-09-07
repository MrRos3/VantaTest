-- VantaTest Android/mobile music discovery layer.
-- Loads the named-track library layer, then searches common executor and Android
-- paths for the user's supplied music pack and copies accessible files into
-- VantaTest/Music automatically.

local CACHE_BUSTER = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local LIBRARY_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/musicplayer_library.lua?v=" .. CACHE_BUSTER

local ok, source = pcall(function()
    return game:HttpGet(LIBRARY_URL)
end)
assert(ok and type(source) == "string" and #source > 0, "[VantaTest Music] Could not load library player")

local loader, loadError = loadstring(source)
assert(loader, "[VantaTest Music] Library player compile failed: " .. tostring(loadError))

local MusicPlayer = loader()
assert(type(MusicPlayer) == "table", "[VantaTest Music] Library player returned an invalid value")

local BaseRefresh = MusicPlayer.Refresh
local BaseShow = MusicPlayer.Show

local PACK_FILES = {
    "Azeri Kavkaz.mp3",
    "Azeri Kavkaz.png",
    "I Love You So (Arabic Version - Slowed).mp3",
    "I Love You So (Arabic Version - Slowed).png",
}

local ROOTS = {
    "VantaTest/Music",
    "workspace/VantaTest/Music",
    "VantaTest_Music_Pack/VantaTest/Music",
    "VantaTest Music Pack/VantaTest/Music",
    "workspace/VantaTest_Music_Pack/VantaTest/Music",
    "workspace/VantaTest Music Pack/VantaTest/Music",
    "Downloads/VantaTest/Music",
    "Download/VantaTest/Music",
    "Downloads/VantaTest_Music_Pack/VantaTest/Music",
    "Download/VantaTest_Music_Pack/VantaTest/Music",
    "/storage/emulated/0/Download/VantaTest/Music",
    "/storage/emulated/0/Download/VantaTest_Music_Pack/VantaTest/Music",
    "/storage/emulated/0/Downloads/VantaTest/Music",
    "/storage/emulated/0/Downloads/VantaTest_Music_Pack/VantaTest/Music",
    "/sdcard/Download/VantaTest/Music",
    "/sdcard/Download/VantaTest_Music_Pack/VantaTest/Music",
    "/sdcard/Downloads/VantaTest/Music",
    "/sdcard/Downloads/VantaTest_Music_Pack/VantaTest/Music",
    "workspace",
    "Downloads",
    "Download",
    ".",
    "",
}

local function norm(path)
    return tostring(path or ""):gsub("\\", "/"):gsub("/+", "/")
end

local function basename(path)
    return norm(path):match("([^/]+)$") or norm(path)
end

local function lower(value)
    return string.lower(tostring(value or ""))
end

local wanted = {}
for _, fileName in ipairs(PACK_FILES) do
    wanted[lower(fileName)] = fileName
end

local function fileExists(path)
    if not isfile then return false end
    local okFile, value = pcall(isfile, path)
    return okFile and value == true
end

local function folderExists(path)
    if not isfolder then return false end
    local okFolder, value = pcall(isfolder, path)
    return okFolder and value == true
end

local function ensureFolder(path)
    if not makefolder then return end
    local current = ""
    for part in norm(path):gmatch("[^/]+") do
        current = current == "" and part or (current .. "/" .. part)
        if not folderExists(current) then
            pcall(makefolder, current)
        end
    end
end

local function safeList(path)
    if not listfiles then return nil end
    local okList, result = pcall(listfiles, path)
    if okList and type(result) == "table" then
        return result
    end
    return nil
end

local function copyReadable(sourcePath, destinationPath)
    if fileExists(destinationPath) then return true end

    if copyfile then
        local okCopy = pcall(copyfile, sourcePath, destinationPath)
        if okCopy and fileExists(destinationPath) then return true end
    end

    if readfile and writefile then
        local okCopy = pcall(function()
            local bytes = readfile(sourcePath)
            writefile(destinationPath, bytes)
        end)
        if okCopy and fileExists(destinationPath) then return true end
    end

    return false
end

function MusicPlayer:_mobileDiscoverPack()
    if self._MobileDiscoveryRunning or not listfiles then return 0 end
    self._MobileDiscoveryRunning = true

    local target = norm(self.Folder or "VantaTest/Music")
    ensureFolder("VantaTest")
    ensureFolder(target)

    local found = {}
    local visited = {}
    local scanned = 0
    local MAX_ENTRIES = 900
    local MAX_DEPTH = 5

    -- Try exact paths first. This is fast and catches the common Android cases.
    for _, root in ipairs(ROOTS) do
        for _, fileName in ipairs(PACK_FILES) do
            local candidate
            if root == "" or root == "." then
                candidate = fileName
            else
                candidate = norm(root) .. "/" .. fileName
            end
            if fileExists(candidate) then
                found[lower(fileName)] = candidate
            end
        end
    end

    local function walk(path, depth)
        if scanned >= MAX_ENTRIES or depth > MAX_DEPTH then return end
        local key = norm(path)
        if visited[key] then return end
        visited[key] = true

        -- Some Android executors can list a path even when isfolder(path) lies,
        -- so deliberately try listfiles without requiring folderExists first.
        local entries = safeList(path)
        if not entries then return end

        for _, raw in ipairs(entries) do
            if scanned >= MAX_ENTRIES then break end
            scanned += 1

            local candidate = norm(raw)
            local fileName = lower(basename(candidate))
            if wanted[fileName] and not found[fileName] and fileExists(candidate) then
                found[fileName] = candidate
            elseif depth < MAX_DEPTH then
                local canDescend = folderExists(candidate)
                if canDescend then
                    local lc = lower(candidate)
                    if not lc:find("cache", 1, true)
                        and not lc:find("logs", 1, true)
                        and not lc:find("temp", 1, true) then
                        walk(candidate, depth + 1)
                    end
                end
            end
        end
    end

    for _, root in ipairs(ROOTS) do
        walk(root, 0)
        if scanned >= MAX_ENTRIES then break end
    end

    local imported = 0
    for lowerName, sourcePath in pairs(found) do
        local canonical = wanted[lowerName]
        local destination = target .. "/" .. canonical
        if norm(sourcePath) == norm(destination) then
            if fileExists(destination) then imported += 1 end
        elseif copyReadable(sourcePath, destination) then
            imported += 1
        end
    end

    self._MobileDiscoveryRunning = false
    self._MobileDiscoveryImported = imported
    return imported
end

function MusicPlayer:Refresh()
    self:_mobileDiscoverPack()
    return BaseRefresh(self)
end

function MusicPlayer:Show()
    self:_mobileDiscoverPack()
    BaseShow(self)

    if self.UI and self.UI.Empty and #(self.Tracks or {}) == 0 then
        self.UI.Empty.Text = "Songs still outside executor storage • move the pack into VantaTest/Music, then tap Refresh"
    end
end

return MusicPlayer
