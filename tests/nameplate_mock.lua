-- Lightweight Roblox instance/event stand-ins for exercising the Nameplate lifecycle in Lua 5.1.
-- No network calls or actual Roblox instance creation.
local function signal()
    local s={listeners={}}
    function s:Connect(fn)
        local conn={active=true, callback=fn}
        function conn:Disconnect() self.active=false end
        self.listeners[#self.listeners+1]=conn
        return conn
    end
    function s:Fire(...)
        for _,c in ipairs(self.listeners) do if c.active then c.callback(...) end end
    end
    return s
end
local all={}
local methods={}
local mt={
    __index=function(self,key)
        if methods[key] then return methods[key] end
        for _,v in ipairs(all) do
            if not rawget(v, 'destroyed') and rawget(v, 'Parent')==self and rawget(v, 'Name')==key then return v end
        end
        return nil
    end
}
local function newObject(class,name,parent)
    local obj=setmetatable({
        ClassName=class,Name=name or class,Destroying=signal(),
        destroyed=false,Parent=parent
    },mt)
    all[#all+1]=obj
    return obj
end
function methods:FindFirstChild(name)
    for _,v in ipairs(all) do
        if not rawget(v, 'destroyed') and rawget(v, 'Parent')==self and rawget(v, 'Name')==name then return v end
    end
    return nil
end
function methods:WaitForChild(name)
    return assert(self:FindFirstChild(name),"Missing mock child "..name)
end
function methods:FindFirstChildOfClass(class)
    for _,v in ipairs(all) do
        if not rawget(v, 'destroyed') and rawget(v, 'Parent')==self and rawget(v, 'ClassName')==class then return v end
    end
end
function methods:IsDescendantOf(parent)
    local p=rawget(self,'Parent')
    while p do
        if p==parent then return true end
        p=rawget(p,'Parent')
    end
    return false
end
function methods:Destroy()
    if self.destroyed then return end
    self.destroyed=true
    self.Destroying:Fire()
    for _,v in ipairs(all) do
        if not rawget(v,'destroyed') and rawget(v,'Parent')==self then v:Destroy() end
    end
    self.Parent=nil
end
Instance={new=function(class) return newObject(class) end}
local function value(...) return {...} end
Color3={fromRGB=value}
Rect={new=value}
Vector3={new=value}
Vector2={new=value}
UDim={new=value}
UDim2={new=value,fromOffset=value,fromScale=value}
ColorSequence={new=value}
ColorSequenceKeypoint={new=value}
Enum={
    Font={Gotham="Gotham",GothamBold="GothamBold"},
    TextXAlignment={Left="Left",Center="Center"},
    TextYAlignment={Center="Center"},
    ScaleType={Slice="Slice",Stretch="Stretch"},
    ApplyStrokeMode={Contextual="Contextual"},
    TextTruncate={AtEnd="AtEnd"},
    HumanoidDisplayDistanceType={None="None",Viewer="Viewer"},
}
utf8={offset=function(s,n)
    if #s<n then return nil end
    return n
end}
math.clamp=function(v, minimum, maximum)
    return math.max(minimum, math.min(maximum, v))
end
task={spawn=function(fn) fn() end}
local renderStep=signal()
local localPlayer=newObject("Player","MockPlayer")
localPlayer.Name="SaltyExample"
localPlayer.DisplayName="Velora"
localPlayer.UserId=123456
localPlayer.CharacterAdded=signal()
localPlayer.CharacterRemoving=signal()
local playerGui=newObject("PlayerGui","PlayerGui",localPlayer)
local char=newObject("Model","Character")
local head=newObject("Part","Head",char)
local coordinateMeta = {
    __sub = function(a,b)
        return {Magnitude=math.abs((a.X or 0)-(b.X or 0))}
    end
}
head.Position={X=0}
workspace={CurrentCamera={CFrame={Position=setmetatable({X=0},coordinateMeta)}}}
local humanoid=newObject("Humanoid","Humanoid",char)
humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.Viewer
humanoid.Health=100
humanoid.MaxHealth=100
humanoid.HealthChanged=signal()
localPlayer.Character=char
game={GetService=function(_,name)
    if name=="Players" then return {LocalPlayer=localPlayer} end
    if name=="RunService" then return {RenderStepped=renderStep} end
    error("Unexpected service "..name)
end}
local mod=dofile("nameplate.lua")
assert(type(mod.new)=="function")
local instance=mod.new({Tag="VANTA",Style="Crimson"})
local billboard=assert(instance:GetBillboard(),"head billboard not created")
assert(billboard.ClassName=="BillboardGui")
assert(billboard.Parent==playerGui)
assert(billboard.Adornee==head)
assert(billboard.Enabled==true)
assert(billboard.MaxDistance==100)

local group=billboard.PlateGroup
local plate=group.Plate
assert(group.GroupTransparency==0)
assert(plate.ChamferShell.Image=="") -- client image-loader optional
assert(plate.Fallback.Visible==true)
assert(plate.TagChip.TagText.Text=="VANTA")
assert(plate.TagChip.Size[1]==64)
assert(plate.TagChip.TagText.TextXAlignment==Enum.TextXAlignment.Left)
assert(plate.TagChip.TagText.TextColor3)
assert(plate.AvatarRing.UIStroke.Thickness==2)
assert(plate.AvatarRing.UIStroke.Color[1]==255)
assert(plate.AvatarRing.BlackInset.BackgroundColor3[1]==8)
assert(plate.AvatarRing.Avatar.Position[2]==4)
assert(plate.AvatarRing.StatusDot.Position[2]==-4)
assert(plate.AvatarRing.StatusDot.Position[4]==-7)
assert(plate.DisplayName.UIStroke.Thickness==1)
assert(plate.DisplayName.UIStroke.ApplyStrokeMode==Enum.ApplyStrokeMode.Contextual)
assert(group.CrimsonOuterGlow.ImageTransparency==0.80)
assert(group.GlowFallback.UIStroke.Transparency==0.88)
assert(plate.DisplayName.Text=="Velora")
assert(plate.StatusLine.Text=="@SaltyExample")
assert(plate.HealthBar.HealthFill.Size[1]==1)
assert(plate.AvatarRing.StatusDot.BackgroundColor3)
assert(humanoid.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.None)
workspace.CurrentCamera.CFrame.Position.X=52
renderStep:Fire(1/15)
assert(group.GroupTransparency>0.4 and group.GroupTransparency<0.6)
assert(billboard.NameOnly.Visible==true)
workspace.CurrentCamera.CFrame.Position.X=70
renderStep:Fire(1/15)
assert(group.GroupTransparency==1)
workspace.CurrentCamera.CFrame.Position.X=0
renderStep:Fire(1/15)
assert(group.GroupTransparency==0)
assert(not billboard.NameOnly.Visible)

instance:SetTag("BOLT")
assert(plate.TagChip.TagText.Text=="BOLT")
assert(plate.TagChip.Size[1]==64)
instance:SetTag("ELITE RANK GOLD")
assert(plate.TagChip.Size[1]>64)
instance:SetTag("BOLT")
instance:SetStyle("Steel")
assert(plate.Fallback.BackgroundColor3)
assert(plate.ChamferShell.Visible==false)
instance:SetShowUsername(false)
assert(plate.StatusLine.Text=="MEMBER")
instance:SetSubtitle("VANTA // LVL 42")
assert(plate.StatusLine.Text=="VANTA // LVL 42")
-- Matching real and display names must not waste the subtitle line.
local oldDisplayName=localPlayer.DisplayName
localPlayer.DisplayName=localPlayer.Name
instance:SetSubtitle("VANTA // TESTER")
assert(plate.StatusLine.Text=="VANTA // TESTER")
localPlayer.DisplayName=oldDisplayName
instance:SetSubtitle("VANTA // LVL 42")
instance:SetScale(130)
assert(billboard.Size[1]==374)
instance:SetHeight(3.4)
assert(billboard.StudsOffsetWorldSpace[2]==3.4)
instance:SetDistance(65)
assert(billboard.MaxDistance==65)

-- Damage reduces actual health and turns the status dot red for a short period.
humanoid.Health=75
humanoid.HealthChanged:Fire(75)
assert(plate.HealthBar.HealthFill.Size[1]==0.75)
renderStep:Fire(1/15)
local damagedColor=plate.AvatarRing.StatusDot.BackgroundColor3
assert(damagedColor[1]==255)
for i=1,100 do renderStep:Fire(1/20) end
local idleColor=plate.AvatarRing.StatusDot.BackgroundColor3
assert(idleColor[1]==73)

assert(instance:IsEnabled()==true)
instance:SetEnabled(false)
assert(instance:IsEnabled()==false)
assert(billboard.Enabled==false)
assert(humanoid.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.Viewer)
instance:SetEnabled(true)
assert(instance:IsEnabled()==true)
assert(humanoid.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.None)

localPlayer.CharacterRemoving:Fire(char)
assert(instance:GetBillboard()==nil)
local second=newObject("Model","NewCharacter")
local secondHead=newObject("Part","Head",second)
local secondHumanoid=newObject("Humanoid","Humanoid",second)
secondHumanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.Viewer
secondHumanoid.Health=100
secondHumanoid.MaxHealth=100
secondHumanoid.HealthChanged=signal()
localPlayer.Character=second
localPlayer.CharacterAdded:Fire(second)
local newBillboard=assert(instance:GetBillboard())
assert(newBillboard.Adornee==secondHead)
assert(newBillboard~=billboard)
assert(newBillboard.PlateGroup.Plate.TagChip.TagText.Text=="BOLT")
assert(secondHumanoid.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.None)

-- Test opt-in custom images: shell turns on and rounded fallback is hidden.
local newer=mod.new({
    Tag="FRESH",Enabled=false,
    LoadRemoteImage=function(url)
        assert(url:find("assets/nameplate",1,true))
        return "local-png-asset"
    end,
})
assert(instance:GetBillboard()==nil)
assert(newer:GetBillboard().Enabled==false)
assert(newer:IsEnabled()==false)
assert(newer:GetBillboard().PlateGroup.Plate.TagChip.TagText.Text=="FRESH")
assert(newer:GetBillboard().PlateGroup.Plate.ChamferShell.Visible)
assert(not newer:GetBillboard().PlateGroup.Plate.Fallback.Visible)
assert(not newer:GetBillboard().PlateGroup.GlowFallback.Visible)
assert(secondHumanoid.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.Viewer)
newer:Destroy()
assert(newer:GetBillboard()==nil)
print("Vanta Edge: lifecycle, health, animation, styles, respawn, PNG fallback and cleanup passed.")
