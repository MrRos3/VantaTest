-- VantaTest built-in music distribution layer.
-- Everyone running the same VantaTest loadstring receives the same built-in
-- tracks automatically. Files are downloaded once from this repository and
-- cached inside the executor's VantaTest/Music folder.

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

local RAW_ROOT = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/assets/music/builtin/"
local CACHE_VERSION = "vanta-builtins-2026-09-09-v2"

local BUILTINS = {
    {
        Key = "azeri-kavkaz",
        LocalStem = "Vanta Builtin - Azeri Kavkaz",
        Title = "Azeri Kavkaz",
        Artist = "Caucasus Dance",
        AudioRemote = "azeri-kavkaz.ogg",
        CoverRemote = "azeri-kavkaz.jpg",
    },
    {
        Key = "i-love-you-so-arabic-slowed",
        LocalStem = "Vanta Builtin - I Love You So (Arabic Version - Slowed)",
        Title = "I Love You So (Arabic Version - Slowed)",
        Artist = "aessy • Tom Vaulbert",
        AudioRemote = "i-love-you-so-arabic-slowed.ogg",
        CoverRemote = "i-love-you-so-arabic-slowed.jpg",
    },
}

local META_BY_STEM = {}
for _, item in ipairs(BUILTINS) do
    META_BY_STEM[item.LocalStem] = item
end

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
    return a:gsub("/$", "") .. "/" .. b:gsub("^/", "")
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

local function readText(path)
    if not readfile or not fileExists(path) then
        return nil
    end
    local success, value = pcall(readfile, path)
    return success and value or nil
end

local function looksLikeHtmlOrError(bytes)
    if type(bytes) ~= "string" then
        return true
    end
    local head = bytes:sub(1, 180):lower()
    return head:find("<!doctype html", 1, true)
        or head:find("<html", 1, true)
        or head:find("404: not found", 1, true)
        or head:find("repository not found", 1, true)
end

local function fetchBinary(url, minimumBytes)
    local success, body = pcall(function()
        return game:HttpGet(url .. "?v=" .. CACHE_BUSTER)
    end)

    if not success or type(body) ~= "string" then
        return nil, "request failed"
    end
    if #body < (minimumBytes or 1) then
        return nil, "response was too small"
    end
    if looksLikeHtmlOrError(body) then
        return nil, "server returned an error page"
    end
    return body
end

function MusicPlayer:_builtinPaths(item)
    local folder = tostring(self.Folder or "VantaTest/Music")
    return join(folder, item.LocalStem .. ".ogg"), join(folder, item.LocalStem .. ".jpg")
end

function MusicPlayer:_builtinMarkerPath()
    return join(tostring(self.Folder or "VantaTest/Music"), ".vanta-builtins")
end

function MusicPlayer:_builtinCacheReady()
    if readText(self:_builtinMarkerPath()) ~= CACHE_VERSION then
        return false
    end

    for _, item in ipairs(BUILTINS) do
        local audioPath, coverPath = self:_builtinPaths(item)
        if not fileExists(audioPath) or not fileExists(coverPath) then
            return false
        end
    end
    return true
end

function MusicPlayer:_downloadBuiltin(item)
    if not writefile then
        return false, "executor does not support writefile"
    end

    local audioPath, coverPath = self:_builtinPaths(item)
    local audio, audioError = fetchBinary(RAW_ROOT .. item.AudioRemote, 50000)
    if not audio then
        return false, item.Title .. " audio: " .. tostring(audioError)
    end

    local cover, coverError = fetchBinary(RAW_ROOT .. item.CoverRemote, 500)
    if not cover then
        return false, item.Title .. " cover: " .. tostring(coverError)
    end

    local audioOk, audioWriteError = pcall(writefile, audioPath, audio)
    if not audioOk then
        return false, item.Title .. " audio write: " .. tostring(audioWriteError)
    end

    local coverOk, coverWriteError = pcall(writefile, coverPath, cover)
    if not coverOk then
        return false, item.Title .. " cover write: " .. tostring(coverWriteError)
    end

    return true
end

function MusicPlayer:_selectFirstBuiltin()
    if self.CurrentIndex or not self.Tracks then
        return
    end

    for index, track in ipairs(self.Tracks) do
        if META_BY_STEM[tostring(track.Name or "")] then
            self:_load(index, false)
            return
        end
    end
end

