from pathlib import Path


def load(path):
    return Path(path).read_text(encoding="utf-8")


def save(path, text):
    Path(path).write_text(text, encoding="utf-8")


def once(text, old, new, label):
    count = text.count(old)
    if count != 1:
        raise RuntimeError(f"{label}: expected 1 match, found {count}")
    return text.replace(old, new, 1)


# ---------------------------------------------------------
# Vanta Edge: topbar divider
# ---------------------------------------------------------
path = "src/components/window/Init.lua"
text = load(path)
text = once(
    text,
    '\t\t\t\tOutline1,\n\t\t\t\tNew("Frame", { -- Topbar Left Side',
    '''\t\t\t\tOutline1,
\t\t\t\tNew("Frame", {
\t\t\t\t\tName = "VantaEdgeDivider",
\t\t\t\t\tSize = UDim2.new(1, 0, 0, 1),
\t\t\t\t\tPosition = UDim2.new(0, 0, 1, 0),
\t\t\t\t\tAnchorPoint = Vector2.new(0, 1),
\t\t\t\t\tBorderSizePixel = 0,
\t\t\t\t\tBackgroundTransparency = 0.66,
\t\t\t\t\tThemeTag = {
\t\t\t\t\t\tBackgroundColor3 = "Primary",
\t\t\t\t\t},
\t\t\t\t\tZIndex = 5,
\t\t\t\t}, {
\t\t\t\t\tNew("UIGradient", {
\t\t\t\t\t\tRotation = 0,
\t\t\t\t\t\tTransparency = NumberSequence.new({
\t\t\t\t\t\t\tNumberSequenceKeypoint.new(0, 0.42),
\t\t\t\t\t\t\tNumberSequenceKeypoint.new(0.22, 0.68),
\t\t\t\t\t\t\tNumberSequenceKeypoint.new(0.62, 0.93),
\t\t\t\t\t\t\tNumberSequenceKeypoint.new(1, 1),
\t\t\t\t\t\t}),
\t\t\t\t\t}),
\t\t\t\t}),
\t\t\t\tNew("Frame", { -- Topbar Left Side''',
    "topbar divider",
)
save(path, text)


# ---------------------------------------------------------
# Vanta Edge: button press depth
# ---------------------------------------------------------
path = "src/components/ui/Button.lua"
text = load(path)
text = once(
    text,
    '''\t}, {
\t\tCreator.NewRoundFrame(Radius, "Squircle", {''',
    '''\t}, {
\t\tNew("UIScale", {
\t\t\tName = "VantaPressScale",
\t\t\tScale = 1,
\t\t}),
\t\tCreator.NewRoundFrame(Radius, "Squircle", {''',
    "button press scale",
)
text = once(
    text,
    '''\tCreator.AddSignal(ButtonFrame.MouseEnter, function()
\t\tTween(ButtonFrame.Frame, 0.047, { ImageTransparency = 0.95 }):Play()
\tend)
\tCreator.AddSignal(ButtonFrame.MouseLeave, function()
\t\tTween(ButtonFrame.Frame, 0.047, { ImageTransparency = 1 }):Play()
\tend)
\tCreator.AddSignal(ButtonFrame.MouseButton1Click, function()''',
    '''\tlocal PressScale = ButtonFrame:FindFirstChild("VantaPressScale")

\tCreator.AddSignal(ButtonFrame.MouseEnter, function()
\t\tTween(ButtonFrame.Frame, 0.047, { ImageTransparency = 0.95 }):Play()
\tend)
\tCreator.AddSignal(ButtonFrame.MouseLeave, function()
\t\tTween(ButtonFrame.Frame, 0.047, { ImageTransparency = 1 }):Play()
\t\tif PressScale then
\t\t\tTween(PressScale, 0.12, { Scale = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
\t\tend
\tend)
\tCreator.AddSignal(ButtonFrame.MouseButton1Down, function()
\t\tif PressScale then
\t\t\tTween(PressScale, 0.07, { Scale = 0.985 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
\t\tend
\tend)
\tCreator.AddSignal(ButtonFrame.MouseButton1Up, function()
\t\tif PressScale then
\t\t\tTween(PressScale, 0.13, { Scale = 1 }, Enum.EasingStyle.Back, Enum.EasingDirection.Out):Play()
\t\tend
\tend)
\tCreator.AddSignal(ButtonFrame.MouseButton1Click, function()''',
    "button press signals",
)
save(path, text)


