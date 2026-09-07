local MusicPlayer = {
    WindUI = nil,
    Window = nil,
    UI = nil,
    Tracks = {},
    Rows = {},
    CurrentIndex = nil,
    Playing = false,
    Shuffle = false,
    RepeatOne = false,
    Volume = 0.65,
    Folder = "VantaTest/Music",
}

local cloneref = cloneref or clonereference or function(v) return v end
local SoundService = cloneref(game:GetService("SoundService"))
local UserInputService = cloneref(game:GetService("UserInputService"))
local RunService = cloneref(game:GetService("RunService"))
local CustomAsset = getcustomasset or getsynasset
local OpenFolder = openfolder or open_folder

local AUDIO = { mp3 = true, wav = true, ogg = true }
local COVER_EXTS = { "png", "jpg", "jpeg", "webp" }

local function norm(p) return tostring(p or ""):gsub("\\", "/") end
local function ext(p) return string.lower((p:match("%.([^%.%/]+)$") or "")) end
local function nameOnly(p)
    p = norm(p)
    local f = p:match("([^/]+)$") or p
    return f:gsub("%.[^%.]+$", "")
end
local function ensure(path)
    if not makefolder then return end
    local cur = ""
    for part in norm(path):gmatch("[^/]+") do
        cur = cur == "" and part or (cur .. "/" .. part)
        if not isfolder or not isfolder(cur) then pcall(makefolder, cur) end
    end
end
local function exists(path)
    if not isfile then return false end
    local ok, value = pcall(isfile, path)
    return ok and value
end
local function timeText(t)
    t = math.max(0, tonumber(t) or 0)
    return string.format("%d:%02d", math.floor(t / 60), math.floor(t % 60))
end

function MusicPlayer:_theme(key, fallback)
    local t = self.WindUI and self.WindUI.Theme
    return (t and t[key]) or fallback
end

function MusicPlayer:_icon(parent, iconName, size)
    local img = Instance.new("ImageLabel")
    img.BackgroundTransparency = 1
    img.Size = UDim2.fromOffset(size, size)
    img.ImageColor3 = self:_theme("Icon", Color3.fromRGB(226,221,224))
    local creator = self.WindUI and self.WindUI.Creator
    local icon = creator and creator.Icon and creator.Icon(iconName)
    if icon then
        img.Image = icon[1]
        if icon[2] then
            img.ImageRectOffset = icon[2].ImageRectPosition
            img.ImageRectSize = icon[2].ImageRectSize
        end
    end
    img.Parent = parent
    return img
end

function MusicPlayer:_text(parent, text, size, bold)
    local label = Instance.new("TextLabel")
    label.BackgroundTransparency = 1
    label.Text = text or ""
    label.TextColor3 = self:_theme("Text", Color3.new(1,1,1))
    label.TextSize = size or 13
    label.TextXAlignment = Enum.TextXAlignment.Left
    label.TextTruncate = Enum.TextTruncate.AtEnd
    local font = self.WindUI and self.WindUI.Creator and self.WindUI.Creator.Font
    label.FontFace = Font.new(font or "rbxasset://fonts/families/GothamSSm.json", bold and Enum.FontWeight.SemiBold or Enum.FontWeight.Regular)
    label.Parent = parent
    return label
end

function MusicPlayer:_button(parent, iconName, size, callback)
    local b = Instance.new("TextButton")
    b.AutoButtonColor = false
    b.Text = ""
    b.BackgroundColor3 = self:_theme("Button", Color3.fromRGB(37,16,22))
    b.BackgroundTransparency = 1
    b.Size = UDim2.fromOffset(size, size)
    b.Parent = parent
    local c = Instance.new("UICorner")
    c.CornerRadius = UDim.new(0, math.floor(size/3))
    c.Parent = b
    local icon = self:_icon(b, iconName, math.floor(size * 0.48))
    icon.AnchorPoint = Vector2.new(0.5,0.5)
    icon.Position = UDim2.fromScale(0.5,0.5)
    b.MouseEnter:Connect(function() b.BackgroundTransparency = 0.35 end)
    b.MouseLeave:Connect(function() b.BackgroundTransparency = 1 end)
    b.MouseButton1Click:Connect(function()
        if self.WindUI and self.WindUI.PlaySound then self.WindUI:PlaySound("Click") end
        if callback then callback() end
    end)
    return b, icon
end

