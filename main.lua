-- VantaTest: production VantaUI + deterministic feature cleanup.
-- Pressing the red X calls Window:Destroy(), so this wrapper runs every
-- registered cleanup first, then lets the normal VantaUI destroy path finish.

local cacheBuster = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local url = "https://raw.githubusercontent.com/MrRos3/VantaUI/main/main.lua?v=" .. cacheBuster

local ok, source = pcall(function()
    return game:HttpGet(url)
end)
assert(ok and type(source) == "string" and #source > 0, "[VantaTest] Failed to load production VantaUI")

local loader, loadError = loadstring(source)
assert(loader, "[VantaTest] Failed to compile production VantaUI: " .. tostring(loadError))

local VantaUI = loader()
assert(type(VantaUI) == "table", "[VantaTest] Production VantaUI returned an invalid value")

local BaseCreateWindow = VantaUI.CreateWindow

local function cleanupResource(resource, customCleanup)
    if customCleanup then
        customCleanup(resource)
        return
    end

    if type(resource) == "function" then
        resource()
        return
    end

    local kind = typeof(resource)
    if kind == "RBXScriptConnection" then
        if resource.Connected then
            resource:Disconnect()
        end
        return
    end

    if kind == "Instance" then
        resource:Destroy()
        return
    end

    if type(resource) == "table" then
        local methods = { "Cleanup", "Destroy", "Disconnect", "Stop", "Disable", "Cancel" }
        for _, methodName in ipairs(methods) do
            local method = resource[methodName]
            if type(method) == "function" then
                method(resource)
                return
            end
        end
    end
end

function VantaUI:CreateWindow(config)
    config = config or {}

    local window = BaseCreateWindow(self, config)
    local BaseDestroy = window.Destroy
    local cleanupStack = {}
    local cleanupRan = false

    -- Register anything that must be undone when the red X destroys the UI.
    -- Supported directly: functions, RBXScriptConnections, Instances, and
    -- tables exposing Cleanup/Destroy/Disconnect/Stop/Disable/Cancel.
    function window:RegisterCleanup(resource, customCleanup)
        if resource == nil or cleanupRan then
            return resource
        end

        table.insert(cleanupStack, {
            Resource = resource,
            Cleanup = customCleanup,
        })
        return resource
    end

    window.AddCleanup = window.RegisterCleanup
    window.RegisterReset = window.RegisterCleanup
    window.TrackFeature = window.RegisterCleanup

    function window:TrackConnection(connection)
        return self:RegisterCleanup(connection)
    end

    function window:TrackInstance(instance)
        return self:RegisterCleanup(instance)
    end

    -- Snapshot one property before a feature changes it. X restores the exact
    -- original value instead of guessing a Roblox default.
    function window:TrackProperty(instance, propertyName)
        if instance == nil or type(propertyName) ~= "string" then
            return nil
        end

        local success, originalValue = pcall(function()
            return instance[propertyName]
        end)
        if not success then
            return nil
        end

        self:RegisterCleanup(function()
            pcall(function()
                instance[propertyName] = originalValue
            end)
        end)

        return originalValue
    end

    function window:TrackProperties(instance, propertyNames)
        local originals = {}
        if type(propertyNames) ~= "table" then
            return originals
        end

        for _, propertyName in ipairs(propertyNames) do
            originals[propertyName] = self:TrackProperty(instance, propertyName)
        end
        return originals
    end

    -- For state that is not a Roblox property, snapshot it with a getter and
    -- restore it with a setter.
    function window:TrackState(getter, setter)
        if type(getter) ~= "function" or type(setter) ~= "function" then
            return nil
        end

        local success, originalValue = pcall(getter)
        if not success then
            return nil
        end

        self:RegisterCleanup(function()
            setter(originalValue)
        end)
        return originalValue
    end

    function window:Cleanup()
        if cleanupRan then
            return
        end
        cleanupRan = true

        -- Reverse order matters: later-created feature resources disappear
        -- before the state they depend on is restored.
        for index = #cleanupStack, 1, -1 do
            local entry = cleanupStack[index]
            cleanupStack[index] = nil

            local success, err = pcall(cleanupResource, entry.Resource, entry.Cleanup)
            if not success then
                warn("[VantaTest Cleanup] " .. tostring(err))
            end
        end
    end

    function window:IsCleanupComplete()
        return cleanupRan
    end

    -- The red X in VantaUI uses Window:Destroy(). Minimize still uses Close(),
    -- so minimizing does NOT disable features. Only a real destroy does.
    function window:Destroy(...)
        self:Cleanup()
        if BaseDestroy then
            return BaseDestroy(self, ...)
        end
    end

    -- Optional cleanup(s) can be supplied right in CreateWindow config.
    if type(config.Cleanup) == "function" then
        window:RegisterCleanup(config.Cleanup)
    elseif type(config.Cleanup) == "table" then
        for _, cleanup in ipairs(config.Cleanup) do
            window:RegisterCleanup(cleanup)
        end
    end

    return window
end

return VantaUI