# ---------------------------------------------------------
# Vanta Edge: active-tab dot + tiny icon drift
# ---------------------------------------------------------
path = "src/components/window/Tab.lua"
text = load(path)
text = once(
    text,
    '''\tlocal TabIndex = TabModule.TabCount
\tTab.Index = TabIndex

\tTab.UIElements.Main = Creator.NewRoundFrame''',
    '''\tlocal TabIndex = TabModule.TabCount
\tTab.Index = TabIndex

\tlocal VantaDot = New("Frame", {
\t\tName = "VantaEdgeDot",
\t\tSize = UDim2.fromOffset(5, 5),
\t\tPosition = UDim2.new(1, -10, 0.5, 0),
\t\tAnchorPoint = Vector2.new(0.5, 0.5),
\t\tBackgroundTransparency = 1,
\t\tBorderSizePixel = 0,
\t\tThemeTag = {
\t\t\tBackgroundColor3 = "Primary",
\t\t},
\t\tZIndex = 8,
\t}, {
\t\tNew("UICorner", {
\t\t\tCornerRadius = UDim.new(1, 0),
\t\t}),
\t})

\tTab.UIElements.Main = Creator.NewRoundFrame''',
    "tab dot definition",
)
text = once(
    text,
    '''\t}, {
\t\tCreator.NewRoundFrame(Tab.UICorner - 1, "Glass-1.4", {''',
    '''\t}, {
\t\tVantaDot,
\t\tCreator.NewRoundFrame(Tab.UICorner - 1, "Glass-1.4", {''',
    "tab dot insertion",
)
text = once(
    text,
    '''\t\t\tIcon.Parent = Tab.UIElements.Main.Frame
\t\t\tTab.UIElements.Icon = Icon
\t\t\tIcon.ImageLabel.ImageTransparency = not Tab.Locked and 0 or 0.7''',
    '''\t\t\tIcon.Parent = Tab.UIElements.Main.Frame
\t\t\tTab.UIElements.Icon = Icon
\t\t\tIcon.ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
\t\t\tIcon.ImageLabel.Position = UDim2.new(0.5, 0, 0.5, 0)
\t\t\tIcon.ImageLabel.ImageTransparency = not Tab.Locked and 0 or 0.7''',
    "tab icon baseline",
)
text = once(
    text,
    '''\tCreator.AddSignal(Tab.UIElements.Main.MouseEnter, function()
\t\tif not Tab.Locked then
\t\t\tCreator.SetThemeTag(Tab.UIElements.Main.Frame, {''',
    '''\tCreator.AddSignal(Tab.UIElements.Main.MouseEnter, function()
\t\tif not Tab.Locked then
\t\t\tif Tab.UIElements.Icon and Tab.UIElements.Icon.ImageLabel then
\t\t\t\tCreator.Tween(Tab.UIElements.Icon.ImageLabel, 0.16, {
\t\t\t\t\tPosition = UDim2.new(0.5, 2, 0.5, 0),
\t\t\t\t}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
\t\t\tend
\t\t\tCreator.SetThemeTag(Tab.UIElements.Main.Frame, {''',
    "tab icon hover",
)
text = once(
    text,
    '''\t\tif not Tab.Locked then
\t\t\tCreator.SetThemeTag(Tab.UIElements.Main.Frame, {
\t\t\t\tImageTransparency = "TabBorderTransparency",''',
    '''\t\tif not Tab.Locked then
\t\t\tif Tab.UIElements.Icon and Tab.UIElements.Icon.ImageLabel then
\t\t\t\tCreator.Tween(Tab.UIElements.Icon.ImageLabel, 0.18, {
\t\t\t\t\tPosition = UDim2.new(0.5, 0, 0.5, 0),
\t\t\t\t}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
\t\t\tend
\t\t\tCreator.SetThemeTag(Tab.UIElements.Main.Frame, {
\t\t\t\tImageTransparency = "TabBorderTransparency",''',
    "tab icon return",
)
text = once(
    text,
    '''\t\t\t\tTabObject.Selected = false''',
    '''\t\t\t\tCreator.Tween(TabObject.UIElements.Main.VantaEdgeDot, 0.16, {
\t\t\t\t\tBackgroundTransparency = 1,
\t\t\t\t}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
\t\t\t\tTabObject.Selected = false''',
    "inactive tab dot",
)
text = once(
    text,
    '''\t\tTabModule.Tabs[TabIndex].Selected = true''',
    '''\t\tCreator.Tween(TabModule.Tabs[TabIndex].UIElements.Main.VantaEdgeDot, 0.2, {
\t\t\tBackgroundTransparency = 0.08,
\t\t}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
\t\tTabModule.Tabs[TabIndex].Selected = true''',
    "active tab dot",
)
save(path, text)


