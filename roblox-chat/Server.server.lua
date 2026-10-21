-- Trusted owned-experience server. Message text travels only through TextChatService.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TextChatService=game:GetService("TextChatService")
local PLATFORM_INTEGRATED_CHAT=false -- Match the setting in Studio.
ReplicatedStorage:SetAttribute("VantaPlatformIntegratedChat",PLATFORM_INTEGRATED_CHAT)
local channels=TextChatService:WaitForChild("TextChannels")
local members,busy,lastRequest,records,recordOrder,generation={},{},{},{},{},{}
setmetatable(generation,{__mode="k"})
local revision=0
local sendTimes={}
local leases,leaseSerial={},0
local function lease(player)
    leaseSerial=leaseSerial+1;leases[player.UserId]=leaseSerial;return leaseSerial
end
local function remote(class,name)
    assert(not ReplicatedStorage:FindFirstChild(name),"Install only one Vanta server")
    local object=Instance.new(class);object.Name=name;return object
end
local membership=remote("RemoteFunction","VantaChatMembership")
local dm=remote("RemoteFunction","VantaChatOpen")
local reaction=remote("RemoteFunction","VantaChatReact")
local updates=remote("RemoteEvent","VantaChatReactions")
local function admitted(channel,id)
    for _,source in ipairs(channel:GetChildren())do
        if source:IsA("TextSource") and source.UserId==id then return source end
    end
end
local function canChat(id)
    local ok,allowed=pcall(function()return TextChatService:CanUserChatAsync(id)end)
    return ok and allowed==true
end
local function pairAllowed(first,second,channel)
    if first==second then return true end
    local ok,result=pcall(function()
        if not TextChatService:CanUsersChatAsync(first,second) then return false end
        local requester=channel.DirectChatRequester
        if requester then
            for _,id in ipairs({first,second})do
                if id~=requester.UserId and not table.find(TextChatService:CanUsersDirectChatAsync(requester.UserId,{id}),id) then return false end
            end
        end
        return true
    end)
    return ok and result==true
end
local function throttled(player,key,seconds)
    local bucket=lastRequest[player] or {};lastRequest[player]=bucket
    if bucket[key] and os.clock()-bucket[key]<seconds then return true end
    bucket[key]=os.clock();return false
