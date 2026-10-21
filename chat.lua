-- VantaTest Chat: Pulse-inspired in-window interface, visual revision 1.0.
-- The original Pulse screenshot supplied the visual reference, NOT source code or transport.
-- Every image icon below uses uploaded MrRos3/SaltyIcons Roblox asset IDs.
-- Messages use Roblox TextChatService only. Install roblox-chat/Server.server.lua in your experience.
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ContentProvider = game:GetService("ContentProvider")
local TextService = game:GetService("TextService")
local LocalPlayer = Players.LocalPlayer

local Chat = {}
local P = {
    bg=Color3.fromRGB(19,16,16),
    panel=Color3.fromRGB(29,24,22),
    panel2=Color3.fromRGB(35,29,27),
    bubble=Color3.fromRGB(45,39,36),
    own=Color3.fromRGB(47,40,36),
    stroke=Color3.fromRGB(76,62,54),
    orange=Color3.fromRGB(229,106,25),
    orangeDeep=Color3.fromRGB(153,62,18),
    pale=Color3.fromRGB(240,237,233),
    dim=Color3.fromRGB(162,153,146),
    mint=Color3.fromRGB(87,209,153),
    gold=Color3.fromRGB(247,190,57),
}
local ICON = {
    chat="rbxassetid://110915451876713",
    send="rbxassetid://104783825572790",
    attach="rbxassetid://98782810652239",
    heart="rbxassetid://80686764701725",
    like="rbxassetid://75110458023624",
    reply="rbxassetid://70778094695584",
    copy="rbxassetid://103363146431717",
    more="rbxassetid://138158933921955",
    remove="rbxassetid://71091959578714",
    user="rbxassetid://108864475481601",
    x="rbxassetid://104564513546348",
    mention="rbxassetid://125917586170394",
    down="rbxassetid://93700951703515",
}
local BUILD="PULSE STYLE 1.1"
local LIMIT=150
local EMOJI={"😀","😂","😍","🥹","😭","❤️","🖤","🌹","🔥","👍","👀","✨","😎","💀","💋","🙏"}

local function inst(class,props,parent)
    local obj=Instance.new(class)
    for k,v in pairs(props or {}) do obj[k]=v end
    if obj:IsA("GuiObject") and not (props and props.ZIndex) then
        obj.ZIndex=parent and parent:IsA("GuiObject") and parent.ZIndex+1 or 1
    end
    if parent then obj.Parent=parent end
    return obj
end
local function corner(parent,r)
    return inst("UICorner",{CornerRadius=UDim.new(0,r)},parent)
end
local function stroke(parent,c,transparency)
    return inst("UIStroke",{Color=c or P.stroke,Transparency=transparency or 0,Thickness=1},parent)
end
local function text(parent,value,size,color,strong,props)
    local t={
        BackgroundTransparency=1,BorderSizePixel=0,
        Text=tostring(value or ""),TextSize=size or 12,
        TextColor3=color or P.pale,
        Font=strong and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Center,
        TextTruncate=Enum.TextTruncate.AtEnd,
    }
    for k,v in pairs(props or {}) do t[k]=v end
    return inst("TextLabel",t,parent)
end
local function image(parent,key,size,props)
    local t={
        Name="SaltyIcon_"..key,
        Image=assert(ICON[key],"Missing SaltyIcons asset "..key),
        BackgroundTransparency=1,
        ImageColor3=P.pale,Size=UDim2.fromOffset(size,size),
        ScaleType=Enum.ScaleType.Fit,
    }
    for k,v in pairs(props or {}) do t[k]=v end
    local icon=inst("ImageLabel",t,parent)
    -- Published SaltyIcons IDs include Decals. A Decal ID can fail as a texture.
    -- rbxthumb resolves that same asset, not a replacement or handmade icon.
    local fallback
    local triedThumbnail=false
    local function useThumbnail()
        if not icon.Parent or icon.IsLoaded or triedThumbnail then return end
        triedThumbnail=true
        icon.Image="rbxthumb://type=Asset&id="..ICON[key]:match("%d+").."&w=150&h=150"
    end
    task.delay(5,useThumbnail)
    task.spawn(function()
        local ok=pcall(function() ContentProvider:PreloadAsync({icon}) end)
        if not icon.Parent then return end
        if not ok or not icon.IsLoaded then
            useThumbnail()
            pcall(function() ContentProvider:PreloadAsync({icon}) end)
        end
        if not icon.Parent or icon.IsLoaded then return end
        icon.Visible=false
        fallback=text(parent,key=="send" and "Send" or key,9,P.dim,true,{
            Position=icon.Position,Size=icon.Size,ZIndex=icon.ZIndex,
            TextScaled=true,TextXAlignment=Enum.TextXAlignment.Center,
        })
        warn("[VantaTest] SaltyIcons asset unavailable: "..key.." "..ICON[key])
    end)
    task.delay(12,function()
        if icon.Parent and not icon.IsLoaded and not fallback then
            icon.Visible=false
            fallback=text(parent,key=="send" and "Send" or key,9,P.dim,true,{
                Position=icon.Position,Size=icon.Size,ZIndex=icon.ZIndex,TextScaled=true,
                TextXAlignment=Enum.TextXAlignment.Center,
            })
        end
    end)
    icon:GetPropertyChangedSignal("IsLoaded"):Connect(function()
        if icon.IsLoaded then icon.Visible=true;if fallback then fallback:Destroy();fallback=nil end end
    end)
    return icon
