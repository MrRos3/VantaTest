-- VantaTest compatibility entry point.
-- The music library is now resolved from Roblox's public audio catalog so
-- every user running the same VantaTest script gets the same built-in tracks.

local CACHE_BUSTER = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local CATALOG_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/musicplayer_catalog.lua?v=" .. CACHE_BUSTER

local ok, source = pcall(function()
    return game:HttpGet(CATALOG_URL)
end)
assert(ok and type(source) == "string" and #source > 0, "[VantaTest Music] Could not load public catalog")

local loader, loadError = loadstring(source)
assert(loader, "[VantaTest Music] Public catalog compile failed: " .. tostring(loadError))
return loader()
