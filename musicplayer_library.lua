-- VantaTest named-track metadata + workspace import layer.
-- Keeps the premium player intact while making the user's music pack easier to install.

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

local TRACK_META = {
    ["Azeri Kavkaz"] = {
        Title = "Azeri Kavkaz",
        Artist = "Caucasus Dance",
        Album = "Azeri Kavkaz",
    },
    ["I Love You So (Arabic Version - Slowed)"] = {
        Title = "I Love You So (Arabic Version - Slowed)",
        Artist = "aessy • Tom Vaulbert",
        Album = "I Love You So (Arabic Version - Slowed)",
    },
}

local PACK_FILES = {
    "Azeri Kavkaz.mp3",
    "Azeri Kavkaz.png",
    "I Love You So (Arabic Version - Slowed).mp3",
    "I Love You So (Arabic Version - Slowed).png",
}

local SEARCH_ROOTS = {
    "VantaTest_Music_Pack/VantaTest/Music",
    "VantaTest Music Pack/VantaTest/Music",
    "VantaTest_Music_Pack",
    "VantaTest Music Pack",
    "Downloads",
    "Download",
    "Music",
    ".",
}

local BaseInit = MusicPlayer.Init
local BaseRefresh = MusicPlayer.Refresh
local BaseShow = MusicPlayer.Show
local BaseUpdate = MusicPlayer._update
local BaseRenderList = MusicPlayer._renderList

local function norm(path)
    return tostring(path or ""):gsub("\\", "/"):gsub("/+", "/")
end

local function join(a, b)
    a, b = norm(a), norm(b)
    if a == "" or a == "." then
        return b
    end
    return a:gsub("/$", "") .. "/" .. b:gsub("^/", "")
end

local function basename(path)
    return norm(path):match("([^/]+)$") or tostring(path or "")
end

local function fileExists(path)
    if not isfile then
        return false
    end
    local success, value = pcall(isfile, path)
    return success and value == true
end

local function folderExists(path)
    if not isfolder then
        return false
    end
    local success, value = pcall(isfolder, path)
    return success and value == true
end

local function ensureFolder(path)
    if not makefolder then
        return
    end

    local current = ""
    for part in norm(path):gmatch("[^/]+") do
        current = current == "" and part or (current .. "/" .. part)
        if not folderExists(current) then
            pcall(makefolder, current)
        end
    end
end

local function copyReadableFile(sourcePath, destinationPath)
    if fileExists(destinationPath) then
        return true
    end

    ensureFolder(norm(destinationPath):match("^(.*)/[^/]+$") or "VantaTest/Music")

    if copyfile then
        local success = pcall(copyfile, sourcePath, destinationPath)
        if success and fileExists(destinationPath) then
            return true
        end
    end

    if readfile and writefile then
        local success = pcall(function()
            local bytes = readfile(sourcePath)
            writefile(destinationPath, bytes)
        end)
        if success and fileExists(destinationPath) then
            return true
        end
    end

    return false
end