end
local function click(parent,name,sz,props)
    local t={
        Name=name,Text="",BackgroundTransparency=1,
        BorderSizePixel=0,AutoButtonColor=true,
        TextColor3=P.pale,Font=Enum.Font.GothamBold,TextSize=11,
        Size=sz,
    }
    for k,v in pairs(props or {}) do t[k]=v end
    return inst("TextButton",t,parent)
end
local function bounds(value,fontSize,font,width)
    local ok,b=pcall(function()
        return TextService:GetTextSize(tostring(value),fontSize,font,Vector2.new(math.max(30,width),1500))
    end)
    return ok and b or Vector2.new(95,16)
end
local function timestamp(when)
    local ok,result=pcall(os.date,"%H:%M",when or os.time())
    return ok and result or ""
end
local function avatarURL(userId)
    return ("rbxthumb://type=AvatarHeadShot&id=%d&w=100&h=100"):format(userId)
end

function Chat.Mount(tab,options)
    options=options or {}
    local holder=assert(tab.UIElements and tab.UIElements.ContainerFrame,"Vanta Chat container missing")
    local previous=holder:FindFirstChild("VantaChatExperiment")
    if previous then previous:Destroy() end
    local pad=holder:FindFirstChildOfClass("UIPadding")
    if pad then
        pad.PaddingTop=UDim.new(0,4)
        pad.PaddingBottom=UDim.new(0,4)
        pad.PaddingLeft=UDim.new(0,4)
        pad.PaddingRight=UDim.new(0,4)
    end

    local root=inst("Frame",{
        Name="VantaChatExperiment",LayoutOrder=1,
        Size=UDim2.new(1,0,0,405),BorderSizePixel=0,
        BackgroundColor3=P.bg,BackgroundTransparency=0.05,
        ClipsDescendants=true,
    },holder)
    corner(root,16)
    stroke(root,P.stroke,0.38)

    local alive=true
    local connections={}
    local room="EN"
    local activeChannel=nil
    local currentDM=nil
    local sending=false
    local channelFolder=TextChatService:FindFirstChild("TextChannels")
    local nativeWindow=nil
    -- This property is protected on some Roblox rollouts. The owner must configure
    -- the matching attribute in Studio; never try to elevate access to read it.
    local integrated=options.PlatformIntegratedChat
    if integrated==nil then integrated=ReplicatedStorage:GetAttribute("VantaPlatformIntegratedChat")==true end
    pcall(function()
        local state=TextChatService.PlatformIntegratedChat
        if state==Enum.RolloutState.Enabled then integrated=true
        elseif state==Enum.RolloutState.Disabled then integrated=false end
    end)
    local messages={}
    local byId={}
    local serial=0
    local selected=nil
    local replying=nil
    local rowArea=nil
    local render
    local selectRoom
    local function watch(connection)
        connections[#connections+1]=connection
        return connection
    end

    -- Top title matches the compact Pulse hierarchy; don't imitate its online counts.
    text(root,"Chat",19,P.pale,true,{
        Position=UDim2.fromOffset(12,5),Size=UDim2.new(1,-85,0,27),
    })
    text(root,"Roblox chat  ·  "..BUILD,10,P.dim,false,{
        Position=UDim2.fromOffset(12,31),Size=UDim2.new(1,-30,0,15),
    })
    local me=inst("ImageLabel",{
        Name="YourAvatar",Position=UDim2.new(1,-45,0,8),
        Size=UDim2.fromOffset(34,34),BackgroundColor3=P.panel,
        BorderSizePixel=0,Image=avatarURL(LocalPlayer.UserId),
    },root)
    corner(me,18)
    stroke(me,P.orange,0.28)

    -- Pulse-like room bar: icon, name, activity indicator, compact language chips, avatars.
    local top=inst("Frame",{
        Name="ChatRoomHeader",
        Position=UDim2.fromOffset(9,55),Size=UDim2.new(1,-18,0,61),
        BackgroundColor3=P.panel,BackgroundTransparency=0.2,BorderSizePixel=0,
    },root)
    corner(top,14)
    stroke(top,P.stroke,0.43)
    local mark=inst("Frame",{
        BackgroundColor3=P.orangeDeep,BorderSizePixel=0,
        Position=UDim2.fromOffset(10,11),Size=UDim2.fromOffset(36,36),
    },top)
    corner(mark,11)
    inst("UIGradient",{
        Color=ColorSequence.new(P.orange,P.orangeDeep),Rotation=90,
    },mark)
    image(mark,"chat",21,{Position=UDim2.fromOffset(7,7)})
    text(top,"Vanta Chat",13,P.pale,true,{
        Position=UDim2.fromOffset(56,9),Size=UDim2.new(1,-230,0,21),
    })
    local indicator=inst("Frame",{
        Position=UDim2.fromOffset(56,37),Size=UDim2.fromOffset(6,6),
        BackgroundColor3=P.orange,BorderSizePixel=0,
    },top)
    corner(indicator,5)
    local status=text(top,"Setup required",10,P.dim,false,{
        Position=UDim2.fromOffset(68,28),Size=UDim2.new(1,-214,0,21),
    })
    local language=inst("Frame",{
        Name="RoomLanguage",Position=UDim2.new(1,-151,0,14),
        Size=UDim2.fromOffset(89,31),
        BackgroundColor3=P.bg,BackgroundTransparency=0.25,BorderSizePixel=0,
    },top)
    corner(language,17)
    stroke(language,P.stroke,0.5)
    local ar=click(language,"AR",UDim2.fromOffset(43,27),{
        Position=UDim2.fromOffset(2,2),Text="AR",TextSize=10,
        BackgroundTransparency=0,BackgroundColor3=P.panel2,
    })
    corner(ar,14)
    local en=click(language,"EN",UDim2.fromOffset(42,27),{
        Position=UDim2.fromOffset(45,2),Text="EN",TextSize=10,
        BackgroundTransparency=0,BackgroundColor3=P.orange,
    })
    corner(en,14)

    local faces=inst("Frame",{
        Name="CurrentServerAvatars",
        Position=UDim2.new(1,-57,0,14),
        Size=UDim2.fromOffset(52,31),BackgroundTransparency=1,
    },top)
    local function drawFaces()
        if not alive then return end
        for _,v in ipairs(faces:GetChildren()) do
            if v.Name=="LocalServerAvatar" then v:Destroy() end
        end
        -- Actual players in THIS server only; never presented as global chat users.
        for index,user in ipairs(Players:GetPlayers()) do
            if index>3 then break end
            local a=inst("ImageLabel",{
                Name="LocalServerAvatar",Image=avatarURL(user.UserId),
                Position=UDim2.fromOffset((index-1)*11,3),
                Size=UDim2.fromOffset(26,26),
                BackgroundColor3=P.panel2,BorderSizePixel=0,ZIndex=4+index,
            },faces)
            corner(a,14)
            stroke(a,P.stroke,0)
        end
    end

    -- Thin divider, flush scrolling area, more like Pulse than giant purple cards.
    inst("Frame",{
        Name="ChatDivider",
        Position=UDim2.fromOffset(11,121),Size=UDim2.new(1,-22,0,1),
        BackgroundColor3=P.stroke,BackgroundTransparency=0.64,BorderSizePixel=0,
    },root)
    local feed=inst("ScrollingFrame",{
        Name="MessageFeed",Position=UDim2.fromOffset(9,160),
        Size=UDim2.new(1,-18,1,-221),
        BackgroundTransparency=1,BorderSizePixel=0,
        CanvasSize=UDim2.fromOffset(0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollingDirection=Enum.ScrollingDirection.Y,
        ScrollBarThickness=2,ScrollBarImageColor3=P.orange,
        ClipsDescendants=true,
    },root)
    inst("UIPadding",{
        PaddingTop=UDim.new(0,4),PaddingBottom=UDim.new(0,6),
        PaddingLeft=UDim.new(0,3),PaddingRight=UDim.new(0,3),
    },feed)
    local list=inst("UIListLayout",{
        SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,4),
    },feed)

    local jump=click(root,"JumpToLatest",UDim2.fromOffset(27,27),{
        Position=UDim2.new(1,-43,1,-91),
        BackgroundTransparency=0.12,BackgroundColor3=P.orange,
        Visible=false,ZIndex=11,
    })
    corner(jump,14)
    image(jump,"down",15,{Position=UDim2.fromOffset(6,6),ZIndex=12})

    -- Input stays docked at bottom of Chat, not in a separate web window.
    local composer=inst("Frame",{
        Name="Composer",Position=UDim2.new(0,10,1,-56),
        Size=UDim2.new(1,-20,0,48),BackgroundColor3=P.panel,
        BorderSizePixel=0,
    },root)
    corner(composer,24)
    stroke(composer,P.stroke,0.3)
    local attachment=click(composer,"AttachmentHint",UDim2.fromOffset(31,34),{
        Position=UDim2.fromOffset(9,7),
    })
    image(attachment,"attach",18,{
        Position=UDim2.fromOffset(6,8),ImageColor3=P.dim,
    })
    local emoji=click(composer,"EmojiPickerToggle",UDim2.fromOffset(27,32),{
        Position=UDim2.fromOffset(39,8),
    })
    image(emoji,"heart",17,{
        Position=UDim2.fromOffset(5,8),ImageColor3=P.dim,
    })
    local entry=inst("TextBox",{
        Name="ComposerInput",Text="",ClearTextOnFocus=false,MultiLine=false,
        RichText=false,TextEditable=false,
        Position=UDim2.fromOffset(73,2),
        Size=UDim2.new(1,-126,1,-4),
        PlaceholderText="Message in EN...",
        TextColor3=P.pale,PlaceholderColor3=P.dim,
        TextSize=12,Font=Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,
        BackgroundTransparency=1,BorderSizePixel=0,
    },composer)
    local send=click(composer,"SendMessage",UDim2.fromOffset(37,37),{
        Position=UDim2.new(1,-42,0,5),
        BackgroundTransparency=0,BackgroundColor3=P.orangeDeep,
    })
    corner(send,20)
    image(send,"send",21,{
        Position=UDim2.fromOffset(8,8),ImageColor3=P.pale,
    })

    local replyBar=inst("Frame",{
        Name="ReplyBar",Visible=false,
        Position=UDim2.new(0,12,1,-93),
        Size=UDim2.new(1,-24,0,30),
        BackgroundColor3=P.panel2,BorderSizePixel=0,
    },root)
    corner(replyBar,8)
    inst("Frame",{
        BackgroundColor3=P.orange,BorderSizePixel=0,
        Position=UDim2.fromOffset(7,4),Size=UDim2.new(0,3,1,-8),
    },replyBar)
    local replyLabel=text(replyBar,"",10,P.pale,false,{
        Position=UDim2.fromOffset(17,2),Size=UDim2.new(1,-54,1,-4),
    })
    local replyClose=click(replyBar,"CancelReply",UDim2.fromOffset(26,26),{
        Position=UDim2.new(1,-29,0,2),
    })
    image(replyClose,"x",15,{Position=UDim2.fromOffset(6,6)})

    local emojiTray=inst("Frame",{
        Name="EmojiPicker",Visible=false,
        Position=UDim2.new(0,13,1,-170),
        Size=UDim2.fromOffset(259,106),
        BackgroundColor3=P.panel2,BorderSizePixel=0,ZIndex=40,
    },root)
    corner(emojiTray,11)
    stroke(emojiTray,P.stroke,0.25)
    text(emojiTray,"EMOJIS",10,P.gold,true,{
        Position=UDim2.fromOffset(10,5),Size=UDim2.fromOffset(95,18),ZIndex=41,
    })

    local mentions=inst("Frame",{
        Name="Mentions",Visible=false,
        Position=UDim2.new(0,52,1,-121),
        Size=UDim2.fromOffset(218,54),
        BackgroundColor3=P.panel2,BorderSizePixel=0,ZIndex=42,
    },root)
    corner(mentions,10)
    stroke(mentions,P.stroke,0.22)
    text(mentions,"CURRENT SERVER · NAME SUGGESTIONS",9,P.gold,true,{
        Position=UDim2.fromOffset(9,4),Size=UDim2.new(1,-12,0,15),ZIndex=43,
    })
    local suggest=click(mentions,"MentionSuggestion",UDim2.new(1,-12,0,28),{
        Position=UDim2.fromOffset(6,23),
        BackgroundTransparency=0.27,BackgroundColor3=P.bubble,ZIndex=43,
    })
    corner(suggest,6)
    image(suggest,"mention",15,{Position=UDim2.fromOffset(7,6),ZIndex=44})
    local suggestedName=text(suggest,"",11,P.pale,false,{
        Position=UDim2.fromOffset(28,0),Size=UDim2.new(1,-34,1,0),ZIndex=44,
    })
    local mentionMatch=nil

    local notice=text(root,"",10,P.gold,false,{
        Position=UDim2.new(0,16,1,-82),Size=UDim2.new(1,-32,0,22),
        BackgroundColor3=P.panel2,BackgroundTransparency=0.05,
        Visible=false,ZIndex=50,
    })
    local function notify(value)
        if not alive then return end
        notice.Text=value
        notice.Visible=true
        task.delay(3,function()
            if alive and notice.Text==value then notice.Visible=false end
        end)
    end
    local function hidePopups()
        emojiTray.Visible=false
        mentions.Visible=false
    end

    -- Pulse's compact action rail: like, reply, copy, more. NOT a tall menu.
    local actions=inst("Frame",{
        Name="QuickMessageActions",Visible=false,ZIndex=51,
        BackgroundColor3=P.panel2,BorderSizePixel=0,
        Size=UDim2.fromOffset(119,32),
    },root)
    corner(actions,10)
    stroke(actions,P.stroke,0.1)
    local toolButtons={}
    local quickKeys={"like","reply","copy","more"}
    for i,key in ipairs(quickKeys) do
        local btn=click(actions,"Quick_"..key,UDim2.fromOffset(26,26),{
            Position=UDim2.fromOffset(3+(i-1)*29,3),
            ZIndex=52,
        })
        image(btn,key,15,{
            Position=UDim2.fromOffset(5,5),ZIndex=53,
            ImageColor3=key=="like" and P.gold or P.dim,
        })
        toolButtons[key]=btn
    end
    local extras=inst("Frame",{
        Name="MoreMessageActions",Visible=false,ZIndex=54,
        BackgroundColor3=P.panel2,BorderSizePixel=0,
        Size=UDim2.fromOffset(126,64),
    },root)
    corner(extras,9)
    stroke(extras,P.stroke,0.2)
    local function menuRow(i,key,word)
        local btn=click(extras,key,UDim2.new(1,-8,0,27),{
            Position=UDim2.fromOffset(4,4+(i-1)*30),
            BackgroundTransparency=0.75,BackgroundColor3=P.bubble,ZIndex=55,
        })
        corner(btn,5)
        image(btn,key=="Delete" and "remove" or "x",13,{
            Position=UDim2.fromOffset(6,7),ZIndex=56,
        })
        text(btn,word,10,P.pale,false,{
            Position=UDim2.fromOffset(26,0),Size=UDim2.new(1,-32,1,0),ZIndex=56,
        })
        return btn
    end
    local hideAction=menuRow(1,"Hide","Hide locally")
    local deleteAction=menuRow(2,"Delete","Hide mine locally")

    local function styleLanguages()
        en.BackgroundColor3=room=="EN" and P.orange or P.panel2
        ar.BackgroundColor3=room=="AR" and P.orange or P.panel2
        en.TextColor3=room=="EN" and P.pale or P.dim
        ar.TextColor3=room=="AR" and P.pale or P.dim
        entry.PlaceholderText=room=="EN" and "Message in EN..." or "اكتب رسالة في AR..."
        entry.TextXAlignment=room=="EN" and Enum.TextXAlignment.Left or Enum.TextXAlignment.Right
    end

    local function setReply(item)
        replying=item
        replyBar.Visible=item~=nil
        if item then
            replyLabel.Text="Reply to "..item.name..": "..item.content
            feed.Size=UDim2.new(1,-18,1,-253)
        else
            feed.Size=UDim2.new(1,-18,1,-221)
        end
    end
    local function addMessage(name,content,lang,preview,mine,replyId)
        serial=serial+1
        local item={
            id=serial,name=name,content=content,lang=lang,preview=preview,
            mine=mine,time=os.time(),replyId=replyId,reaction=nil,hidden=false,
        }
        messages[#messages+1]=item
        byId[item.id]=item
        if #messages>LIMIT then
            local removed=table.remove(messages,1)
            if removed then byId[removed.id]=nil;if removed.messageId then byId[removed.messageId]=nil end end
        end
        return item
    end
    local function closeActions()
        selected=nil
        actions.Visible=false
        extras.Visible=false
    end
    local function makeRow(item,order)
        local available=math.max(120,feed.AbsoluteSize.X)
        local maxWidth=math.max(65,math.min(335,available-58))
        local displayName=item.name..(item.preview and " · DEMO" or item.mine and " · YOU" or "")
        local nameW=bounds(displayName,11,Enum.Font.GothamBold,1000).X
        local bodyW=bounds(item.content,12,Enum.Font.Gotham,1000).X
        local quote=byId[item.replyId]
        local quoteText=quote and (quote.name..": "..quote.content) or ""
        local quoteW=quote and bounds(quoteText,10,Enum.Font.Gotham,1000).X or 0
        local bubbleWidth=math.min(maxWidth,math.max(103,math.ceil(
            math.max(nameW+25,bodyW+48,quoteW+25))))
        local bodyHeight=math.max(16,bounds(item.content,12,Enum.Font.Gotham,bubbleWidth-22).Y)
        local quoted=quote and 26 or 0
        local bubbleHeight=math.max(49,bodyHeight+42+quoted)
        local extraReaction=item.reaction and 8 or 0
        local itemRow=inst("Frame",{
            Name="MessageRow",LayoutOrder=order,
            BackgroundTransparency=1,
            Size=UDim2.new(1,0,0,bubbleHeight+extraReaction+3),
        },feed)
        local face=inst("Frame",{
            Name="MessageAvatar",
            Position=UDim2.fromOffset(2,3),Size=UDim2.fromOffset(29,29),
            BackgroundColor3=item.mine and P.orangeDeep or P.panel2,
            BorderSizePixel=0,
        },itemRow)
        corner(face,16)
        if item.mine or item.userId then
            local avatar=inst("ImageLabel",{
                BackgroundTransparency=1,
                Image=avatarURL(item.userId or LocalPlayer.UserId),Size=UDim2.fromScale(1,1),
            },face)
            corner(avatar,16)
        else
            image(face,"user",16,{
                Position=UDim2.fromOffset(7,7),ImageColor3=P.dim,
            })
        end
        local bubble=click(itemRow,"MessageBubble",UDim2.fromOffset(bubbleWidth,bubbleHeight),{
            Position=UDim2.fromOffset(41,0),
            BackgroundTransparency=0.03,
            BackgroundColor3=item.mine and P.own or P.bubble,
        })
        corner(bubble,13)
        local senderColor=item.mine and P.gold or
            (order%3==0 and P.mint or order%3==1 and P.gold or P.pale)
        text(bubble,displayName,11,senderColor,true,{
            Position=UDim2.fromOffset(10,4),Size=UDim2.new(1,-18,0,18),
        })
        if quote then
            local q=inst("Frame",{
                Position=UDim2.fromOffset(9,23),Size=UDim2.new(1,-18,0,24),
                BackgroundColor3=P.panel2,BorderSizePixel=0,
            },bubble)
            corner(q,5)
            inst("Frame",{
                BackgroundColor3=P.orange,BorderSizePixel=0,
                Size=UDim2.new(0,3,1,0),
            },q)
            text(q,quoteText,10,P.dim,false,{
                Position=UDim2.fromOffset(8,0),Size=UDim2.new(1,-13,1,0),
            })
        end
        text(bubble,item.content,12,P.pale,false,{
            Position=UDim2.fromOffset(10,23+quoted),
            Size=UDim2.new(1,-20,0,bodyHeight+2),
            TextWrapped=true,TextTruncate=Enum.TextTruncate.None,
            TextYAlignment=Enum.TextYAlignment.Top,
            TextXAlignment=item.lang=="AR" and Enum.TextXAlignment.Right
                or Enum.TextXAlignment.Left,
        })
        text(bubble,timestamp(item.time),9,P.dim,false,{
            Position=UDim2.new(1,-43,1,-14),
            Size=UDim2.fromOffset(36,12),
            TextXAlignment=Enum.TextXAlignment.Right,
        })
        if item.reaction then
            local reaction=text(bubble,item.reaction,13,P.pale,true,{
                Position=UDim2.new(1,-31,1,-2),Size=UDim2.fromOffset(27,19),
                BackgroundTransparency=0,BackgroundColor3=P.panel2,
                TextXAlignment=Enum.TextXAlignment.Center,
            })
            corner(reaction,10)
        end
        bubble.MouseButton1Click:Connect(function()
            if not alive then return end
            selected=item
            hidePopups()
            extras.Visible=false
            local x=math.min(math.max(6,
                bubble.AbsolutePosition.X-root.AbsolutePosition.X+bubble.AbsoluteSize.X+4),
                math.max(6,root.AbsoluteSize.X-125))
            local y=math.clamp(bubble.AbsolutePosition.Y-root.AbsolutePosition.Y+4,
                160,math.max(160,root.AbsoluteSize.Y-98))
            actions.Position=UDim2.fromOffset(x,y)
            actions.Visible=true
        end)
    end

    local function jumpBottom()
        task.defer(function()
            if not alive or not feed.Parent then return end
            feed.CanvasPosition=Vector2.new(0,math.max(0,
                list.AbsoluteContentSize.Y-feed.AbsoluteSize.Y+15))
            jump.Visible=false
        end)
    end
    render=function(preserveScroll)
        if not alive then return end
        local oldPosition=feed.CanvasPosition
        local readingOlder=preserveScroll and list.AbsoluteContentSize.Y-feed.AbsoluteSize.Y-oldPosition.Y>70
        closeActions()
        for _,v in ipairs(feed:GetChildren()) do
            if v.Name=="MessageRow" then v:Destroy() end
        end
        local count=0
        for _,item in ipairs(messages) do
            if not item.hidden and item.channel== (activeChannel and activeChannel.Name) then
                count=count+1
                makeRow(item,count)
            end
        end
        if count==0 then
            local empty=inst("Frame",{
                Name="MessageRow",LayoutOrder=1,BackgroundTransparency=1,
                Size=UDim2.new(1,0,0,86),
            },feed)
            text(empty,"No received messages. Select a room or friend above.\nRequires the Vanta server script in your experience.",12,P.dim,false,{
                Position=UDim2.fromOffset(10,12),
                Size=UDim2.new(1,-20,0,44),
                TextWrapped=true,
                TextXAlignment=Enum.TextXAlignment.Center,
            })
        end
        if readingOlder then
            task.defer(function()if alive then feed.CanvasPosition=oldPosition;jump.Visible=true end end)
        else
            jumpBottom()
        end
    end

    local function doAction(kind)
        local item=selected
        closeActions()
        if not item then return end
        if kind=="like" then
            item.reaction="👍"
            notify("Reaction saved on this device only.")
            render()
        elseif kind=="reply" then
            setReply(item)
            entry:CaptureFocus()
        elseif kind=="copy" then
            local clipboard=setclipboard or toclipboard
            if type(clipboard)=="function" then
                local ok=pcall(clipboard,item.content)
                notify(ok and "Copied." or "Clipboard unavailable.")
            else
                notify("Clipboard unavailable.")
            end
        elseif kind=="hide" then
            item.hidden=true
            render()
        elseif kind=="delete" and item.mine then
            item.hidden=true
            render()
        end
    end
    watch(toolButtons.like.MouseButton1Click:Connect(function()doAction("like")end))
    watch(toolButtons.reply.MouseButton1Click:Connect(function()doAction("reply")end))
    watch(toolButtons.copy.MouseButton1Click:Connect(function()doAction("copy")end))
    watch(toolButtons.more.MouseButton1Click:Connect(function()
        if not selected then return end
        deleteAction.Visible=selected.mine
        extras.Size=UDim2.fromOffset(126,selected.mine and 64 or 34)
        extras.Position=UDim2.fromOffset(math.clamp(
            actions.AbsolutePosition.X-root.AbsolutePosition.X-6,
            6,root.AbsoluteSize.X-132),
            math.min(root.AbsoluteSize.Y-79,
                actions.AbsolutePosition.Y-root.AbsolutePosition.Y+35))
        extras.Visible=not extras.Visible
    end))
    watch(hideAction.MouseButton1Click:Connect(function()doAction("hide")end))
    watch(deleteAction.MouseButton1Click:Connect(function()doAction("delete")end))

    local function updateMentions()
        if not alive then return end
        local q=entry.Text:match("@([%w_]*)$")
        if not q or #q>25 then mentions.Visible=false;return end
        local hit=nil
        for _,user in ipairs(Players:GetPlayers()) do
            if user.Name:lower():sub(1,#q)==q:lower() then
                hit=user.Name
                break
            end
        end
        mentionMatch=hit
        mentions.Visible=hit~=nil
        if hit then suggestedName.Text="@"..hit end
    end
    watch(entry:GetPropertyChangedSignal("Text"):Connect(updateMentions))
    watch(suggest.MouseButton1Click:Connect(function()
        if not mentionMatch then return end
        entry.Text=entry.Text:gsub("@[%w_]*$","@"..mentionMatch.." ")
        mentions.Visible=false
        entry:CaptureFocus()
    end))
    watch(attachment.MouseButton1Click:Connect(function()
        notify("Attachments aren't supported in the chat.")
    end))
    watch(emoji.MouseButton1Click:Connect(function()
        closeActions()
        mentions.Visible=false
        emojiTray.Visible=not emojiTray.Visible
    end))
    for i,value in ipairs(EMOJI) do
        local pick=click(emojiTray,"Emoji_"..i,UDim2.fromOffset(29,30),{
            Position=UDim2.fromOffset(12+((i-1)%8)*30,25+math.floor((i-1)/8)*36),
            Text=value,TextSize=20,Font=Enum.Font.SourceSans,ZIndex=42,
        })
        watch(pick.MouseButton1Click:Connect(function()
            entry.Text=entry.Text..value
            entry:CaptureFocus()
        end))
    end

    local function sendMessage()
        if not alive then return end
        local content=entry.Text:match("^%s*(.-)%s*$") or ""
        if content=="" then return end
        local ok,size=pcall(utf8.len,content)
        if not ok or not size then notify("Invalid message.");return end
        if size>280 then notify("Maximum 280 characters.");return end
        if not activeChannel then notify("Chat unavailable. Install the server script and check Roblox permissions.");return end
        if sending or not entry.TextEditable then return end
        sending=true
        local channel=activeChannel
        local replyMetadata=replying and replying.messageId and ("vanta-reply:"..replying.messageId) or ""
        local ok,result=pcall(function() return channel:SendAsync(content,replyMetadata) end)
        sending=false
        if not alive then return end
        if not ok or not result or result.Status~=Enum.TextChatMessageStatus.Success then
            notify("Roblox could not send this message. Check permissions or wait and retry.")
            return
        end
        -- Never insert the unfiltered draft or claim recipient delivery/read receipts.
        if activeChannel==channel and entry.Text:match("^%s*(.-)%s*$")==content then entry.Text="" end
        setReply(nil)
        hidePopups()
        notify("Accepted by Roblox. Recipient delivery is not confirmed.")
    end
    watch(send.MouseButton1Click:Connect(sendMessage))
    watch(entry.FocusLost:Connect(function(entered)
        if entered then task.spawn(sendMessage) end
    end))
    watch(replyClose.MouseButton1Click:Connect(function()setReply(nil)end))
    watch(en.MouseButton1Click:Connect(function()
        room="EN";currentDM=nil;setReply(nil);hidePopups();styleLanguages();selectRoom()
    end))
    watch(ar.MouseButton1Click:Connect(function()
        room="AR";currentDM=nil;setReply(nil);hidePopups();styleLanguages();selectRoom()
    end))
    watch(jump.MouseButton1Click:Connect(jumpBottom))
    watch(feed:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if not alive then return end
        local remaining=list.AbsoluteContentSize.Y-feed.AbsoluteSize.Y-feed.CanvasPosition.Y
        jump.Visible=remaining>70
        if actions.Visible then closeActions() end
    end))
    watch(feed:GetPropertyChangedSignal("AbsoluteSize"):Connect(function()
        if alive then render() end
    end))
    watch(Players.PlayerAdded:Connect(drawFaces))
    watch(Players.PlayerRemoving:Connect(function()
        task.defer(drawFaces)
    end))
    watch(root.Destroying:Connect(function()
        alive=false
        for _,signal in ipairs(connections) do signal:Disconnect() end
        table.clear(connections)
    end))
    -- The control-plane remote takes only a target UserId. No message text leaves TextChatService.
    local friendButton=click(root,"ChooseFriend",UDim2.new(1,-112,0,28),{
        Position=UDim2.fromOffset(10,125),Text="Friends in this server",TextSize=11,
        BackgroundTransparency=0.15,BackgroundColor3=P.panel2,
    })
    corner(friendButton,8)
    local roomButton=click(root,"ChooseRoom",UDim2.fromOffset(87,28),{
        Position=UDim2.new(1,-97,0,125),Text="Room",TextSize=11,
        BackgroundTransparency=0.15,BackgroundColor3=P.panel2,
    })
    corner(roomButton,8)
    local choices=inst("ScrollingFrame",{
        Name="FriendChoices",Visible=false,ZIndex=60,Position=UDim2.fromOffset(10,156),
        Size=UDim2.new(1,-20,0,120),BackgroundColor3=P.panel2,BorderSizePixel=0,
        CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,ScrollBarThickness=3,
    },root)
    inst("UIListLayout",{SortOrder=Enum.SortOrder.LayoutOrder},choices)
    local function selectChannel(channel)
        activeChannel=channel
        entry.Text=""
        setReply(nil)
        friendButton.Text=currentDM and ("DM · "..currentDM) or "Friends in this server"
        if nativeWindow then nativeWindow:Destroy();nativeWindow=nil end
        feed.Visible=not integrated
        composer.Visible=not integrated
        local usable=channel~=nil
        if channel then
            usable=false
            for _,source in ipairs(channel:GetChildren()) do
                if source:IsA("TextSource") and source.UserId==LocalPlayer.UserId and source.CanSend then
                    usable=true
                end
            end
        end
        local windowFailed=false
        if integrated and channel then
            local ok,window=pcall(function()
                local w=Instance.new("TextChannelWindow")
                w.Name="RobloxChatWindow"
                w.Position=UDim2.fromOffset(10,160)
                w.Size=UDim2.new(1,-20,1,-170)
                w.BackgroundColor3=P.panel
                w.Target=channel
                w.ZIndex=feed.ZIndex
                w.Parent=root
                return w
            end)
            if ok then nativeWindow=window else windowFailed=true end
        end
        status.Text=windowFailed and "Native window unavailable" or usable and (currentDM and "Friend DM · this server" or "Room · this server") or "Setup / permission required"
        indicator.BackgroundColor3=usable and not windowFailed and P.mint or P.orange
        entry.TextEditable=usable and not integrated
        send.AutoButtonColor=entry.TextEditable
        send.BackgroundColor3=entry.TextEditable and P.orange or P.orangeDeep
        entry.PlaceholderText=usable and "Message via Roblox..." or "Chat unavailable · setup required"
        render()
    end
    selectRoom=function()
        channelFolder=TextChatService:FindFirstChild("TextChannels")
        selectChannel(channelFolder and channelFolder:FindFirstChild("Vanta"..room))
    end
    local function refreshFriendChoices()
        for _,child in ipairs(choices:GetChildren()) do
            if child:IsA("GuiObject") then child:Destroy() end
        end
        local count=0
        for _,player in ipairs(Players:GetPlayers()) do
            if player~=LocalPlayer then
                local ok,isFriend=pcall(function() return LocalPlayer:IsFriendsWith(player.UserId) end)
                if not alive then return end
                if ok and isFriend then
                    count=count+1
                    local button=click(choices,"Friend_"..player.UserId,UDim2.new(1,0,0,32),{
                        Text=player.DisplayName.." (@"..player.Name..")",TextSize=11,LayoutOrder=count,
                    })
                    button.MouseButton1Click:Connect(function()
                        choices.Visible=false
                        local remote=ReplicatedStorage:FindFirstChild("VantaChatOpen")
                        if not remote or not remote:IsA("RemoteFunction") then notify("Server module is not installed.");return end
                        task.spawn(function()
                            local opened,name,reason=pcall(function() return remote:InvokeServer(player.UserId) end)
                            if not alive then return end
                            if not opened or not name then notify(reason or "Roblox denied the conversation.");return end
                            local channel=channelFolder and channelFolder:WaitForChild(name,5)
                            if not alive then return end
                            if not channel then notify("Conversation has not replicated. Retry.");return end
                            currentDM=player.DisplayName
                            selectChannel(channel)
                        end)
                    end)
                end
            end
        end
        if count==0 then
            text(choices,"No friends here. Ask a friend to join this server.",11,P.dim,false,{
                Size=UDim2.new(1,0,0,40),TextWrapped=true,
            })
        end
    end
    watch(friendButton.MouseButton1Click:Connect(function()
        choices.Visible=not choices.Visible
        if choices.Visible then task.spawn(refreshFriendChoices) end
    end))
    watch(roomButton.MouseButton1Click:Connect(function()currentDM=nil;selectRoom()end))
    watch(TextChatService.MessageReceived:Connect(function(message)
        if integrated or not alive or message.Status~=Enum.TextChatMessageStatus.Success then return end
        local channel=message.TextChannel
        local source=message.TextSource
        if not channel or not source or not channel.Name:match("^Vanta") or message.Text=="" then return end
        if byId[message.MessageId] then return end
        local player=Players:GetPlayerByUserId(source.UserId)
        local item=addMessage(player and player.DisplayName or tostring(source.UserId),message.Text,
            room,false,source.UserId==LocalPlayer.UserId)
        item.channel=channel.Name
        item.userId=source.UserId
        local parentId=(message.Metadata or ""):match("^vanta%-reply:(.+)$")
        local parent=parentId and byId[parentId]
        item.replyId=parent and parent.channel==channel.Name and parent.id or nil
        byId[message.MessageId]=item
        item.messageId=message.MessageId
        if not activeChannel or (channel~=activeChannel and channel.Name:match("^VantaDM_")) then
            notify("New friend message. Open Friends and select the sender.")
        end
        render(true)
    end))
    local attachedFolder=nil
    local function attachFolder(folder)
        if attachedFolder==folder then return end
        channelFolder=folder
        attachedFolder=folder
        watch(channelFolder.ChildAdded:Connect(function(channel)
            if channel.Name=="Vanta"..room and not currentDM then selectRoom() end
        end))
        watch(channelFolder.ChildRemoved:Connect(function(channel)
            if channel==activeChannel then currentDM=nil;selectRoom() end
        end))
        watch(channelFolder.DescendantAdded:Connect(function(source)
            if source:IsA("TextSource") and source.UserId==LocalPlayer.UserId then
                task.defer(function()
                    if alive and source.Parent==activeChannel then selectChannel(activeChannel) end
                end)
                watch(source:GetPropertyChangedSignal("CanSend"):Connect(function()
                    if alive and source.Parent==activeChannel then selectChannel(activeChannel) end
                end))
            end
        end))
        if not currentDM then selectRoom() end
    end
    if channelFolder then attachFolder(channelFolder) end
    watch(TextChatService.ChildAdded:Connect(function(folder)
        if folder.Name=="TextChannels" then attachFolder(folder) end
    end))
    local function resize()
        root.Size=UDim2.new(1,0,0,math.max(300,holder.AbsoluteSize.Y-8))
        local narrow=root.AbsoluteSize.X<390
        faces.Visible=not narrow
        language.Position=UDim2.new(1,narrow and -97 or -151,0,14)
    end
    watch(holder:GetPropertyChangedSignal("AbsoluteSize"):Connect(resize))
    resize()
    selectRoom()
    drawFaces()
    styleLanguages()
    if not entry.TextEditable then entry.PlaceholderText="Chat unavailable · setup / permission required" end
    render()
    print("[VantaTest Chat] "..BUILD.." · Roblox TextChatService; no external chat relay.")
    return root
end

return Chat

