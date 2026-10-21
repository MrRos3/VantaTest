-- Vanta Chat LAB companion launcher (VantaTest only)
-- No Roblox TextChatService calls, no client-to-client unfiltered chat relay.
-- User-owned SaltyIcons asset IDs from MrRos3/SaltyIcons roblox/Icons.lua.
local Chat = {}
local SITE = "https://vanta-chat-lab.onrender.com"
local COLORS = {
    bg = Color3.fromRGB(15, 12, 16),
    panel = Color3.fromRGB(30, 23, 29),
    card = Color3.fromRGB(38, 29, 36),
    crimson = Color3.fromRGB(150, 50, 80),
    white = Color3.fromRGB(245, 238, 243),
    muted = Color3.fromRGB(181, 157, 170),
}
local ICONS = {
    chat = "rbxassetid://126050900811446",
    send = "rbxassetid://104783825572790",
    copy = "rbxassetid://103363146431717",
    lock = "rbxassetid://75617874061550",
}

local function new(class, attributes, parent)
    local instance=Instance.new(class)
    for key,value in pairs(attributes or {}) do
        instance[key]=value
    end
    instance.Parent=parent
    return instance
end

local function round(parent, radius)
    new("UICorner",{CornerRadius=UDim.new(0,radius)},parent)
end

local function text(parent, label, size, bold, color, attrs)
    local values = {
        BackgroundTransparency=1,Text=label,TextSize=size,
        Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextColor3=color or COLORS.white,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Center,
        TextWrapped=false,TextTruncate=Enum.TextTruncate.AtEnd,
    }
    for key,value in pairs(attrs or {}) do values[key]=value end
    return new("TextLabel",values,parent)
end

local function pic(parent, image, size, attrs)
    local values={
        BackgroundTransparency=1,Image=image,ImageColor3=COLORS.white,
        Size=UDim2.fromOffset(size,size),ScaleType=Enum.ScaleType.Fit,
    }
    for key,value in pairs(attrs or {}) do values[key]=value end
    return new("ImageLabel",values,parent)
end

function Chat.Mount(tab)
    local holder=assert(tab.UIElements and tab.UIElements.ContainerFrame,"Vanta Chat container is missing")
    local existing=holder:FindFirstChild("VantaChatExperiment")
    if existing then existing:Destroy() end

    local padding=holder:FindFirstChildOfClass("UIPadding")
    if padding then
        padding.PaddingTop=UDim.new(0,5)
        padding.PaddingBottom=UDim.new(0,5)
        padding.PaddingLeft=UDim.new(0,5)
        padding.PaddingRight=UDim.new(0,5)
    end

    local root=new("Frame",{
        Name="VantaChatExperiment",LayoutOrder=1,
        Size=UDim2.new(1,0,0,405),
        BackgroundColor3=COLORS.bg,BackgroundTransparency=0.06,
        BorderSizePixel=0,ClipsDescendants=true,
    },holder)
    round(root,15)
    new("UIStroke",{Color=Color3.fromRGB(83,51,65),Thickness=1,Transparency=0.35},root)

    text(root,"Vanta Chat",20,true,COLORS.white,{
        Position=UDim2.fromOffset(17,11),Size=UDim2.new(1,-35,0,28),
    })
    text(root,"Independent worldwide chat · no Roblox game-chat restrictions",10,false,COLORS.muted,{
        Position=UDim2.fromOffset(17,40),Size=UDim2.new(1,-35,0,20),
    })

    local header=new("Frame",{
        Position=UDim2.fromOffset(12,71),Size=UDim2.new(1,-24,0,75),
        BackgroundColor3=COLORS.panel,BorderSizePixel=0,
    },root)
    round(header,12)
    local square=new("Frame",{
        Position=UDim2.fromOffset(12,14),Size=UDim2.fromOffset(45,45),
        BackgroundColor3=COLORS.crimson,BorderSizePixel=0,
    },header)
    round(square,12)
    pic(square,ICONS.chat,26,{
        AnchorPoint=Vector2.new(0.5,0.5),Position=UDim2.fromScale(0.5,0.5),
    })
    text(header,"Vanta Global",14,true,COLORS.white,{
        Position=UDim2.fromOffset(67,13),Size=UDim2.new(1,-88,0,24),
    })
    text(header,"EN / AR  ·  Invite-only beta",11,false,COLORS.muted,{
        Position=UDim2.fromOffset(67,39),Size=UDim2.new(1,-88,0,19),
    })

    local explanation=new("Frame",{
        Position=UDim2.fromOffset(12,158),Size=UDim2.new(1,-24,0,126),
        BackgroundColor3=COLORS.card,BackgroundTransparency=.13,BorderSizePixel=0,
    },root)
    round(explanation,12)
    local smallLock=pic(explanation,ICONS.lock,19,{Position=UDim2.fromOffset(14,16)})
    text(explanation,"A separate chat that actually works globally",12,true,COLORS.white,{
        Position=UDim2.fromOffset(43,11),Size=UDim2.new(1,-57,0,30),
    })
    text(explanation,
        "Messages, replies, reactions, emojis and Arabic/English rooms live\n"
        .. "on the companion website, not in Roblox's public game chat.\n"
        .. "Create your chat account there with a beta invite code.",
        11,false,COLORS.muted,{
            Position=UDim2.fromOffset(15,48),Size=UDim2.new(1,-30,0,67),
            TextWrapped=true,TextYAlignment=Enum.TextYAlignment.Top,
        })

    local copy=new("TextButton",{
        Name="OpenCompanionLink",Text="Copy Vanta Chat link",
        Position=UDim2.new(0,12,1,-107),Size=UDim2.new(1,-24,0,50),
        BackgroundColor3=Color3.fromRGB(117,40,63),BorderSizePixel=0,
        TextColor3=COLORS.white,Font=Enum.Font.GothamBold,
        TextSize=13,AutoButtonColor=true,
    },root)
    round(copy,14)
    pic(copy,ICONS.copy,20,{
        AnchorPoint=Vector2.new(0,0.5),Position=UDim2.new(0,15,0.5,0),
    })
    local status=text(root,"Open the link in your browser to join the live rooms.",11,false,COLORS.muted,{
        Position=UDim2.new(0,15,1,-48),Size=UDim2.new(1,-30,0,38),
        TextWrapped=true,
    })

    copy.MouseButton1Click:Connect(function()
        local clipboard=setclipboard or toclipboard
        if type(clipboard)=="function" then
            local ok=pcall(clipboard,SITE)
            status.Text=ok and "Link copied! Paste it into your browser. 🤍"
                or "Clipboard unavailable. URL: "..SITE
        else
            status.Text="Open this link in your browser: "..SITE
        end
        print("[VantaTest Chat] "..SITE)
    end)

    return root
end

return Chat
