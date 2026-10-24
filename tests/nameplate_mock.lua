-- Vanta Edge nameplate module tests with Roblox instance & event stand-ins (Lua 5.1).
local function signal()
  local s={listeners={}}
  function s:Connect(fn)
    local conn={active=true,fn=fn}
    function conn:Disconnect() self.active=false end
    s.listeners[#s.listeners+1]=conn
    return conn
  end
  function s:Fire(...)
    for _,conn in ipairs(self.listeners) do if conn.active then conn.fn(...) end end
  end
  return s
end
local all,methods={},{}
local mt={__index=function(self,key)
  if methods[key] then return methods[key] end
  for _,v in ipairs(all) do
    if not rawget(v,"destroyed") and rawget(v,"Parent")==self and rawget(v,"Name")==key then return v end
  end
end}
local function new(class,name,parent)
  local obj=setmetatable({ClassName=class,Name=name or class,Parent=parent,
    Destroying=signal(),destroyed=false},mt)
  all[#all+1]=obj
  return obj
end
function methods:FindFirstChild(name)
  for _,v in ipairs(all) do if not rawget(v,"destroyed") and rawget(v,"Parent")==self and rawget(v,"Name")==name then return v end end
end
function methods:FindFirstChildOfClass(class)
  for _,v in ipairs(all) do if not rawget(v,"destroyed") and rawget(v,"Parent")==self and rawget(v,"ClassName")==class then return v end end
end
function methods:WaitForChild(name) return assert(self:FindFirstChild(name),"Missing mock child "..name) end
function methods:IsDescendantOf(parent)
  local p=rawget(self,"Parent")
  while p do if p==parent then return true end p=rawget(p,"Parent") end
  return false
end
function methods:Destroy()
  if self.destroyed then return end
  self.destroyed=true
  self.Destroying:Fire()
  for _,obj in ipairs(all) do
    if not rawget(obj,"destroyed") and rawget(obj,"Parent")==self then obj:Destroy() end
  end
  self.Parent=nil
end
Instance={new=function(class)return new(class) end}
local function val(...) return {...} end
UDim2={new=val,fromOffset=val,fromScale=val}
UDim={new=val}
Vector2={new=val}
Vector3={new=val}
Color3={fromRGB=val}
ColorSequence={new=val}
ColorSequenceKeypoint={new=val}
TweenInfo={new=val}
Enum={
  Font={Gotham="Gotham",GothamBold="GothamBold"},
  EasingStyle={Linear="Linear"},EasingDirection={Out="Out"},
  TextXAlignment={Left="Left",Center="Center"},
  TextYAlignment={Center="Center"},
  TextTruncate={AtEnd="AtEnd"},
  HumanoidDisplayDistanceType={None="None",Viewer="Viewer"},
  ThumbnailType={HeadShot="HeadShot"},ThumbnailSize={Size100x100="Size100x100"},
}
math.clamp=function(x,a,b) return math.max(a,math.min(x,b)) end
utf8={offset=function(s,n)
  if #s<n then return nil end
  return n
end,len=function(s) return #s end}
task={spawn=function(fn)fn()end}
local rt=signal()
local tweenCancel=0
local thumbCalls=0
local tweenService={Create=function(_,item,info,goal)
  local tween={played=false}
  function tween:Play()self.played=true end
  function tween:Cancel() tweenCancel=tweenCancel+1 end
  return tween
end}
local playerList={}
local playerAdded,playerRemoving=signal(),signal()
local players={
  PlayerAdded=playerAdded,PlayerRemoving=playerRemoving,
  GetPlayers=function()return playerList end,
  GetUserThumbnailAsync=function(_,id,kind,size)
    assert(kind==Enum.ThumbnailType.HeadShot and size==Enum.ThumbnailSize.Size100x100)
    thumbCalls=thumbCalls+1
    return "rbxthumb://id="..id,true
  end,
}
local function mockPlayer(name,display,id)
  local p=new("Player",name)
  p.DisplayName=display
  p.UserId=id
  p.CharacterAdded=signal()
  p.CharacterRemoving=signal()
  return p
end
local localPlayer=mockPlayer("SaltyExample","SaltyExample",123)
players.LocalPlayer=localPlayer
local guiRoot=new("PlayerGui","PlayerGui",localPlayer)
local scriptsRoot=new("PlayerScripts","PlayerScripts",localPlayer)
local friend=mockPlayer("Friend123","Friendly",456)
playerList[1]=localPlayer
playerList[2]=friend
local function character(parent,name)
  local char=new("Model",name or "Character")
  local head=new("Part","Head",char)
  head.Position={X=0}
  local hum=new("Humanoid","Humanoid",char)
  hum.Health=100
  hum.MaxHealth=100
  hum.HealthChanged=signal()
  hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.Viewer
  parent.Character=char
  return char,head,hum
end
local oldChar,oldHead,oldHum=character(localPlayer)
local friendChar,friendHead,friendHum=character(friend)
game={GetService=function(_,name)
  if name=="Players" then return players end
  if name=="RunService" then return {RenderStepped=rt} end
  if name=="TweenService" then return tweenService end
  error("Unexpected service "..name)
end}
local vectorMeta={__sub=function(a,b)return {Magnitude=math.abs(a.X-b.X)}end}
workspace={CurrentCamera={CFrame={Position=setmetatable({X=0},vectorMeta)}}}
local mod=dofile("nameplate.lua")
local instance=mod.new()
local me=assert(instance:GetBillboard(localPlayer))
assert(instance:GetBillboard(friend)==nil, "Friend must have no client-side nameplate")
assert(me.Adornee==oldHead and me.Parent==guiRoot)
assert(me.PlateGroup.Plate.Size[1]==230 and me.PlateGroup.Plate.Size[2]==72)
assert(me.StudsOffsetWorldSpace[2]==2.5 and me.MaxDistance==60)
assert(me.PlateGroup.Plate.BackgroundTransparency==0.15)
assert(me.PlateGroup.Plate.TagChip.TagText.Text=="VANTA")
assert(me.PlateGroup.Plate.StatusLine.Text=="MEMBER")
assert(me.PlateGroup.Plate.AvatarRing.Avatar.Image=="rbxthumb://id=123")
assert(thumbCalls==1, "No thumbnail request for anyone other than LocalPlayer")
assert(oldHum.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.None)
assert(friendHum.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.Viewer)
assert(me.PlateGroup.Plate.AvatarRing.UIStroke.Thickness==2)
-- Precise Vanta Edge polish geometry.
local plate=me.PlateGroup.Plate
local bar=plate.HealthBar
assert(bar.Position[1]==10 and bar.Position[2]==66)
assert(bar.Size[2]==-20 and bar.Size[4]==3)
assert(bar.BackgroundColor3[1]==42 and bar.BackgroundColor3[2]==10 and bar.BackgroundColor3[3]==18)
assert(bar.UICorner.CornerRadius[2]==2 and bar.HealthFill.UICorner.CornerRadius[2]==2)
assert(plate.TagChip.Position[1]==6 and plate.TagChip.Position[2]==6)
assert(plate.TagChip.UICorner.CornerRadius[2]==3)
assert(plate.AvatarRing.StatusDot.Position[2]==0 and plate.AvatarRing.StatusDot.Position[4]==-10)
assert(plate.StatusLine.Position[2] + plate.StatusLine.Size[4] + 4 == bar.Position[2])
assert(plate.AvatarRing.Position[2]+40 < bar.Position[2])
assert(plate.DisplayName.TextTruncate==Enum.TextTruncate.AtEnd)
assert(plate.DisplayName.Size[2]==-(60+10))

-- Damage changes actual health, briefly reddens status dot.
oldHum.Health=35
oldHum.HealthChanged:Fire(35)
assert(me.PlateGroup.Plate.HealthBar.HealthFill.Size[1]==0.35)
rt:Fire(1/15)
assert(me.PlateGroup.Plate.AvatarRing.StatusDot.BackgroundColor3[1]==255)
for i=1,85 do rt:Fire(1/15) end
assert(me.PlateGroup.Plate.AvatarRing.StatusDot.BackgroundColor3[1]==72)

workspace.CurrentCamera.CFrame.Position.X=50
rt:Fire(1/15)
local transparency=me.PlateGroup.GroupTransparency
assert(transparency>0.4 and transparency<0.6)
workspace.CurrentCamera.CFrame.Position.X=60
rt:Fire(1/15)
assert(me.PlateGroup.GroupTransparency==1)
workspace.CurrentCamera.CFrame.Position.X=0
rt:Fire(1/15)

instance:SetTag("VIP")
instance:SetSubtitle("MEMBER // LVL 42")
instance:SetShowUsername(true)
assert(me.PlateGroup.Plate.TagChip.TagText.Text=="VIP")
assert(me.PlateGroup.Plate.StatusLine.Text=="MEMBER // LVL 42")
assert(instance:GetBillboard(friend)==nil)
instance:SetScale(120)
assert(me.Size[1]==295)
instance:SetHeight(3)
assert(me.StudsOffsetWorldSpace[2]==3)
instance:SetDistance(80)
assert(me.MaxDistance==80)
instance:SetEnabled(false)
assert(not me.Enabled)
assert(oldHum.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.Viewer)
assert(friendHum.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.Viewer)
instance:SetEnabled(true)
assert(instance:IsEnabled() and me.Enabled)

-- Simulate Roblox PlayerGui reset, including destroying all visible GUIs.
-- PlayerScripts lifecycle MUST survive so CharacterAdded still reattaches nameplate.
assert(scriptsRoot:FindFirstChild("VantaTestNameplateLifecycle"))
me:Destroy()
localPlayer.CharacterRemoving:Fire(oldChar)
local newChar,newHead,newHum=character(localPlayer,"NewCharacter")
localPlayer.CharacterAdded:Fire(newChar)
local second=assert(instance:GetBillboard(localPlayer))
assert(second~=me and second.Adornee==newHead)
assert(second.Parent==guiRoot)
assert(second.PlateGroup.Plate.TagChip.TagText.Text=="VIP")
assert(newHum.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.None)
-- Other player respawn must NOT mount anything, or disturb our nameplate.
friend.CharacterRemoving:Fire(friendChar)
local newFriend,newFriendHead,newFriendHum=character(friend,"FriendRespawn")
friend.CharacterAdded:Fire(newFriend)
assert(instance:GetBillboard(friend)==nil)
assert(newFriendHum.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.Viewer)
assert(instance:GetBillboard(localPlayer)==second)

-- Join and leave while the module is already running.
local guest=mockPlayer("Guest987","New Guest",789)
local gChar,gHead=character(guest)
playerList[3]=guest
playerAdded:Fire(guest)
assert(instance:GetBillboard(guest)==nil)
playerRemoving:Fire(guest)
assert(instance:GetBillboard(guest)==nil)

-- Re-executing destroys previous controller without stacking or leaking listeners.
local newer=mod.new({Enabled=false})
assert(instance:GetBillboard(localPlayer)==nil)
assert(not newer:IsEnabled())
assert(newer:GetBillboard(localPlayer).Enabled==false)
assert(newer:GetBillboard(friend)==nil)
newer:Destroy()
assert(newer:GetBillboard(localPlayer)==nil)
assert(newHum.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.Viewer)
assert(newFriendHum.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.Viewer)
assert(tweenCancel>=2)
-- Standalone LocalScript must also execute without remote code or asset loaders.
local standalone = dofile("nameplate_standalone.lua")
assert(standalone:GetBillboard(localPlayer) ~= nil)
assert(standalone:GetBillboard(friend) == nil)
standalone:Destroy()
print("Vanta Edge: self-only spawn, PlayerGui reset respawn, 3px rounded health bar, tag, status dot, and cleanup passed.")