function MusicPlayer:_coverFor(track)
    if not CustomAsset or not track then return nil end
    local base = track.Path:gsub("%.[^%.%/]+$", "")
    for _, e in ipairs(COVER_EXTS) do
        local p = base .. "." .. e
        if exists(p) then
            local ok, asset = pcall(CustomAsset, p)
            if ok then return asset end
        end
    end
    local folder = norm(track.Path):match("^(.*)/[^/]+$") or self.Folder
    for _, e in ipairs(COVER_EXTS) do
        local p = folder .. "/cover." .. e
        if exists(p) then
            local ok, asset = pcall(CustomAsset, p)
            if ok then return asset end
        end
    end
    return nil
end

function MusicPlayer:Refresh()
    ensure("VantaTest")
    ensure(self.Folder)
    self.Tracks = {}
    if listfiles then
        local ok, files = pcall(listfiles, self.Folder)
        if ok and type(files) == "table" then
            for _, p in ipairs(files) do
                p = norm(p)
                if AUDIO[ext(p)] then
                    table.insert(self.Tracks, { Path = p, Name = nameOnly(p), Asset = nil, Cover = nil })
                end
            end
            table.sort(self.Tracks, function(a,b) return a.Name:lower() < b.Name:lower() end)
        end
    end
    if self.CurrentIndex and not self.Tracks[self.CurrentIndex] then self.CurrentIndex = nil end
    self:_renderList()
    self:_update()
end

function MusicPlayer:_load(index, autoplay)
    local t = self.Tracks[index]
    if not t or not CustomAsset then return end
    if not t.Asset then
        local ok, asset = pcall(CustomAsset, t.Path)
        if not ok or not asset then return end
        t.Asset = asset
    end
    self.CurrentIndex = index
    self.Sound:Stop()
    self.Sound.SoundId = t.Asset
    self.Sound.Volume = self.Volume
    self.Sound.Looped = self.RepeatOne
    if autoplay ~= false then self.Sound:Play(); self.Playing = true else self.Playing = false end
    self:_update()
    self:_renderList()
end

function MusicPlayer:TogglePlay()
    if not self.CurrentIndex then
        if #self.Tracks > 0 then self:_load(1, true) end
        return
    end
    if self.Sound.IsPlaying then self.Sound:Pause(); self.Playing = false else self.Sound:Resume(); self.Playing = true end
    self:_update()
end

function MusicPlayer:Next()
    if #self.Tracks == 0 then return end
    local i
    if self.Shuffle and #self.Tracks > 1 then
        repeat i = math.random(1,#self.Tracks) until i ~= self.CurrentIndex
    else
        i = ((self.CurrentIndex or 0) % #self.Tracks) + 1
    end
    self:_load(i, true)
end

function MusicPlayer:Previous()
    if #self.Tracks == 0 then return end
    local i = (self.CurrentIndex or 2) - 1
    if i < 1 then i = #self.Tracks end
    self:_load(i, true)
end

function MusicPlayer:_drag(frame, handle)
    local dragging, startPos, startInput
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            startInput = input.Position
            startPos = frame.Position
        end
    end)
    UserInputService.InputChanged:Connect(function(input)
        if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch) then
            local d = input.Position - startInput
            frame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + d.X, startPos.Y.Scale, startPos.Y.Offset + d.Y)
        end
    end)
    UserInputService.InputEnded:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then dragging = false end
    end)
end

function MusicPlayer:_renderList()
    if not self.UI then return end
    for _, row in ipairs(self.Rows) do row:Destroy() end
    self.Rows = {}
    self.UI.Empty.Visible = #self.Tracks == 0
    for i, track in ipairs(self.Tracks) do
        local row = Instance.new("TextButton")
        row.AutoButtonColor = false
        row.Text = ""
        row.Size = UDim2.new(1,0,0,28)
        row.BackgroundColor3 = self:_theme("ElementBackground", Color3.fromRGB(21,17,22))
        row.BackgroundTransparency = i == self.CurrentIndex and 0.05 or 1
        row.Parent = self.UI.List
        local c = Instance.new("UICorner"); c.CornerRadius = UDim.new(0,8); c.Parent = row
        local title = self:_text(row, track.Name, 12, false)
        title.Position = UDim2.fromOffset(8,0); title.Size = UDim2.new(1,-55,1,0)
        local num = self:_text(row, string.format("%02d", i), 10, false)
        num.Position = UDim2.new(1,-30,0,0); num.Size = UDim2.fromOffset(22,28); num.TextXAlignment = Enum.TextXAlignment.Right
        row.MouseButton1Click:Connect(function() self:_load(i, true) end)
        table.insert(self.Rows, row)
    end
end

