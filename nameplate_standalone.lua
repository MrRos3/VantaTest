-- Standalone Vanta Owl overhead nameplate; uses the bundled owl PNG.
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
    ICON_PADDING = 18,
    HEIGHT = 44,
    MIN_WIDTH = 190,
    NAME_EXTRA_PADDING = 76,
    NAME_SIZE = 14,
    NAME_FONT = Enum.Font.Michroma,
    NAME_WIDE_SPACING = false, -- Michroma is already spacious; optional thin spaces.
    NAME_SHINE_SECONDS = 1.4,
    NAME_SHINE_PAUSE = 2.5,
    FILL = Color3.fromRGB(5,5,6),                -- #050506
    BORDER_DARK = Color3.fromRGB(90,10,28),      -- #5A0A1C
    BORDER_BRIGHT = Color3.fromRGB(255,51,85),   -- #FF3355
    BORDER_THICKNESS = 2,
    HEIGHT_STUDS = 2.5,
    MAX_DISTANCE = 60,
    FADE_START = 40,
    BORDER_ROTATE_SECONDS = 5,
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
local function stroke(parent,color,weight,transparency)
    return new("UIStroke",{Color=color,Thickness=weight,Transparency=transparency or 0},parent)
end
-- TextBounds determines the width once Roblox has measured the label.
-- Until that happens (including immediately after a name change), use
-- TextService with the same Michroma font and 14px size as the label.
local function getWidth(displayName,textBoundsX)
    local ok,sz=pcall(function()
        return TextService:GetTextSize(displayName,CONFIG.NAME_SIZE,
            CONFIG.NAME_FONT,Vector2.new(2000,CONFIG.HEIGHT))
    end)
    local textWidth=ok and sz.X or (#displayName*CONFIG.NAME_SIZE*0.65)
    if type(textBoundsX)=="number" and textBoundsX>0 then
        textWidth=textBoundsX
    end
    return math.max(CONFIG.MIN_WIDTH,
        math.ceil(2*CONFIG.ICON_SIZE+textWidth+CONFIG.NAME_EXTRA_PADDING))
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

-- HTTP PNGs require local registration; Roblox IDs work without file APIs.
local function normalizeOwlImage(value)
    if value==nil then return nil end
    local input=tostring(value):match("^%s*(.-)%s*$")
    local id=input:match("^rbxassetid://(%d+)$") or input:match("^(%d+)$")
    return id and "rbxassetid://"..id or nil
end
local PNG_SIGNATURE={137,80,78,71,13,10,26,10}
local function validPNG(bytes)
    if type(bytes)~="string" or #bytes<8 then return false end
    for i=1,8 do
        if string.byte(bytes,i)~=PNG_SIGNATURE[i] then return false end
    end
    return true
end
local function resolveOwlAsset(chosen)
    local value=chosen
    if value==nil then value=CONFIG.OWL_IMAGE end
    local id=normalizeOwlImage(value)
    if id then return id,"loaded Roblox owl image ID" end
    if value~=nil and tostring(value)~="" then
        return nil,"invalid Roblox owl image ID"
    end
    local custom=type(getcustomasset)=="function" and getcustomasset or nil
    local synasset=type(getsynasset)=="function" and getsynasset or nil
    local status="download failed"
    for attempt=1,3 do
        local url=CONFIG.OWL_SOURCE.."?v=owl-96-3"
        local providers={}
        if type(request)=="function" then providers[#providers+1]=request end
        if type(http_request)=="function" then providers[#providers+1]=http_request end
        if type(syn)=="table" and type(syn.request)=="function" then providers[#providers+1]=syn.request end
        if type(http)=="table" and type(http.request)=="function" then providers[#providers+1]=http.request end
        local data
        for _,fetch in ipairs(providers) do
            local ok,response=pcall(fetch,{Url=url,Method="GET"})
            if ok and type(response)=="table" and type(response.Body)=="string"
                and response.Success~=false
                and (response.StatusCode==nil or response.StatusCode==200) then
                data=response.Body
                break
            end
        end
        if not data then
            local ok,body=pcall(function()return game:HttpGet(url)end)
            if ok and type(body)=="string" then data=body end
        end
        if not data then status="download failed"
        elseif not validPNG(data) then status="bad PNG"
        elseif type(writefile)~="function" then status="writefile failed"
        else
            local paths={}
            if type(makefolder)=="function" then
                local ok=pcall(function()
                    if type(isfolder)~="function" or not isfolder("VantaTest") then
                        makefolder("VantaTest")
                    end
                end)
                if ok then paths[#paths+1]="VantaTest/"..CONFIG.OWL_FILE end
            end
            paths[#paths+1]=CONFIG.OWL_FILE
            local written=false
            for _,path in ipairs(paths) do
                if pcall(writefile,path,data) then
                    written=true
                    if not custom and not synasset then
                        status="no getcustomasset"
                    else
                        if custom then
                            local ok,uri=pcall(custom,path)
                            if ok and type(uri)=="string" and uri~="" then
                                return uri,"loaded via getcustomasset"
                            end
                            ok,uri=pcall(custom,path,true)
                            if ok and type(uri)=="string" and uri~="" then
                                return uri,"loaded via getcustomasset(path, true)"
                            end
                        end
                        if synasset then
                            local ok,uri=pcall(synasset,path)
                            if ok and type(uri)=="string" and uri~="" then
                                return uri,"loaded via getsynasset"
                            end
                        end
                        status="getcustomasset failed"
                    end
                end
            end
            if not written then status="writefile failed" end
        end
        if attempt<3 and type(task.wait)=="function" then task.wait(0.5) end
    end
    return nil,status
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
    local gui,humanoid,nameEvent,boundsEvent
    local borderTween,borderStroke
    local nameShineTween,nameGradient,nameStroke
    local oldDistance
    local plateGroup,plate,plateScale,contentLayer
    local owls,emojiLabels={},{}
    local displayLabel
    local owlAsset=nil
    local iconStatus="loading"
    local currentOwlImage=options.OWL_IMAGE or CONFIG.OWL_IMAGE
    local statusListener
    local assetSerial=0
    local serial=0
    local updateTime=0
    local shineClock=0
    local shineActive=false
    -- Only a single gradient on the actual name: all red at idle offsets.
    local NAME_COLORS=ColorSequence.new({
        ColorSequenceKeypoint.new(0.00,Color3.fromRGB(255,26,61)),
        ColorSequenceKeypoint.new(0.35,Color3.fromRGB(255,26,61)),
        ColorSequenceKeypoint.new(0.50,Color3.fromRGB(255,255,255)),
        ColorSequenceKeypoint.new(0.65,Color3.fromRGB(255,26,61)),
        ColorSequenceKeypoint.new(1.00,Color3.fromRGB(255,26,61)),
    })
    local function showName(value)
        if not CONFIG.NAME_WIDE_SPACING then return value end
        -- Unicode thin spaces are optional, never inserted by default.
        local letters={}
        for _,codepoint in utf8.codes(value) do
            letters[#letters+1]=utf8.char(codepoint)
        end
        return table.concat(letters," ")
    end
    local visible=options.Enabled~=false
    local scale=math.clamp(tonumber(options.Scale) or 100,70,140)/100
    local height=math.clamp(tonumber(options.Height) or CONFIG.HEIGHT_STUDS,1.5,4.5)
    local maxDistance=math.clamp(tonumber(options.MaxDistance) or CONFIG.MAX_DISTANCE,30,150)

    local function listen(signal,callback)
        local event=signal:Connect(callback)
        events[#events+1]=event
        return event
    end
    -- Reset only after the white band has exited, leaving solid red while idle.
    local function stopNameShine()
        shineActive=false
        if nameShineTween then nameShineTween:Cancel() end
        if nameGradient then nameGradient.Offset=Vector2.new(-1,0) end
    end

    local function startNameShine()
        if not nameShineTween or not nameGradient then return end
        nameShineTween:Cancel()
        nameGradient.Offset=Vector2.new(-1,0)
        shineActive=true
        nameShineTween:Play()
    end

    local function clearGui()
        if nameEvent then nameEvent:Disconnect();nameEvent=nil end
        if boundsEvent then boundsEvent:Disconnect();boundsEvent=nil end
        if borderTween then borderTween:Cancel();borderTween=nil end
        borderStroke=nil
        stopNameShine()
        nameShineTween=nil
        nameGradient=nil
        nameStroke=nil
        shineClock=0
        if gui then gui:Destroy();gui=nil end
        if humanoid and humanoid.Parent and oldDistance then
            pcall(function()humanoid.DisplayDistanceType=oldDistance end)
        end
        humanoid=nil
        oldDistance=nil
        plateGroup=nil
        plate=nil
        plateScale=nil
        contentLayer=nil
        displayLabel=nil
        owls,emojiLabels={},{}
    end
    local function setOwlImage(value,status)
        owlAsset=value
        iconStatus=status or (value and "loaded" or "fallback")
        for _,icon in ipairs(owls) do icon.Image=value or "" end
        for _,fallback in ipairs(emojiLabels) do fallback.Visible=not value end
        if statusListener then pcall(statusListener,iconStatus) end
    end

    local function updateDimensions()
        if not gui or not gui.Parent or not plate or not displayLabel then return end
        local name=showName(LocalPlayer.DisplayName)
        local textChanged=displayLabel.Text~=name
        if textChanged then displayLabel.Text=name end
        -- The previous TextBounds may belong to another DisplayName.
        local bounds=not textChanged and displayLabel.TextBounds
        local width=getWidth(name,bounds and bounds.X)
        local canvasWidth=width+24
        gui.Size=UDim2.fromOffset(math.floor(canvasWidth*scale),math.floor(68*scale))
        gui.MaxDistance=maxDistance
        gui.StudsOffsetWorldSpace=Vector3.new(0,height,0)
        plateGroup.Size=UDim2.fromOffset(canvasWidth,68)
        plateScale.Scale=scale
        plate.Size=UDim2.fromOffset(width,CONFIG.HEIGHT)
        contentLayer.Size=plate.Size
        displayLabel.Size=UDim2.fromOffset(
            width-2*CONFIG.ICON_SIZE-CONFIG.NAME_EXTRA_PADDING,CONFIG.HEIGHT)
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
        local fallback=new("Frame",{
            Name=name.."Fallback",Visible=not owlAsset,
            BackgroundTransparency=1,BorderSizePixel=0,
            Position=icon.Position,Size=icon.Size,ZIndex=6,
        },parent)
        new("UICorner",{CornerRadius=UDim.new(1,0)},fallback)
        new("UIStroke",{
            Name="CircleOutline",Color=Color3.fromRGB(255,255,255),
            Thickness=1.5,Transparency=0,
        },fallback)
        new("TextLabel",{
            Name="Mark",Text="V",Font=Enum.Font.Michroma,TextSize=17,
            TextColor3=Color3.fromRGB(255,255,255),
            BackgroundTransparency=1,BorderSizePixel=0,
            Size=UDim2.fromScale(1,1),ZIndex=7,
        },fallback)
        owls[#owls+1]=icon
        emojiLabels[#emojiLabels+1]=fallback
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
        local w=getWidth(showName(LocalPlayer.DisplayName))
        plateGroup=new("CanvasGroup",{
            Name="NameplateGroup",Size=UDim2.fromOffset(w+24,68),
            BackgroundTransparency=1,GroupTransparency=0,BorderSizePixel=0,
            AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
            Active=false,
        },gui)
        plateScale=new("UIScale",{Scale=scale},plateGroup)
        -- A single fully rounded, flat black plate. Only its stroke rotates.
        plate=new("Frame",{
            Name="Plate",Position=UDim2.fromOffset(12,12),
            Size=UDim2.fromOffset(w,CONFIG.HEIGHT),
            BackgroundColor3=CONFIG.FILL,
            BackgroundTransparency=0,BorderSizePixel=0,ZIndex=1,
        },plateGroup)
        new("UICorner",{CornerRadius=UDim.new(0.5,0)},plate)
        borderStroke=stroke(plate,Color3.fromRGB(255,255,255),
            CONFIG.BORDER_THICKNESS,0)
        borderStroke.Name="CrimsonBorderStroke"
        borderStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Border
        local borderGradient=new("UIGradient",{
            Name="RotatingCrimsonBorder",Rotation=0,
            Color=ColorSequence.new({
                ColorSequenceKeypoint.new(0.00,CONFIG.BORDER_DARK),
                ColorSequenceKeypoint.new(0.40,CONFIG.BORDER_DARK),
                ColorSequenceKeypoint.new(0.50,CONFIG.BORDER_BRIGHT),
                ColorSequenceKeypoint.new(0.60,CONFIG.BORDER_DARK),
                ColorSequenceKeypoint.new(1.00,CONFIG.BORDER_DARK),
            }),
        },borderStroke)
        borderTween=TweenService:Create(borderGradient,
            TweenInfo.new(CONFIG.BORDER_ROTATE_SECONDS,Enum.EasingStyle.Linear,
                Enum.EasingDirection.Out,-1,false),
            {Rotation=360})
        borderTween:Play()
        -- No backing frame for the owls; the transparent content is the
        -- sole layout child over the capsule, keeping 18px end padding.
        contentLayer=new("Frame",{
            Name="Content",Position=UDim2.fromOffset(0,0),
            Size=UDim2.fromOffset(w,CONFIG.HEIGHT),
            BackgroundTransparency=1,BorderSizePixel=0,ZIndex=2,
        },plate)
        createOwl(contentLayer,"LeftOwl",CONFIG.ICON_PADDING,false)
        createOwl(contentLayer,"RightOwl",0,true)
        displayLabel=new("TextLabel",{
            Name="DisplayName",Text=showName(LocalPlayer.DisplayName),
            Font=CONFIG.NAME_FONT,TextSize=CONFIG.NAME_SIZE,
            TextColor3=Color3.fromRGB(255,255,255),
            TextStrokeTransparency=1,
            TextXAlignment=Enum.TextXAlignment.Center,
            TextYAlignment=Enum.TextYAlignment.Center,
            TextTruncate=Enum.TextTruncate.AtEnd,
            AnchorPoint=Vector2.new(0.5,0.5),
            Position=UDim2.fromScale(0.5,0.5),
            Size=UDim2.fromOffset(w-2*CONFIG.ICON_SIZE-CONFIG.NAME_EXTRA_PADDING,CONFIG.HEIGHT),
            BackgroundTransparency=1,BorderSizePixel=0,ZIndex=6,
        },contentLayer)
        -- Exactly one UIGradient on the name. White glyphs keep the colors true.
        -- -1 and +1 both park the white band completely outside the glyphs.
        nameGradient=new("UIGradient",{
            Name="CrimsonNameGradient",Color=NAME_COLORS,
            Offset=Vector2.new(-1,0),Rotation=0,
        },displayLabel)
        nameStroke=stroke(displayLabel,Color3.fromRGB(26,0,8),1,0.3)
        nameStroke.Name="NameOutlineStroke"
        nameStroke.ApplyStrokeMode=Enum.ApplyStrokeMode.Contextual
        nameShineTween=TweenService:Create(nameGradient,
            TweenInfo.new(CONFIG.NAME_SHINE_SECONDS,Enum.EasingStyle.Sine,
                Enum.EasingDirection.InOut),
            {Offset=Vector2.new(1,0)})
        shineClock=0
        if visible then startNameShine() end
        updateDimensions()
        nameEvent=LocalPlayer:GetPropertyChangedSignal("DisplayName"):Connect(updateDimensions)
        boundsEvent=displayLabel:GetPropertyChangedSignal("TextBounds"):Connect(updateDimensions)
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
    listen(Players.PlayerRemoving,function(p)
        if p==LocalPlayer then controller:Destroy() end
    end)
    listen(RunService.RenderStepped,function(dt)
        if ended or not visible or not gui or not gui.Parent or not plateGroup then return end
        updateTime=updateTime+math.min(dt or 1/60,0.075)
        if updateTime<1/CONFIG.UPDATE_FPS then return end
        local step=updateTime
        updateTime=0
        -- 1.4s Sine sweep, then 2.5s with the band parked entirely offscreen.
        -- No other code changes the name's color or horizontal position.
        shineClock=shineClock+step
        if shineActive and shineClock>=CONFIG.NAME_SHINE_SECONDS then
            stopNameShine()
        end
        local cycle=CONFIG.NAME_SHINE_SECONDS+CONFIG.NAME_SHINE_PAUSE
        if shineClock>=cycle then
            shineClock=shineClock%cycle
            startNameShine()
        end
        local dist=0
        local cam=workspace.CurrentCamera
        if cam and gui.Adornee then
            pcall(function()dist=(cam.CFrame.Position-gui.Adornee.Position).Magnitude end)
        end
        local fade=math.clamp((dist-CONFIG.FADE_START)/
            math.max(1,maxDistance-CONFIG.FADE_START),0,1)
        -- Fade the capsule fill and its stroke together, including the
        -- animated bright band, without duplicating transparency effects.
        plate.BackgroundTransparency=fade
        borderStroke.Transparency=fade
        for _,icon in ipairs(owls) do icon.ImageTransparency=fade end
        for _,fallback in ipairs(emojiLabels) do
            local mark=fallback:FindFirstChild("Mark")
            local ring=fallback:FindFirstChild("CircleOutline")
            if mark then mark.TextTransparency=fade end
            if ring then ring.Transparency=fade end
        end
        displayLabel.TextTransparency=fade
        nameStroke.Transparency=0.3+0.7*fade
    end)
    listen(lifecycle.Destroying,function()controller:Destroy()end)

    function controller:SetEnabled(on)
        if ended then return end
        visible=not not on
        if gui then gui.Enabled=visible end
        shineClock=0
        if visible then startNameShine() else stopNameShine() end
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
    function controller:OnOwlStatus(callback)
        statusListener=type(callback)=="function" and callback or nil
        if statusListener then pcall(statusListener,iconStatus) end
    end
    function controller:SetOwlImage(value)
        currentOwlImage=value==nil and "" or tostring(value)
        assetSerial=assetSerial+1
        local version=assetSerial
        iconStatus="loading"
        if statusListener then pcall(statusListener,iconStatus) end
        task.spawn(function()
            local asset,status=resolveOwlAsset(currentOwlImage)
            if ended or version~=assetSerial then return end
            setOwlImage(asset,status)
            if not asset and type(warn)=="function" then warn("[Vanta Owl] "..status) end
        end)
        return normalizeOwlImage(currentOwlImage)~=nil or currentOwlImage==""
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
    controller:SetOwlImage(currentOwlImage)
    return controller
end

return module.new()
