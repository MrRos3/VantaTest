-- Vanta Edge | VantaTest client-only overhead nameplate.
-- Visual design: two chamfered corners, gradient crimson contour, 9-slice red glow,
-- solid tag, honest identity/subtitle, live Humanoid health, distance LOD and damage flicker.
-- Does NOT replicate to other players in arbitrary Roblox games.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local player = assert(Players.LocalPlayer, "Vanta Edge requires a Roblox client")
local Nameplate = {}

local ROOT_NAME = "VantaTestNameplateLifecycle"
local GUI_NAME = "VantaEdgeNameplate"
local SHELL_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/assets/nameplate/vanta-edge-shell.png?v=edge-1"
local GLOW_URL = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/assets/nameplate/vanta-edge-glow-9slice.png?v=edge-1"
local WHITE = Color3.fromRGB(250, 248, 251)
local BLACK = Color3.fromRGB(8, 8, 10)
local GREEN = Color3.fromRGB(73, 221, 149)

local STYLES = {
    Crimson = {
        bright = Color3.fromRGB(224, 23, 61), -- #E0173D
        dark = Color3.fromRGB(74, 10, 24), -- #4A0A18
        background = Color3.fromRGB(8, 8, 10),
        tagText = BLACK,
        status = Color3.fromRGB(233, 93, 123),
    },
    OLED = {
        bright = Color3.fromRGB(192, 44, 76),
        dark = Color3.fromRGB(67, 18, 35),
        background = Color3.fromRGB(4, 4, 6),
        tagText = BLACK,
        status = Color3.fromRGB(233, 168, 186),
    },
    Steel = {
        bright = Color3.fromRGB(167, 191, 209),
        dark = Color3.fromRGB(46, 64, 83),
        background = Color3.fromRGB(10, 12, 15),
        tagText = BLACK,
        status = Color3.fromRGB(169, 194, 213),
    },
}

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k,v in pairs(props or {}) do obj[k]=v end
    if parent then obj.Parent=parent end
    return obj
end
local function round(parent, radius)
    return make("UICorner", {CornerRadius=UDim.new(0, radius)}, parent)
end
local function outline(parent, color, thickness, transparency)
    return make("UIStroke", {
        Color=color,Thickness=thickness or 1,Transparency=transparency or 0
    }, parent)
end
local function label(parent, name, value, size, color, heavy, extra)
    local props={
        Name=name,Text=tostring(value or ""),Font=heavy and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextSize=size,TextColor3=color,TextTruncate=Enum.TextTruncate.AtEnd,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,
        BackgroundTransparency=1,BorderSizePixel=0,
    }
    for k,v in pairs(extra or {}) do props[k]=v end
    return make("TextLabel",props,parent)
end
local function cleanText(v,maxChars)
    local s=tostring(v or ""):gsub("[%c]"," "):match("^%s*(.-)%s*$") or ""
    local ok,stop=pcall(utf8.offset,s,maxChars+1)
    if not ok then return "" end
    if stop then return s:sub(1,stop-1) end
    return s
end
local function sequence(left,right)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0,left),
        ColorSequenceKeypoint.new(1,right),
    })
end