end
local function room(name)
    assert(not channels:FindFirstChild(name),"Duplicate Vanta channel")
    local channel=Instance.new("TextChannel");channel.Name=name
    channel.ShouldDeliverCallback=function(message,recipient)
        local sender=message.TextSource
        if not sender or not members[sender.UserId] or not members[recipient.UserId] then return false end
        local id=message.MessageId
        if type(id)~="string" or id=="" then return false end
        if type(id)=="string" and id~="" then
            local record=records[id]
            if not record then
                local now=os.clock()
                local times=sendTimes[sender.UserId] or {};sendTimes[sender.UserId]=times
                while times[1] and now-times[1]>=60 do table.remove(times,1) end
                local burst=0
                for _,when in ipairs(times)do if now-when<8 then burst=burst+1 end end
                local allowed=#times<10 and burst<4
                if allowed then times[#times+1]=now end
                record={channel=channel,sender=sender.UserId,viewers={},votes={},version=0,allowed=allowed}
                records[id]=record;recordOrder[#recordOrder+1]=id
                if #recordOrder>300 then records[table.remove(recordOrder,1)]=nil end
            end
            if not record.allowed or record.channel~=channel or record.sender~=sender.UserId then return false end
            record.viewers[recipient.UserId]=true
            record.viewers[sender.UserId]=true
        end
        -- Roblox additionally applies filtering and its own privacy/delivery checks.
        return true
    end
    channel.Parent=channels;return channel
end
local rooms={room("VantaEN"),room("VantaAR")}
local function leave(player)
    generation[player]=(generation[player] or 0)+1
    members[player.UserId]=nil
    leases[player.UserId]=nil
    player:SetAttribute("VantaChatJoined",false)
    for _,channel in ipairs(channels:GetChildren())do
        if channel.Name:match("^Vanta") then
            local first,second=channel.Name:match("^VantaDM_(%d+)_(%d+)$")
            if tonumber(first)==player.UserId or tonumber(second)==player.UserId then
                channel:Destroy()
            else
                local source=admitted(channel,player.UserId);if source then source:Destroy() end
            end
        end
    end
end
membership.OnServerInvoke=function(player,action,session)
    if action=="leave" then
        if session~=leases[player.UserId] or session==nil then return false end
        leave(player);return true
    end
    if action~="join" then return false,"Invalid Vanta membership request." end
    local config=TextChatService:FindFirstChild("ChatWindowConfiguration")
    local configured,displayMode=pcall(function()return config.TextChannelDisplayMode end)
    local input=TextChatService:FindFirstChild("ChatInputBarConfiguration")
    local dedicatedDisplay=configured and displayMode==Enum.TextChannelDisplayMode.DefaultTextChannels
    local frontendHidden=config and input and config.Enabled==false and input.Enabled==false
    if not dedicatedDisplay and not frontendHidden then
        return false,"Configure Vanta-only chat display in Studio; see the setup guide."
    end
    if members[player.UserId] then
        if not canChat(player.UserId) then leave(player);return false,"Roblox chat permission required." end
        return true,nil,lease(player)
    end
    if busy[player] or throttled(player,"join",2) then return false,"Please wait before joining again." end
    busy[player]=true
    local epoch=generation[player] or 0
    local ok,result=pcall(function()
        if not canChat(player.UserId) then return false end
        for _,channel in ipairs(rooms)do
            channel:AddUserAsync(player.UserId)
            if not admitted(channel,player.UserId) then return false end
        end
        return player.Parent~=nil and (generation[player] or 0)==epoch
    end)
    busy[player]=nil
    if not ok or not result then leave(player);return false,"Roblox did not admit this account to Vanta chat." end
    members[player.UserId]=player
    player:SetAttribute("VantaChatJoined",true)
    return true,nil,lease(player)
end
dm.OnServerInvoke=function(player,targetId)
    if throttled(player,"dm",2) then return nil,"Please wait before opening another conversation." end
    if type(targetId)~="number" or targetId%1~=0 or targetId==player.UserId then return nil,"Select a Vanta friend." end
    local target=Players:GetPlayerByUserId(targetId)
    if not target or not members[player.UserId] or not members[targetId] then return nil,"Both friends must join Vanta here." end
    local name="VantaDM_"..math.min(player.UserId,targetId).."_"..math.max(player.UserId,targetId)
    if busy[name] then return nil,"Conversation is opening." end
    busy[name]=true
    local ok,result=pcall(function()
        if not canChat(player.UserId) or not canChat(targetId) or not player:IsFriendsWith(targetId) then return nil end
        if not table.find(TextChatService:CanUsersDirectChatAsync(player.UserId,{targetId}),targetId) then return nil end
        if not pairAllowed(player.UserId,targetId,rooms[1]) then return nil end
        if not player.Parent or not target.Parent or not members[player.UserId] or not members[targetId] then return nil end
        local existing=channels:FindFirstChild(name);if existing then return existing end
        local channel=room(name)
        local success=pcall(function()
            channel:SetDirectChatRequester(player);channel:AddUserAsync(targetId)
            assert(admitted(channel,player.UserId) and admitted(channel,targetId))
            assert(members[player.UserId] and members[targetId] and player.Parent and target.Parent)
        end)
        if not success then channel:Destroy();return nil end
        return channel
    end)
    busy[name]=nil
    return ok and result and result.Name or nil,"Roblox did not allow this Vanta direct chat."
end
local allowedEmoji={["👍"]=true,["❤️"]=true,["😂"]=true,["🔥"]=true,["🌹"]=true}
reaction.OnServerInvoke=function(player,channelName,id,emoji)
    if throttled(player,"react",0.5) or not members[player.UserId] then return false end
    if type(id)~="string" or #id>128 or not allowedEmoji[emoji] then return false end
    local record=records[id]
    if not record or record.channel.Name~=channelName or not record.channel.Parent or not record.viewers[player.UserId] then return false end
    local channel=record.channel
    if not admitted(channel,player.UserId) or not canChat(player.UserId) or not pairAllowed(record.sender,player.UserId,channel) then return false end
    if not members[player.UserId] then return false end
    if record.votes[player.UserId]==emoji then record.votes[player.UserId]=nil else record.votes[player.UserId]=emoji end
    local counts={}
    for _,vote in pairs(record.votes)do counts[vote]=(counts[vote] or 0)+1 end
    revision=revision+1;record.version=revision
    for recipientId,recipient in pairs(members)do
        if record.viewers[recipientId] and admitted(channel,recipientId) and canChat(recipientId)
            and pairAllowed(record.sender,recipientId,channel) and pairAllowed(player.UserId,recipientId,channel)
            and members[recipientId] and members[player.UserId] then
            updates:FireClient(recipient,{channel=channel.Name,messageId=id,counts=counts,version=revision})
            -- Send only fixed reaction enums/counts and the original message handle.
        end
    end
    return true
end
-- Assign parents only after handlers are ready.
membership.Parent=ReplicatedStorage;dm.Parent=ReplicatedStorage
reaction.Parent=ReplicatedStorage;updates.Parent=ReplicatedStorage
Players.PlayerRemoving:Connect(function(player)leave(player);lastRequest[player]=nil;busy[player]=nil;sendTimes[player.UserId]=nil end)