function MusicPlayer:_update()
    if not self.UI then return end
    local t = self.CurrentIndex and self.Tracks[self.CurrentIndex]
    self.UI.Title.Text = t and t.Name or "Nothing playing"
    self.UI.Sub.Text = t and "Local MP3" or "Drop songs into VantaTest/Music"
    self.UI.PlayIcon.Visible = not self.Playing
    self.UI.PauseIcon.Visible = self.Playing
    self.UI.Time.Text = timeText(self.Sound and self.Sound.TimePosition or 0)
    local len = self.Sound and self.Sound.TimeLength or 0
    self.UI.Duration.Text = timeText(len)
    local ratio = (len > 0 and self.Sound.TimePosition / len) or 0
    self.UI.ProgressFill.Size = UDim2.new(math.clamp(ratio,0,1),0,1,0)
    local cover = t and (t.Cover or self:_coverFor(t)) or nil
    if t then t.Cover = cover end
    self.UI.Cover.Image = cover or ""
    self.UI.Cover.Visible = cover ~= nil
    self.UI.CoverFallback.Visible = cover == nil
    self.UI.MiniTitle.Text = t and t.Name or "Music Player"
    self.UI.MiniPlay.Visible = not self.Playing
    self.UI.MiniPause.Visible = self.Playing
end

