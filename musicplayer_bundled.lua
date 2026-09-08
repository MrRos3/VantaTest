-- VantaTest built-in music distribution layer.
-- Built-in tracks live in this repository as base64 chunks. On first run the
-- executor downloads, decodes and caches them into VantaTest/Music. Later runs
-- reuse the local cache. No YouTube/Roblox audio/catalog API is involved.

local CACHE_BUSTER = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local REPO_RAW = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/"
local PREMIUM_URL = REPO_RAW .. "musicplayer_premium.lua?v=" .. CACHE_BUSTER
local BUNDLE_ROOT = REPO_RAW .. "assets/music/b64-v2/"
local MANIFEST_URL = BUNDLE_ROOT .. "manifest.lua?v=" .. CACHE_BUSTER

local ok, premiumSource = pcall(function()
    return game:HttpGet(PREMIUM_URL)
end)
assert(ok and type(premiumSource) == "string" and #premiumSource > 0,
    "[VantaTest Music] Could not load premium player")

local premiumLoader, premiumError = loadstring(premiumSource)
assert(premiumLoader, "[VantaTest Music] Premium player compile failed: " .. tostring(premiumError))

local MusicPlayer = premiumLoader()
assert(type(MusicPlayer) == "table", "[VantaTest Music] Premium player returned an invalid value")

local BaseInit = MusicPlayer.Init
local BaseRefresh = MusicPlayer.Refresh
local BaseShow = MusicPlayer.Show
local BaseUpdate = MusicPlayer._update
local BaseRenderList = MusicPlayer._renderList

local function norm(path)
    return tostring(path or ""):gsub("\\", "/"):gsub("/+", "/")
end

local function join(a, b)
    return norm(a):gsub("/$", "") .. "/" .. norm(b):gsub("^/", "")
end

local function fileExists(path)
    if not isfile then return false end
    local success, value = pcall(isfile, path)
    return success and value == true
end

local function folderExists(path)
    if not isfolder then return false end
    local success, value = pcall(isfolder, path)
    return success and value == true
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

local function deleteQuietly(path)
    if delfile and fileExists(path) then
        pcall(delfile, path)
    end
end

local function readText(path)
    if not readfile or not fileExists(path) then return nil end
    local success, value = pcall(readfile, path)
    return success and value or nil
end

