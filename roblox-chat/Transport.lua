-- Dedicated Vanta channels only. No HTTP transport and no public-chat fallback.
local Players=game:GetService("Players")
local ReplicatedStorage=game:GetService("ReplicatedStorage")
local TextChatService=game:GetService("TextChatService")
local Transport={}
function Transport.new()
    local self={joined=false}
    function self:Join()
        self.closed=false
        local remote=ReplicatedStorage:FindFirstChild("VantaChatMembership")
        if not remote then return false,"Vanta network is not installed in this experience." end
        local ok,result,reason,session=pcall(function()return remote:InvokeServer("join")end)
        self.joined=ok and result==true
        self.session=self.joined and session or nil
        if self.closed then self:Destroy();return false,"Join cancelled." end
        return self.joined,reason or (not ok and "Vanta admission failed." or nil)
    end
    function self:GetRoom(language)
        local folder=TextChatService:FindFirstChild("TextChannels")
        return self.joined and folder and folder:FindFirstChild("Vanta"..language) or nil
    end
    function self:CanSend(channel)
        if not self.joined or not channel or not channel.Name:match("^Vanta") then return false end
        local ok,allowed=pcall(function()return TextChatService:CanUserChatAsync(Players.LocalPlayer.UserId)end)
        if not ok or not allowed then return false end
        for _,source in ipairs(channel:GetChildren())do
            if source:IsA("TextSource") and source.UserId==Players.LocalPlayer.UserId then return source.CanSend end
        end
        return false
    end
    function self:Send(channel,content,metadata)
        assert(self:CanSend(channel),"Vanta chat permission unavailable")
        return channel:SendAsync(content,metadata)
    end
    function self:React(channel,id,emoji)
        if not self:CanSend(channel) then return false end
        local remote=ReplicatedStorage:FindFirstChild("VantaChatReact")
        if not remote then return false end
        local ok,result=pcall(function()return remote:InvokeServer(channel.Name,id,emoji)end)
        return ok and result==true
    end
    function self:Destroy()
        self.closed=true
        self.joined=false
        local session=self.session;self.session=nil
        local remote=ReplicatedStorage:FindFirstChild("VantaChatMembership")
        if remote and session then task.spawn(function()pcall(function()remote:InvokeServer("leave",session)end)end) end
    end
    return self
end
return Transport

