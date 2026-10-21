-- Engine double for logic tests only: NOT a rendering/filtering/network simulator.
function signal()
    local s={listeners={}}
    function s:Connect(fn)
        local connection={Connected=true}
        function connection:Disconnect() self.Connected=false end
        table.insert(self.listeners,{connection,fn})
        return connection
    end
    function s:Fire(...)
        for _,entry in ipairs(self.listeners) do if entry[1].Connected then entry[2](...) end end
    end
    return s
end
local function enum()
    return setmetatable({}, {__index=function(t,k) local v=enum();rawset(t,k,v);return v end})
end
Enum=enum()
Color3={fromRGB=function(...)return {...}end}
ColorSequence={new=function(...)return {...}end}
Vector2={new=function(x,y)return {X=x,Y=y}end}
UDim={new=function(s,o)return {Scale=s,Offset=o}end}
UDim2={new=function(...)return {...}end,fromOffset=function(...)return {...}end,fromScale=function(...)return {...}end}
math.clamp=function(v,a,b)return math.max(a,math.min(b,v))end
table.clear=function(t)for k in pairs(t)do t[k]=nil end end
table.find=function(t,v)for k,value in ipairs(t)do if value==v then return k end end end
task={spawn=function(fn,...)fn(...)end,defer=function()end,delay=function()end}
warn=function()end
local methods={}
local guiClasses={Frame=true,ScrollingFrame=true,TextBox=true,TextButton=true,ImageLabel=true,TextLabel=true,TextChannelWindow=true}
function methods:IsA(class)return self.ClassName==class or (class=="GuiObject" and guiClasses[self.ClassName]) end
function methods:GetChildren()local r={} for _,v in ipairs(objects)do if v.Parent==self then table.insert(r,v) end end return r end
function methods:FindFirstChild(name,recursive)
    for _,v in ipairs(self:GetChildren())do
        if v.Name==name then return v end
        if recursive then local found=v:FindFirstChild(name,true);if found then return found end end
    end
end
function methods:WaitForChild(name)return self:FindFirstChild(name)end
function methods:FindFirstChildOfClass(class)for _,v in ipairs(self:GetChildren())do if v:IsA(class)then return v end end end
function methods:GetPropertyChangedSignal(name)self.signals[name]=self.signals[name]or signal();return self.signals[name]end
function methods:Destroy()self.Destroying:Fire();for _,v in ipairs(self:GetChildren())do v:Destroy()end;self.Parent=nil end
function methods:SetAttribute(k,v)self.attributes[k]=v end
function methods:GetAttribute(k)return self.attributes[k]end
function methods:CaptureFocus()end
function methods:InvokeServer(...)return self.OnServerInvoke(me,...)end
function methods:AddUserAsync(id)
    if admissionDenied then return nil end
    local source=Instance.new("TextSource");source.Name=id==11 and "Alice" or "Bob";source.UserId=id;source.CanSend=true;source.Parent=self
    return source
end
function methods:SetDirectChatRequester(player)self:AddUserAsync(player.UserId)end
function methods:SendAsync(content,metadata)
    self.sent=content;self.sentMetadata=metadata
    if sendError then error("engine send error")end
    return {Status=sendStatus or Enum.TextChatMessageStatus.Success}
end
objects={}
Instance={new=function(class)
    local o=setmetatable({ClassName=class,Name=class,signals={},attributes={},ZIndex=1,
        AbsoluteSize={X=450,Y=405},AbsolutePosition={X=0,Y=0},AbsoluteContentSize={X=0,Y=0},
        CanvasPosition={X=0,Y=0},IsLoaded=not unloadedIcons,Destroying=signal(),
        MouseButton1Click=signal(),Activated=signal(),FocusLost=signal(),
        ChildAdded=signal(),ChildRemoved=signal(),DescendantAdded=signal(),DescendantRemoving=signal()}, {__index=methods})
    table.insert(objects,o);return o
end}
me=Instance.new("Player");me.UserId=11;me.Name="Alice";me.DisplayName="Alice";me.Parent=true
friend=Instance.new("Player");friend.UserId=22;friend.Name="Bob";friend.DisplayName="Bob";friend.Parent=true
function me:IsFriendsWith(id)return friendsAllowed~=false and id==22 end
function friend:IsFriendsWith(id)return friendsAllowed~=false and id==11 end
players={LocalPlayer=me,PlayerAdded=signal(),PlayerRemoving=signal()}
function players:GetPlayers()return {me,friend}end
function players:GetPlayerByUserId(id)if id==11 then return me elseif id==22 and friend.Parent then return friend end end
storage=Instance.new("ReplicatedStorage")
tcs=Instance.new("TextChatService");tcs.MessageReceived=signal()
channels=Instance.new("Folder");channels.Name="TextChannels";channels.Parent=tcs
function tcs:CanUsersDirectChatAsync(_,ids)if permissionDenied then return {}end;return ids end
local services={Players=players,TextChatService=tcs,ReplicatedStorage=storage,
    ContentProvider={PreloadAsync=function()end},TextService={GetTextSize=function(_,value,size,_,width)
        return {X=math.min(#value*6,width.X),Y=math.max(16,math.ceil(#value*6/width.X)*16)}end}}
game={GetService=function(_,name)return assert(services[name],name)end}
holder=Instance.new("Frame")
function find(name)return holder:FindFirstChild(name,true)end
function allText()
    local result={}
    for _,obj in ipairs(objects)do if obj.Parent and obj.Text then table.insert(result,obj.Text)end end
    return table.concat(result,"\n")
end
now=10
os.clock=function()return now end

