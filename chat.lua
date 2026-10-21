-- VantaTest Chat LAB v2
-- Telegram-inspired script-tagged feed, sent via PUBLIC Roblox chat in the SAME server.
-- Cross-game chat requires a separate authenticated, moderated hosted relay.
local Players = game:GetService("Players")
local TextChatService = game:GetService("TextChatService")
local HttpService = game:GetService("HttpService")
local TextService = game:GetService("TextService")
local LocalPlayer = Players.LocalPlayer

local Chat = {}
local BG = Color3.fromRGB(15, 13, 15)
local HEADER = Color3.fromRGB(27, 23, 26)
local PANEL = Color3.fromRGB(23, 20, 23)
local BUBBLE = Color3.fromRGB(43, 36, 40)
local OWN = Color3.fromRGB(65, 33, 46)
local ACCENT = Color3.fromRGB(133, 48, 70)
local LINE = Color3.fromRGB(76, 58, 67)
local WHITE = Color3.fromRGB(247, 240, 243)
local DIM = Color3.fromRGB(174, 163, 170)
local GREEN = Color3.fromRGB(75, 211, 139)
local META_PREFIX = "VCHAT2|"

local function make(class, props, parent)
    local object = Instance.new(class)
    for k, v in pairs(props or {}) do object[k] = v end
    if parent then object.Parent = parent end
    return object
end

local function corner(parent, radius)
    return make("UICorner", { CornerRadius = UDim.new(0, radius) }, parent)
end

local function stroke(parent, color, alpha, thickness)
    return make("UIStroke", {
        Color = color or LINE, Transparency = alpha or 0,
        Thickness = thickness or 1,
    }, parent)
end

local function label(parent, value, size, color, bold, props)
    local settings = {
        BackgroundTransparency = 1, BorderSizePixel = 0,
        Text = tostring(value or ""), TextColor3 = color or WHITE,
        TextSize = size or 12, Font = bold and Enum.Font.GothamBold or Enum.Font.Gotham,
        TextXAlignment = Enum.TextXAlignment.Left,
        TextYAlignment = Enum.TextYAlignment.Center,
        TextTruncate = Enum.TextTruncate.AtEnd,
    }
    for k,v in pairs(props or {}) do settings[k] = v end
    return make("TextLabel", settings, parent)
end

local function button(parent, name, props)
    local defaults = {
        Name = name, Text = "", AutoButtonColor = false,
        BorderSizePixel = 0, BackgroundTransparency = 1,
        TextColor3 = WHITE, TextSize = 12, Font = Enum.Font.GothamBold,
    }
    for k,v in pairs(props or {}) do defaults[k] = v end
    return make("TextButton", defaults, parent)
end

-- Draw all essential interface icons from native UI primitives. No missing
-- Unicode glyphs, remote icon modules, image permissions or executor assets.
local function icon(parent, kind, size, color)
    local frame = make("Frame", {
        BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size),
        Name = "Vector_" .. kind,
    }, parent)
    local function line(x, y, w, h, rotation, radius)
        local piece = make("Frame", {
            BackgroundColor3 = color or WHITE, BorderSizePixel = 0,
            Size = UDim2.fromOffset(w, h), Position = UDim2.fromOffset(x, y),
            Rotation = rotation or 0,
        }, frame)
        corner(piece, radius or math.min(h,w)/2)
        return piece
    end
    if kind == "chat" then
        local bubble = make("Frame", {
            BackgroundTransparency = 1, BorderSizePixel = 0,
            Size = UDim2.fromOffset(size-6, size-9), Position = UDim2.fromOffset(2, 2),
        }, frame)
        corner(bubble, 4)
        stroke(bubble, color, 0, 1.6)
        line(6, 7, size-14, 2)
        line(6, 12, size-17, 2)
        line(3, size-6, 5, 2, -35)
    elseif kind == "send" then
        line(3, math.floor(size/2), size-9, 2)
        line(size-10, math.floor(size/2)-5, 10, 2, 45)
        line(size-10, math.floor(size/2)+5, 10, 2, -45)
    elseif kind == "emoji" then
        local circle = make("Frame", {
            Size = UDim2.fromOffset(size-4,size-4),
            Position = UDim2.fromOffset(2,2), BackgroundTransparency = 1,
        },frame)
        corner(circle, size)
        stroke(circle,color,0,1.6)
        line(math.floor(size*.31),math.floor(size*.34),2,2,0,2)
        line(math.floor(size*.64),math.floor(size*.34),2,2,0,2)
        line(math.floor(size*.35),math.floor(size*.64),math.floor(size*.36),2,0,2)
    elseif kind == "reply" then
        line(4,math.floor(size*.35),size-9,2)
        line(3,math.floor(size*.35),8,2,-45)
        line(3,math.floor(size*.35),8,2,45)
        line(math.floor(size*.70),math.floor(size*.35),2,math.floor(size*.36))
    elseif kind == "close" then
        line(4,math.floor(size/2),size-8,2,45)
        line(4,math.floor(size/2),size-8,2,-45)
    else
        line(3,math.floor(size/2),size-6,2)
    end
    return frame
