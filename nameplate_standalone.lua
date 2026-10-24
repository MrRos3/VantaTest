-- Standalone Vanta Edge LocalScript. Place in StarterPlayerScripts or execute as Lua.
-- No external images or modules. Return the controller to executor callers.
-- Vanta Edge overhead nameplates. Self-contained Roblox LocalScript module.
-- All art uses native Roblox UI; ONLY headshots use GetUserThumbnailAsync.
-- Client-only: visible to THIS client for every player, not replicated.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local LocalPlayer = assert(Players.LocalPlayer, "Vanta Edge requires a client")

local CONFIG = {
    Tag = "VANTA", Subtitle = "MEMBER",
    Width = 230, Height = 64, Scale = 100,
    Fill = Color3.fromRGB(14,14,16), FillTransparency = 0.15,
    Crimson = Color3.fromRGB(224,23,61),
    CrimsonDark = Color3.fromRGB(74,10,24),
    BrightRing = Color3.fromRGB(255,42,77),
    GlowTransparency = 0.89,
    IdleDot = Color3.fromRGB(72,211,125),
    CombatDot = Color3.fromRGB(255,73,84),
    MaxDistance = 60, FadeStart = 40,
    Offset = Vector3.new(0,2.5,0),
    NameSize = 16, SubtitleSize = 11, TagSize = 10,
    ShowUsername = false, HealthBar = true,
}
local STYLES = {
    Crimson = {main = CONFIG.Crimson, dark = CONFIG.CrimsonDark},
    OLED = {main = Color3.fromRGB(196,40,72),dark=Color3.fromRGB(63,15,27)},
    Steel = {main = Color3.fromRGB(169,185,206),dark=Color3.fromRGB(49,58,73)},
}
local ROOT = "VantaTestNameplateLifecycle"
local BILLBOARD = "VantaEdgeNameplate"
local module = {}

local function make(class, props, parent)
    local obj = Instance.new(class)
    for k,v in pairs(props or {}) do obj[k]=v end
    if parent then obj.Parent=parent end
    return obj
end
local function round(parent, radius)
    return make("UICorner",{CornerRadius=UDim.new(0,radius)},parent)
end
local function outline(parent,color,thickness,transparency)
    return make("UIStroke",{
        Color=color,Thickness=thickness or 1,Transparency=transparency or 0,
    },parent)
end
local function text(parent,name,stringValue,size,color,bold,props)
    local args={
        Name=name,Text=tostring(stringValue or ""),Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextSize=size,TextColor3=color,TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Center,TextTruncate=Enum.TextTruncate.AtEnd,
        BackgroundTransparency=1,BorderSizePixel=0,
    }
    for k,v in pairs(props or {}) do args[k]=v end
    return make("TextLabel",args,parent)
end
local function trim(value,limit)
    local s=tostring(value or ""):gsub("[%c]"," "):match("^%s*(.-)%s*$") or ""
    local ok,index=pcall(utf8.offset,s,limit+1)
    if not ok then return "" end
    if index then return s:sub(1,index-1) end
    return s
end
local function gradient(a,b)
    return ColorSequence.new({
        ColorSequenceKeypoint.new(0,a),ColorSequenceKeypoint.new(1,b),
    })
end

