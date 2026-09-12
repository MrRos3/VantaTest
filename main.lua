-- VantaTest reset: mirror the normal production VantaUI loader.
-- No music-player experiments, cloud catalogs, bundled tracks, or local audio hooks.

local cacheBuster = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local url = "https://raw.githubusercontent.com/MrRos3/VantaUI/main/main.lua?v=" .. cacheBuster

local ok, source = pcall(function()
    return game:HttpGet(url)
end)
assert(ok and type(source) == "string" and #source > 0, "[VantaTest] Failed to load production VantaUI")

local loader, loadError = loadstring(source)
assert(loader, "[VantaTest] Failed to compile production VantaUI: " .. tostring(loadError))

return loader()