function MusicPlayer:_build()
    if self.UI then return end
    local parent = self.WindUI.ScreenGui
    local root = Instance.new("Frame")
    root.Name = "VantaCompactMusicPlayer"
    root.Size = UDim2.fromOffset(360, 258)
    root.Position = UDim2.new(0.5,-180,0.5,-129)
    root.BackgroundColor3 = self:_theme("Background", Color3.fromRGB(0,0,0))
    root.BackgroundTransparency = 0.03
    root.BorderSizePixel = 0
    root.ZIndex = 5000
    root.Visible = false
    root.Parent = parent
    local rc = Instance.new("UICorner"); rc.CornerRadius = UDim.new(0,14); rc.Parent = root
    local stroke = Instance.new("UIStroke"); stroke.Color = self:_theme("Outline", Color3.fromRGB(90,24,36)); stroke.Transparency = 0.7; stroke.Thickness = 1; stroke.Parent = root

    local top = Instance.new("Frame")
    top.Size = UDim2.new(1,0,0,36); top.BackgroundTransparency = 1; top.Active = true; top.ZIndex = 5001; top.Parent = root
    local musicIcon = self:_icon(top,"music-2",16); musicIcon.Position = UDim2.fromOffset(12,10)
    local topTitle = self:_text(top,"Music Player",13,true); topTitle.Position = UDim2.fromOffset(36,0); topTitle.Size = UDim2.new(1,-110,1,0)
    local min = self:_button(top,"minus",26,function() self:Minimize() end); min.Position = UDim2.new(1,-60,0,5)
    local close = self:_button(top,"x",26,function() root.Visible = false end); close.Position = UDim2.new(1,-30,0,5)

    local coverBox = Instance.new("Frame")
    coverBox.Size = UDim2.fromOffset(72,72); coverBox.Position = UDim2.fromOffset(12,48); coverBox.BackgroundColor3 = self:_theme("ElementBackground", Color3.fromRGB(21,17,22)); coverBox.BorderSizePixel=0; coverBox.Parent=root
    local cc=Instance.new("UICorner"); cc.CornerRadius=UDim.new(0,10); cc.Parent=coverBox
    local cover=Instance.new("ImageLabel"); cover.BackgroundTransparency=1; cover.Size=UDim2.fromScale(1,1); cover.ScaleType=Enum.ScaleType.Crop; cover.Parent=coverBox
    local coverFallback=self:_icon(coverBox,"disc-3",28); coverFallback.AnchorPoint=Vector2.new(.5,.5); coverFallback.Position=UDim2.fromScale(.5,.5)

    local title=self:_text(root,"Nothing playing",14,true); title.Position=UDim2.fromOffset(96,48); title.Size=UDim2.new(1,-108,0,22)
    local sub=self:_text(root,"Drop songs into VantaTest/Music",10,false); sub.Position=UDim2.fromOffset(96,68); sub.Size=UDim2.new(1,-108,0,18); sub.TextTransparency=.4

    local progress=Instance.new("TextButton"); progress.Text=""; progress.AutoButtonColor=false; progress.BackgroundColor3=self:_theme("ElementBackground",Color3.fromRGB(21,17,22)); progress.BackgroundTransparency=.2; progress.Size=UDim2.new(1,-108,0,4); progress.Position=UDim2.fromOffset(96,92); progress.Parent=root
    local pc=Instance.new("UICorner"); pc.CornerRadius=UDim.new(1,0); pc.Parent=progress
    local fill=Instance.new("Frame"); fill.BackgroundColor3=self:_theme("Slider",Color3.fromRGB(161,22,47)); fill.BorderSizePixel=0; fill.Size=UDim2.new(0,0,1,0); fill.Parent=progress
    local fc=Instance.new("UICorner"); fc.CornerRadius=UDim.new(1,0); fc.Parent=fill
    progress.MouseButton1Down:Connect(function(x)
        local r=math.clamp((x-progress.AbsolutePosition.X)/progress.AbsoluteSize.X,0,1)
        if self.Sound and self.Sound.TimeLength>0 then self.Sound.TimePosition=self.Sound.TimeLength*r end
    end)
    local time=self:_text(root,"0:00",9,false); time.Position=UDim2.fromOffset(96,98); time.Size=UDim2.fromOffset(35,14); time.TextTransparency=.45
    local duration=self:_text(root,"0:00",9,false); duration.Position=UDim2.new(1,-47,0,98); duration.Size=UDim2.fromOffset(35,14); duration.TextXAlignment=Enum.TextXAlignment.Right; duration.TextTransparency=.45

    local controls=Instance.new("Frame"); controls.BackgroundTransparency=1; controls.Size=UDim2.fromOffset(212,32); controls.Position=UDim2.fromOffset(96,116); controls.Parent=root
    local shuffle=self:_button(controls,"shuffle",28,function() self.Shuffle=not self.Shuffle end); shuffle.Position=UDim2.fromOffset(0,2)
    local prev=self:_button(controls,"skip-back",28,function() self:Previous() end); prev.Position=UDim2.fromOffset(42,2)
    local play=self:_button(controls,"play",32,function() self:TogglePlay() end); play.Position=UDim2.fromOffset(86,0)
    local playIcon=play:FindFirstChildOfClass("ImageLabel")
    local pause=self:_icon(play,"pause",16); pause.AnchorPoint=Vector2.new(.5,.5); pause.Position=UDim2.fromScale(.5,.5); pause.Visible=false
    local nextb=self:_button(controls,"skip-forward",28,function() self:Next() end); nextb.Position=UDim2.fromOffset(130,2)
    local repeatb=self:_button(controls,"repeat-2",28,function() self.RepeatOne=not self.RepeatOne; self.Sound.Looped=self.RepeatOne end); repeatb.Position=UDim2.fromOffset(174,2)

    local volumeIcon=self:_icon(root,"volume-2",14); volumeIcon.Position=UDim2.fromOffset(96,154)
    local volume=Instance.new("TextButton"); volume.Text=""; volume.AutoButtonColor=false; volume.BackgroundColor3=self:_theme("ElementBackground",Color3.fromRGB(21,17,22)); volume.BackgroundTransparency=.2; volume.Size=UDim2.fromOffset(185,4); volume.Position=UDim2.fromOffset(116,159); volume.Parent=root
    local vc=Instance.new("UICorner"); vc.CornerRadius=UDim.new(1,0); vc.Parent=volume
    local vf=Instance.new("Frame"); vf.BackgroundColor3=self:_theme("Slider",Color3.fromRGB(161,22,47)); vf.BorderSizePixel=0; vf.Size=UDim2.new(self.Volume,0,1,0); vf.Parent=volume
    local vfc=Instance.new("UICorner"); vfc.CornerRadius=UDim.new(1,0); vfc.Parent=vf
    volume.MouseButton1Down:Connect(function(x)
        self.Volume=math.clamp((x-volume.AbsolutePosition.X)/volume.AbsoluteSize.X,0,1); vf.Size=UDim2.new(self.Volume,0,1,0); self.Sound.Volume=self.Volume
    end)

    local line=Instance.new("Frame"); line.BorderSizePixel=0; line.BackgroundColor3=self:_theme("Outline",Color3.fromRGB(90,24,36)); line.BackgroundTransparency=.8; line.Size=UDim2.new(1,-24,0,1); line.Position=UDim2.fromOffset(12,178); line.Parent=root
    local playlistLabel=self:_text(root,"Playlist",11,true); playlistLabel.Position=UDim2.fromOffset(12,184); playlistLabel.Size=UDim2.fromOffset(80,22)
    local refresh=self:_button(root,"refresh-cw",24,function() self:Refresh() end); refresh.Position=UDim2.new(1,-62,0,183)
    local folder=self:_button(root,"folder-open",24,function() if OpenFolder then pcall(OpenFolder,self.Folder) end end); folder.Position=UDim2.new(1,-34,0,183)
    local list=Instance.new("ScrollingFrame"); list.BackgroundTransparency=1; list.BorderSizePixel=0; list.ScrollBarThickness=2; list.Size=UDim2.new(1,-24,0,48); list.Position=UDim2.fromOffset(12,208); list.CanvasSize=UDim2.new(); list.AutomaticCanvasSize=Enum.AutomaticSize.Y; list.Parent=root
    local layout=Instance.new("UIListLayout"); layout.Padding=UDim.new(0,2); layout.Parent=list
    local empty=self:_text(list,"No songs yet — add MP3 files to VantaTest/Music",10,false); empty.Size=UDim2.new(1,0,0,28); empty.TextXAlignment=Enum.TextXAlignment.Center; empty.TextTransparency=.45

    local mini=Instance.new("Frame"); mini.Size=UDim2.fromOffset(248,48); mini.Position=UDim2.new(.5,-124,.82,0); mini.BackgroundColor3=self:_theme("Background",Color3.fromRGB(0,0,0)); mini.BackgroundTransparency=.03; mini.BorderSizePixel=0; mini.Visible=false; mini.ZIndex=5000; mini.Parent=parent
    local mc=Instance.new("UICorner"); mc.CornerRadius=UDim.new(0,14); mc.Parent=mini
    local ms=Instance.new("UIStroke"); ms.Color=self:_theme("Outline",Color3.fromRGB(90,24,36)); ms.Transparency=.7; ms.Thickness=1; ms.Parent=mini
    local miniTitle=self:_text(mini,"Music Player",11,true); miniTitle.Position=UDim2.fromOffset(12,0); miniTitle.Size=UDim2.new(1,-100,1,0)
    local miniPlay=self:_button(mini,"play",30,function() self:TogglePlay() end); miniPlay.Position=UDim2.new(1,-70,0,9)
    local miniPlayIcon=miniPlay:FindFirstChildOfClass("ImageLabel")
    local miniPause=self:_icon(miniPlay,"pause",14); miniPause.AnchorPoint=Vector2.new(.5,.5); miniPause.Position=UDim2.fromScale(.5,.5); miniPause.Visible=false
    local restore=self:_button(mini,"chevron-up",30,function() self:Restore() end); restore.Position=UDim2.new(1,-36,0,9)

    self:_drag(root,top); self:_drag(mini,mini)

    self.UI={Root=root,Mini=mini,Title=title,Sub=sub,Cover=cover,CoverFallback=coverFallback,ProgressFill=fill,Time=time,Duration=duration,PlayIcon=playIcon,PauseIcon=pause,List=list,Empty=empty,MiniTitle=miniTitle,MiniPlay=miniPlayIcon,MiniPause=miniPause}
    self:ApplyTheme()
