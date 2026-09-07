local cacheBuster = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local source = game:HttpGet(
    "https://raw.githubusercontent.com/MrRos3/VantaTest/main/example.lua?v=" .. cacheBuster
)

source = source:gsub(
    "https://raw%.githubusercontent%.com/MrRos3/VantaTest/main/musicplayer_library%.lua%?v=",
    "https://raw.githubusercontent.com/MrRos3/VantaTest/public-music-catalog-v2/musicplayer_catalog.lua?v="
)

local loader, err = loadstring(source)
assert(loader, "[VantaTest Catalog Test] compile failed: " .. tostring(err))
return loader()
