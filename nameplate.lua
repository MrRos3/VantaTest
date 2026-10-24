-- VantaTest Nameplate · native BillboardGui above the local player's character.
-- Client-only visual: other clients do not see it unless implemented on the server
-- of a Roblox experience you control. No remotes, HTTP requests or game changes.
local Players = game:GetService("Players")

local player = assert(Players.LocalPlayer, "Nameplate requires a Roblox client")
local Nameplate = {}

local ROOT_NAME = "VantaTestNameplateLifecycle"
local GUI_NAME = "VantaTestNameplate"

local STYLES = {
    Crimson = {
        accent = Color3.fromRGB(196, 36, 66),
        edge = Color3.fromRGB(103, 36, 57),
        fillA = Color3.fromRGB(25, 16, 23),
        fillB = Color3.fromRGB(9, 9, 13),
        badge = Color3.fromRGB(244, 159, 181),
    },
    OLED = {
        accent = Color3.fromRGB(157, 68, 85),
        edge = Color3.fromRGB(75, 52, 64),
        fillA = Color3.fromRGB(12, 11, 15),
        fillB = Color3.fromRGB(3, 3, 6),
        badge = Color3.fromRGB(220, 197, 207),
    },
    Steel = {
        accent = Color3.fromRGB(135, 151, 166),
        edge = Color3.fromRGB(67, 76, 90),
        fillA = Color3.fromRGB(22, 26, 33),
        fillB = Color3.fromRGB(8, 10, 15),
        badge = Color3.fromRGB(200, 212, 226),
    },
}

local function make(class, props, parent)
    local obj = Instance.new(class)
    for key, value in pairs(props or {}) do
        obj[key] = value
    end
    if parent then obj.Parent = parent end
    return obj
end

local function rounded(parent, radius)
    return make("UICorner", {CornerRadius = UDim.new(0, radius)}, parent)
end

local function stroke(parent, color, transparency)
    return make("UIStroke", {
        Color = color, Transparency = transparency or 0, Thickness = 1
    }, parent)
end

local function label(parent, name, value, fontSize, color, bold, props)
    local args = {
        Name = name, Text = tostring(value or ""),
        TextColor3 = color, TextSize = fontSize,
        Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
    }
    for k,v in pairs(props or {}) do args[k] = v end
    return make("TextLabel", args, parent)
end

local function cleanTag(value)
    local s = tostring(value or ""):gsub("[%c]", " "):match("^%s*(.-)%s*$") or ""
    -- Truncate at Unicode code-point boundaries; preserve Arabic and emoji.
    local valid, cutoff = pcall(utf8.offset, s, 19)
    if valid and cutoff then return s:sub(1, cutoff - 1) end
    if not valid then return "VANTA" end
    return s
end