local function pureLuaBase64Decode(data)
    local alphabet = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
    local lookup = {}
    for i = 1, #alphabet do
        lookup[alphabet:sub(i, i)] = i - 1
    end

    data = tostring(data or ""):gsub("%s+", "")
    local output = table.create and table.create(math.floor(#data * 0.75)) or {}
    local n = 0

    for i = 1, #data, 4 do
        local c1 = data:sub(i, i)
        local c2 = data:sub(i + 1, i + 1)
        local c3 = data:sub(i + 2, i + 2)
        local c4 = data:sub(i + 3, i + 3)
        local a = lookup[c1] or 0
        local b = lookup[c2] or 0
        local c = c3 == "=" and 0 or (lookup[c3] or 0)
        local d = c4 == "=" and 0 or (lookup[c4] or 0)

        n += 1
        output[n] = string.char(a * 4 + math.floor(b / 16))
        if c3 ~= "=" and c3 ~= "" then
            n += 1
            output[n] = string.char((b % 16) * 16 + math.floor(c / 4))
        end
        if c4 ~= "=" and c4 ~= "" then
            n += 1
            output[n] = string.char((c % 4) * 64 + d)
        end
    end

    return table.concat(output)
end

local function getBase64Decoder()
    if type(base64decode) == "function" then return base64decode end
    if crypt then
        if type(crypt.base64decode) == "function" then return crypt.base64decode end
        if crypt.base64 and type(crypt.base64.decode) == "function" then return crypt.base64.decode end
    end
    if syn and syn.crypt and syn.crypt.base64 and type(syn.crypt.base64.decode) == "function" then
        return syn.crypt.base64.decode
    end
    return pureLuaBase64Decode
end

local decodeBase64 = getBase64Decoder()

local function fetchText(url)
    local success, body = pcall(function()
        return game:HttpGet(url .. (url:find("?", 1, true) and "&" or "?") .. "cb=" .. CACHE_BUSTER)
    end)
    if not success or type(body) ~= "string" or #body == 0 then return nil, "request failed" end
    local head = body:sub(1, 160):lower()
    if head:find("404: not found", 1, true) or head:find("<!doctype html", 1, true) or head:find("<html", 1, true) then
        return nil, "repository file unavailable"
    end
    return body
end

local function loadManifest()
    local body, fetchError = fetchText(MANIFEST_URL)
    if not body then return nil, fetchError end
    local loader, compileError = loadstring(body)
    if not loader then return nil, "manifest compile failed: " .. tostring(compileError) end
    local success, manifest = pcall(loader)
    if not success or type(manifest) ~= "table" or type(manifest.tracks) ~= "table" then
        return nil, "manifest returned invalid data"
    end
    if type(manifest.version) ~= "string" or manifest.version == "" then return nil, "manifest has no version" end
    return manifest
end

local function chunkName(index)
    return string.format("%03d.b64", index)
end

function MusicPlayer:_bundleManifest(force)
    if self._BuiltinManifest and not force then return self._BuiltinManifest end
    local manifest, manifestError = loadManifest()
    if not manifest then
        self._BuiltinManifestError = manifestError
        return nil
    end
    self._BuiltinManifest = manifest
    self._BuiltinManifestError = nil
    return manifest
end

function MusicPlayer:_trackPaths(item)
    local folder = tostring(self.Folder or "VantaTest/Music")
    local stem = tostring(item.local_stem or item.title or item.key or "Vanta Builtin")
    local audioExt = tostring(item.audio and item.audio.ext or "mp3")
    local coverExt = tostring(item.cover and item.cover.ext or "jpg")
    return join(folder, stem .. "." .. audioExt), join(folder, stem .. "." .. coverExt)
end

function MusicPlayer:_markerPath()
    return join(tostring(self.Folder or "VantaTest/Music"), ".vanta-builtins-v2")
end

function MusicPlayer:_cacheReady(manifest)
    manifest = manifest or self:_bundleManifest(false)
    if not manifest or readText(self:_markerPath()) ~= manifest.version then return false end
    for _, item in ipairs(manifest.tracks) do
        local audioPath, coverPath = self:_trackPaths(item)
        if not fileExists(audioPath) or not fileExists(coverPath) then return false end
    end
    return true
end

function MusicPlayer:_decodeRemoteChunk(relativePath)
    local encoded, fetchError = fetchText(BUNDLE_ROOT .. relativePath)
    if not encoded then return nil, fetchError end
    encoded = encoded:gsub("%s+", "")
    local success, decoded = pcall(decodeBase64, encoded)
    if not success or type(decoded) ~= "string" or #decoded == 0 then return nil, "base64 decode failed" end
    return decoded
end

function MusicPlayer:_assembleFile(spec, outputPath)
    if not writefile then return false, "executor does not support writefile" end
    if type(spec) ~= "table" or type(spec.path) ~= "string" or tonumber(spec.chunks) == nil then
        return false, "invalid bundle file spec"
    end

    local count = math.max(1, math.floor(tonumber(spec.chunks)))
    local total = 0
    local pieces = appendfile and nil or {}
    deleteQuietly(outputPath)

    local opened, openError = pcall(writefile, outputPath, "")
    if not opened then return false, "could not create cache file: " .. tostring(openError) end

    for index = 1, count do
        local relative = norm(spec.path) .. "/" .. chunkName(index)
        local decoded, chunkError = self:_decodeRemoteChunk(relative)
        if not decoded then
            deleteQuietly(outputPath)
            return false, relative .. ": " .. tostring(chunkError)
        end

        total += #decoded
        if appendfile then
            local wrote, appendError = pcall(appendfile, outputPath, decoded)
            if not wrote then
                deleteQuietly(outputPath)
                return false, "cache append failed: " .. tostring(appendError)
            end
        else
            pieces[#pieces + 1] = decoded
        end
        if task and task.wait then task.wait() end
    end

    if pieces then
        local wrote, writeError = pcall(writefile, outputPath, table.concat(pieces))
        if not wrote then
            deleteQuietly(outputPath)
            return false, "cache write failed: " .. tostring(writeError)
        end
    end

    local wanted = tonumber(spec.bytes) or 0
    if wanted > 0 and total ~= wanted then
        deleteQuietly(outputPath)
        return false, string.format("byte check failed (%d/%d)", total, wanted)
    end
    return true
end

function MusicPlayer:_installTrack(item)
    local audioPath, coverPath = self:_trackPaths(item)
    local audioOk, audioError = self:_assembleFile(item.audio, audioPath)
    if not audioOk then return false, tostring(item.title or item.key) .. " audio: " .. tostring(audioError) end
    local coverOk, coverError = self:_assembleFile(item.cover, coverPath)
    if not coverOk then
        deleteQuietly(audioPath)
        return false, tostring(item.title or item.key) .. " cover: " .. tostring(coverError)
    end
    return true
end

function MusicPlayer:_builtinMeta(track)
    if not track or not self._BuiltinManifest then return nil end
    local name = tostring(track.Name or "")
    for _, item in ipairs(self._BuiltinManifest.tracks) do
        if name == tostring(item.local_stem or "") then return item end
    end
    return nil
end

function MusicPlayer:_selectFirstBuiltin()
    if self.CurrentIndex or not self.Tracks then return end
    for index, track in ipairs(self.Tracks) do
        if self:_builtinMeta(track) then
            self:_load(index, false)
            return
        end
    end
end

function MusicPlayer:_setInstallMessage(text)
    if self.UI and self.UI.Empty and #self.Tracks == 0 then
        self.UI.Empty.Visible = true
        self.UI.Empty.Text = text
    end
end

function MusicPlayer:_finishBuiltinInstall(success, errorMessage)
    self._BuiltinInstalling = false
    self._BuiltinInstalled = success == true
    self._BuiltinInstallError = success and nil or tostring(errorMessage or "download failed")
    local manifest = self._BuiltinManifest
    if success and manifest and writefile then pcall(writefile, self:_markerPath(), manifest.version) end

    if self.UI then
        BaseRefresh(self)
        if success then
            self:_selectFirstBuiltin()
        elseif #self.Tracks == 0 then
            self:_setInstallMessage("Built-in music download failed  •  tap ↻ to retry")
        end
    end
end

function MusicPlayer:_ensureBuiltins(force)
    if self._BuiltinInstalling then return end
    ensureFolder("VantaTest")
    ensureFolder(tostring(self.Folder or "VantaTest/Music"))

    local manifest = self:_bundleManifest(force == true and self._BuiltinManifest == nil)
    if not manifest then
        self._BuiltinInstallError = self._BuiltinManifestError or "manifest unavailable"
        self:_setInstallMessage("Built-in music bundle unavailable  •  tap ↻ to retry")
        return
    end

    if not force and self:_cacheReady(manifest) then
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
    self:_setInstallMessage("Downloading Vanta music…")

    task.spawn(function()
        for _, item in ipairs(manifest.tracks) do
            local success, installError = self:_installTrack(item)
            if not success then
                self:_finishBuiltinInstall(false, installError)
                return
            end
        end
        self:_finishBuiltinInstall(true)
    end)
end

function MusicPlayer:Init(windui, config)
    self._BuiltinManifest = nil
    self._BuiltinManifestError = nil
    self._BuiltinInstalling = false
    self._BuiltinInstalled = false
    self._BuiltinInstallError = nil
    BaseInit(self, windui, config)
    self:_ensureBuiltins(false)
    return self
end

function MusicPlayer:Refresh()
    BaseRefresh(self)
    local manifest = self:_bundleManifest(false)
    if manifest and self:_cacheReady(manifest) then
        self._BuiltinInstalled = true
        self._BuiltinInstallError = nil
        self:_selectFirstBuiltin()
        return
    end
    if self._BuiltinInstalling then
        self:_setInstallMessage("Downloading Vanta music…")
        return
    end
    if self._BuiltinInstallError then
        self:_setInstallMessage("Retrying Vanta music…")
        self:_ensureBuiltins(true)
    else
        self:_setInstallMessage("Getting built-in music…")
        self:_ensureBuiltins(false)
    end
end

function MusicPlayer:Show()
    BaseShow(self)
    if #self.Tracks == 0 then
        if self._BuiltinInstalling then
            self:_setInstallMessage("Downloading Vanta music…")
        elseif self._BuiltinInstallError then
            self:_setInstallMessage("Built-in music download failed  •  tap ↻ to retry")
        else
            self:_setInstallMessage("Getting built-in music…")
        end
    end
end

-- Compact base still references the non-standard IsPlaying property. Override it
-- here so the bundled player uses Roblox Sound.Playing reliably.
function MusicPlayer:TogglePlay()
    if not self.CurrentIndex then
        if #self.Tracks > 0 then self:_load(1, true) end
        return
    end
    local isPlaying = false
    if self.Sound then
        local success, value = pcall(function() return self.Sound.Playing end)
        isPlaying = success and value == true
    end
    if isPlaying then
        self.Sound:Pause()
        self.Playing = false
    else
        self.Sound:Resume()
        self.Playing = true
    end
    self:_update()
end

function MusicPlayer:_update()
    BaseUpdate(self)
    if not self.UI then return end
    local track = self.CurrentIndex and self.Tracks[self.CurrentIndex] or nil
    local meta = self:_builtinMeta(track)
    if not meta then return end
    if self.UI.Title then self.UI.Title.Text = tostring(meta.title or track.Name) end
    if self.UI.Sub then self.UI.Sub.Text = tostring(meta.artist or "Vanta") .. "  •  Vanta Built-in" end
    if self.UI.MiniPremiumTitle then self.UI.MiniPremiumTitle.Text = tostring(meta.title or track.Name) end
end

function MusicPlayer:_renderList()
    BaseRenderList(self)
    if not self.UI then return end
    if #self.Tracks == 0 then
        if self._BuiltinInstalling then
            self:_setInstallMessage("Downloading Vanta music…")
        elseif self._BuiltinInstallError then
            self:_setInstallMessage("Built-in music download failed  •  tap ↻ to retry")
        end
        return
    end

    for index, row in ipairs(self.Rows or {}) do
        local track = self.Tracks and self.Tracks[index]
        local meta = self:_builtinMeta(track)
        if row and row.Parent and meta then
            local labels = {}
            for _, child in ipairs(row:GetChildren()) do
                if child:IsA("TextLabel") then labels[#labels + 1] = child end
            end
            table.sort(labels, function(a, b)
                if a.Position.Y.Offset == b.Position.Y.Offset then return a.Position.X.Offset < b.Position.X.Offset end
                return a.Position.Y.Offset < b.Position.Y.Offset
            end)
            if labels[1] then labels[1].Text = tostring(meta.title or track.Name) end
            if labels[2] and meta.artist then labels[2].Text = tostring(meta.artist) end
        end
    end
end

return MusicPlayer
