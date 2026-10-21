-- VantaTest Chat LAB · native in-window interactive PREVIEW.
-- Real SaltyIcons Roblox IDs from MrRos3/SaltyIcons/roblox/Icons.lua.
-- Intentionally NO Roblox TextChatService, HTTP chat relay, or external browser.
-- Local messages never transmit to other Roblox clients or to the hosted site.
local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local LocalPlayer = Players.LocalPlayer

local Chat = {}
local PALETTE = {
    black = Color3.fromRGB(13, 11, 14),
    dark = Color3.fromRGB(20, 17, 21),
    card = Color3.fromRGB(34, 28, 33),
    bubble = Color3.fromRGB(45, 37, 43),
    mine = Color3.fromRGB(73, 37, 52),
    border = Color3.fromRGB(84, 55, 68),
    burgundy = Color3.fromRGB(142, 50, 76),
    pale = Color3.fromRGB(247, 241, 243),
    dim = Color3.fromRGB(173, 159, 168),
    rose = Color3.fromRGB(241, 151, 185),
}
local ICONS = {
    chat = "rbxassetid://110915451876713",
    message = "rbxassetid://126050900811446",
    send = "rbxassetid://104783825572790",
    heart = "rbxassetid://80686764701725",
    reply = "rbxassetid://70778094695584",
    copy = "rbxassetid://103363146431717",
    close = "rbxassetid://104564513546348",
    more = "rbxassetid://138158933921955",
    remove = "rbxassetid://71091959578714",
    user = "rbxassetid://108864475481601",
    clock = "rbxassetid://118647085388941",
    mention = "rbxassetid://125917586170394",
    down = "rbxassetid://93700951703515",
}
local MAX_HISTORY = 150 -- cap render load like Pulse's sampled message list
local EMOJIS = {"😀","😂","😍","🥹","😭","❤️","🖤","🌹","🔥","👍","👀","✨","😎","💀","💋","🙏"}

local function new(class, props, parent)
    local obj = Instance.new(class)
    for k,v in pairs(props or {}) do
        obj[k] = v
    end
    if parent then obj.Parent = parent end
    return obj
end

local function round(parent, radius)
    return new("UICorner", {CornerRadius=UDim.new(0,radius)}, parent)
end

local function outline(parent, color, transparency)
    return new("UIStroke", {
        Color=color or PALETTE.border,
        Transparency=transparency or 0, Thickness=1,
    }, parent)
end

local function label(parent, value, size, color, bold, extra)
    local props = {
        Text=tostring(value or ""),TextColor3=color or PALETTE.pale,
        TextSize=size or 12,Font=bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment=Enum.TextXAlignment.Left,TextYAlignment=Enum.TextYAlignment.Center,
        TextTruncate=Enum.TextTruncate.AtEnd,BackgroundTransparency=1,
        BorderSizePixel=0,
    }
    for k,v in pairs(extra or {}) do props[k]=v end
    return new("TextLabel",props,parent)
end

local function icon(parent, kind, size, extra)
    local props={
        Name="SaltyIcon_"..kind,
        Image=assert(ICONS[kind],"Missing SaltyIcons asset: "..tostring(kind)),
        ImageColor3=PALETTE.pale,
        BackgroundTransparency=1,
        Size=UDim2.fromOffset(size,size),
        ScaleType=Enum.ScaleType.Fit,
    }
    for k,v in pairs(extra or {}) do props[k]=v end
    return new("ImageLabel",props,parent)
end

local function button(parent, name, size, extra)
    local props={
        Name=name,Text="",AutoButtonColor=true,
        BorderSizePixel=0,BackgroundTransparency=1,
        Size=size,TextColor3=PALETTE.pale,
        Font=Enum.Font.GothamBold,TextSize=12,
    }
    for k,v in pairs(extra or {}) do props[k]=v end
    return new("TextButton",props,parent)
end