function Nameplate.new(options)
    local config = options or {}
    local playerGui = player:WaitForChild("PlayerGui")
    local old = playerGui:FindFirstChild(ROOT_NAME)
    if old then old:Destroy() end

    local lifecycle = make("Folder", {Name = ROOT_NAME}, playerGui)
    local active = nil
    local humanoid = nil
    local previousDisplayType = nil
    local disposed = false
    local connections = {}

    local current = {
        enabled = config.Enabled ~= false,
        tag = cleanTag(config.Tag or "VANTA"),
        style = STYLES[config.Style] and config.Style or "Crimson",
        scale = math.clamp(tonumber(config.Scale) or 100, 70, 140) / 100,
        maxDistance = math.clamp(tonumber(config.MaxDistance) or 100, 30, 150),
        height = math.clamp(tonumber(config.Height) or 2.65, 1.5, 4.5),
        showUsername = config.ShowUsername ~= false,
    }

    local controller = {}

    local function track(conn)
        connections[#connections + 1] = conn
        return conn
    end

    local function restoreDefaultName()
        if humanoid and humanoid.Parent and previousDisplayType then
            pcall(function() humanoid.DisplayDistanceType = previousDisplayType end)
        end
        humanoid = nil
        previousDisplayType = nil
    end

    local function hideDefaultName(char)
        local hum = char:FindFirstChildOfClass("Humanoid")
        if not hum then return end
        if hum ~= humanoid then
            restoreDefaultName()
            humanoid = hum
            previousDisplayType = hum.DisplayDistanceType
        end
        if current.enabled then
            pcall(function()
                hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
            end)
        else
            restoreDefaultName()
        end
    end

    local function updateStyle()
        if not active or not active.Parent then return end
        local style = STYLES[current.style]
        local plate = active:FindFirstChild("Plate")
        if not plate then return end

        plate.BackgroundColor3 = style.fillA
        plate.UIStroke.Color = style.edge
        plate.UIGradient.Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, style.fillA),
            ColorSequenceKeypoint.new(1, style.fillB),
        })
        plate.Accent.BackgroundColor3 = style.accent
        plate.AvatarRing.UIStroke.Color = style.edge
        plate.AvatarRing.BackgroundColor3 = style.edge
        plate.TagChip.BackgroundColor3 = style.fillA
        plate.TagChip.UIStroke.Color = style.edge
        plate.TagChip.TagText.TextColor3 = style.badge
        plate.TagChip.StatusDot.BackgroundColor3 = style.accent
    end

    local function updateContents()
        if not active or not active.Parent then return end
        local plate = active.Plate
        plate.DisplayName.Text = player.DisplayName
        plate.Username.Text = "@" .. player.Name
        plate.Username.Visible = current.showUsername
        plate.TagChip.TagText.Text = current.tag ~= "" and current.tag or "VANTA"
    end

    local function updateGeometry()
        if not active or not active.Parent then return end
        local s = current.scale
        active.Size = UDim2.fromOffset(math.floor(260 * s), math.floor(82 * s))
        active.MaxDistance = current.maxDistance
        active.StudsOffsetWorldSpace = Vector3.new(0, current.height, 0)
        -- Text and avatar scale as one composition, not stretched independently.
        active.Plate.UIScale.Scale = s
    end

    local function destroyPlate()
        if active then
            active:Destroy()
            active = nil
        end
        restoreDefaultName()
    end

    local function createForCharacter(char)
        local head = char:FindFirstChild("Head") or char:WaitForChild("Head", 8)
        if disposed or not head or char ~= player.Character then return end

        destroyPlate()
        active = make("BillboardGui", {
            Name = GUI_NAME,
            Adornee = head,
            AlwaysOnTop = true,
            Active = false,
            Enabled = current.enabled,
            LightInfluence = 0,
            MaxDistance = current.maxDistance,
            Size = UDim2.fromOffset(260, 82),
            StudsOffsetWorldSpace = Vector3.new(0, current.height, 0),
            ResetOnSpawn = false,
        }, playerGui)

        local plate = make("Frame", {
            Name = "Plate",
            AnchorPoint = Vector2.new(0.5, 0.5),
            Position = UDim2.fromScale(0.5, 0.5),
            Size = UDim2.fromOffset(248, 68),
            BackgroundColor3 = STYLES[current.style].fillA,
            BorderSizePixel = 0,
            ClipsDescendants = false,
            Active = false,
        }, active)
        rounded(plate, 13)
        stroke(plate, STYLES[current.style].edge, 0.18)
        make("UIGradient", {
            Rotation = 12,
            Color = ColorSequence.new({
                ColorSequenceKeypoint.new(0, STYLES[current.style].fillA),
                ColorSequenceKeypoint.new(1, STYLES[current.style].fillB),
            })
        }, plate)
        make("UIScale", {Scale = current.scale}, plate)
        make("Frame", {
            Name = "Accent",
            Position = UDim2.fromOffset(0, 12),
            Size = UDim2.new(0, 3, 1, -24),
            BackgroundColor3 = STYLES[current.style].accent,
            BorderSizePixel = 0,
        }, plate)

        local ring = make("Frame", {
            Name = "AvatarRing",
            Position = UDim2.fromOffset(10, 11),
            Size = UDim2.fromOffset(45, 45),
            BackgroundColor3 = STYLES[current.style].edge,
            BorderSizePixel = 0,
        }, plate)
        rounded(ring, 24)
        stroke(ring, STYLES[current.style].edge, 0.08)
        local photo = make("ImageLabel", {
            Name = "Avatar",
            Image = ("rbxthumb://type=AvatarHeadShot&id=%d&w=100&h=100"):format(player.UserId),
            BackgroundTransparency = 1,
            Position = UDim2.fromOffset(3, 3),
            Size = UDim2.new(1, -6, 1, -6),
        }, ring)
        rounded(photo, 22)

        label(plate, "DisplayName", player.DisplayName, 16,
            Color3.fromRGB(246, 242, 247), true, {
            Position = UDim2.fromOffset(66, 24),
            Size = UDim2.fromOffset(164, 19),
        })
        label(plate, "Username", "@" .. player.Name, 10,
            Color3.fromRGB(175, 159, 172), false, {
            Position = UDim2.fromOffset(66, 43),
            Size = UDim2.fromOffset(163, 15),
        })

        local chip = make("Frame", {
            Name = "TagChip",
            Position = UDim2.fromOffset(66, 5),
            Size = UDim2.fromOffset(126, 18),
            BackgroundColor3 = STYLES[current.style].fillA,
            BackgroundTransparency = 0.1,
            BorderSizePixel = 0,
        }, plate)
        rounded(chip, 8)
        stroke(chip, STYLES[current.style].edge, 0.3)
        local dot = make("Frame", {
            Name = "StatusDot",
            Position = UDim2.fromOffset(8, 7),
            Size = UDim2.fromOffset(4, 4),
            BackgroundColor3 = STYLES[current.style].accent,
            BorderSizePixel = 0,
        }, chip)
        rounded(dot, 3)
        label(chip, "TagText", current.tag, 10, STYLES[current.style].badge, true, {
            Position = UDim2.fromOffset(19, 0),
            Size = UDim2.new(1, -25, 1, 0),
        })

        updateStyle()
        updateContents()
        updateGeometry()
        hideDefaultName(char)
    end

    local function mountCharacter(char)
        if disposed then return end
        task.spawn(function()
            createForCharacter(char)
        end)
    end

    function controller:SetEnabled(flag)
        if disposed then return end
        current.enabled = not not flag
        if active then active.Enabled = current.enabled end
        if current.enabled and player.Character then
            hideDefaultName(player.Character)
        else
            restoreDefaultName()
        end
    end

    function controller:SetStyle(value)
        if disposed or not STYLES[value] then return end
        current.style = value
        updateStyle()
    end

    function controller:SetTag(value)
        if disposed then return end
        current.tag = cleanTag(value)
        updateContents()
    end

    function controller:SetScale(value)
        if disposed then return end
        current.scale = math.clamp(tonumber(value) or 100, 70, 140) / 100
        updateGeometry()
    end

    function controller:SetDistance(value)
        if disposed then return end
        current.maxDistance = math.clamp(tonumber(value) or 100, 30, 150)
        updateGeometry()
    end

    function controller:SetHeight(value)
        if disposed then return end
        current.height = math.clamp(tonumber(value) or 2.65, 1.5, 4.5)
        updateGeometry()
    end

    function controller:SetShowUsername(flag)
        if disposed then return end
        current.showUsername = not not flag
        updateContents()
    end

    function controller:GetBillboard()
        return active
    end

    function controller:Destroy()
        if disposed then return end
        disposed = true
        for _,conn in ipairs(connections) do conn:Disconnect() end
        destroyPlate()
        if lifecycle.Parent then lifecycle:Destroy() end
    end

    track(lifecycle.Destroying:Connect(function()
        controller:Destroy()
    end))
    track(player.CharacterAdded:Connect(mountCharacter))
    track(player.CharacterRemoving:Connect(function(char)
        if active and active.Adornee and active.Adornee:IsDescendantOf(char) then
            destroyPlate()
        end
    end))

    if player.Character then
        mountCharacter(player.Character)
    end

    return controller
end

return Nameplate
