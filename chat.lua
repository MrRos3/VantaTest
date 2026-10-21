-- VantaTest Chat LAB
-- A Pulse-inspired visual experiment with real, filtered Roblox server chat.
-- This is NOT a cross-game or cross-server relay; never invent global presence.
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local TextService = game:GetService("TextService")
local LocalPlayer = Players.LocalPlayer

local Chat = {}
local DARK = Color3.fromRGB(18, 15, 17)
local PANEL = Color3.fromRGB(28, 23, 25)
local BUBBLE = Color3.fromRGB(43, 35, 38)
local BURGUNDY = Color3.fromRGB(122, 39, 57)
local TEXT = Color3.fromRGB(246, 239, 242)
local MUTED = Color3.fromRGB(164, 151, 157)
local GREEN = Color3.fromRGB(58, 208, 125)

local function node(kind, props, parent)
    local instance = Instance.new(kind)
    for key, value in pairs(props or {}) do
        instance[key] = value
    end
    if parent then instance.Parent = parent end
    return instance
end

local function rounded(parent, radius)
    return node("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function text(parent, value, size, color, weight, props)
    local settings = {
        BackgroundTransparency = 1,
        Text = value, TextSize = size, TextColor3 = color or TEXT,
        Font = weight or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }
    for k, v in pairs(props or {}) do settings[k] = v end
    return node("TextLabel", settings, parent)
end

local function channel()
    local folder = TextChatService:FindFirstChild("TextChannels")
    local general = folder and folder:FindFirstChild("RBXGeneral")
    if general and general:IsA("TextChannel") then return general end
    return nil
end

local function detectLanguage(value)
    local ok, isRussian = pcall(function()
        for _, codepoint in utf8.codes(value) do
            if codepoint >= 0x0400 and codepoint <= 0x052F then
                return true
            end
        end
        return false
    end)
    return (ok and isRussian) and "RU" or "EN"
end

local function headshot(userId)
    return ("rbxthumb://type=AvatarHeadShot&id=%d&w=100&h=100"):format(userId)
end

function Chat.Mount(tab)
    local viewport = assert(tab.UIElements and tab.UIElements.ContainerFrame, "Missing VantaTest tab container")
    local pad = viewport:FindFirstChildOfClass("UIPadding")
    if pad then
        pad.PaddingTop = UDim.new(0, 6)
        pad.PaddingBottom = UDim.new(0, 6)
        pad.PaddingLeft = UDim.new(0, 6)
        pad.PaddingRight = UDim.new(0, 6)
    end

    local root = node("Frame", {
        Name = "VantaChatExperiment", LayoutOrder = 1,
        Size = UDim2.new(1, 0, 0, 404),
        BackgroundColor3 = DARK, BackgroundTransparency = 0.06,
        BorderSizePixel = 0, ClipsDescendants = true,
    }, viewport)
    rounded(root, 16)
    node("UIStroke", { Color = Color3.fromRGB(91, 58, 66), Transparency = 0.57, Thickness = 1 }, root)

    text(root, "Chat", 19, TEXT, Enum.Font.GothamBold, {
        Position = UDim2.fromOffset(14, 6), Size = UDim2.new(0.62, 0, 0, 26),
    })
    text(root, "Talk with players in this Roblox server", 11, MUTED, nil, {
        Position = UDim2.fromOffset(14, 31), Size = UDim2.new(0.77, 0, 0, 17),
    })
    local liveDot = node("Frame", {
        Position = UDim2.new(1, -61, 0, 18), Size = UDim2.fromOffset(7, 7),
        BackgroundColor3 = GREEN, BorderSizePixel = 0,
    }, root)
    rounded(liveDot, 7)
    local liveLabel = text(root, "LIVE", 10, GREEN, Enum.Font.GothamBold, {
        Position = UDim2.new(1, -51, 0, 11), Size = UDim2.fromOffset(43, 20),
    })

    local room = node("Frame", {
        Name = "RoomBar", Position = UDim2.fromOffset(10, 56),
        Size = UDim2.new(1, -20, 0, 54),
        BackgroundColor3 = Color3.fromRGB(31, 26, 28),
        BackgroundTransparency = 0.05, BorderSizePixel = 0,
    }, root)
    rounded(room, 13)
    node("UIStroke", { Color = Color3.fromRGB(76, 62, 67), Transparency = 0.62 }, room)
    local logo = node("Frame", {
        Position = UDim2.fromOffset(9, 10), Size = UDim2.fromOffset(33, 33),
        BackgroundColor3 = BURGUNDY, BorderSizePixel = 0,
    }, room)
    rounded(logo, 9)
    text(logo, "▣", 19, TEXT, Enum.Font.GothamBold, {
        Size = UDim2.fromScale(1, 1), TextXAlignment = Enum.TextXAlignment.Center,
    })
    text(room, "Vanta Chat", 13, TEXT, Enum.Font.GothamBold, {
        Position = UDim2.fromOffset(50, 8), Size = UDim2.new(0, 116, 0, 19),
    })
    local online = text(room, "", 10, MUTED, nil, {
        Position = UDim2.fromOffset(50, 28), Size = UDim2.fromOffset(142, 14),
    })
    local languages = {}
    local currentLanguage = "EN"
    local messages = {}
    local seen = {}
    local messageConnections = {}
    local alive = true

    local function markConnection(conn)
        if conn then messageConnections[#messageConnections + 1] = conn end
    end

    local function makeLanguageButton(language, x)
        local button = node("TextButton", {
            Name = language .. "Filter", Text = language,
            Font = Enum.Font.GothamBold, TextSize = 10,
            TextColor3 = MUTED, AutoButtonColor = false,
            Position = UDim2.new(1, x, 0, 13),
            Size = UDim2.fromOffset(40, 27), BorderSizePixel = 0,
            BackgroundColor3 = Color3.fromRGB(38, 33, 35),
        }, room)
        rounded(button, 14)
        languages[language] = button
        return button
    end
    local enButton = makeLanguageButton("EN", -141)
    local ruButton = makeLanguageButton("RU", -97)

    local playerAvatars = node("Frame", {
        Name = "OnlineAvatars", Size = UDim2.fromOffset(43, 33),
        Position = UDim2.new(1, -48, 0, 10),
        BackgroundTransparency = 1,
    }, room)
    local function refreshPresence()
        if not alive then return end
        local everyone = Players:GetPlayers()
        online.Text = tostring(#everyone) .. " in this server"
        for _, obj in ipairs(playerAvatars:GetChildren()) do obj:Destroy() end
        for idx = 1, math.min(#everyone, 3) do
            local member = everyone[idx]
            local avatar = node("ImageLabel", {
                Name = "PlayerAvatar",
                Image = headshot(member.UserId),
                BackgroundColor3 = Color3.fromRGB(66, 58, 62),
                Position = UDim2.fromOffset((idx - 1) * 11, 7),
                Size = UDim2.fromOffset(23, 23),
                BorderSizePixel = 0, ZIndex = idx + 2,
            }, playerAvatars)
            rounded(avatar, 23)
            node("UIStroke", { Color = DARK, Thickness = 1.5 }, avatar)
        end
    end

    local feed = node("ScrollingFrame", {
        Name = "MessageFeed", Position = UDim2.fromOffset(10, 117),
        Size = UDim2.new(1, -20, 1, -181),
        CanvasSize = UDim2.fromOffset(0, 0),
        AutomaticCanvasSize = Enum.AutomaticSize.Y,
        ScrollingDirection = Enum.ScrollingDirection.Y,
        ScrollBarThickness = 2,
        ScrollBarImageColor3 = BURGUNDY,
        BackgroundColor3 = Color3.fromRGB(22, 19, 20),
        BackgroundTransparency = 0.12, BorderSizePixel = 0,
    }, root)
    rounded(feed, 13)
    node("UIPadding", {
        PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 9),
        PaddingLeft = UDim.new(0, 9), PaddingRight = UDim.new(0, 9),
    }, feed)
    local layout = node("UIListLayout", {
        Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder,
    }, feed)

    local compose = node("Frame", {
        Name = "Composer",
        Position = UDim2.new(0, 10, 1, -56),
        Size = UDim2.new(1, -20, 0, 45),
        BackgroundColor3 = Color3.fromRGB(31, 27, 28),
        BorderSizePixel = 0,
    }, root)
    rounded(compose, 20)
    node("UIStroke", { Color = Color3.fromRGB(91, 69, 74), Transparency = 0.55 }, compose)
    text(compose, "▧", 16, MUTED, nil, {
        Position = UDim2.fromOffset(12, 3), Size = UDim2.fromOffset(24, 38),
    })
    local input = node("TextBox", {
        Name = "MessageInput", Text = "", PlaceholderText = "Message in EN...",
        ClearTextOnFocus = false, MultiLine = false,
        Font = Enum.Font.Gotham, TextSize = 13,
        TextColor3 = TEXT, PlaceholderColor3 = MUTED,
        TextXAlignment = Enum.TextXAlignment.Left,
        BackgroundTransparency = 1,
        Position = UDim2.fromOffset(43, 1),
        Size = UDim2.new(1, -95, 1, -2),
    }, compose)
    local sendButton = node("TextButton", {
        Name = "Send", Text = "➤",
        TextColor3 = Color3.fromRGB(255, 236, 241),
        Font = Enum.Font.GothamBold, TextSize = 20,
        BackgroundColor3 = BURGUNDY, BorderSizePixel = 0,
        Position = UDim2.new(1, -41, 0, 5),
        Size = UDim2.fromOffset(35, 35), AutoButtonColor = true,
    }, compose)
    rounded(sendButton, 35)

    local notice = text(root, "Preview bubbles below are examples until someone speaks.", 9, MUTED, nil, {
        Position = UDim2.fromOffset(13, 110),
        Size = UDim2.new(1, -26, 0, 9), Visible = false,
    })

    local function updateAvailability()
        local ready = channel() ~= nil
        liveDot.BackgroundColor3 = ready and GREEN or Color3.fromRGB(237, 163, 79)
        liveLabel.Text = ready and "LIVE" or "LOCAL"
        liveLabel.TextColor3 = ready and GREEN or Color3.fromRGB(237, 163, 79)
        if not ready then
            input.PlaceholderText = "Chat unavailable in this game"
        else
            input.PlaceholderText = "Message in " .. currentLanguage .. "..."
        end
    end

    local function showLanguage()
        for language, button in pairs(languages) do
            local selected = language == currentLanguage
            button.BackgroundColor3 = selected and BURGUNDY or Color3.fromRGB(38, 33, 35)
            button.TextColor3 = selected and TEXT or MUTED
        end
        updateAvailability()
    end

    local demo = {
        { display = "Vanta Preview", name = "Preview", content = "The new chat design is looking clean! 🌹", demo = true, lang = "EN" },
        { display = "UI Preview", name = "Preview", content = "Tap a live message to @reply. Messages are filtered by Roblox.", demo = true, lang = "EN" },
        { display = "Vanta Preview", name = "Preview", content = "Привет! 🌹", demo = true, lang = "RU" },
    }
    local function scrollToBottom()
        task.defer(function()
            if alive and feed.Parent then
                local maxY = math.max(0, layout.AbsoluteContentSize.Y - feed.AbsoluteSize.Y + 22)
                feed.CanvasPosition = Vector2.new(0, maxY)
            end
        end)
    end
    local function showRow(item, index)
        local width = math.max(185, feed.AbsoluteSize.X - 76)
        local own = item.userId == LocalPlayer.UserId and not item.demo
        local safeText = tostring(item.content or "")
        local textBounds = TextService:GetTextSize(safeText, 12, Enum.Font.Gotham, Vector2.new(width - 27, 4000))
        local textHeight = math.max(19, textBounds.Y)
        local rowHeight = 37 + textHeight + 10
        local row = node("Frame", {
            Name = "ChatRow", LayoutOrder = index, BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, rowHeight),
        }, feed)
        local avatar = node("Frame", {
            BackgroundColor3 = Color3.fromRGB(67, 47, 57),
            BorderSizePixel = 0, Size = UDim2.fromOffset(29, 29),
            Position = own and UDim2.new(1, -29, 0, 3) or UDim2.fromOffset(0, 3),
        }, row)
        rounded(avatar, 29)
        if item.userId then
            node("ImageLabel", {
                Image = headshot(item.userId), BackgroundTransparency = 1,
                Size = UDim2.fromScale(1, 1),
            }, avatar)
            rounded(avatar:FindFirstChildOfClass("ImageLabel"), 29)
        else
            text(avatar, "V", 15, TEXT, Enum.Font.GothamBold, {
                Size = UDim2.fromScale(1, 1),
                TextXAlignment = Enum.TextXAlignment.Center,
            })
        end
        local bubble = node("TextButton", {
            Text = "", AutoButtonColor = false,
            Size = UDim2.new(1, -44, 0, rowHeight - 2),
            Position = own and UDim2.fromOffset(0, 0) or UDim2.fromOffset(38, 0),
            BackgroundColor3 = own and Color3.fromRGB(59, 31, 42) or BUBBLE,
            BackgroundTransparency = 0.08, BorderSizePixel = 0,
        }, row)
        rounded(bubble, 12)
        text(bubble, tostring(item.display or "Player") .. (item.demo and "  · DEMO" or ""), 12,
            item.demo and Color3.fromRGB(224, 169, 186) or Color3.fromRGB(236, 211, 217),
            Enum.Font.GothamBold, {
                Position = UDim2.fromOffset(11, 5),
                Size = UDim2.new(1, -24, 0, 16),
            })
        text(bubble, safeText, 12, TEXT, Enum.Font.Gotham, {
            Position = UDim2.fromOffset(11, 23),
            Size = UDim2.new(1, -23, 0, textHeight + 4),
            TextWrapped = true,
            TextYAlignment = Enum.TextYAlignment.Top,
            TextTruncate = Enum.TextTruncate.None,
        })
        if not item.demo and not own and item.name then
            bubble.MouseButton1Click:Connect(function()
                input.Text = "@" .. item.name .. " "
                input:CaptureFocus()
                input.CursorPosition = #input.Text + 1
            end)
        end
    end

    local function render()
        if not alive then return end
        for _, child in ipairs(feed:GetChildren()) do
            if child.Name == "ChatRow" then child:Destroy() end
        end
        local shown = 0
        local current = #messages > 0 and messages or demo
        for _, item in ipairs(current) do
            if item.lang == currentLanguage then
                shown = shown + 1
                showRow(item, shown)
            end
        end
        if shown == 0 then
            showRow({
                display = "Vanta Chat",
                content = "No " .. currentLanguage .. " messages yet. The feed will update as people chat.",
                demo = true,
            }, 1)
        end
        scrollToBottom()
    end

    for language, button in pairs(languages) do
        markConnection(button.MouseButton1Click:Connect(function()
            currentLanguage = language
            showLanguage()
            render()
        end))
    end

    local sending = false
    local function sendMessage()
        if sending or not alive then return end
        local value = input.Text:match("^%s*(.-)%s*$")
        if value == "" then return end
        local destination = channel()
        if not destination then
            updateAvailability()
            return
        end
        sending = true
        sendButton.Text = "…"
        task.spawn(function()
            local ok, err = pcall(function()
                destination:SendAsync(value:sub(1, 200))
            end)
            if alive and input.Parent then
                if ok then
                    input.Text = ""
                else
                    warn("[Vanta Chat] Send failed: " .. tostring(err))
                    input.PlaceholderText = "Couldn't send. Try again."
                end
                sendButton.Text = "➤"
                sending = false
            end
        end)
    end
    markConnection(sendButton.MouseButton1Click:Connect(sendMessage))
    markConnection(input.FocusLost:Connect(function(pressedEnter)
        if pressedEnter then sendMessage() end
    end))

    markConnection(TextChatService.MessageReceived:Connect(function(message)
        if not alive or not message or not message.TextSource then return end
        if message.TextChannel and message.TextChannel.Name ~= "RBXGeneral" then return end
        local content = tostring(message.Text or "")
        if content == "" then return end
        local id = message.MessageId
        if id and id ~= "" then
            if seen[id] then return end
            seen[id] = true
        end
        local userId = message.TextSource.UserId
        local player = Players:GetPlayerByUserId(userId)
        messages[#messages + 1] = {
            userId = userId,
            display = player and player.DisplayName or ("User " .. userId),
            name = player and player.Name or tostring(userId),
            content = content, lang = detectLanguage(content),
        }
        if #messages > 80 then table.remove(messages, 1) end
        render()
    end))
    markConnection(Players.PlayerAdded:Connect(refreshPresence))
    markConnection(Players.PlayerRemoving:Connect(function()
        task.defer(refreshPresence)
    end))
    local folders = TextChatService:FindFirstChild("TextChannels")
    if folders then markConnection(folders.ChildAdded:Connect(updateAvailability)) end
    markConnection(feed:GetPropertyChangedSignal("AbsoluteSize"):Connect(render))
    markConnection(root.Destroying:Connect(function()
        alive = false
        for _, connection in ipairs(messageConnections) do
            connection:Disconnect()
        end
        table.clear(messageConnections)
    end))
    refreshPresence()
    showLanguage()
    render()
    return root
end

return Chat
