-- VantaTest reset: run the normal production VantaUI showcase.

local cacheBuster = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local url = "https://raw.githubusercontent.com/MrRos3/VantaUI/main/example.lua?v=" .. cacheBuster

local ok, source = pcall(function()
    return game:HttpGet(url)
end)
assert(ok and type(source) == "string" and #source > 0, "[VantaTest] Failed to load production VantaUI example")

local loader, loadError = loadstring(source)
assert(loader, "[VantaTest] Failed to compile production VantaUI example: " .. tostring(loadError))

return loader()
