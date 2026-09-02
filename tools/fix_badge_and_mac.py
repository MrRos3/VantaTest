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
# Open button: full-bleed zoom, true all-surface drag, drag/click separation
# ---------------------------------------------------------
path = "src/components/window/Openbutton.lua"
text = load(path)

text = once(
    text,
    '''    local OpenButtonMain = {\n        Button = nil,\n        Icon = nil,\n    }''',
    '''    local OpenButtonMain = {\n        Button = nil,\n        Icon = nil,\n        Hitbox = nil,\n        Dragging = false,\n        WasDragged = false,\n    }''',
    "OpenButtonMain state",
)

text = once(
    text,
    '''    OpenButtonMain.Button = Button\n\n    function OpenButtonMain:SetIcon(newIcon)''',
    '''    local Hitbox = New("TextButton", {\n        Name = "DragHitbox",\n        Size = UDim2.fromScale(1, 1),\n        Position = UDim2.fromScale(0, 0),\n        BackgroundTransparency = 1,\n        Text = "",\n        AutoButtonColor = false,\n        Active = true,\n        ZIndex = 10050,\n        Parent = Button,\n    })\n\n    OpenButtonMain.Button = Button\n    OpenButtonMain.Hitbox = Hitbox\n\n    function OpenButtonMain:SetIcon(newIcon)''',
    "full button hitbox",
)

text = text.replace(
    'Creator.AddSignal(Button.TextButton.MouseEnter, function()',
    'Creator.AddSignal(Hitbox.MouseEnter, function()',
    1,
)
text = text.replace(
    'Creator.AddSignal(Button.TextButton.MouseLeave, function()',
    'Creator.AddSignal(Hitbox.MouseLeave, function()',
    1,
)

old_drag = '''    -- Drag the whole visible button face. This keeps the badge draggable\n    -- without requiring a separate move-handle icon.\n    local DragModule = Creator.Drag(Container, { Button.TextButton })'''
new_drag = '''    -- A transparent full-size hitbox owns both drag and click so every pixel\n    -- of the floating badge behaves consistently, including the border/image.\n    local DragStartPosition\n    local DragModule = Creator.Drag(Container, { Hitbox }, function(dragging)\n        if dragging then\n            OpenButtonMain.Dragging = true\n            OpenButtonMain.WasDragged = false\n            DragStartPosition = Container.Position\n        else\n            OpenButtonMain.Dragging = false\n            if DragStartPosition then\n                local dx = Container.Position.X.Offset - DragStartPosition.X.Offset\n                local dy = Container.Position.Y.Offset - DragStartPosition.Y.Offset\n                OpenButtonMain.WasDragged = math.abs(dx) > 2 or math.abs(dy) > 2\n                if OpenButtonMain.WasDragged then\n                    task.delay(0.12, function()\n                        OpenButtonMain.WasDragged = false\n                    end)\n                end\n            end\n        end\n    end)\n\n    Creator.AddSignal(Hitbox.MouseButton1Click, function()\n        if OpenButtonMain.WasDragged or OpenButtonMain.Dragging then\n            return\n        end\n        if Window.Open then\n            Window:Open()\n        end\n    end)'''
text = once(text, old_drag, new_drag, "drag surface")

text = once(
    text,
    '''            Scale = OpenButtonConfig.Scale or 1,\n            Color = OpenButtonConfig.Color''',
    '''            Scale = OpenButtonConfig.Scale or 1,\n            ImageZoom = OpenButtonConfig.ImageZoom or 1.5,\n            Color = OpenButtonConfig.Color''',
    "image zoom config",
)

edit_marker = '    function OpenButtonMain:Edit(OpenButtonConfig)'
head, tail = text.split(edit_marker, 1)
count = tail.count('Icon.ImageLabel.Size = UDim2.fromScale(1, 1)')
if count != 2:
    raise RuntimeError(f"icon-only zoom: expected 2 matches after Edit, found {count}")
tail = tail.replace(
    'Icon.ImageLabel.Size = UDim2.fromScale(1, 1)',
    'Icon.ImageLabel.Size = UDim2.fromScale(OpenButtonModule.ImageZoom, OpenButtonModule.ImageZoom)',
)
text = head + edit_marker + tail

