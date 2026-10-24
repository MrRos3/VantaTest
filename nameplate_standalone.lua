-- Standalone Vanta Owl overhead nameplate. Run as LocalScript or executor Lua.
-- Vanta Owl | self-only overhead nameplate for VantaTest
-- Assets: your actual monochrome owl PNG in this repo. No Roblox upload ID required
-- on executors providing writefile + getcustomasset/getsynasset.
-- Other players NEVER receive a Vanta nameplate from this script.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local TextService = game:GetService("TextService")
local LocalPlayer = assert(Players.LocalPlayer, "Vanta Owl requires a Roblox client")

local CONFIG = {
    OWL_IMAGE = "", -- Optionally override with a published Roblox rbxassetid://123456
    OWL_SOURCE = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/assets/owl/vanta_owl_96.png",
    OWL_FILE = "VantaTest_Owl_96.png",
    OWL_TINT = Color3.fromRGB(255, 255, 255),
    ICON_SIZE = 30,
    ICON_PADDING = 12,
    NAME_PADDING = 24,
    HEIGHT = 44,
    MIN_WIDTH = 200,
    MAX_WIDTH = 420,
    NAME_SIZE = 16,
    FILL = Color3.fromRGB(14, 14, 16),
    FILL_TRANSPARENCY = 0.15,
    BORDER_BRIGHT = Color3.fromRGB(224, 23, 61),
    BORDER_DARK = Color3.fromRGB(74, 10, 24),
    GLOW = Color3.fromRGB(224, 23, 61),
    GLOW_TRANSPARENCY = 0.85,
    HEIGHT_STUDS = 2.5,
    MAX_DISTANCE = 60,
    FADE_START = 40,
    MIN_SCALE = 0.82,
    SWEEP_SECONDS = 4,
    UPDATE_FPS = 30,
}
local ROOT = "VantaTestNameplateLifecycle"
local GUI_NAME = "VantaOwlNameplate"
local module = {}

local function new(class, fields, parent)
    local object = Instance.new(class)
    for k,v in pairs(fields or {}) do object[k] = v end
    if parent then object.Parent = parent end
    return object
end
local function rounded(parent,px)
    return new("UICorner",{CornerRadius=UDim.new(0,px)},parent)
end
local function stroke(parent,color,weight,transparency)
    return new("UIStroke",{Color=color,Thickness=weight,Transparency=transparency or 0},parent)
end
local function colors(a,b)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0,a),
        ColorSequenceKeypoint.new(1,b),
    })
