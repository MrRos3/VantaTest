-- VantaTest keeps the normal production VantaUI showcase, but routes its
-- loader through VantaTest/main.lua so the red-X cleanup lifecycle is active.

local cacheBuster = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local productionExampleUrl = "https://raw.githubusercontent.com/MrRos3/VantaUI/main/example.lua?v=" .. cacheBuster

local ok, source = pcall(function()
    return game:HttpGet(productionExampleUrl)
end)
assert(ok and type(source) == "string" and #source > 0, "[VantaTest] Failed to load production VantaUI example")

source = source:gsub(
    "https://raw%.githubusercontent%.com/MrRos3/VantaUI/main/main%.lua%?v=",
    "https://raw.githubusercontent.com/MrRos3/VantaTest/main/main.lua?v="
)

local loader, loadError = loadstring(source)
assert(loader, "[VantaTest] Failed to compile production VantaUI example: " .. tostring(loadError))
return loader()