end

local function generalChannel()
    local channels = TextChatService:FindFirstChild("TextChannels")
    local general = channels and channels:FindFirstChild("RBXGeneral")
    return (general and general:IsA("TextChannel")) and general or nil
end

local function languageOf(value)
    local result = "EN"
    pcall(function()
        for _, c in utf8.codes(value) do
            if (c >= 0x0600 and c <= 0x06FF)
                or (c >= 0x0750 and c <= 0x077F)
                or (c >= 0x08A0 and c <= 0x08FF)
                or (c >= 0xFB50 and c <= 0xFDFF)
                or (c >= 0xFE70 and c <= 0xFEFF) then
                result = "AR"
                break
            end
        end
    end)
    return result
end

local function avatarURL(userId)
    return ("rbxthumb://type=AvatarHeadShot&id=%d&w=100&h=100"):format(userId)
end

local function decodeMetadata(value)
    if type(value) ~= "string" or value:sub(1, #META_PREFIX) ~= META_PREFIX then return nil end
    local ok, data = pcall(HttpService.JSONDecode, HttpService, value:sub(#META_PREFIX + 1))
    if not ok or type(data) ~= "table" or data.v ~= 2 then return nil end
    if data.lang ~= "EN" and data.lang ~= "AR" then return nil end
    return data
end

local function safeExcerpt(value)
    local result = tostring(value or ""):gsub("[%c]", " ")
    return result:sub(1, 64)
end

function Chat.Mount(tab)
    local viewport = assert(tab.UIElements and tab.UIElements.ContainerFrame, "VantaTest Chat: tab container missing")
    local old = viewport:FindFirstChild("VantaChatExperiment")
    if old then old:Destroy() end
    local pad = viewport:FindFirstChildOfClass("UIPadding")
    if pad then
        pad.PaddingTop = UDim.new(0, 3)
        pad.PaddingBottom = UDim.new(0, 3)
        pad.PaddingLeft = UDim.new(0, 3)
        pad.PaddingRight = UDim.new(0, 3)
    end

    local root = make("Frame", {
        Name = "VantaChatExperiment", LayoutOrder = 1,
        Size = UDim2.new(1, 0, 0, 405), BackgroundColor3 = BG,
        BackgroundTransparency = 0.03, BorderSizePixel = 0, ClipsDescendants = true,
    }, viewport)
    corner(root, 15)
    stroke(root, LINE, 0.47)

    local subscriptions = {}
    local items, index = {}, {}
    local destroyed = false
    local roomName = "EN"
    local replyTo = nil
    local menuFor = nil
    local sending = false
    local emojiVisible = false
    local serial = 0
    local function sub(connection)
        subscriptions[#subscriptions+1] = connection
        return connection
    end

    label(root,"Chat",18,WHITE,true,{
        Position=UDim2.fromOffset(14,6),Size=UDim2.new(1,-85,0,24),
    })
    local description = label(root,"Public Roblox chat  ·  current server",10,DIM,false,{
        Position=UDim2.fromOffset(14,29),Size=UDim2.new(1,-85,0,17),
    })
    local statusDot = make("Frame", {
        Position=UDim2.new(1,-58,0,19),Size=UDim2.fromOffset(7,7),
        BackgroundColor3=GREEN,BorderSizePixel=0,
    },root)
    corner(statusDot,7)
    local status = label(root,"SERVER",9,GREEN,true,{
        Position=UDim2.new(1,-47,0,12),Size=UDim2.fromOffset(46,21),
    })

    local head = make("Frame",{
        Name="RoomHeader",Position=UDim2.fromOffset(10,53),
        Size=UDim2.new(1,-20,0,54),BackgroundColor3=HEADER,
        BorderSizePixel=0,
    },root)
    corner(head,12)
    stroke(head,LINE,.58)
    local badge = make("Frame",{
        Position=UDim2.fromOffset(9,10),Size=UDim2.fromOffset(33,33),
        BackgroundColor3=ACCENT,BorderSizePixel=0,
    },head)
    corner(badge,9)
    local chatIcon=icon(badge,"chat",21,WHITE)
    chatIcon.Position=UDim2.fromOffset(6,6)

    label(head,"Vanta Chat",13,WHITE,true,{
        Position=UDim2.fromOffset(49,7),Size=UDim2.new(1,-242,0,21),
    })
    local members=label(head,"Script members in this server",10,DIM,false,{
        Position=UDim2.fromOffset(49,28),Size=UDim2.new(1,-242,0,17),
    })
    local function roomButton(name, x)
        local btn=button(head,name.."Room",{
            Text=name,Position=UDim2.new(1,x,0,14),Size=UDim2.fromOffset(39,26),
            BackgroundTransparency=0,BackgroundColor3=PANEL,
            TextSize=10,TextColor3=DIM,
        })
        corner(btn,14)
        return btn
    end
    local btnEN=roomButton("EN",-139)
    local btnAR=roomButton("AR",-96)
    local heads=make("Frame",{
        BackgroundTransparency=1,Position=UDim2.new(1,-51,0,8),
        Size=UDim2.fromOffset(46,38),
    },head)
    local function presence()
        if destroyed then return end
        local players=Players:GetPlayers()
        members.Text=tostring(#players).." players  ·  this server"
        for _,child in ipairs(heads:GetChildren()) do child:Destroy() end
        for i=1,math.min(3,#players) do
            local iconHead=make("ImageLabel",{
                BackgroundColor3=Color3.fromRGB(64,54,59),BorderSizePixel=0,
                Image=avatarURL(players[i].UserId),
                Position=UDim2.fromOffset((i-1)*11,8),Size=UDim2.fromOffset(25,25),
                ZIndex=2+i,
            },heads)
            corner(iconHead,13)
            stroke(iconHead,BG,0,1.5)
        end
    end

    local feed=make("ScrollingFrame",{
        Name="MessageFeed",
        Position=UDim2.fromOffset(10,113),Size=UDim2.new(1,-20,1,-177),
        CanvasSize=UDim2.new(),AutomaticCanvasSize=Enum.AutomaticSize.Y,
        ScrollingDirection=Enum.ScrollingDirection.Y,ScrollBarThickness=2,
        ScrollBarImageColor3=ACCENT,BackgroundColor3=PANEL,
        BackgroundTransparency=.36,BorderSizePixel=0,
    },root)
    corner(feed,10)
    make("UIPadding",{
        PaddingTop=UDim.new(0,10),PaddingBottom=UDim.new(0,9),
        PaddingLeft=UDim.new(0,8),PaddingRight=UDim.new(0,8),
    },feed)
    local layout=make("UIListLayout",{
        SortOrder=Enum.SortOrder.LayoutOrder,Padding=UDim.new(0,7),
    },feed)

    local compose=make("Frame",{
        Name="Composer",Position=UDim2.new(0,10,1,-54),
        Size=UDim2.new(1,-20,0,45),BackgroundColor3=HEADER,
        BorderSizePixel=0,
    },root)
    corner(compose,21)
    stroke(compose,LINE,.52)

    local emojiButton=button(compose,"EmojiPickerToggle",{
        Position=UDim2.fromOffset(7,6),Size=UDim2.fromOffset(34,33),
    })
    local smile=icon(emojiButton,"emoji",21,DIM)
    smile.Position=UDim2.fromOffset(6,6)
    local entry=make("TextBox",{
        Name="MessageInput",Text="",PlaceholderText="Message in EN...",
        BackgroundTransparency=1,ClearTextOnFocus=false,
        Font=Enum.Font.Gotham,TextSize=13,TextColor3=WHITE,
        PlaceholderColor3=DIM,TextXAlignment=Enum.TextXAlignment.Left,
        TextYAlignment=Enum.TextYAlignment.Center,MultiLine=false,
        Position=UDim2.fromOffset(46,2),Size=UDim2.new(1,-96,1,-4),
    },compose)
    local send=button(compose,"SendMessage",{
        Position=UDim2.new(1,-40,0,5),Size=UDim2.fromOffset(35,35),
        BackgroundTransparency=0,BackgroundColor3=ACCENT,
    })
    corner(send,18)
    local sendIcon=icon(send,"send",19,WHITE)
    sendIcon.Position=UDim2.fromOffset(8,8)

    local replyBar=make("Frame",{
        Name="ReplyPreview",Visible=false,
        Position=UDim2.new(0,10,1,-91),Size=UDim2.new(1,-20,0,32),
        BackgroundColor3=Color3.fromRGB(39,27,33),BorderSizePixel=0,
    },root)
    corner(replyBar,8)
    local quoteMarker=make("Frame",{
        Size=UDim2.new(0,3,1,-8),Position=UDim2.fromOffset(7,4),
        BackgroundColor3=ACCENT,BorderSizePixel=0,
    },replyBar)
    corner(quoteMarker,2)
    local replyPreviewText=label(replyBar,"Replying",11,WHITE,false,{
        Position=UDim2.fromOffset(17,1),Size=UDim2.new(1,-49,1,-2),
    })
    local cancelReply=button(replyBar,"CancelReply",{
        Position=UDim2.new(1,-33,0,2),Size=UDim2.fromOffset(29,29),
    })
    local closeIcon=icon(cancelReply,"close",15,DIM)
    closeIcon.Position=UDim2.fromOffset(7,7)

    local popup=make("Frame",{
        Name="EmojiPicker",Visible=false,
        Position=UDim2.new(0,10,1,-189),Size=UDim2.fromOffset(231,130),
        BackgroundColor3=Color3.fromRGB(31,26,30),BorderSizePixel=0,
        ZIndex=20,
    },root)
    corner(popup,12)
    stroke(popup,LINE,.20)
    label(popup,"EMOJI",10,DIM,true,{
        Position=UDim2.fromOffset(12,5),Size=UDim2.new(1,-20,0,17),ZIndex=21,
    })
    local emojiSet={"😀","😂","😍","🥹","😭","❤️","🖤","🌹","🔥","👍","👀","✨","😎","💀","💋","🙏"}
    for i,symbol in ipairs(emojiSet) do
        local cell=button(popup,"Emoji_"..i,{
            Text=symbol,Font=Enum.Font.SourceSans,TextSize=20,
            Position=UDim2.fromOffset(8+((i-1)%8)*27,24+math.floor((i-1)/8)*42),
            Size=UDim2.fromOffset(25,32),ZIndex=21,
        })
        sub(cell.MouseButton1Click:Connect(function()
            if destroyed then return end
            entry.Text=entry.Text..symbol
            entry:CaptureFocus()
        end))
    end

    local context=make("Frame",{
        Name="MessageActions",Visible=false,
        Position=UDim2.new(1,-144,0,118),Size=UDim2.fromOffset(136,0),
        AutomaticSize=Enum.AutomaticSize.Y,
        BackgroundColor3=Color3.fromRGB(37,30,34),BorderSizePixel=0,
        ZIndex=30,
    },root)
    corner(context,10)
    stroke(context,LINE,.16)
    make("UIPadding",{
        PaddingTop=UDim.new(0,5),PaddingBottom=UDim.new(0,5),
        PaddingLeft=UDim.new(0,5),PaddingRight=UDim.new(0,5),
    },context)
    make("UIListLayout",{Padding=UDim.new(0,2),SortOrder=Enum.SortOrder.LayoutOrder},context)

    local menuHandlers={}
    for i,item in ipairs({"Reply","Copy","React ❤️","React 👍","Hide locally","Cancel"}) do
        local b=button(context,"Menu_"..i,{
            Text=item,TextColor3=WHITE,TextSize=11,
            TextXAlignment=Enum.TextXAlignment.Left,
            Size=UDim2.new(1,0,0,27),LayoutOrder=i,
            BackgroundTransparency=0.88,BackgroundColor3=LINE,
            ZIndex=31,
        })
        corner(b,6)
        make("UIPadding",{PaddingLeft=UDim.new(0,9)},b)
        menuHandlers[i]=b
    end

    local function updateStatus()
        if destroyed then return end
        local available=generalChannel()~=nil
        statusDot.BackgroundColor3=available and GREEN or Color3.fromRGB(244,168,93)
        status.Text=available and "SERVER" or "OFF"
        status.TextColor3=available and GREEN or Color3.fromRGB(244,168,93)
        description.Text=available and "Public game chat  ·  same server"
            or "Chat unavailable in this experience"
        entry.PlaceholderText=available and (roomName=="AR" and "رسالة عامة..." or "Public chat in EN...")
            or "TextChatService unavailable"
        entry.TextXAlignment=roomName=="AR" and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left
    end

    local function refreshRooms()
        btnEN.BackgroundColor3=roomName=="EN" and ACCENT or PANEL
        btnAR.BackgroundColor3=roomName=="AR" and ACCENT or PANEL
        btnEN.TextColor3=roomName=="EN" and WHITE or DIM
        btnAR.TextColor3=roomName=="AR" and WHITE or DIM
        updateStatus()
    end

    local function setReply(item)
        replyTo=item
        menuFor=nil
        context.Visible=false
        if not item then
            replyBar.Visible=false
            feed.Size=UDim2.new(1,-20,1,-177)
        else
            replyBar.Visible=true
            replyPreviewText.Text=tostring(item.display or "Player")..": "..safeExcerpt(item.content)
            feed.Size=UDim2.new(1,-20,1,-214)
        end
    end

    local function timeString(item)
        local stamp=tonumber(item.time) or os.time()
        local ok, value=pcall(os.date,"%H:%M",stamp)
        return ok and value or ""
    end

    local function bottom()
        task.defer(function()
            if not destroyed and feed.Parent then
                feed.CanvasPosition=Vector2.new(0,math.max(0,layout.AbsoluteContentSize.Y-feed.AbsoluteSize.Y+24))
            end
        end)
    end

    local example={
        {id="demo-en-1",display="Vanta Preview",content="Welcome to Vanta Chat! Tap a bubble for reply, copy and reactions.",lang="EN",demo=true,time=os.time()-55},
        {id="demo-en-2",display="Design Preview",content="Choose the emoji icon at the bottom left 🌹",lang="EN",demo=true,time=os.time()-33},
        {id="demo-ar-1",display="معاينة فانتـا",content="هلا والله! هذه معاينة للمحادثة العربية 🤍",lang="AR",demo=true,time=os.time()-35},
    }

    local function renderRow(item, order)
        local own=item.userId==LocalPlayer.UserId and not item.demo
        local width=math.max(180,feed.AbsoluteSize.X-82)
        local lineText=tostring(item.content or "")
        local measured=TextService:GetTextSize(lineText,12,Enum.Font.Gotham,Vector2.new(width-27,3000))
        local linesHeight=math.max(19,measured.Y+3)
        local reply=type(item.replyId)=="string" and index[item.replyId] or nil
        local extra=reply and 30 or 0
        local rowHeight=math.min(310,linesHeight+47+extra)
        local row=make("Frame",{
            Name="MessageRow",LayoutOrder=order,
            Size=UDim2.new(1,0,0,rowHeight),BackgroundTransparency=1,
        },feed)

        local badgeFrame=make("Frame",{
            Size=UDim2.fromOffset(27,27),
            Position=own and UDim2.new(1,-27,0,4) or UDim2.fromOffset(0,4),
            BackgroundColor3=Color3.fromRGB(75,52,63),BorderSizePixel=0,
        },row)
        corner(badgeFrame,15)
        if item.userId then
            local img=make("ImageLabel",{
                Image=avatarURL(item.userId),BackgroundTransparency=1,
                Size=UDim2.fromScale(1,1),
            },badgeFrame)
            corner(img,15)
        else
            label(badgeFrame,"V",14,WHITE,true,{
                Size=UDim2.fromScale(1,1),TextXAlignment=Enum.TextXAlignment.Center,
            })
        end
        local bubble=button(row,"Bubble",{
            BackgroundTransparency=.09,BackgroundColor3=own and OWN or BUBBLE,
            Position=own and UDim2.fromOffset(0,0) or UDim2.fromOffset(34,0),
            Size=UDim2.new(1,-38,0,rowHeight-2),
        })
        corner(bubble,12)
        local title=tostring(item.display or "Player")..(item.demo and "  · PREVIEW" or "")
        label(bubble,title,12,item.demo and Color3.fromRGB(223,164,184) or WHITE,true,{
            Position=UDim2.fromOffset(10,3),Size=UDim2.new(1,-90,0,19),
        })
        label(bubble,timeString(item),9,DIM,false,{
            Position=UDim2.new(1,-49,0,4),Size=UDim2.fromOffset(42,16),
            TextXAlignment=Enum.TextXAlignment.Right,
        })
        if reply then
            local quoted=make("Frame",{
                Position=UDim2.fromOffset(10,24),Size=UDim2.new(1,-20,0,27),
                BackgroundColor3=Color3.fromRGB(73,43,54),
                BackgroundTransparency=.29,BorderSizePixel=0,
            },bubble)
            corner(quoted,6)
            make("Frame",{
                BackgroundColor3=ACCENT,BorderSizePixel=0,
                Position=UDim2.fromOffset(0,0),Size=UDim2.new(0,3,1,0),
            },quoted)
            label(quoted,tostring(reply.display)..": "..safeExcerpt(reply.content),10,WHITE,false,{
                Position=UDim2.fromOffset(9,1),Size=UDim2.new(1,-16,1,-2),
            })
        end
        label(bubble,lineText,12,WHITE,false,{
            Position=UDim2.fromOffset(11,24+extra),
            Size=UDim2.new(1,-22,0,linesHeight),
            TextWrapped=true,TextTruncate=Enum.TextTruncate.None,
            TextYAlignment=Enum.TextYAlignment.Top,
            TextXAlignment=item.lang=="AR" and Enum.TextXAlignment.Right or Enum.TextXAlignment.Left,
        })
        if item.reaction then
            label(bubble,item.reaction,12,WHITE,true,{
                Position=UDim2.new(1,-34,1,-20),
                Size=UDim2.fromOffset(30,18),
                TextXAlignment=Enum.TextXAlignment.Center,
            })
        end
        bubble.MouseButton1Click:Connect(function()
            menuFor=item
            emojiVisible=false
            popup.Visible=false
            context.Visible=true
            local relY=math.max(115,math.min(root.AbsoluteSize.Y-211,row.AbsolutePosition.Y-root.AbsolutePosition.Y))
            context.Position=UDim2.new(1,-149,0,relY)
        end)
    end

    local function render()
        if destroyed then return end
        for _,child in ipairs(feed:GetChildren()) do
            if child.Name=="MessageRow" then child:Destroy() end
        end
        local showing=(#items>0) and items or example
        local order=0
        for _,item in ipairs(showing) do
            if item.lang==roomName and not item.hidden then
                order=order+1
                renderRow(item,order)
            end
        end
        if order==0 then
            renderRow({
                id="none",display="Vanta Chat",
                content=roomName=="AR" and "لا توجد رسائل بعد. ابدأ المحادثة! 🌹"
                    or "No messages in this room yet. Say hello! 🌹",
                lang=roomName,demo=true,time=os.time(),
            },1)
        end
        bottom()
    end

    sub(btnEN.MouseButton1Click:Connect(function()
        roomName="EN";setReply(nil);refreshRooms();render()
    end))
    sub(btnAR.MouseButton1Click:Connect(function()
        roomName="AR";setReply(nil);refreshRooms();render()
    end))
    sub(cancelReply.MouseButton1Click:Connect(function()setReply(nil)end))
    sub(emojiButton.MouseButton1Click:Connect(function()
        emojiVisible=not emojiVisible
        popup.Visible=emojiVisible
        context.Visible=false
    end))

    local function contextAction(number)
        local item=menuFor
        menuFor=nil
        context.Visible=false
        if not item then return end
        if number==1 then
            setReply(item)
            entry:CaptureFocus()
        elseif number==2 then
            if type(setclipboard)=="function" then
                pcall(setclipboard,tostring(item.content or ""))
            elseif type(toclipboard)=="function" then
                pcall(toclipboard,tostring(item.content or ""))
            end
        elseif number==3 or number==4 then
            item.reaction=number==3 and "❤️" or "👍"
            render()
        elseif number==5 then
            item.hidden=true
            render()
        end
    end
    for i,b in ipairs(menuHandlers) do
        sub(b.MouseButton1Click:Connect(function()contextAction(i)end))
    end

    local lastSend = 0
    local function outgoing()
        if destroyed or sending or os.clock()-lastSend < 0.85 then return end
        local raw=tostring(entry.Text or "")
        local trimmed=raw:match("^%s*(.-)%s*$") or ""
        if trimmed=="" then return end
        local target=generalChannel()
        if not target then updateStatus();return end
        sending=true
        lastSend=os.clock()
        send.BackgroundColor3=Color3.fromRGB(79,66,71)
        local replyId=replyTo and (replyTo.messageId or replyTo.id) or nil
        local meta={v=2,lang=roomName}
        if type(replyId)=="string" and #replyId<110 then meta.r=replyId end
        local encoded=META_PREFIX..HttpService:JSONEncode(meta)
        local value=utf8.len(trimmed) and trimmed or raw
        task.spawn(function()
            local ok,err=pcall(function()
                target:SendAsync(value:sub(1,300),encoded)
            end)
            if destroyed then return end
            sending=false
            send.BackgroundColor3=ACCENT
            if ok then
                entry.Text=""
                setReply(nil)
                emojiVisible=false
                popup.Visible=false
            else
                warn("[Vanta Chat] Failed sending message: "..tostring(err))
                entry.PlaceholderText="Couldn't send. Try again."
            end
        end)
    end
    sub(send.MouseButton1Click:Connect(outgoing))
    sub(entry.FocusLost:Connect(function(enter)
        if enter then outgoing() end
    end))

    sub(TextChatService.MessageReceived:Connect(function(message)
        if destroyed or not message or not message.TextSource then return end
        if not message.TextChannel or message.TextChannel.Name~="RBXGeneral" then return end
        local data=decodeMetadata(message.Metadata)
        if not data then return end
        local raw=tostring(message.Text or "")
        if raw=="" then return end
        local messageId=tostring(message.MessageId or "")
        if messageId~="" and index[messageId] then return end
        serial=serial+1
        local userId=message.TextSource.UserId
        local person=Players:GetPlayerByUserId(userId)
        local item={
            id=messageId~="" and messageId or ("local-"..serial),
            messageId=messageId,replyId=data.r,
            userId=userId,display=person and person.DisplayName or ("Player "..userId),
            name=person and person.Name or tostring(userId),
            content=raw,lang=data.lang,time=os.time(),
        }
        items[#items+1]=item
        index[item.id]=item
        while #items>70 do
            local removed=table.remove(items,1)
            index[removed.id]=nil
        end
        render()
    end))
    sub(Players.PlayerAdded:Connect(presence))
    sub(Players.PlayerRemoving:Connect(function()task.defer(presence)end))
    local channels=TextChatService:FindFirstChild("TextChannels")
    if channels then sub(channels.ChildAdded:Connect(updateStatus)) end
    sub(feed:GetPropertyChangedSignal("AbsoluteSize"):Connect(render))
    sub(root.Destroying:Connect(function()
        destroyed=true
        for _,connection in ipairs(subscriptions) do
            connection:Disconnect()
        end
        table.clear(subscriptions)
    end))

    presence()
    refreshRooms()
    render()
    return root
end

return Chat
