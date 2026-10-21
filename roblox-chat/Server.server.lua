-- Install in ServerScriptService of an experience you control. No chat text remotes.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")
-- Match your Studio TextChatService.PlatformIntegratedChat setting explicitly.
-- true requires Enabled in Studio and uses Roblox's native TextChannelWindow.
local PLATFORM_INTEGRATED_CHAT = false
ReplicatedStorage:SetAttribute("VantaPlatformIntegratedChat", PLATFORM_INTEGRATED_CHAT)
local channels = TextChatService:WaitForChild("TextChannels")
local api = Instance.new("RemoteFunction")
api.Name = "VantaChatOpen"
local lastRequest, busy = {}, {}

local function room(name)
    local channel = Instance.new("TextChannel")
    channel.Name = name
    channel.Parent = channels
    return channel
end
local public = {room("VantaEN"), room("VantaAR")}
local function join(player)
    for _, channel in ipairs(public) do
        local ok, err = pcall(function() channel:AddUserAsync(player.UserId) end)
        if not ok then warn("Vanta channel admission failed: " .. tostring(err)) end
    end
end
Players.PlayerAdded:Connect(join)
for _, player in ipairs(Players:GetPlayers()) do task.spawn(join, player) end

api.OnServerInvoke = function(player, targetId)
    if lastRequest[player] and os.clock() - lastRequest[player] < 2 then
        return nil, "Please wait before opening another conversation."
    end
    lastRequest[player] = os.clock()
    if type(targetId) ~= "number" or targetId % 1 ~= 0 or targetId == player.UserId then
        return nil, "Select a friend in this server."
    end
    local target = Players:GetPlayerByUserId(targetId)
    if not target then return nil, "Friend must be in this server." end
    local first, second = math.min(player.UserId, targetId), math.max(player.UserId, targetId)
    local name = "VantaDM_" .. first .. "_" .. second
    if busy[name] then return nil, "Conversation is opening. Try again." end
    busy[name] = true
    local ok, result = pcall(function()
        if not player:IsFriendsWith(targetId) then return nil end
        local allowed = TextChatService:CanUsersDirectChatAsync(player.UserId, {targetId})
        if not table.find(allowed, targetId) then return nil end
        if not player.Parent or not target.Parent then return nil end
        local existing = channels:FindFirstChild(name)
        if existing then return existing end
        local channel = room(name)
        local admitted = pcall(function()
            channel:SetDirectChatRequester(player)
            channel:AddUserAsync(targetId)
            -- Admission is checked as well as permissions; never expose a half-open DM.
            local members = {}
            for _, source in ipairs(channel:GetChildren()) do
                if source:IsA("TextSource") then members[source.UserId] = true end
            end
            assert(members[player.UserId] and members[targetId])
        end)
        if not admitted then channel:Destroy(); return nil end
        channel:SetAttribute("VantaReady", true)
        return channel
    end)
    busy[name] = nil
    if ok and result then return result.Name end
    return nil, "Roblox did not allow this direct chat. Check communication permissions and Studio setup."
end
api.Parent = ReplicatedStorage
Players.PlayerRemoving:Connect(function(player)
    lastRequest[player] = nil
    for _, channel in ipairs(channels:GetChildren()) do
        local first, second=channel.Name:match("^VantaDM_(%d+)_(%d+)$")
        if tonumber(first)==player.UserId or tonumber(second)==player.UserId then channel:Destroy() end
    end
end)

