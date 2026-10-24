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
            if not v.destroyed and v.Parent==self and v.Name==key then return v end
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
        if not v.destroyed and v.Parent==self and v.Name==name then return v end
    end
    return nil
end
function methods:WaitForChild(name)
    return assert(self:FindFirstChild(name),"Missing mock child "..name)
end
function methods:FindFirstChildOfClass(class)
    for _,v in ipairs(all) do
        if not v.destroyed and v.Parent==self and v.ClassName==class then return v end
    end
end
function methods:IsDescendantOf(parent)
    local p=self.Parent
    while p do
        if p==parent then return true end
        p=p.Parent
    end
    return false
end
function methods:Destroy()
    if self.destroyed then return end
    self.destroyed=true
    self.Destroying:Fire()
    for _,v in ipairs(all) do
        if not v.destroyed and v.Parent==self then v:Destroy() end
    end
    self.Parent=nil
end
Instance={new=function(class) return newObject(class) end}
local function value(...) return {...} end
Color3={fromRGB=value}
Vector3={new=value}
UDim={new=value}
UDim2={new=value,fromOffset=value,fromScale=value}
ColorSequence={new=value}
ColorSequenceKeypoint={new=value}
Enum={
    Font={Gotham="Gotham",GothamBold="GothamBold"},
    TextXAlignment={Left="Left"},
    TextYAlignment={Center="Center"},
    TextTruncate={AtEnd="AtEnd"},
    HumanoidDisplayDistanceType={None="None",Viewer="Viewer"},
}
utf8={offset=function(s,n)
    if #s<n then return nil end
    return n
end}
task={spawn=function(fn) fn() end}
local localPlayer=newObject("Player","MockPlayer")
localPlayer.Name="SaltyExample"
localPlayer.DisplayName="Velora"
localPlayer.UserId=123456
localPlayer.CharacterAdded=signal()
localPlayer.CharacterRemoving=signal()
local playerGui=newObject("PlayerGui","PlayerGui",localPlayer)
local char=newObject("Model","Character")
local head=newObject("Part","Head",char)
local humanoid=newObject("Humanoid","Humanoid",char)
humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.Viewer
localPlayer.Character=char
game={GetService=function(_,name)
    if name=="Players" then return {LocalPlayer=localPlayer} end
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
assert(billboard.Plate.DisplayName.Text=="Velora")
assert(billboard.Plate.Username.Text=="@SaltyExample")
assert(billboard.Plate.TagChip.TagText.Text=="VANTA")
assert(humanoid.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.None)
instance:SetTag("BOLT")
assert(billboard.Plate.TagChip.TagText.Text=="BOLT")
instance:SetStyle("Steel")
assert(billboard.Plate.TagChip.TagText.TextColor3)
instance:SetShowUsername(false)
assert(billboard.Plate.Username.Visible==false)
instance:SetScale(130)
assert(billboard.Size[1]==338)
instance:SetHeight(3.4)
assert(billboard.StudsOffsetWorldSpace[2]==3.4)
instance:SetDistance(65)
assert(billboard.MaxDistance==65)
instance:SetEnabled(false)
assert(billboard.Enabled==false)
assert(humanoid.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.Viewer)
instance:SetEnabled(true)
assert(humanoid.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.None)

localPlayer.CharacterRemoving:Fire(char)
assert(instance:GetBillboard()==nil)
local second=newObject("Model","NewCharacter")
local secondHead=newObject("Part","Head",second)
local secondHumanoid=newObject("Humanoid","Humanoid",second)
secondHumanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.Viewer
localPlayer.Character=second
localPlayer.CharacterAdded:Fire(second)
local newBillboard=assert(instance:GetBillboard())
assert(newBillboard.Adornee==secondHead)
assert(newBillboard~=billboard)
assert(newBillboard.Plate.TagChip.TagText.Text=="BOLT")
assert(secondHumanoid.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.None)

-- Re-running VantaTest must clean up the previous controller and not stack billboards.
local newer=mod.new({Tag="FRESH",Enabled=false})
assert(instance:GetBillboard()==nil)
assert(newer:GetBillboard().Enabled==false)
assert(newer:GetBillboard().Plate.TagChip.TagText.Text=="FRESH")
assert(secondHumanoid.DisplayDistanceType==Enum.HumanoidDisplayDistanceType.Viewer)
newer:Destroy()
assert(newer:GetBillboard()==nil)
print("Nameplate lifecycle, settings, respawn, client-only mount and re-execution checks passed.")