end
local function getWidth(displayName,scale)
    local ok,sz=pcall(function()
        return TextService:GetTextSize(displayName,CONFIG.NAME_SIZE,
            Enum.Font.GothamBold,Vector2.new(2000,CONFIG.HEIGHT))
    end)
    local textWidth=ok and sz.X or (#displayName * CONFIG.NAME_SIZE * 0.65)
    local occupied=2*(CONFIG.ICON_SIZE+CONFIG.ICON_PADDING)+CONFIG.NAME_PADDING
    return math.clamp(math.ceil(textWidth+occupied),CONFIG.MIN_WIDTH,CONFIG.MAX_WIDTH)
end

local function clearLegacy()
    -- Shut down our earlier all-players standalone executor script, if still alive.
    local env=_G
    pcall(function()
        if type(getgenv)=="function" then env=getgenv() end
    end)
    if type(env.__VANTA_OWL_CLEANUP)=="function" then
        pcall(env.__VANTA_OWL_CLEANUP)
        env.__VANTA_OWL_CLEANUP=nil
    end
    -- Only remove nameplates created by our older scripts, never game-owned tags.
    for _,p in ipairs(Players:GetPlayers()) do
        local character=p.Character
        local head=character and character:FindFirstChild("Head")
        if head then
            local old=head:FindFirstChild(GUI_NAME)
            if old then old:Destroy() end
        end
    end
end

-- GitHub raw PNG URLs cannot be assigned directly to Roblox ImageLabel.Image.
-- Use the actual repo image via executor custom asset support, or a proper
-- published rbxassetid override. Emoji fallbacks prevent blank icon slots.
local function resolveOwlAsset()
    if type(CONFIG.OWL_IMAGE)=="string" and
        CONFIG.OWL_IMAGE:match("^rbxassetid://%d+$") then
        return CONFIG.OWL_IMAGE
    end
    local assetFunc=type(getcustomasset)=="function" and getcustomasset
        or type(getsynasset)=="function" and getsynasset or nil
    if not assetFunc or type(writefile)~="function" then
        return nil
    end
    local ok,data=pcall(function()
        return game:HttpGet(CONFIG.OWL_SOURCE .. "?v=owl-96-1")
    end)
    if not ok or type(data)~="string" or data:sub(1,8)~="\137PNG\r\n\26\n" then
        return nil
    end
    local written=pcall(writefile,CONFIG.OWL_FILE,data)
    if not written then return nil end
    local loaded,uri=pcall(assetFunc,CONFIG.OWL_FILE)
    return loaded and type(uri)=="string" and uri~="" and uri or nil
end

function module.new(options)
    options=options or {}
    local playerScripts=LocalPlayer:WaitForChild("PlayerScripts")
    local previous=playerScripts:FindFirstChild(ROOT)
    if previous then previous:Destroy() end
    local playerGui=LocalPlayer:WaitForChild("PlayerGui")
    local prevGui=playerGui:FindFirstChild(ROOT)
    if prevGui then prevGui:Destroy() end
    clearLegacy()
    local lifecycle=new("Folder",{Name=ROOT},playerScripts)
    local controller={}
    local events={}
    local ended=false
    local gui,humanoid,tween,healthEvent,nameEvent
    local oldDistance
    local plateGroup,plate,glowStroke,innerGlowStroke,plateScale
    local owls,emojiLabels={},{}
    local displayLabel
    local owlAsset=nil
    local iconStatus="loading"
    local serial=0
    local updateTime=0
    local elapsed=0
    local healthLast=0
    local damageDuration=0
    local visible=options.Enabled~=false
    local scale=math.clamp(tonumber(options.Scale) or 100,70,140)/100
    local height=math.clamp(tonumber(options.Height) or CONFIG.HEIGHT_STUDS,1.5,4.5)
    local maxDistance=math.clamp(tonumber(options.MaxDistance) or CONFIG.MAX_DISTANCE,30,150)

    local function listen(signal,callback)
        local event=signal:Connect(callback)
        events[#events+1]=event
        return event
    end
    local function clearGui()
        if healthEvent then healthEvent:Disconnect();healthEvent=nil end
        if nameEvent then nameEvent:Disconnect();nameEvent=nil end
        if tween then tween:Cancel();tween=nil end
        if gui then gui:Destroy();gui=nil end
        if humanoid and humanoid.Parent and oldDistance then
            pcall(function()humanoid.DisplayDistanceType=oldDistance end)
        end
        humanoid=nil
        oldDistance=nil
        plateGroup=nil
        plate=nil
        plateScale=nil
        displayLabel=nil
        owls,emojiLabels={},{}
    end
    local function setOwlImage(value)
        owlAsset=value
        iconStatus=value and "loaded" or "fallback"
        for _,icon in ipairs(owls) do icon.Image=value or "" end
        for _,fallback in ipairs(emojiLabels) do fallback.Visible=not not (not value) end
    end

    local function updateDimensions()
        if not gui or not gui.Parent or not plate or not displayLabel then return end
        local width=getWidth(LocalPlayer.DisplayName)
        local outerWidth=width+24
        gui.Size=UDim2.fromOffset(math.floor(outerWidth*scale),math.floor(68*scale))
        gui.MaxDistance=maxDistance
        gui.StudsOffsetWorldSpace=Vector3.new(0,height,0)
        plateGroup.Size=UDim2.fromOffset(outerWidth,68)
        plateScale.Scale=scale
        plate.Size=UDim2.fromOffset(width,CONFIG.HEIGHT)
        glowStroke.Parent.Size=UDim2.fromOffset(width,CONFIG.HEIGHT)
        innerGlowStroke.Parent.Size=UDim2.fromOffset(width,CONFIG.HEIGHT)
        displayLabel.Size=UDim2.fromOffset(
            width-2*(CONFIG.ICON_SIZE+CONFIG.ICON_PADDING),CONFIG.HEIGHT)
        displayLabel.Text=LocalPlayer.DisplayName
    end

    local function createOwl(parent,name,x,isRight)
        local icon=new("ImageLabel",{
            Name=name,Image=owlAsset or "",ImageColor3=CONFIG.OWL_TINT,
            BackgroundTransparency=1,BorderSizePixel=0,
            ImageTransparency=0,ScaleType=Enum.ScaleType.Fit,
            Position=isRight and UDim2.new(1,-CONFIG.ICON_SIZE-CONFIG.ICON_PADDING,0,7)
                or UDim2.fromOffset(x,7),
            Size=UDim2.fromOffset(CONFIG.ICON_SIZE,CONFIG.ICON_SIZE),
            ZIndex=6,
        },parent)
        local label=new("TextLabel",{
            Name=name.."Fallback",Text="🦉",TextScaled=true,Visible=not owlAsset,
            BackgroundTransparency=1,BorderSizePixel=0,TextColor3=CONFIG.OWL_TINT,
            Position=icon.Position,Size=icon.Size,ZIndex=6,
        },parent)
        owls[#owls+1]=icon
        emojiLabels[#emojiLabels+1]=label
    end

    local function attach(character,version)
        local head=character:FindFirstChild("Head") or character:WaitForChild("Head",12)
        local hum=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",12)
        if ended or serial~=version or character~=LocalPlayer.Character or not head or not hum then return end
        clearGui()
        humanoid=hum
        oldDistance=hum.DisplayDistanceType
        if visible then
            pcall(function()hum.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end)
        end
        -- Parent the GUI to Head; it is discarded automatically with the old rig.
        gui=new("BillboardGui",{
            Name=GUI_NAME,Adornee=head,AlwaysOnTop=true,Active=false,
            Enabled=visible,LightInfluence=0,MaxDistance=maxDistance,
            Size=UDim2.fromOffset(224,68),
            StudsOffsetWorldSpace=Vector3.new(0,height,0),
        },head)
        local w=getWidth(LocalPlayer.DisplayName)
        plateGroup=new("CanvasGroup",{
            Name="NameplateGroup",Size=UDim2.fromOffset(w+24,68),
            BackgroundTransparency=1,GroupTransparency=0,BorderSizePixel=0,
            AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
            Active=false,
        },gui)
        plateScale=new("UIScale",{Scale=scale},plateGroup)
        local glow=new("Frame",{
            Name="SoftGlow",Position=UDim2.fromOffset(12,12),
            Size=UDim2.fromOffset(w,CONFIG.HEIGHT),
            BackgroundTransparency=1,BorderSizePixel=0,ZIndex=1,
        },plateGroup)
        rounded(glow,7)
        glowStroke=stroke(glow,CONFIG.GLOW,6,CONFIG.GLOW_TRANSPARENCY)
        local innerGlow=new("Frame",{
            Name="InnerGlow",Position=UDim2.fromOffset(12,12),
            Size=UDim2.fromOffset(w,CONFIG.HEIGHT),
            BackgroundTransparency=1,BorderSizePixel=0,ZIndex=2,
        },plateGroup)
        rounded(innerGlow,6)
        innerGlowStroke=stroke(innerGlow,CONFIG.GLOW,3,0.93)

        plate=new("Frame",{
            Name="Plate",Position=UDim2.fromOffset(12,12),
            Size=UDim2.fromOffset(w,CONFIG.HEIGHT),
            BackgroundColor3=CONFIG.FILL,
            BackgroundTransparency=CONFIG.FILL_TRANSPARENCY,
            BorderSizePixel=0,ZIndex=3,
        },plateGroup)
        rounded(plate,5)
        new("UIGradient",{
            Rotation=90,Color=colors(Color3.fromRGB(22,21,25),CONFIG.FILL),
        },plate)
        local plateStroke=stroke(plate,CONFIG.BORDER_BRIGHT,1,0)
        local borderGradient=new("UIGradient",{
            Color=colors(CONFIG.BORDER_BRIGHT,CONFIG.BORDER_DARK),
            Rotation=0,Offset=Vector2.new(-1,0),
        },plateStroke)
        tween=TweenService:Create(borderGradient,
            TweenInfo.new(CONFIG.SWEEP_SECONDS,Enum.EasingStyle.Linear,
                Enum.EasingDirection.Out,-1,false),
            {Offset=Vector2.new(1,0)})
        tween:Play()

        createOwl(plate,"LeftOwl",CONFIG.ICON_PADDING,false)
        createOwl(plate,"RightOwl",0,true)
        displayLabel=new("TextLabel",{
            Name="DisplayName",Text=LocalPlayer.DisplayName,
            Font=Enum.Font.GothamBold,TextSize=CONFIG.NAME_SIZE,
            TextColor3=Color3.fromRGB(255,255,255),
            TextStrokeColor3=Color3.fromRGB(0,0,0),TextStrokeTransparency=0.24,
            TextXAlignment=Enum.TextXAlignment.Center,
            TextYAlignment=Enum.TextYAlignment.Center,
            TextTruncate=Enum.TextTruncate.AtEnd,
            AnchorPoint=Vector2.new(0.5,0.5),
            Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(w-2*(CONFIG.ICON_SIZE+CONFIG.ICON_PADDING),CONFIG.HEIGHT),
            BackgroundTransparency=1,BorderSizePixel=0,ZIndex=6,
        },plate)
        updateDimensions()
        nameEvent=LocalPlayer:GetPropertyChangedSignal("DisplayName"):Connect(updateDimensions)
        healthLast=hum.Health
        damageDuration=0
        healthEvent=hum.HealthChanged:Connect(function(hp)
            if hp<healthLast then damageDuration=0.32 end
            healthLast=hp
        end)
    end

    local function startCharacter(character)
        serial=serial+1
        local version=serial
        clearGui()
        task.spawn(function()attach(character,version)end)
    end

    listen(LocalPlayer.CharacterAdded,startCharacter)
    listen(LocalPlayer.CharacterRemoving,function()
        serial=serial+1
        clearGui()
    end)
    listen(RunService.RenderStepped,function(dt)
        if ended or not visible or not gui or not gui.Parent or not plateGroup then return end
        updateTime=updateTime+math.min(dt or 1/60,0.075)
        if updateTime<1/CONFIG.UPDATE_FPS then return end
        local step=updateTime
        updateTime=0
        elapsed=elapsed+step
        damageDuration=math.max(0,damageDuration-step)
        local dist=0
        local cam=workspace.CurrentCamera
        if cam and gui.Adornee then
            pcall(function()dist=(cam.CFrame.Position-gui.Adornee.Position).Magnitude end)
        end
        local fade=math.clamp((dist-CONFIG.FADE_START)/
            math.max(1,maxDistance-CONFIG.FADE_START),0,1)
        plateGroup.GroupTransparency=fade*0.84
        plateScale.Scale=scale*(1-(1-CONFIG.MIN_SCALE)*fade)
        local flicker=damageDuration>0 and math.floor(elapsed*34)%2==0 and 0.15 or 0
        local wave=0.5+0.5*math.sin(elapsed*1.9)
        glowStroke.Transparency=math.clamp(CONFIG.GLOW_TRANSPARENCY-0.055*wave-flicker,0.43,0.97)
        innerGlowStroke.Transparency=math.clamp(0.93-0.04*wave-flicker,0.55,0.97)
        plate.BackgroundTransparency=math.clamp(CONFIG.FILL_TRANSPARENCY+flicker,0,0.55)
    end)
    listen(lifecycle.Destroying,function()controller:Destroy()end)

    function controller:SetEnabled(on)
        if ended then return end
        visible=not not on
        if gui then gui.Enabled=visible end
        if humanoid and humanoid.Parent then
            pcall(function()
                humanoid.DisplayDistanceType=visible and
                    Enum.HumanoidDisplayDistanceType.None or oldDistance
            end)
        end
    end
    function controller:IsEnabled()
        return not ended and visible
    end
    function controller:SetScale(n)
        scale=math.clamp(tonumber(n) or 100,70,140)/100
        updateDimensions()
    end
    function controller:SetDistance(n)
        maxDistance=math.clamp(tonumber(n) or 60,30,150)
        updateDimensions()
    end
    function controller:SetHeight(n)
        height=math.clamp(tonumber(n) or 2.5,1.5,4.5)
        updateDimensions()
    end
    function controller:GetBillboard(p)
        if p and p~=LocalPlayer then return nil end
        return gui
    end
    function controller:GetOwlStatus()
        return iconStatus
    end
    function controller:Destroy()
        if ended then return end
        ended=true
        serial=serial+1
        for _,event in ipairs(events) do event:Disconnect() end
        clearGui()
        if lifecycle.Parent then lifecycle:Destroy() end
    end

    if LocalPlayer.Character then startCharacter(LocalPlayer.Character) end
    task.spawn(function()
        local asset=resolveOwlAsset()
        if ended then return end
        setOwlImage(asset)
        if not asset then
            warn("[Vanta Owl] Custom PNG asset APIs unavailable. Showing owl emoji fallback. Upload the image to Roblox or use an executor supporting getcustomasset.")
        end
    end)
    return controller
end

return module.new()
