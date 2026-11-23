-- SaltyUI loader by Salty
-- Usage: local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/MrRos3/VantaTest/main/main.lua"))()
local RUNTIME_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/dist/main.lua"

local downloaded, source = pcall(function()
    return game:HttpGet(RUNTIME_URL)
end)
assert(downloaded, "[SaltyUI] Download failed: " .. tostring(source))
assert(type(source) == "string" and #source > 0, "[SaltyUI] Download was empty")

local loadRuntime, compileError = loadstring(source)
assert(loadRuntime, "[SaltyUI] Compile failed: " .. tostring(compileError))

local started, runtime = pcall(loadRuntime)
assert(started, "[SaltyUI] Startup failed: " .. tostring(runtime))
return runtime
