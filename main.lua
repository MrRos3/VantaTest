-- VantaTest loader by MrRos3 (salty)
-- Usage: local UI = loadstring(game:HttpGet("https://raw.githubusercontent.com/MrRos3/VantaTest/main/main.lua"))()
local RUNTIME_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/dist/main.lua"

local downloaded, source = pcall(function()
    return game:HttpGet(RUNTIME_URL)
end)
assert(downloaded, "[VantaTest] Download failed: " .. tostring(source))
assert(type(source) == "string" and #source > 0, "[VantaTest] Download was empty")

local loadRuntime, compileError = loadstring(source)
assert(loadRuntime, "[VantaTest] Compile failed: " .. tostring(compileError))

local started, runtime = pcall(loadRuntime)
assert(started, "[VantaTest] Startup failed: " .. tostring(runtime))
return runtime
