-- VantaTest public loader.
-- Core UI logic is preserved in main_core.lua; this wrapper adds the
-- GitHub-backed user-owned music layer without changing the core runtime.

local CACHE_BUSTER = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local REPO_RAW = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/"
local CORE_URL = REPO_RAW .. "main_core.lua?v=" .. CACHE_BUSTER
local MUSIC_URL = REPO_RAW .. "musicplayer_cloud_owned.lua?v=" .. CACHE_BUSTER

local function loadRemote(url, label)
    local ok, source = pcall(function()
        return game:HttpGet(url)
    end)
    assert(ok and type(source) == "string" and #source > 0,
        "[VantaTest] Could not load " .. tostring(label))

    local fn, err = loadstring(source)
    assert(fn, "[VantaTest] " .. tostring(label) .. " compile failed: " .. tostring(err))
    return fn()
end

local VantaUI = loadRemote(CORE_URL, "core")
assert(type(VantaUI) == "table", "[VantaTest] Core returned an invalid value")

local previousMusicPlayer = VantaUI.MusicPlayer
local musicOk, MusicPlayer = pcall(loadRemote, MUSIC_URL, "cloud music player")

if musicOk and type(MusicPlayer) == "table" then
    if previousMusicPlayer and previousMusicPlayer ~= MusicPlayer and previousMusicPlayer.Destroy then
        pcall(function()
            previousMusicPlayer:Destroy()
        end)
    end

    local initOk, initError = pcall(function()
        MusicPlayer:Init(VantaUI, {
            Folder = "VantaTest/Music",
        })
    end)

    if initOk then
        VantaUI.MusicPlayer = MusicPlayer
    else
        warn("[VantaTest Music] Cloud music init failed: " .. tostring(initError))
    end
else
    warn("[VantaTest Music] Cloud music layer unavailable; using local player")
end

return VantaUI