local function timeString(timestamp)
    local ok,result=pcall(os.date,"%H:%M",timestamp or os.time())
    return ok and result or ""
end

local function countSize(message, width)
    local ok,bounds=pcall(TextService.GetTextSize,TextService,tostring(message),12,
        Enum.Font.Gotham,Vector2.new(math.max(100,width),2000))
    return ok and math.max(18,bounds.Y) or 30
end

local function headshot(id)
    return ("rbxthumb://type=AvatarHeadShot&id=%d&w=100&h=100"):format(id)
end

function Chat.Mount(tab)
    local holder=assert(tab.UIElements and tab.UIElements.ContainerFrame,
        "Vanta Chat requires a VantaTest tab")
    local previous=holder:FindFirstChild("VantaChatExperiment")
    if previous then previous:Destroy() end

    local pad=holder:FindFirstChildOfClass("UIPadding")
    if pad then
        pad.PaddingTop=UDim.new(0,4)
        pad.PaddingBottom=UDim.new(0,4)
        pad.PaddingLeft=UDim.new(0,4)
        pad.PaddingRight=UDim.new(0,4)
    end

    local root=new("Frame",{
        Name="VantaChatExperiment", LayoutOrder=1,
        Size=UDim2.new(1,0,0,405),ZIndex=2,
        BorderSizePixel=0, BackgroundColor3=PALETTE.black,
        BackgroundTransparency=0.08,ClipsDescendants=true,
    },holder)
    round(root,15)
    outline(root,PALETTE.border,0.28)

    local alive=true
    local room="EN"
    local messages={}
    local byId={}
    local selected=nil
    local replying=nil
    local serial=0
    local globals={}
    local controls={}
    local function watch(signal)
        globals[#globals+1]=signal
        return signal
    end

    label(root,"Chat",18,PALETTE.pale,true,{
        Position=UDim2.fromOffset(14,4),Size=UDim2.new(1,-90,0,26),
    })
    label(root,"Explore Vanta Chat's in-script design",10,PALETTE.dim,false,{
        Position=UDim2.fromOffset(14,30),Size=UDim2.new(1,-30,0,15),
    })
    local statusDot=new("Frame",{
        Position=UDim2.new(1,-107,0,17),Size=UDim2.fromOffset(6,6),
        BackgroundColor3=PALETTE.rose,BorderSizePixel=0,
    },root)
    round(statusDot,5)
    label(root,"LOCAL DEMO",9,PALETTE.rose,true,{
        Position=UDim2.new(1,-96,0,10),Size=UDim2.fromOffset(90,18),
    })

    local header=new("Frame",{
        Name="RoomHeader",Position=UDim2.fromOffset(10,53),
        Size=UDim2.new(1,-20,0,55),BackgroundColor3=PALETTE.dark,
        BorderSizePixel=0,
    },root)
    round(header,12)
    outline(header,PALETTE.border,0.62)
    local square=new("Frame",{
        Position=UDim2.fromOffset(9,11),Size=UDim2.fromOffset(34,34),
        BackgroundColor3=PALETTE.burgundy,BorderSizePixel=0,
    },header)
    round(square,9)
    icon(square,"chat",22,{
        AnchorPoint=Vector2.new(.5,.5),Position=UDim2.fromScale(.5,.5),
    })
    label(header,"Vanta Chat",13,PALETTE.pale,true,{
        Position=UDim2.fromOffset(52,8),Size=UDim2.new(1,-195,0,19),
    })
    label(header,"Prototype  •  Not connected",10,PALETTE.dim,false,{
        Position=UDim2.fromOffset(52,29),Size=UDim2.new(1,-195,0,15),
    })
    local function roomButton(name,x)
        local obj=button(header,name.."Room",UDim2.fromOffset(37,26),{
            Text=name,TextSize=10,BackgroundTransparency=0,
            BackgroundColor3=PALETTE.card,
            Position=UDim2.new(1,x,0,14),
        })
        round(obj,16)
        return obj
    end
    local en=roomButton("EN",-85)
    local ar=roomButton("AR",-43)

    local feed=new("ScrollingFrame",{
        Name="MessageFeed",Position=UDim2.fromOffset(10,114),
        Size=UDim2.new(1,-20,1,-177),
        BorderSizePixel=0,BackgroundColor3=PALETTE.dark,
        BackgroundTransparency=0.39,
        CanvasSize=UDim2.fromOffset(0,0),
        AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollingDirection=Enum.ScrollingDirection.Y,
        ScrollBarThickness=2,ScrollBarImageColor3=PALETTE.burgundy,
    },root)
    round(feed,11)
    new("UIPadding",{
        PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,10),
        PaddingLeft=UDim.new(0,9),PaddingRight=UDim.new(0,9),
    },feed)
    local layout=new("UIListLayout",{
        Padding=UDim.new(0,8),SortOrder=Enum.SortOrder.LayoutOrder,
    },feed)

    -- Scroll-to-latest control for large chat histories.
    local jump=button(root,"JumpToLatest",UDim2.fromOffset(30,30),{
        Position=UDim2.new(1,-48,1,-91),
        BackgroundTransparency=0.07,BackgroundColor3=PALETTE.burgundy,
        Visible=false,ZIndex=8,
    })
    round(jump,15)
    outline(jump,PALETTE.border,0.25)
    icon(jump,"down",16,{Position=UDim2.fromOffset(7,7),ZIndex=9})

    local compose=new("Frame",{
        Name="Composer",Position=UDim2.new(0,10,1,-55),
        Size=UDim2.new(1,-20,0,45),
        BackgroundColor3=PALETTE.card,
        BorderSizePixel=0,
    },root)
    round(compose,23)
    outline(compose,PALETTE.border,0.35)
    local emojiBtn=button(compose,"EmojiToggle",UDim2.fromOffset(33,37),{
        Position=UDim2.fromOffset(7,4),
    })
    -- The smile icon is not published in SaltyIcons' uploaded Roblox IDs.
    -- Use the user's real heart icon to open an actual emoji picker.
    icon(emojiBtn,"heart",20,{Position=UDim2.fromOffset(6,7),ImageColor3=PALETTE.dim})
    local mentionBtn=button(compose,"MentionToggle",UDim2.fromOffset(29,37),{
        Position=UDim2.fromOffset(38,4),
    })
    icon(mentionBtn,"mention",17,{
        Position=UDim2.fromOffset(6,9),ImageColor3=PALETTE.dim,
    })
    local entry=new("TextBox",{
        Name="ComposerInput",
        Position=UDim2.fromOffset(72,1),
        Size=UDim2.new(1,-121,1,-2),
        BackgroundTransparency=1,BorderSizePixel=0,
        Text="",ClearTextOnFocus=false,MultiLine=false,
        PlaceholderText="Type a local demo message...",
        TextColor3=PALETTE.pale,
        PlaceholderColor3=PALETTE.dim,
        Font=Enum.Font.Gotham,TextSize=12,
        TextXAlignment=Enum.TextXAlignment.Left,
    },compose)
    local send=button(compose,"SendLocalDemo",UDim2.fromOffset(35,35),{
        Position=UDim2.new(1,-40,0,5),
        BackgroundTransparency=0,BackgroundColor3=PALETTE.burgundy,
    })
    round(send,18)
    icon(send,"send",20,{
        Position=UDim2.fromOffset(7,7),
    })

    -- Local-only name suggestions, inspired by Pulse's Mentions pane.
    -- The suggestions are NOT a list of global chat participants.
    local mentions=new("Frame",{
        Name="Mentions",Visible=false,
        Position=UDim2.new(0,42,1,-127),
        Size=UDim2.fromOffset(226,60),ZIndex=24,
        BackgroundColor3=PALETTE.card,BorderSizePixel=0,
    },root)
    round(mentions,10)
    outline(mentions,PALETTE.border,0.3)
    label(mentions,"SERVER NAME · LOCAL DEMO",9,PALETTE.rose,true,{
        Position=UDim2.fromOffset(9,4),
        Size=UDim2.new(1,-18,0,17),ZIndex=25,
    })
    local mentionChoice=button(mentions,"MentionCandidate",UDim2.new(1,-14,0,28),{
        Position=UDim2.fromOffset(7,27),BackgroundTransparency=.5,
        BackgroundColor3=PALETTE.bubble,ZIndex=25,
    })
    round(mentionChoice,6)
    icon(mentionChoice,"mention",16,{
        Position=UDim2.fromOffset(7,6),ZIndex=26,
    })
    local mentionName=label(mentionChoice,"",11,PALETTE.pale,false,{
        Position=UDim2.fromOffset(30,0),Size=UDim2.new(1,-37,1,0),ZIndex=26,
    })
    local mentionTarget=nil
    local function updateMentions()
        local query=entry.Text:match("@([%w_]*)$")
        if not query or #query>24 then
            mentions.Visible=false
            return
        end
        local found=nil
        for _,user in ipairs(Players:GetPlayers()) do
            if user.Name:lower():sub(1,#query)==query:lower() then
                found=user.Name
                break
            end
        end
        mentionTarget=found
        mentions.Visible=found~=nil
        if found then mentionName.Text="@"..found.."  (preview)" end
    end
    watch(mentionBtn.MouseButton1Click:Connect(function()
        entry.Text=entry.Text.."@"
        entry:CaptureFocus()
        updateMentions()
    end))
    watch(mentionChoice.MouseButton1Click:Connect(function()
        if not mentionTarget then return end
        entry.Text=entry.Text:gsub("@[%w_]*$","@"..mentionTarget.." ")
        mentions.Visible=false
        entry:CaptureFocus()
    end))
    watch(entry:GetPropertyChangedSignal("Text"):Connect(updateMentions))

    local replyBar=new("Frame",{
        Name="ReplyPreview",Visible=false,
        Position=UDim2.new(0,10,1,-92),
        Size=UDim2.new(1,-20,0,31),
        BackgroundColor3=Color3.fromRGB(47,29,39),
        BorderSizePixel=0,
    },root)
    round(replyBar,8)
    new("Frame",{
        Position=UDim2.fromOffset(5,4),Size=UDim2.new(0,3,1,-8),
        BackgroundColor3=PALETTE.burgundy,BorderSizePixel=0,
    },replyBar)
    local replyText=label(replyBar,"",10,PALETTE.pale,false,{
        Position=UDim2.fromOffset(15,1),Size=UDim2.new(1,-56,1,-2),
    })
    local clearReply=button(replyBar,"CancelReply",UDim2.fromOffset(29,29),{
        Position=UDim2.new(1,-31,0,1),
    })
    icon(clearReply,"close",15,{Position=UDim2.fromOffset(7,7)})

    local emojiTray=new("Frame",{
        Name="EmojiPicker",Visible=false,
        Position=UDim2.new(0,13,1,-188),
        Size=UDim2.fromOffset(248,127),
        ZIndex=25,BackgroundColor3=PALETTE.card,BorderSizePixel=0,
    },root)
    round(emojiTray,12)
    outline(emojiTray,PALETTE.border,0.25)
    label(emojiTray,"EMOJIS",10,PALETTE.rose,true,{
        Position=UDim2.fromOffset(10,6),Size=UDim2.fromOffset(120,17),ZIndex=26,
    })
    for i,emoji in ipairs(EMOJIS) do
        local slot=button(emojiTray,"Emoji"..i,UDim2.fromOffset(27,34),{
            Position=UDim2.fromOffset(12+((i-1)%8)*29,25+math.floor((i-1)/8)*42),
            Text=emoji,TextSize=21,Font=Enum.Font.SourceSans,ZIndex=26,
        })
        watch(slot.MouseButton1Click:Connect(function()
            if not alive then return end
            entry.Text=entry.Text..emoji
            entry:CaptureFocus()
        end))
    end

    local actions=new("Frame",{
        Name="MessageActions",Visible=false,ZIndex=30,
        Position=UDim2.new(1,-146,0,133),
        Size=UDim2.fromOffset(139,160),
        BackgroundColor3=PALETTE.card,
        BorderSizePixel=0,
    },root)
    round(actions,12)
    outline(actions,PALETTE.border,0.2)
    new("UIPadding",{
        PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,5),
        PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5),
    },actions)
    new("UIListLayout",{
        SortOrder=Enum.SortOrder.LayoutOrder,
        Padding=UDim.new(0,2),
    },actions)
    local function action(textValue,key,i)
        local actionBtn=button(actions,key,UDim2.new(1,0,0,24),{
            LayoutOrder=i,BackgroundTransparency=0.7,
            BackgroundColor3=PALETTE.bubble,
        })
        round(actionBtn,6)
        icon(actionBtn,key=="Delete" and "remove" or key=="Reply" and "reply"
            or key=="Copy" and "copy" or key=="React" and "heart"
            or key=="Hide" and "close" or "more",14,{
            Position=UDim2.fromOffset(7,5),
        })
        label(actionBtn,textValue,11,PALETTE.pale,false,{
            Position=UDim2.fromOffset(27,0),
            Size=UDim2.new(1,-31,1,0),
        })
        return actionBtn
    end
    local menuItems={
        action("Reply","Reply",1),
        action("Copy","Copy",2),
        action("React ❤️","React",3),
        action("Hide locally","Hide",4),
        action("Delete mine","Delete",5),
    }

    local toast=label(root,"",10,PALETTE.rose,false,{
        Position=UDim2.new(0,13,1,-12),
        Size=UDim2.new(1,-26,0,12),Visible=false,
    })
    local function notify(msg)
        if not alive then return end
        toast.Text=msg
        toast.Visible=true
        task.delay(3,function()
            if alive and toast.Text==msg then toast.Visible=false end
        end)
    end

    local function setReply(message)
        replying=message
        if message then
            replyText.Text="↩ "..message.name..": "..message.content
            replyBar.Visible=true
            feed.Size=UDim2.new(1,-20,1,-210)
        else
            replyBar.Visible=false
            feed.Size=UDim2.new(1,-20,1,-177)
        end
    end

    local function styleRooms()
        en.BackgroundColor3=room=="EN" and PALETTE.burgundy or PALETTE.card
        ar.BackgroundColor3=room=="AR" and PALETTE.burgundy or PALETTE.card
        en.TextColor3=room=="EN" and PALETTE.pale or PALETTE.dim
        ar.TextColor3=room=="AR" and PALETTE.pale or PALETTE.dim
        entry.PlaceholderText=room=="AR" and "اكتب رسالة تجريبية..." or "Type a local demo message..."
        entry.TextXAlignment=room=="AR" and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    end

    local function addMessage(content,name,language,preview,mine,replyId,emoji)
        serial=serial+1
        local item={
            id=serial,name=name,content=content,
            lang=language,preview=preview,mine=mine,
            time=os.time(),replyId=replyId,reaction=emoji,hidden=false,
        }
        messages[#messages+1]=item
        byId[item.id]=item
        if #messages>MAX_HISTORY then
            local dropped=table.remove(messages,1)
            if dropped then byId[dropped.id]=nil end
        end
        return item
    end

    addMessage("Welcome to Vanta Chat. Tap a message to reply, copy or react.",
        "Vanta Preview","EN",true,false)
    addMessage("This demo stays in your script. It doesn't send messages to other players.",
        "Design Preview","EN",true,false)
    addMessage("هلا والله! هنا تقدر تجرب المحادثة بالعربي 🤍",
        "معاينة فانتـا","AR",true,false)

    local function rowFor(item,order)
        local width=math.max(170,math.min(348,feed.AbsoluteSize.X-74))
        local bodyHeight=countSize(item.content,width-24)
        local reply=byId[item.replyId]
        local quoted=reply and 28 or 0
        local rowHeight=math.min(300,40+bodyHeight+quoted)
        local row=new("Frame",{
            Name="MessageRow",LayoutOrder=order,
            BackgroundTransparency=1,Size=UDim2.new(1,0,0,rowHeight),
        },feed)
        local avatar=new("Frame",{
            Position=item.mine and UDim2.new(1,-28,0,3) or UDim2.fromOffset(0,3),
            Size=UDim2.fromOffset(28,28),
            BackgroundColor3=Color3.fromRGB(83,51,66),BorderSizePixel=0,
        },row)
        round(avatar,15)
        if item.mine then
            local playerFace=new("ImageLabel",{
                BackgroundTransparency=1,Size=UDim2.fromScale(1,1),
                Image=headshot(LocalPlayer.UserId),
            },avatar)
            round(playerFace,15)
        else
            icon(avatar,"user",16,{
                AnchorPoint=Vector2.new(.5,.5),
                Position=UDim2.fromScale(.5,.5),
            })
        end

        local bubble=button(row,"MessageBubble",UDim2.fromOffset(width,rowHeight-2),{
            Position=item.mine and UDim2.new(1,-width-34,0,0)
                or UDim2.fromOffset(34,0),
            BackgroundTransparency=0.08,
            BackgroundColor3=item.mine and PALETTE.mine or PALETTE.bubble,
        })
        round(bubble,13)
        local senderName=item.name
            ..(item.preview and "  · PREVIEW" or item.mine and "  · LOCAL" or "")
        label(bubble,senderName,11,
            item.mine and PALETTE.pale or PALETTE.rose,true,{
            Position=UDim2.fromOffset(10,5),
            Size=UDim2.new(1,-61,0,17),
        })
        label(bubble,timeString(item.time),9,PALETTE.dim,false,{
            Position=UDim2.new(1,-48,0,5),Size=UDim2.fromOffset(39,14),
            TextXAlignment=Enum.TextXAlignment.Right,
        })
        if reply then
            local box=new("Frame",{
                Position=UDim2.fromOffset(9,23),
                Size=UDim2.new(1,-18,0,26),
                BackgroundColor3=PALETTE.mine,
                BackgroundTransparency=0.32,BorderSizePixel=0,
            },bubble)
            round(box,6)
            new("Frame",{
                BackgroundColor3=PALETTE.burgundy,BorderSizePixel=0,
                Size=UDim2.new(0,3,1,0),
            },box)
            label(box,reply.name..": "..reply.content,10,PALETTE.pale,false,{
                Position=UDim2.fromOffset(9,0),Size=UDim2.new(1,-17,1,0),
            })
        end
        label(bubble,item.content,12,PALETTE.pale,false,{
            Position=UDim2.fromOffset(10,23+quoted),
            Size=UDim2.new(1,-20,0,bodyHeight+3),
            TextWrapped=true,TextTruncate=Enum.TextTruncate.None,
            TextYAlignment=Enum.TextYAlignment.Top,
            TextXAlignment=item.lang=="AR"
                and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
        })
        if item.reaction then
            label(bubble,item.reaction,13,PALETTE.pale,true,{
                Position=UDim2.new(1,-33,1,-17),
                Size=UDim2.fromOffset(30,18),
            })
        end
        bubble.MouseButton1Click:Connect(function()
            if not alive then return end
            selected=item
            emojiTray.Visible=false
            actions.Visible=true
            menuItems[5].Visible=item.mine
            actions.Size=UDim2.fromOffset(139,item.mine and 160 or 134)
            local y=row.AbsolutePosition.Y-root.AbsolutePosition.Y
            local maxY=root.AbsoluteSize.Y-(item.mine and 168 or 143)
            actions.Position=UDim2.new(1,-147,0,math.clamp(y,109,math.max(109,maxY)))
        end)
        return row
    end

    local function bottom()
        task.defer(function()
            if alive and feed.Parent then
                feed.CanvasPosition=Vector2.new(0,math.max(0,
                    layout.AbsoluteContentSize.Y-feed.AbsoluteSize.Y+21))
                jump.Visible=false
            end
        end)
    end
    watch(jump.MouseButton1Click:Connect(bottom))
    watch(feed:GetPropertyChangedSignal("CanvasPosition"):Connect(function()
        if not alive then return end
        local remaining=layout.AbsoluteContentSize.Y-feed.AbsoluteSize.Y-feed.CanvasPosition.Y
        jump.Visible=remaining>75
    end))

    local function render()
        if not alive then return end
        for _,c in ipairs(feed:GetChildren()) do
            if c.Name=="MessageRow" then c:Destroy() end
        end
        local count=0
        for _,item in ipairs(messages) do
            if item.lang==room and not item.hidden then
                count=count+1
                rowFor(item,count)
            end
        end
        if count==0 then
            local phrase=room=="AR" and "ما عندك رسائل تجريبية هنا 🤍"
                or "No messages in this demo room yet."
            count=count+1
            rowFor({
                name="Vanta Demo",content=phrase,lang=room,
                time=os.time(),preview=true,
            },count)
        end
        bottom()
    end

    watch(en.MouseButton1Click:Connect(function()
        room="EN";selected=nil;actions.Visible=false;setReply(nil);styleRooms();render()
    end))
    watch(ar.MouseButton1Click:Connect(function()
        room="AR";selected=nil;actions.Visible=false;setReply(nil);styleRooms();render()
    end))
    watch(clearReply.MouseButton1Click:Connect(function() setReply(nil) end))
    watch(emojiBtn.MouseButton1Click:Connect(function()
        actions.Visible=false
        mentions.Visible=false
        emojiTray.Visible=not emojiTray.Visible
    end))

    local function perform(kind)
        local item=selected
        actions.Visible=false
        selected=nil
        if not item then return end
        if kind=="Reply" then
            setReply(item)
            entry:CaptureFocus()
        elseif kind=="Copy" then
            local copy=setclipboard or toclipboard
            if type(copy)=="function" then
                local ok=pcall(copy,item.content)
                notify(ok and "Message copied." or "Clipboard is not available.")
            else
                notify("Clipboard is not available.")
            end
        elseif kind=="React" then
            item.reaction="❤️"
            render()
        elseif kind=="Hide" then
            item.hidden=true
            render()
        elseif kind=="Delete" and item.mine then
            item.hidden=true
            render()
        end
    end
    for i,item in ipairs(menuItems) do
        local key=({"Reply","Copy","React","Hide","Delete"})[i]
        watch(item.MouseButton1Click:Connect(function()perform(key)end))
    end

    local function sendDemo()
        if not alive then return end
        local value=entry.Text:match("^%s*(.-)%s*$") or ""
        if value=="" then return end
        local count=0
        for _ in utf8.codes(value) do
            count=count+1
            if count>280 then notify("Demo messages are limited to 280 characters.");return end
        end
        addMessage(value,LocalPlayer.DisplayName or LocalPlayer.Name,
            room,false,true,replying and replying.id or nil)
        entry.Text=""
        setReply(nil)
        emojiTray.Visible=false
        mentions.Visible=false
        actions.Visible=false
        render()
        notify("Local demo only. Your message was not transmitted.")
    end
    watch(send.MouseButton1Click:Connect(sendDemo))
    watch(entry.FocusLost:Connect(function(enter)
        if enter then sendDemo() end
    end))
    watch(root.Destroying:Connect(function()
        alive=false
        for _,conn in ipairs(globals) do
            conn:Disconnect()
        end
        table.clear(globals)
    end))

    styleRooms()
    render()
    return root
end

return Chat