# ---------------------------------------------------------
# Vanta Edge: slider halo while dragging only
# ---------------------------------------------------------
path = "src/elements/Slider.lua"
text = load(path)
text = once(
    text,
    '''\t\t\t\tName = "Thumb",
\t\t\t}, {
\t\t\t\tCreator.NewRoundFrame(999, "SquircleGlass", {''',
    '''\t\t\t\tName = "Thumb",
\t\t\t}, {
\t\t\t\tCreator.NewRoundFrame(999, "Squircle", {
\t\t\t\t\tName = "VantaEdgeHalo",
\t\t\t\t\tSize = UDim2.fromOffset(Slider.ThumbSize + 12, Slider.ThumbSize + 12),
\t\t\t\t\tPosition = UDim2.new(0.5, 0, 0.5, 0),
\t\t\t\t\tAnchorPoint = Vector2.new(0.5, 0.5),
\t\t\t\t\tImageTransparency = 1,
\t\t\t\t\tThemeTag = {
\t\t\t\t\t\tImageColor3 = "Slider",
\t\t\t\t\t},
\t\t\t\t}),
\t\t\t\tCreator.NewRoundFrame(999, "SquircleGlass", {''',
    "slider halo",
)
text = once(
    text,
    '''\t\t\t\t\tScrollingFrameParent.ScrollingEnabled = false
\t\t\t\t\tIsSliderHolding = true

\t\t\t\t\tlocal inputPosition''',
    '''\t\t\t\t\tScrollingFrameParent.ScrollingEnabled = false
\t\t\t\t\tIsSliderHolding = true
\t\t\t\t\tTween(Slider.UIElements.SliderIcon.Frame.Thumb.VantaEdgeHalo, 0.16, {
\t\t\t\t\t\tImageTransparency = 0.76,
\t\t\t\t\t\tSize = UDim2.fromOffset(Slider.ThumbSize + 16, Slider.ThumbSize + 16),
\t\t\t\t\t}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()

\t\t\t\t\tlocal inputPosition''',
    "slider halo on",
)
text = once(
    text,
    '''\t\t\t\t\t\t\tIsSliderHolding = false
\t\t\t\t\t\t\tScrollingFrameParent.ScrollingEnabled = true

\t\t\t\t\t\t\tConfig.WindUI.CurrentInput = nil''',
    '''\t\t\t\t\t\t\tIsSliderHolding = false
\t\t\t\t\t\t\tScrollingFrameParent.ScrollingEnabled = true
\t\t\t\t\t\t\tTween(Slider.UIElements.SliderIcon.Frame.Thumb.VantaEdgeHalo, 0.22, {
\t\t\t\t\t\t\t\tImageTransparency = 1,
\t\t\t\t\t\t\t\tSize = UDim2.fromOffset(Slider.ThumbSize + 12, Slider.ThumbSize + 12),
\t\t\t\t\t\t\t}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()

\t\t\t\t\t\t\tConfig.WindUI.CurrentInput = nil''',
    "slider halo off",
)
save(path, text)


# ---------------------------------------------------------
# Vanta Edge: dropdown keeps its shape, gains tiny glide
# ---------------------------------------------------------
path = "src/components/ui/Dropdown.lua"
text = load(path)
text = once(
    text,
    '''\t\t\tDropdown.UIElements.MenuCanvas.Active = true
\t\t\tDropdown.UIElements.Menu.Size = UDim2.new(1, 0, 0, 0)
\t\t\tTween(Dropdown.UIElements.Menu, 0.1, {
\t\t\t\tSize = UDim2.new(1, 0, 1, 0),
\t\t\t\tImageTransparency = 0,
\t\t\t}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out):Play()''',
    '''\t\t\tDropdown.UIElements.MenuCanvas.Active = true
\t\t\tDropdown.UIElements.Menu.Size = UDim2.new(1, 0, 0, 0)
\t\t\tDropdown.UIElements.Menu.Position = UDim2.new(1, 0, 0, -5)
\t\t\tTween(Dropdown.UIElements.Menu, 0.16, {
\t\t\t\tSize = UDim2.new(1, 0, 1, 0),
\t\t\t\tPosition = UDim2.new(1, 0, 0, 0),
\t\t\t\tImageTransparency = 0,
\t\t\t}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()''',
    "dropdown open glide",
)
text = once(
    text,
    '''\t\tTween(Dropdown.UIElements.Menu, 0.25, {
\t\t\tSize = UDim2.new(1, 0, 0, 0),
\t\t\tImageTransparency = 1,
\t\t}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out):Play()''',
    '''\t\tTween(Dropdown.UIElements.Menu, 0.18, {
\t\t\tSize = UDim2.new(1, 0, 0, 0),
\t\t\tPosition = UDim2.new(1, 0, 0, 3),
\t\t\tImageTransparency = 1,
\t\t}, Enum.EasingStyle.Quint, Enum.EasingDirection.In):Play()''',
    "dropdown close glide",
)
save(path, text)