function module.new(opts)
    local options=opts or {}
    local scripts=LocalPlayer:WaitForChild("PlayerScripts")
    local previous=scripts:FindFirstChild(ROOT)
    if previous then previous:Destroy() end
    -- Clean old build, which incorrectly put the lifecycle under resettable PlayerGui.
    local playerGui=LocalPlayer:WaitForChild("PlayerGui")
    local legacy=playerGui:FindFirstChild(ROOT)
    if legacy then legacy:Destroy() end
    local lifecycle=make("Folder",{Name=ROOT},scripts)

    local state={
        enabled=options.Enabled~=false,
        tag=trim(options.Tag or CONFIG.Tag,18),
        subtitle=trim(options.Subtitle or CONFIG.Subtitle,30),
        style=STYLES[options.Style] and options.Style or "Crimson",
        scale=math.clamp(tonumber(options.Scale) or CONFIG.Scale,70,140)/100,
        maxDistance=math.clamp(tonumber(options.MaxDistance) or CONFIG.MaxDistance,30,150),
        height=math.clamp(tonumber(options.Height) or 2.5,1.5,4.5),
        showUsername=options.ShowUsername==true,
    }
    local records={}
    local connections={}
    local stopped=false
    local elapsed=0
    local accumulator=0
    local api={}

    local function track(conn)
        connections[#connections+1]=conn
        return conn
    end
    local function removeCharacter(record)
        record.serial=record.serial+1
        if record.healthSignal then record.healthSignal:Disconnect();record.healthSignal=nil end
        if record.tween then record.tween:Cancel();record.tween=nil end
        if record.billboard then record.billboard:Destroy();record.billboard=nil end
        if record.humanoid and record.originalNameDistance and record.humanoid.Parent then
            pcall(function()
                record.humanoid.DisplayDistanceType=record.originalNameDistance
            end)
        end
        record.humanoid=nil
        record.originalNameDistance=nil
        record.ui=nil
    end
    local function labelTextFor(p)
        local same=string.lower(p.DisplayName)==string.lower(p.Name)
        if state.showUsername and not same then
            return "@"..p.Name
        end
        return state.subtitle~="" and state.subtitle or CONFIG.Subtitle
    end
    local function applyLook(record)
        local ui=record.ui
        if not ui then return end
        local style=STYLES[state.style]
        ui.Tag.BackgroundColor3=style.main
        ui.TagText.Text=state.tag~="" and state.tag or CONFIG.Tag
        local ok,length=pcall(utf8.len,ui.TagText.Text)
        ui.Tag.Size=UDim2.fromOffset(math.clamp((ok and length or #ui.TagText.Text)*7+18,64,155),15)
        ui.AvatarRing.BackgroundColor3=CONFIG.BrightRing
        ui.AvatarRing.UIStroke.Color=CONFIG.BrightRing
        ui.BarFill.BackgroundColor3=style.main
        ui.Subtitle.TextColor3=style.main
        ui.Border.Color=style.main
        ui.BorderGradient.Color=gradient(style.main,style.dark)
        ui.FallbackGlow.UIStroke.Color=style.main
        ui.Name.Text=record.player.DisplayName
        ui.DistanceName.Text=record.player.DisplayName
        ui.Subtitle.Text=labelTextFor(record.player)
        ui.BarBack.Visible=CONFIG.HealthBar
    end

    local function setGeometry(record)
        local ui=record.ui
        if not ui then return end
        record.billboard.Size=UDim2.fromOffset(math.floor(246*state.scale),math.floor(80*state.scale))
        record.billboard.StudsOffsetWorldSpace=Vector3.new(0,state.height,0)
        record.billboard.MaxDistance=state.maxDistance
        ui.Scale.Scale=state.scale
        ui.DistanceName.TextSize=17*state.scale
    end
    local function updateHealth(record,value)
        if not record.ui or not record.humanoid then return end
        local max=math.max(1,tonumber(record.humanoid.MaxHealth) or 100)
        local hp=math.clamp(tonumber(value) or 0,0,max)
        record.ui.BarFill.Size=UDim2.fromScale(hp/max,1)
        if record.previousHealth and hp<record.previousHealth-0.01 then
            record.combat=3.5
            record.flash=0.22
        end
        record.previousHealth=hp
    end
    local function createPlate(record,character,head,humanoid,version)
        if stopped or records[record.player]~=record or record.serial~=version
            or record.player.Character~=character then return end
        removeCharacter(record)
        local thisSerial=record.serial
        record.humanoid=humanoid
        record.originalNameDistance=humanoid.DisplayDistanceType
        if state.enabled then
            pcall(function()humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None end)
        end
        local gui=make("BillboardGui",{
            Name=BILLBOARD,Adornee=head,AlwaysOnTop=true,Active=false,Enabled=state.enabled,
            ResetOnSpawn=false,LightInfluence=0,Size=UDim2.fromOffset(246,80),
            MaxDistance=state.maxDistance,
            StudsOffsetWorldSpace=Vector3.new(0,state.height,0),
        },LocalPlayer:WaitForChild("PlayerGui"))
        record.billboard=gui
        local far=text(gui,"DistanceName",record.player.DisplayName,17,Color3.fromRGB(255,255,255),true,{
            AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.49),
            Size=UDim2.fromOffset(230,26),Visible=false,
            TextXAlignment=Enum.TextXAlignment.Center,
            TextStrokeColor3=CONFIG.Fill,TextStrokeTransparency=0.25,
            ZIndex=11,
        })

        local group=make("CanvasGroup",{
            Name="PlateGroup",Size=UDim2.fromOffset(246,80),
            AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
            BackgroundTransparency=1,BorderSizePixel=0,GroupTransparency=0,
            Active=false,
        },gui)
        local groupScale=make("UIScale",{Scale=1},group)

        -- A soft native 2-layer red halo. No external image asset required.
        local halo=make("Frame",{
            Name="SoftGlow",Position=UDim2.fromOffset(10,8),
            Size=UDim2.fromOffset(226,68),BackgroundTransparency=1,BorderSizePixel=0,
            ZIndex=1,
        },group)
        round(halo,8)
        local outer=outline(halo,CONFIG.Crimson,6,CONFIG.GlowTransparency)
        local inner=outline(make("Frame",{
            Size=UDim2.new(1,-3,1,-3),Position=UDim2.fromOffset(1,1),
            BackgroundTransparency=1,BorderSizePixel=0,
        },halo),CONFIG.Crimson,3,0.83)

        local plate=make("Frame",{
            Name="Plate",Position=UDim2.fromOffset(8,8),
            Size=UDim2.fromOffset(CONFIG.Width,CONFIG.Height),
            BackgroundColor3=CONFIG.Fill,BackgroundTransparency=CONFIG.FillTransparency,
            BorderSizePixel=0,Active=false,ZIndex=2,
        },group)
        -- Native UICorner approximation for the chamfered silhouette, no PNG.
        round(plate,5)
        local fillShade=make("UIGradient",{
            Rotation=90,Color=gradient(Color3.fromRGB(21,20,24),CONFIG.Fill),
        },plate)
        local contour=outline(plate,CONFIG.Crimson,1,0)
        local contourGradient=make("UIGradient",{
            Color=gradient(CONFIG.Crimson,CONFIG.CrimsonDark),
            Rotation=0,Offset=Vector2.new(-1,0),
        },contour)
        local sweep=TweenService:Create(contourGradient,
            TweenInfo.new(4,Enum.EasingStyle.Linear,Enum.EasingDirection.Out,-1,false),
            {Offset=Vector2.new(1,0)})
        sweep:Play()
        record.tween=sweep

        local tag=make("Frame",{
            Name="TagChip",Size=UDim2.fromOffset(64,15),
            Position=UDim2.fromOffset(4,4),BackgroundColor3=CONFIG.Crimson,
            BorderSizePixel=0,ZIndex=5,
        },plate)
        round(tag,2)
        local tagLabel=text(tag,"TagText",state.tag,CONFIG.TagSize,CONFIG.Fill,true,{
            Position=UDim2.fromOffset(7,0),
            Size=UDim2.new(1,-12,1,0),ZIndex=6,
        })
        local avatarRing=make("Frame",{
            Name="AvatarRing",Size=UDim2.fromOffset(40,40),
            Position=UDim2.fromOffset(8,19),
            BackgroundColor3=CONFIG.BrightRing,BorderSizePixel=0,ZIndex=5,
        },plate)
        round(avatarRing,21)
        outline(avatarRing,CONFIG.BrightRing,2,0)
        local inset=make("Frame",{
            Name="BlackInset",Size=UDim2.new(1,-4,1,-4),
            Position=UDim2.fromOffset(2,2),BackgroundColor3=CONFIG.Fill,
            BorderSizePixel=0,ZIndex=6,
        },avatarRing)
        round(inset,19)
        local portrait=make("ImageLabel",{
            Name="Avatar",Position=UDim2.fromOffset(4,4),
            Size=UDim2.new(1,-8,1,-8),
            BackgroundTransparency=1,Image="",ZIndex=7,
        },avatarRing)
        round(portrait,17)
        text(avatarRing,"AvatarFallback",record.player.DisplayName:sub(1,1),16,
            Color3.fromRGB(255,255,255),true,{
            Position=UDim2.fromOffset(11,10),Size=UDim2.fromOffset(17,18),
            TextXAlignment=Enum.TextXAlignment.Center,ZIndex=6,
        })
        local dot=make("Frame",{
            Name="StatusDot",Size=UDim2.fromOffset(10,10),
            Position=UDim2.new(1,-3,1,-7),
            BackgroundColor3=CONFIG.IdleDot,BorderSizePixel=0,ZIndex=9,
        },avatarRing)
        round(dot,6)
        outline(dot,CONFIG.Fill,1,0)

        local name=text(plate,"DisplayName",record.player.DisplayName,CONFIG.NameSize,
            Color3.fromRGB(255,255,255),true,{
            Position=UDim2.fromOffset(56,23),Size=UDim2.fromOffset(167,20),
            TextStrokeColor3=CONFIG.Fill,TextStrokeTransparency=0.24,ZIndex=7,
        })
        local subtitle=text(plate,"StatusLine",state.subtitle,CONFIG.SubtitleSize,
            CONFIG.Crimson,true,{
            Position=UDim2.fromOffset(56,42),Size=UDim2.fromOffset(166,17),
            TextTransparency=0.3,ZIndex=7,
        })
        local hpBackground=make("Frame",{
            Name="HealthBar",Position=UDim2.fromOffset(56,60),
            Size=UDim2.fromOffset(167,2),
            BackgroundColor3=Color3.fromRGB(58,32,40),
            BackgroundTransparency=0.25,BorderSizePixel=0,ZIndex=7,
        },plate)
        local hpFill=make("Frame",{
            Name="HealthFill",Size=UDim2.fromScale(1,1),
            BackgroundColor3=CONFIG.Crimson,BorderSizePixel=0,ZIndex=8,
        },hpBackground)
        record.ui={
            PlateGroup=group,Scale=groupScale,Plate=plate,Name=name,
            DistanceName=far,Tag=tag,TagText=tagLabel,
            AvatarRing=avatarRing,Avatar=portrait,Dot=dot,
            Subtitle=subtitle,BarBack=hpBackground,BarFill=hpFill,
            Border=contour,BorderGradient=contourGradient,
            FallbackGlow=halo,GlowStroke=outer,GlowInner=inner,
        }
        record.combat=0
        record.flash=0
        record.previousHealth=tonumber(humanoid.Health) or 100
        applyLook(record)
        setGeometry(record)
        updateHealth(record,record.previousHealth)
        if humanoid.HealthChanged then
            record.healthSignal=humanoid.HealthChanged:Connect(function(v)
                if stopped or record.serial~=thisSerial then return end
                updateHealth(record,v)
            end)
        end

        task.spawn(function()
            local ok,uri=pcall(function()
                return Players:GetUserThumbnailAsync(
                    record.player.UserId,Enum.ThumbnailType.HeadShot,Enum.ThumbnailSize.Size100x100)
            end)
            if ok and type(uri)=="string" and record.billboard==gui and
                record.serial==thisSerial and portrait.Parent then portrait.Image=uri end
        end)
    end

    local function attach(record,character)
        if stopped then return end
        removeCharacter(record)
        local version=record.serial
        task.spawn(function()
            local head=character:FindFirstChild("Head") or character:WaitForChild("Head",12)
            local human=character:FindFirstChildOfClass("Humanoid") or character:WaitForChild("Humanoid",12)
            if head and human then createPlate(record,character,head,human,version) end
        end)
    end
    local function unbind(p)
        local record=records[p]
        if not record then return end
        records[p]=nil
        for _,conn in ipairs(record.connections) do conn:Disconnect() end
        removeCharacter(record)
    end
    local function bind(p)
        if records[p] then return end
        local record={
            player=p,serial=0,connections={},billboard=nil,
            originalNameDistance=nil,previousHealth=nil,combat=0,flash=0,
        }
        records[p]=record
        record.connections[#record.connections+1]=p.CharacterAdded:Connect(function(char)
            attach(record,char)
        end)
        record.connections[#record.connections+1]=p.CharacterRemoving:Connect(function(char)
            if record.billboard and record.billboard.Adornee and
                record.billboard.Adornee:IsDescendantOf(char) then
                removeCharacter(record)
            else
                record.serial=record.serial+1
            end
        end)
        if p.Character then attach(record,p.Character) end
    end

    track(Players.PlayerAdded:Connect(bind))
    track(Players.PlayerRemoving:Connect(unbind))
    -- Bind newly joined players too, even during initial enumeration.
    for _,p in ipairs(Players:GetPlayers()) do bind(p) end

    track(RunService.RenderStepped:Connect(function(dt)
        if stopped or not state.enabled then return end
        accumulator=accumulator+math.min(tonumber(dt) or 1/60,0.075)
        if accumulator<1/24 then return end
        local delta=accumulator
        accumulator=0
        elapsed=elapsed+delta
        local camera=workspace.CurrentCamera
        for _,record in pairs(records) do
            local ui=record.ui
            if ui and record.billboard and record.billboard.Parent then
                record.combat=math.max(0,record.combat-delta)
                record.flash=math.max(0,record.flash-delta)
                local dist=0
                if camera and record.billboard.Adornee then
                    local success,result=pcall(function()
                        return (camera.CFrame.Position-record.billboard.Adornee.Position).Magnitude
                    end)
                    if success and type(result)=="number" then dist=result end
                end
                local faded=math.clamp((dist-CONFIG.FadeStart)/20,0,1)
                ui.PlateGroup.GroupTransparency=faded
                ui.Scale.Scale=state.scale*(1-0.16*faded)
                ui.DistanceName.Visible=faded>0.48
                ui.DistanceName.TextTransparency=math.clamp(2*(1-faded),0,1)
                ui.Dot.BackgroundColor3=record.combat>0 and CONFIG.CombatDot or CONFIG.IdleDot
                local pulse=0.5+0.5*math.sin(elapsed*1.9)
                local flicker=record.flash>0 and ((math.floor(elapsed*45)%2)==0 and 0.11 or 0) or 0
                ui.GlowStroke.Transparency=math.clamp(CONFIG.GlowTransparency-0.05*pulse-flicker,0.55,0.96)
                ui.GlowInner.Transparency=math.clamp(0.92-0.035*pulse-flicker,0.6,0.97)
                ui.Plate.BackgroundTransparency=math.clamp(CONFIG.FillTransparency+flicker,0,0.45)
            end
        end
    end))

    function api:SetEnabled(flag)
        if stopped then return end
        state.enabled=not not flag
        for _,record in pairs(records) do
            if record.billboard then record.billboard.Enabled=state.enabled end
            if record.humanoid and record.humanoid.Parent then
                if state.enabled then
                    pcall(function()
                        record.humanoid.DisplayDistanceType=Enum.HumanoidDisplayDistanceType.None
                    end)
                elseif record.originalNameDistance then
                    pcall(function()
                        record.humanoid.DisplayDistanceType=record.originalNameDistance
                    end)
                end
            end
        end
    end
    function api:IsEnabled() return not stopped and state.enabled end
    function api:SetTag(v)
        if stopped then return end
        state.tag=trim(v,18)
        for _,record in pairs(records) do applyLook(record) end
    end
    function api:SetSubtitle(v)
        if stopped then return end
        state.subtitle=trim(v,30)
        for _,record in pairs(records) do applyLook(record) end
    end
    function api:SetStyle(v)
        if stopped or not STYLES[v] then return end
        state.style=v
        for _,record in pairs(records) do applyLook(record) end
    end
    function api:SetScale(v)
        if stopped then return end
        state.scale=math.clamp(tonumber(v) or 100,70,140)/100
        for _,record in pairs(records) do setGeometry(record) end
    end
    function api:SetDistance(v)
        if stopped then return end
        state.maxDistance=math.clamp(tonumber(v) or CONFIG.MaxDistance,30,150)
        for _,record in pairs(records) do setGeometry(record) end
    end
    function api:SetHeight(v)
        if stopped then return end
        state.height=math.clamp(tonumber(v) or 2.5,1.5,4.5)
        for _,record in pairs(records) do setGeometry(record) end
    end
    function api:SetShowUsername(v)
        if stopped then return end
        state.showUsername=not not v
        for _,record in pairs(records) do applyLook(record) end
    end
    function api:GetBillboard(p)
        local record=records[p or LocalPlayer]
        return record and record.billboard or nil
    end
    function api:Destroy()
        if stopped then return end
        stopped=true
        for _,conn in ipairs(connections) do conn:Disconnect() end
        for p in pairs(records) do unbind(p) end
        if lifecycle.Parent then lifecycle:Destroy() end
    end
    track(lifecycle.Destroying:Connect(function()api:Destroy()end))
    return api
end

return module.new()