local function directCandidates(fileName)
    local candidates = {}
    for _, root in ipairs(SEARCH_ROOTS) do
        candidates[#candidates + 1] = join(root, fileName)
        candidates[#candidates + 1] = join(root, "VantaTest/Music/" .. fileName)
    end
    return candidates
end

local function findAccessibleFile(fileName)
    for _, candidate in ipairs(directCandidates(fileName)) do
        if fileExists(candidate) then
            return candidate
        end
    end

    if not listfiles then
        return nil
    end

    local queue = {}
    for _, root in ipairs(SEARCH_ROOTS) do
        queue[#queue + 1] = { Path = root, Depth = 0 }
    end

    local visited = {}
    local scanned = 0
    while #queue > 0 and scanned < 180 do
        local item = table.remove(queue, 1)
        local folder = norm(item.Path)
        if not visited[folder] and folderExists(folder) then
            visited[folder] = true
            scanned = scanned + 1

            local success, children = pcall(listfiles, folder)
            if success and type(children) == "table" then
                for _, child in ipairs(children) do
                    child = norm(child)
                    if fileExists(child) and basename(child) == fileName then
                        return child
                    end
                    if item.Depth < 3 and folderExists(child) then
                        queue[#queue + 1] = { Path = child, Depth = item.Depth + 1 }
                    end
                end
            end
        end
    end

    return nil
end

function MusicPlayer:_importMusicPack()
    local destinationRoot = tostring(self.Folder or "VantaTest/Music")
    ensureFolder("VantaTest")
    ensureFolder(destinationRoot)

    local imported = 0
    for _, fileName in ipairs(PACK_FILES) do
        local destination = join(destinationRoot, fileName)
        if not fileExists(destination) then
            local sourcePath = findAccessibleFile(fileName)
            if sourcePath and norm(sourcePath) ~= norm(destination) then
                if copyReadableFile(sourcePath, destination) then
                    imported = imported + 1
                end
            end
        end
    end

    if imported > 0 then
        self._ImportedPackCount = (self._ImportedPackCount or 0) + imported
    end

    return imported
end

function MusicPlayer:_hasUserSongs()
    local root = tostring(self.Folder or "VantaTest/Music")
    return fileExists(join(root, "Azeri Kavkaz.mp3"))
        or fileExists(join(root, "I Love You So (Arabic Version - Slowed).mp3"))
end

function MusicPlayer:_trackMeta(track)
    if not track then
        return nil
    end
    return TRACK_META[tostring(track.Name or "")]
end

function MusicPlayer:Init(windui, config)
    BaseInit(self, windui, config)
    self:_importMusicPack()
    return self
end

function MusicPlayer:Refresh()
    self:_importMusicPack()
    return BaseRefresh(self)
end

function MusicPlayer:Show()
    self:_importMusicPack()
    BaseShow(self)

    if self.UI and self.UI.Empty and #self.Tracks == 0 then
        self.UI.Empty.Text = "No songs found • extract the pack into your executor workspace / VantaTest/Music"
    end

    if not self:_hasUserSongs() and not self._MissingPackNotified then
        self._MissingPackNotified = true
        task.defer(function()
            if self.WindUI and self.WindUI.Notify then
                self.WindUI:Notify({
                    Title = "Music files not found",
                    Content = "VantaTest can only read your executor workspace. Extract the music pack so the files end up in VantaTest/Music, then press Refresh.",
                    Icon = "folder-open",
                    Duration = 8,
                })
            end
        end)
    end
end

function MusicPlayer:_update()
    BaseUpdate(self)

    if not self.UI then
        return
    end

    local track = self.CurrentIndex and self.Tracks[self.CurrentIndex] or nil
    local meta = self:_trackMeta(track)
    if not meta then
        return
    end

    if self.UI.Title then
        self.UI.Title.Text = meta.Title
    end
    if self.UI.Sub then
        self.UI.Sub.Text = meta.Artist .. "  •  " .. meta.Album
    end
    if self.UI.MiniPremiumTitle then
        self.UI.MiniPremiumTitle.Text = meta.Title
    end
    if self.UI.MiniPremiumSub then
        self.UI.MiniPremiumSub.Text = meta.Artist
    end
end

function MusicPlayer:_renderList()
    BaseRenderList(self)

    if self.UI and self.UI.Empty and #self.Tracks == 0 then
        self.UI.Empty.Text = "No songs found • VantaTest/Music"
    end

    for index, row in ipairs(self.Rows or {}) do
        local track = self.Tracks and self.Tracks[index]
        local meta = self:_trackMeta(track)
        if row and row.Parent and meta then
            local labels = {}
            for _, child in ipairs(row:GetChildren()) do
                if child:IsA("TextLabel") then
                    table.insert(labels, child)
                end
            end

            table.sort(labels, function(a, b)
                return a.Position.Y.Offset < b.Position.Y.Offset
            end)

            if labels[1] then
                labels[1].Text = meta.Title
            end
            if labels[2] then
                labels[2].Text = meta.Artist
            end
        end
    end
end

return MusicPlayer