end

function MusicPlayer:ApplyTheme()
    if not self.UI then return end
    local bg=self:_theme("Background",Color3.fromRGB(0,0,0)); local outline=self:_theme("Outline",Color3.fromRGB(90,24,36))
    self.UI.Root.BackgroundColor3=bg; self.UI.Mini.BackgroundColor3=bg
    local s=self.UI.Root:FindFirstChildOfClass("UIStroke"); if s then s.Color=outline end
    local ms=self.UI.Mini:FindFirstChildOfClass("UIStroke"); if ms then ms.Color=outline end
end

function MusicPlayer:Show()
    self:_build(); self:Refresh(); self.UI.Mini.Visible=false; self.UI.Root.Visible=true
end
function MusicPlayer:Minimize()
    if not self.UI then return end; self.UI.Root.Visible=false; self.UI.Mini.Visible=true
end
function MusicPlayer:Restore()
    if not self.UI then return end; self.UI.Mini.Visible=false; self.UI.Root.Visible=true
end

function MusicPlayer:Init(windui, config)
    self.WindUI=windui
    if type(config)=="table" and config.Folder then self.Folder=config.Folder end
    self.Sound=Instance.new("Sound")
    self.Sound.Name="VantaCompactMusic"
    self.Sound.Volume=self.Volume
    self.Sound.Parent=SoundService
    self.Sound.Ended:Connect(function() if not self.RepeatOne then self:Next() end end)
    RunService.RenderStepped:Connect(function() if self.UI and self.UI.Root.Visible then self:_update() end end)
    return self
end

function MusicPlayer:Attach(window)
    self.Window=window
    window.Topbar:Button({Name="Music",Icon="music-2",LayoutOrder=996,IconThemed=true,Callback=function() if self.UI and self.UI.Root.Visible then self.UI.Root.Visible=false else self:Show() end end})
    return self
end

return MusicPlayer