# ---------------------------------------------------------
# Cinematic Vanta Edge intro preview in test.lua
# ---------------------------------------------------------
path = "test.lua"
text = load(path)
intro = r'''local function playVantaEdgeIntro()
    local TweenService = game:GetService("TweenService")
    local CoreGui = game:GetService("CoreGui")
    local parent = (gethui and gethui()) or CoreGui

    local old = parent:FindFirstChild("VantaEdgeIntro")
    if old then
        old:Destroy()
    end

    local gui = Instance.new("ScreenGui")
    gui.Name = "VantaEdgeIntro"
    gui.IgnoreGuiInset = true
    gui.ResetOnSpawn = false
    gui.DisplayOrder = 1000000
    gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
    gui.Parent = parent

    local root = Instance.new("CanvasGroup")
    root.Name = "Root"
    root.Size = UDim2.fromScale(1, 1)
    root.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    root.BorderSizePixel = 0
    root.GroupTransparency = 0
    root.Parent = gui

    local aura = Instance.new("Frame")
    aura.Size = UDim2.fromOffset(170, 170)
    aura.Position = UDim2.fromScale(0.5, 0.5)
    aura.AnchorPoint = Vector2.new(0.5, 0.5)
    aura.BackgroundColor3 = Color3.fromRGB(124, 140, 255)
    aura.BackgroundTransparency = 0.94
    aura.BorderSizePixel = 0
    aura.Parent = root
    local auraCorner = Instance.new("UICorner")
    auraCorner.CornerRadius = UDim.new(1, 0)
    auraCorner.Parent = aura
    local auraScale = Instance.new("UIScale")
    auraScale.Scale = 0.5
    auraScale.Parent = aura

    local center = Instance.new("Frame")
    center.Size = UDim2.fromOffset(360, 190)
    center.Position = UDim2.fromScale(0.5, 0.5)
    center.AnchorPoint = Vector2.new(0.5, 0.5)
    center.BackgroundTransparency = 1
    center.Parent = root
    local centerScale = Instance.new("UIScale")
    centerScale.Scale = 0.88
    centerScale.Parent = center

    local sweep = Instance.new("Frame")
    sweep.Size = UDim2.fromOffset(0, 1)
    sweep.Position = UDim2.new(0.5, 0, 0.5, -24)
    sweep.AnchorPoint = Vector2.new(0.5, 0.5)
    sweep.BackgroundColor3 = Color3.fromRGB(130, 145, 255)
    sweep.BackgroundTransparency = 0.22
    sweep.BorderSizePixel = 0
    sweep.Parent = center
    local sweepGradient = Instance.new("UIGradient")
    sweepGradient.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.2, 0.25),
        NumberSequenceKeypoint.new(0.5, 0),
        NumberSequenceKeypoint.new(0.8, 0.25),
        NumberSequenceKeypoint.new(1, 1),
    })
    sweepGradient.Parent = sweep

    local mark = Instance.new("Frame")
    mark.Size = UDim2.fromOffset(58, 58)
    mark.Position = UDim2.new(0.5, 0, 0, 18)
    mark.AnchorPoint = Vector2.new(0.5, 0)
    mark.BackgroundColor3 = Color3.fromRGB(10, 11, 15)
    mark.BackgroundTransparency = 0
    mark.BorderSizePixel = 0
    mark.Rotation = -7
    mark.Parent = center
    local markCorner = Instance.new("UICorner")
    markCorner.CornerRadius = UDim.new(0, 17)
    markCorner.Parent = mark
    local markStroke = Instance.new("UIStroke")
    markStroke.Color = Color3.fromRGB(145, 156, 255)
    markStroke.Thickness = 1
    markStroke.Transparency = 1
    markStroke.Parent = mark
    local markScale = Instance.new("UIScale")
    markScale.Scale = 0.55
    markScale.Parent = mark

    local letter = Instance.new("TextLabel")
    letter.Size = UDim2.fromScale(1, 1)
    letter.BackgroundTransparency = 1
    letter.Text = "V"
    letter.TextColor3 = Color3.fromRGB(242, 244, 255)
    letter.TextTransparency = 1
    letter.TextSize = 26
    letter.Font = Enum.Font.GothamBold
    letter.Parent = mark

    local title = Instance.new("TextLabel")
    title.Size = UDim2.fromOffset(300, 38)
    title.Position = UDim2.new(0.5, 0, 0, 90)
    title.AnchorPoint = Vector2.new(0.5, 0)
    title.BackgroundTransparency = 1
    title.Text = "VANTA"
    title.TextColor3 = Color3.fromRGB(244, 245, 250)
    title.TextTransparency = 1
    title.TextSize = 27
    title.Font = Enum.Font.GothamBold
    title.TextXAlignment = Enum.TextXAlignment.Center
    title.Parent = center
    local titleGradient = Instance.new("UIGradient")
    titleGradient.Offset = Vector2.new(-1, 0)
    titleGradient.Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Color3.fromRGB(205, 209, 225)),
        ColorSequenceKeypoint.new(0.48, Color3.fromRGB(255, 255, 255)),
        ColorSequenceKeypoint.new(1, Color3.fromRGB(173, 184, 255)),
    })
    titleGradient.Parent = title

    local sub = Instance.new("TextLabel")
    sub.Size = UDim2.fromOffset(300, 20)
    sub.Position = UDim2.new(0.5, 0, 0, 126)
    sub.AnchorPoint = Vector2.new(0.5, 0)
    sub.BackgroundTransparency = 1
    sub.Text = "EDGE  //  TEST LAB"
    sub.TextColor3 = Color3.fromRGB(145, 149, 165)
    sub.TextTransparency = 1
    sub.TextSize = 10
    sub.Font = Enum.Font.GothamMedium
    sub.TextXAlignment = Enum.TextXAlignment.Center
    sub.Parent = center

    local track = Instance.new("Frame")
    track.Size = UDim2.fromOffset(150, 2)
    track.Position = UDim2.new(0.5, 0, 0, 160)
    track.AnchorPoint = Vector2.new(0.5, 0)
    track.BackgroundColor3 = Color3.fromRGB(25, 27, 34)
    track.BackgroundTransparency = 0.2
    track.BorderSizePixel = 0
    track.Parent = center
    local trackCorner = Instance.new("UICorner")
    trackCorner.CornerRadius = UDim.new(1, 0)
    trackCorner.Parent = track

    local fill = Instance.new("Frame")
    fill.Size = UDim2.new(0, 0, 1, 0)
    fill.BackgroundColor3 = Color3.fromRGB(129, 142, 255)
    fill.BorderSizePixel = 0
    fill.Parent = track
    local fillCorner = Instance.new("UICorner")
    fillCorner.CornerRadius = UDim.new(1, 0)
    fillCorner.Parent = fill

    TweenService:Create(auraScale, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Scale = 1 }):Play()
    TweenService:Create(aura, TweenInfo.new(0.8, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { BackgroundTransparency = 0.975 }):Play()
    TweenService:Create(centerScale, TweenInfo.new(0.65, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Scale = 1 }):Play()
    TweenService:Create(sweep, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.fromOffset(330, 1) }):Play()
    TweenService:Create(markScale, TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
    TweenService:Create(mark, TweenInfo.new(0.55, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Rotation = 0 }):Play()
    TweenService:Create(markStroke, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Transparency = 0.28 }):Play()
    TweenService:Create(letter, TweenInfo.new(0.35, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { TextTransparency = 0 }):Play()

    task.wait(0.28)
    TweenService:Create(title, TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), {
        TextTransparency = 0,
        Position = UDim2.new(0.5, 0, 0, 86),
    }):Play()
    TweenService:Create(titleGradient, TweenInfo.new(0.85, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Offset = Vector2.new(1, 0) }):Play()
    TweenService:Create(sub, TweenInfo.new(0.42, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { TextTransparency = 0.15 }):Play()
    TweenService:Create(fill, TweenInfo.new(0.92, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { Size = UDim2.new(1, 0, 1, 0) }):Play()

    task.wait(1.02)
    TweenService:Create(centerScale, TweenInfo.new(0.45, Enum.EasingStyle.Quint, Enum.EasingDirection.In), { Scale = 1.035 }):Play()
    TweenService:Create(root, TweenInfo.new(0.48, Enum.EasingStyle.Quint, Enum.EasingDirection.Out), { GroupTransparency = 1 }):Play()
    task.wait(0.5)
    gui:Destroy()
end

playVantaEdgeIntro()
'''
text = once(
    text,
    ']]\n\nlocal VantaUI = loadstring(game:HttpGet(',
    ']]\n\n' + intro + '\nlocal VantaUI = loadstring(game:HttpGet(',
    "intro insertion",
)
text = text.replace('Content = "Test window loaded successfully.",', 'Content = "Vanta Edge preview loaded successfully.",', 1)
save(path, text)

print("Vanta Edge patch applied successfully")