function Nameplate.new(options)
    local config=options or {}
    local rootFolder=player:WaitForChild("PlayerGui")
    local old=rootFolder:FindFirstChild(ROOT_NAME)
    if old then old:Destroy() end

    local lifecycle=make("Folder",{Name=ROOT_NAME},rootFolder)
    local active,humanoid,healthConnection
    local oldDisplayType
    local disposed=false
    local connections={}
    local ui={}
    local combatLeft=0
    local damageFlash=0
    local lastHealth=nil
    local clock=0
    local accumulator=0
    local fade=0
    local lastDistance=0

    local state={
        enabled=config.Enabled~=false,
        tag=cleanText(config.Tag or "VANTA",18),
        subtitle=cleanText(config.Subtitle or "VANTA // MEMBER",30),
        style=STYLES[config.Style] and config.Style or "Crimson",
        showUsername=config.ShowUsername~=false,
        size=math.clamp(tonumber(config.Scale) or 100,70,140)/100,
        height=math.clamp(tonumber(config.Height) or 2.65,1.5,4.5),
        maxDistance=math.clamp(tonumber(config.MaxDistance) or 100,30,150),
    }
    local controller={}

    local function track(conn)
        if conn then connections[#connections+1]=conn end
        return conn
    end

    local function restoreName()
        if humanoid and humanoid.Parent and oldDisplayType then
            pcall(function() humanoid.DisplayDistanceType=oldDisplayType end)
        end
        humanoid=nil
        oldDisplayType=nil
    end
    local function stopHealth()
        if healthConnection then healthConnection:Disconnect();healthConnection=nil end
        restoreName()
        lastHealth=nil
        damageFlash=0
        combatLeft=0
    end

    local function hideDefault(char)
        local h=char:FindFirstChildOfClass("Humanoid")
        if not h then return end
        if humanoid~=h then
            restoreName()
            humanoid=h
            oldDisplayType=h.DisplayDistanceType
        end
        if state.enabled then
            pcall(function() h.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end)
        else
            restoreName()
        end
    end

    local function applyStyle()
        if not active or not active.Parent then return end
        local theme=STYLES[state.style]
        ui.TagChip.BackgroundColor3=theme.bright
        ui.TagText.TextColor3=theme.tagText
        ui.AvatarRing.BackgroundColor3=theme.bright
        ui.AvatarRing.UIStroke.Color=theme.bright
        ui.NameStroke.Color=theme.dark
        ui.HealthFill.BackgroundColor3=theme.bright
        ui.BorderStroke.Color=theme.bright
        ui.BorderGradient.Color=sequence(theme.bright,theme.dark)
        ui.Fallback.BackgroundColor3=theme.background
        ui.Fallback.UIStroke.Color=theme.bright
        ui.Fallback.UIGradient.Color=sequence(
            Color3.fromRGB(13,13,17),theme.background)
        ui.Shell.Visible=state.style=="Crimson" and ui.Shell.Image~=""
        ui.Fallback.Visible=not ui.Shell.Visible
        ui.StatusLine.TextColor3=theme.status
        ui.NameOnly.TextColor3=WHITE
    end

    local function applyText()
        if not active or not active.Parent then return end
        ui.DisplayName.Text=player.DisplayName
        local differs=string.lower(player.DisplayName)~=string.lower(player.Name)
        local showRealUsername=differs and state.showUsername
        ui.StatusLine.Text=showRealUsername and ("@"..player.Name) or
            (state.subtitle~="" and state.subtitle or "VANTA // MEMBER")
        ui.TagText.Text=state.tag~="" and state.tag or "VANTA"
        ui.NameOnly.Text=player.DisplayName
    end

    local function updateScale()
        if not active or not active.Parent then return end
        active.Size=UDim2.fromOffset(math.floor(288*state.size),math.floor(108*state.size))
        active.MaxDistance=state.maxDistance
        active.StudsOffsetWorldSpace=Vector3.new(0,state.height,0)
        ui.PlateScale.Scale=state.size*(1-0.16*fade)
        ui.NameOnly.Size=UDim2.fromOffset(245*state.size,28*state.size)
    end

    local function updateHealth(value)
        if not active or not active.Parent or not humanoid then return end
        local max=math.max(1,tonumber(humanoid.MaxHealth) or 100)
        local v=math.clamp(tonumber(value) or 0,0,max)
        local percent=v/max
        ui.HealthFill.Size=UDim2.fromScale(percent,1)
        if lastHealth and v<lastHealth-0.01 then
            combatLeft=4
            damageFlash=0.32
        end
        lastHealth=v
    end

    local function destroyPlate()
        if healthConnection then healthConnection:Disconnect();healthConnection=nil end
        if active then active:Destroy();active=nil end
        ui={}
        restoreName()
        lastHealth=nil
        damageFlash=0
        combatLeft=0
    end

    local function loadArt(target, url, onLoad)
        if type(config.LoadRemoteImage)~="function" then return end
        task.spawn(function()
            local ok,asset=pcall(config.LoadRemoteImage,url,"VantaTest")
            if not ok or type(asset)~="string" or asset=="" then return end
            if disposed or not target.Parent then return end
            target.Image=asset
            if onLoad then onLoad() end
        end)
    end

    local function createForCharacter(char)
        local head=char:FindFirstChild("Head") or char:WaitForChild("Head",8)
        if disposed or char~=player.Character or not head then return end
        destroyPlate()
        active=make("BillboardGui",{
            Name=GUI_NAME,Adornee=head,AlwaysOnTop=true,Active=false,
            Enabled=state.enabled,LightInfluence=0,MaxDistance=state.maxDistance,
            Size=UDim2.fromOffset(288,108),
            StudsOffsetWorldSpace=Vector3.new(0,state.height,0),
            ResetOnSpawn=false,
        },rootFolder)
        local plateGroup=make("CanvasGroup",{
            Name="PlateGroup",Size=UDim2.fromOffset(288,108),
            AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
            BackgroundTransparency=1,BorderSizePixel=0,GroupTransparency=0,
            Active=false,
        },active)
        local scale=make("UIScale",{Scale=state.size},plateGroup)
        local glow=make("ImageLabel",{
            Name="CrimsonOuterGlow",BackgroundTransparency=1,Image="",
            Position=UDim2.fromOffset(0,4),Size=UDim2.fromOffset(288,100),
            ScaleType=Enum.ScaleType.Slice,
            SliceCenter=Rect.new(24,24,72,72),SliceScale=1,
            ImageTransparency=0.7,ImageColor3=Color3.fromRGB(255,255,255),
            ZIndex=1,
        },plateGroup)
        local glowFallback=make("Frame",{
            Name="GlowFallback",Position=UDim2.fromOffset(22,19),
            Size=UDim2.fromOffset(248,72),
            BackgroundTransparency=1,BorderSizePixel=0,ZIndex=1,
        },plateGroup)
        round(glowFallback,6)
        outline(glowFallback,STYLES[state.style].bright,4,0.83)

        local plate=make("Frame",{
            Name="Plate",Size=UDim2.fromOffset(248,72),
            Position=UDim2.fromOffset(20,18),
            BackgroundTransparency=1,BorderSizePixel=0,Active=false,
            ZIndex=2,
        },plateGroup)
        local fallback=make("Frame",{
            Name="Fallback",Size=UDim2.fromScale(1,1),
            BackgroundTransparency=0.15,BorderSizePixel=0,
            BackgroundColor3=BLACK,ZIndex=2,
        },plate)
        round(fallback,6)
        local fallbackStroke=outline(fallback,STYLES[state.style].bright,1,0.15)
        local fallbackGrad=make("UIGradient",{
            Rotation=90,Color=sequence(Color3.fromRGB(15,15,20),BLACK),
        },fallback)
        local shell=make("ImageLabel",{
            Name="ChamferShell",Size=UDim2.fromScale(1,1),
            BackgroundTransparency=1,Image="",ImageTransparency=0,
            ScaleType=Enum.ScaleType.Stretch,ZIndex=3,Visible=false,
        },plate)
        local contour=make("Frame",{
            Name="EdgeStrokeHost",Size=UDim2.new(1,-8,1,-8),
            Position=UDim2.fromOffset(4,4),BorderSizePixel=0,
            BackgroundTransparency=1,ZIndex=4,
        },plate)
        round(contour,4)
        local borderStroke=outline(contour,STYLES[state.style].bright,1,0.78)
        local borderGradient=make("UIGradient",{
            Color=sequence(STYLES[state.style].bright,STYLES[state.style].dark),
            Rotation=0,Offset=Vector2.new(0,0),
        },borderStroke)

        local tagChip=make("Frame",{
            Name="TagChip",Position=UDim2.fromOffset(9,6),
            Size=UDim2.fromOffset(94,18),
            BackgroundColor3=STYLES[state.style].bright,
            BackgroundTransparency=0,BorderSizePixel=0,ZIndex=6,
        },plate)
        round(tagChip,2)
        local tagText=label(tagChip,"TagText",state.tag,10,BLACK,true,{
            Position=UDim2.fromOffset(6,0),
            Size=UDim2.new(1,-12,1,0),TextXAlignment=Enum.TextXAlignment.Center,
            ZIndex=7,
        })
        local ring=make("Frame",{
            Name="AvatarRing",Position=UDim2.fromOffset(13,27),
            Size=UDim2.fromOffset(35,35),BackgroundColor3=STYLES[state.style].bright,
            BorderSizePixel=0,ZIndex=6,
        },plate)
        round(ring,18)
        outline(ring,STYLES[state.style].bright,2,0)
        local portrait=make("ImageLabel",{
            Name="Avatar",
            Image=("rbxthumb://type=AvatarHeadShot&id=%d&w=100&h=100"):format(player.UserId),
            Position=UDim2.fromOffset(2,2),
            Size=UDim2.new(1,-4,1,-4),
            BackgroundTransparency=1,ZIndex=7,
        },ring)
        round(portrait,18)
        local statusDot=make("Frame",{
            Name="StatusDot",Position=UDim2.new(1,-6,1,-9),
            Size=UDim2.fromOffset(9,9),
            BorderSizePixel=0,BackgroundColor3=GREEN,ZIndex=9,
        },ring)
        round(statusDot,6)
        outline(statusDot,Color3.fromRGB(8,8,10),1.5,0)
        local title=label(plate,"DisplayName",player.DisplayName,16,WHITE,true,{
            Position=UDim2.fromOffset(60,26),
            Size=UDim2.fromOffset(177,20),ZIndex=8,
        })
        local nameStroke=outline(title,STYLES[state.style].dark,0.6,0.54)
        local subtitle=label(plate,"StatusLine","VANTA // MEMBER",10,
            STYLES[state.style].status,true,{
                Position=UDim2.fromOffset(60,47),
                Size=UDim2.fromOffset(177,15),ZIndex=8,
            })
        local healthBar=make("Frame",{
            Name="HealthBar",Position=UDim2.fromOffset(12,67),
            Size=UDim2.fromOffset(224,2),BackgroundColor3=Color3.fromRGB(55,30,36),
            BackgroundTransparency=0.12,BorderSizePixel=0,ZIndex=7,
        },plate)
        local healthFill=make("Frame",{
            Name="HealthFill",Size=UDim2.fromScale(1,1),
            BorderSizePixel=0,BackgroundColor3=STYLES[state.style].bright,
            BackgroundTransparency=0,ZIndex=8,
        },healthBar)
        local onlyName=label(active,"NameOnly",player.DisplayName,17,WHITE,true,{
            AnchorPoint=Vector2.new(0.5,0.5),
            Position=UDim2.fromScale(0.5,0.50),
            Size=UDim2.fromOffset(245,28),Visible=false,
            TextXAlignment=Enum.TextXAlignment.Center,ZIndex=12,
        })
        outline(onlyName,STYLES[state.style].dark,0.65,0.27)

        ui={
            PlateGroup=plateGroup,PlateScale=scale,Shell=shell,Fallback=fallback,
            Glow=glow,GlowFallback=glowFallback,Plate=plate,
            TagChip=tagChip,TagText=tagText,AvatarRing=ring,
            DisplayName=title,NameStroke=nameStroke,StatusLine=subtitle,
            HealthFill=healthFill,StatusDot=statusDot,BorderStroke=borderStroke,
            BorderGradient=borderGradient,NameOnly=onlyName,
        }
        applyStyle()
        applyText()
        updateScale()
        hideDefault(char)
        local hum=char:FindFirstChildOfClass("Humanoid")
        if hum and hum==humanoid then
            lastHealth=tonumber(hum.Health) or 100
            updateHealth(lastHealth)
            if hum.HealthChanged then
                healthConnection=hum.HealthChanged:Connect(updateHealth)
            end
        end
        loadArt(shell,SHELL_URL,function()
            if active and ui.Shell==shell then applyStyle() end
        end)
        loadArt(glow,GLOW_URL,function()
            if active and ui.Glow==glow then glowFallback.Visible=false end
        end)
    end

    local function mountCharacter(char)
        if disposed then return end
        task.spawn(function()createForCharacter(char)end)
    end

    -- One throttled render listener for distance transition, sweep, idle pulse and damage.
    track(RunService.RenderStepped:Connect(function(dt)
        if disposed or not active or not active.Parent or not state.enabled then return end
        accumulator=accumulator+math.min(tonumber(dt) or 1/60,0.08)
        if accumulator<1/24 then return end
        local step=accumulator
        accumulator=0
        clock=clock+step
        combatLeft=math.max(0,combatLeft-step)
        damageFlash=math.max(0,damageFlash-step)

        local distance=0
        local ok,result=pcall(function()
            local cam=workspace.CurrentCamera
            return (cam.CFrame.Position-active.Adornee.Position).Magnitude
        end)
        if ok and type(result)=="number" then distance=result end
        lastDistance=distance
        -- Shrink and fade the plate from 40 to 65 studs, leaving the white name.
        local nextFade=math.clamp((distance-40)/25,0,1)
        if math.abs(nextFade-fade)>0.002 then
            fade=nextFade
            ui.PlateGroup.GroupTransparency=fade
            ui.PlateScale.Scale=state.size*(1-0.16*fade)
        end
        ui.NameOnly.Visible=fade>0.42
        ui.NameOnly.TextTransparency=math.clamp((1-fade)*1.7,0,1)
        ui.StatusDot.BackgroundColor3=combatLeft>0
            and Color3.fromRGB(255,62,87) or GREEN

        -- The bright pass takes one slow trip along the contour every 4s.
        local sweep=(clock%4)/4
        ui.BorderGradient.Offset=Vector2.new(-1+2*sweep,0)
        local wave=0.5+0.5*math.sin(clock*2.0)
        local flicker=damageFlash>0 and ((math.floor(clock*45)%2==0) and 0.18 or 0) or 0
        ui.Glow.ImageTransparency=math.clamp(0.73-0.09*wave-flicker,0.37,0.85)
        ui.GlowFallback.UIStroke.Transparency=math.clamp(0.91-0.07*wave-flicker,0.42,0.96)
        ui.BorderStroke.Transparency=math.clamp(0.74-0.16*wave-flicker,0.26,0.87)
        if state.style=="Crimson" and ui.Shell.Image~="" then
            ui.Shell.ImageTransparency=flicker
        end
    end))

    function controller:SetEnabled(v)
        if disposed then return end
        state.enabled=not not v
        if active then active.Enabled=state.enabled end
        if state.enabled and player.Character then
            hideDefault(player.Character)
        else
            restoreName()
        end
    end
    function controller:SetStyle(value)
        if disposed or not STYLES[value] then return end
        state.style=value
        applyStyle()
    end
    function controller:SetTag(value)
        if disposed then return end
        state.tag=cleanText(value,18)
        applyText()
    end
    function controller:SetSubtitle(value)
        if disposed then return end
        state.subtitle=cleanText(value,30)
        applyText()
    end
    function controller:SetShowUsername(v)
        if disposed then return end
        state.showUsername=not not v
        applyText()
    end
    function controller:SetScale(value)
        if disposed then return end
        state.size=math.clamp(tonumber(value) or 100,70,140)/100
        updateScale()
    end
    function controller:SetDistance(value)
        if disposed then return end
        state.maxDistance=math.clamp(tonumber(value) or 100,30,150)
        updateScale()
    end
    function controller:SetHeight(value)
        if disposed then return end
        state.height=math.clamp(tonumber(value) or 2.65,1.5,4.5)
        updateScale()
    end
    function controller:GetBillboard()
        return active
    end
    function controller:Destroy()
        if disposed then return end
        disposed=true
        for _,conn in ipairs(connections) do conn:Disconnect() end
        destroyPlate()
        if lifecycle.Parent then lifecycle:Destroy() end
    end

    track(lifecycle.Destroying:Connect(function()
        controller:Destroy()
    end))
    track(player.CharacterAdded:Connect(mountCharacter))
    track(player.CharacterRemoving:Connect(function(char)
        if active and active.Adornee and active.Adornee:IsDescendantOf(char) then
            destroyPlate()
        end
    end))
    if player.Character then mountCharacter(player.Character) end
    return controller
end

return Nameplate