function MusicPlayer:_finishBuiltinInstall(success, errorMessage)
    self._BuiltinInstalling = false
    self._BuiltinInstalled = success == true
    self._BuiltinInstallError = success and nil or tostring(errorMessage or "download failed")

    if success and writefile then
        pcall(writefile, self:_builtinMarkerPath(), CACHE_VERSION)
    end

    if self.UI then
        BaseRefresh(self)
        if success then
            self:_selectFirstBuiltin()
        elseif self.UI.Empty and #self.Tracks == 0 then
            self.UI.Empty.Visible = true
            self.UI.Empty.Text = "Couldn't cache Vanta music  •  tap ↻ to retry"
        end
    end
end

function MusicPlayer:_ensureBuiltins(force)
    if self._BuiltinInstalling then
        return
    end

    ensureFolder("VantaTest")
    ensureFolder(tostring(self.Folder or "VantaTest/Music"))

    if not force and self:_builtinCacheReady() then
        self._BuiltinInstalled = true
        self._BuiltinInstallError = nil
        if self.UI then
            BaseRefresh(self)
            self:_selectFirstBuiltin()
        end
        return
    end

    self._BuiltinInstalling = true
    self._BuiltinInstallError = nil

    if self.UI and self.UI.Empty and #self.Tracks == 0 then
        self.UI.Empty.Visible = true
        self.UI.Empty.Text = "Getting Vanta music…"
    end

    task.spawn(function()
        for _, item in ipairs(BUILTINS) do
            local success, errorMessage = self:_downloadBuiltin(item)
            if not success then
                self:_finishBuiltinInstall(false, errorMessage)
                return
            end
            task.wait()
        end
        self:_finishBuiltinInstall(true)
    end)
end

function MusicPlayer:_builtinMeta(track)
    if not track then
        return nil
    end
    return META_BY_STEM[tostring(track.Name or "")]
end

function MusicPlayer:Init(windui, config)
    BaseInit(self, windui, config)
    self._BuiltinInstalling = false
    self._BuiltinInstalled = false
    self._BuiltinInstallError = nil
    self:_ensureBuiltins(false)
    return self
end

function MusicPlayer:Refresh()
    BaseRefresh(self)

    if self:_builtinCacheReady() then
        self._BuiltinInstalled = true
        self:_selectFirstBuiltin()
        return
    end

    if self.UI and self.UI.Empty and #self.Tracks == 0 then
        self.UI.Empty.Visible = true
        self.UI.Empty.Text = self._BuiltinInstalling
            and "Getting Vanta music…"
            or "Preparing built-in music…"
    end

    self:_ensureBuiltins(self._BuiltinInstallError ~= nil)
end

function MusicPlayer:Show()
    BaseShow(self)

    if self.UI and self.UI.Empty and #self.Tracks == 0 then
        self.UI.Empty.Visible = true
        if self._BuiltinInstalling then
            self.UI.Empty.Text = "Getting Vanta music…"
        elseif self._BuiltinInstallError then
            self.UI.Empty.Text = "Couldn't cache Vanta music  •  tap ↻ to retry"
        else
            self.UI.Empty.Text = "Preparing built-in music…"
        end
    end
end

function MusicPlayer:_update()
    BaseUpdate(self)

    if not self.UI then
        return
    end

    local track = self.CurrentIndex and self.Tracks[self.CurrentIndex] or nil
    local meta = self:_builtinMeta(track)
    if not meta then
        return
    end

    if self.UI.Title then
        self.UI.Title.Text = meta.Title
    end
    if self.UI.Sub then
        self.UI.Sub.Text = meta.Artist .. "  •  Vanta Built-in"
    end
    if self.UI.MiniPremiumTitle then
        self.UI.MiniPremiumTitle.Text = meta.Title
    end
end

function MusicPlayer:_renderList()
    BaseRenderList(self)

    if not self.UI then
        return
    end

    if #self.Tracks == 0 and self.UI.Empty then
        self.UI.Empty.Visible = true
        if self._BuiltinInstalling then
            self.UI.Empty.Text = "Getting Vanta music…"
        elseif self._BuiltinInstallError then
            self.UI.Empty.Text = "Couldn't cache Vanta music  •  tap ↻ to retry"
        end
    end

    for index, row in ipairs(self.Rows or {}) do
        local track = self.Tracks and self.Tracks[index]
        local meta = self:_builtinMeta(track)
        if row and row.Parent and meta then
            local labels = {}
            for _, child in ipairs(row:GetChildren()) do
                if child:IsA("TextLabel") then
                    table.insert(labels, child)
                end
            end

            table.sort(labels, function(a, b)
                if a.Position.Y.Offset == b.Position.Y.Offset then
                    return a.Position.X.Offset < b.Position.X.Offset
                end
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