text = once(
    text,
    '''        Button.TextButton.UICorner.CornerRadius = UDim.new(\n            OpenButtonModule.CornerRadius.Scale,\n            math.max(OpenButtonModule.CornerRadius.Offset - 2, 0)\n        )''',
    '''        Button.TextButton.UICorner.CornerRadius = OpenButtonModule.CornerRadius''',
    "matching inner badge radius",
)

save(path, text)


# ---------------------------------------------------------
# Window topbar: Mac buttons use native circles, not dynamic squircle textures
# ---------------------------------------------------------
path = "src/components/window/Init.lua"
text = load(path)
start_token = '\t\tlocal Button = Creator.NewRoundFrame('
end_token = '\n\t\tlocal ButtonContainer = New("Frame", {'
start = text.find(start_token)
if start == -1:
    raise RuntimeError("Mac traffic light block start not found")
end = text.find(end_token, start)
if end == -1:
    raise RuntimeError("Mac traffic light block end not found")

replacement = '''\t\tlocal Button\n\t\tif Window.Topbar.ButtonsType == "Default" then\n\t\t\tButton = Creator.NewRoundFrame(\n\t\t\t\tWindow.UICorner - (Window.UIPadding / 2),\n\t\t\t\t"Squircle",\n\t\t\t\t{\n\t\t\t\t\tSize = UDim2.new(0, Window.Topbar.Height - 16, 0, Window.Topbar.Height - 16),\n\t\t\t\t\tLayoutOrder = LayoutOrder or 999,\n\t\t\t\t\tZIndex = 9999,\n\t\t\t\t\tAnchorPoint = Vector2.new(0.5, 0.5),\n\t\t\t\t\tPosition = UDim2.new(0.5, 0, 0.5, 0),\n\t\t\t\t\tThemeTag = { ImageColor3 = "Text" },\n\t\t\t\t\tImageTransparency = 1,\n\t\t\t\t},\n\t\t\t\t{\n\t\t\t\t\tIconFrame,\n\t\t\t\t\tNew("UIScale", { Scale = 1 }),\n\t\t\t\t},\n\t\t\t\ttrue\n\t\t\t)\n\t\telse\n\t\t\t-- Native TextButton + UICorner makes a mathematically round traffic light.\n\t\t\t-- This avoids the tiny asymmetric fill from the squircle texture.\n\t\t\tButton = New("TextButton", {\n\t\t\t\tSize = UDim2.fromOffset(14, 14),\n\t\t\t\tLayoutOrder = LayoutOrder or 999,\n\t\t\t\tText = "",\n\t\t\t\tAutoButtonColor = false,\n\t\t\t\tBackgroundColor3 = Color or Color3.fromHex("#ff3030"),\n\t\t\t\tBackgroundTransparency = 0,\n\t\t\t\tZIndex = 9999,\n\t\t\t\tAnchorPoint = Vector2.new(0.5, 0.5),\n\t\t\t\tPosition = UDim2.new(0.5, 0, 0.5, 0),\n\t\t\t}, {\n\t\t\t\tNew("UICorner", { CornerRadius = UDim.new(1, 0) }),\n\t\t\t\tNew("UIAspectRatioConstraint", { AspectRatio = 1 }),\n\t\t\t\tIconFrame,\n\t\t\t\tNew("UIScale", { Scale = 1 }),\n\t\t\t})\n\t\tend\n'''
text = text[:start] + replacement + text[end:]
save(path, text)


# ---------------------------------------------------------
# Test config: zoom the brand crop so the art visually fills the badge
# ---------------------------------------------------------
path = "test.lua"
text = load(path)
text = once(
    text,
    '''        StrokeThickness = 2,\n        Color = ColorSequence.new({''',
    '''        StrokeThickness = 2,\n        ImageZoom = 1.5,\n        Color = ColorSequence.new({''',
    "test badge zoom",
)
save(path, text)

print("Applied full-bleed badge drag + native Mac circle fixes")
