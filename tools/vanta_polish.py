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


def many(text, old, new, expected, label):
    count = text.count(old)
    if count != expected:
        raise RuntimeError(f"{label}: expected {expected} matches, found {count}")
    return text.replace(old, new)


# Window / topbar / global element geometry
path = "src/components/window/Init.lua"
text = load(path)
text = once(text, 'IconSize = Config.IconSize or 22,', 'IconSize = Config.IconSize or 20,', 'topbar icon size')
text = once(text, '\t\tUIPadding = 14,', '\t\tUIPadding = UserInputService.TouchEnabled and 16 or 14,', 'window touch padding')
text = once(text, '\tWindow.TopBarButtonIconSize = Window.TopBarButtonIconSize or (Window.Topbar.ButtonsType == "Mac" and 11 or 16)', '\tWindow.TopBarButtonIconSize = Window.TopBarButtonIconSize or (Window.Topbar.ButtonsType == "Mac" and 10 or 16)', 'mac icon size')
text = once(text, '\tWindow.ElementConfig = {\n\t\tUIPadding = (Window.NewElements and 10 or 13),\n\t\tUICorner = Window.ElementsRadius or (Window.NewElements and 23 or 16),\n\t}', '\tWindow.ElementConfig = {\n\t\tUIPadding = Window.NewElements and (UserInputService.TouchEnabled and 12 or 10) or 13,\n\t\tUICorner = Window.ElementsRadius or (Window.NewElements and 14 or 16),\n\t}', 'element geometry')
text = once(text, '\t\t\tTextSize = 13,', '\t\t\tTextSize = 12,', 'author size')
text = once(text, '\t\tTextSize = 16,', '\t\tTextSize = 15,', 'title size')
text = once(text, '\t\t\t\t\t\tPadding = UDim.new(0, Window.UIPadding + 4),', '\t\t\t\t\t\tPadding = UDim.new(0, math.max(8, Window.UIPadding - 2)),', 'topbar left spacing')
text = once(text, 'Padding = UDim.new(0, Window.Topbar.ButtonsType == "Default" and 9 or 0),', 'Padding = UDim.new(0, Window.Topbar.ButtonsType == "Default" and 9 or 6),', 'mac dot spacing')
text = once(text, '\t\t\t\t\tPaddingRight = UDim.new(0, 8),', '\t\t\t\t\tPaddingRight = UDim.new(0, Window.Topbar.ButtonsType == "Mac" and 12 or 8),', 'topbar right padding')
text = once(text, '\t\t\t\t\t\tor UDim2.new(0, 14, 0, 14),', '\t\t\t\t\t\tor UDim2.new(0, 12, 0, 12),', 'mac dot size')
text = once(text,
    '\t\t\t\tOutline1,\n\t\t\t\t--[[New("Frame", { -- Outline',
    '\t\t\t\tOutline1,\n\t\t\t\tNew("Frame", {\n\t\t\t\t\tName = "VantaHoverGlow",\n\t\t\t\t\tSize = UDim2.new(1, 0, 1, 0),\n\t\t\t\t\tBackgroundTransparency = 1,\n\t\t\t\t\tBorderSizePixel = 0,\n\t\t\t\t\tThemeTag = {\n\t\t\t\t\t\tBackgroundColor3 = "Primary",\n\t\t\t\t\t},\n\t\t\t\t}, {\n\t\t\t\t\tNew("UICorner", {\n\t\t\t\t\t\tCornerRadius = UDim.new(0, math.max(8, Window.UICorner - 4)),\n\t\t\t\t\t}),\n\t\t\t\t}),\n\t\t\t\t--[[New("Frame", { -- Outline',
    'topbar hover glow frame')
text = once(text,
    '\tCreator.AddSignal(Window.UIElements.Main.Main.Topbar.Left:GetPropertyChangedSignal("AbsoluteSize"), function()',
    '\tlocal VantaTopbarGlow = Window.UIElements.Main.Main.Topbar:FindFirstChild("VantaHoverGlow")\n\tif VantaTopbarGlow and not UserInputService.TouchEnabled then\n\t\tCreator.AddSignal(Window.UIElements.Main.Main.Topbar.MouseEnter, function()\n\t\t\tTween(VantaTopbarGlow, 0.2, { BackgroundTransparency = 0.965 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()\n\t\tend)\n\t\tCreator.AddSignal(Window.UIElements.Main.Main.Topbar.MouseLeave, function()\n\t\t\tTween(VantaTopbarGlow, 0.24, { BackgroundTransparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()\n\t\tend)\n\tend\n\n\tCreator.AddSignal(Window.UIElements.Main.Main.Topbar.Left:GetPropertyChangedSignal("AbsoluteSize"), function()',
    'topbar hover signals')
save(path, text)

# Sidebar tabs
path = "src/components/window/Tab.lua"
text = load(path)
text = once(text, '\t\tTabPaddingX = 4 + (Window.UIPadding / 2),', '\t\tTabPaddingX = 7 + (Window.UIPadding / 2),', 'tab padding')
text = once(text,
    '\tlocal TabIndex = TabModule.TabCount\n\tTab.Index = TabIndex\n\n\tTab.UIElements.Main = Creator.NewRoundFrame',
    '\tlocal TabIndex = TabModule.TabCount\n\tTab.Index = TabIndex\n\n\tlocal ActiveIndicator = New("Frame", {\n\t\tName = "ActiveIndicator",\n\t\tSize = UDim2.fromOffset(3, 18),\n\t\tPosition = UDim2.new(0, 3, 0.5, 0),\n\t\tAnchorPoint = Vector2.new(0, 0.5),\n\t\tBackgroundTransparency = 1,\n\t\tBorderSizePixel = 0,\n\t\tThemeTag = {\n\t\t\tBackgroundColor3 = "Primary",\n\t\t},\n\t}, {\n\t\tNew("UICorner", {\n\t\t\tCornerRadius = UDim.new(1, 0),\n\t\t}),\n\t})\n\n\tTab.UIElements.Main = Creator.NewRoundFrame',
    'active indicator definition')
text = once(text, '\t}, {\n\t\tCreator.NewRoundFrame(Tab.UICorner - 1, "Glass-1.4", {', '\t}, {\n\t\tActiveIndicator,\n\t\tCreator.NewRoundFrame(Tab.UICorner - 1, "Glass-1.4", {', 'active indicator insertion')
text = once(text, '\t\t\t\tTextTransparency = not Tab.Locked and 0.4 or 0.7,\n\t\t\t\tTextSize = 15,', '\t\t\t\tTextTransparency = not Tab.Locked and 0.4 or 0.7,\n\t\t\t\tTextSize = 14,', 'tab text size')
text = many(text, 'not Window.HidePanelBackground and 20 or 10', '(not Window.HidePanelBackground and 20 or 10) + (UserInputService.TouchEnabled and 4 or 0)', 4, 'content touch padding')
text = once(text,
    '\t\t\t\tCreator.SetThemeTag(TabObject.UIElements.Main, {\n\t\t\t\t\tImageTransparency = "TabBorderTransparency",\n\t\t\t\t}, 0.15)',
    '\t\t\t\tCreator.SetThemeTag(TabObject.UIElements.Main, {\n\t\t\t\t\tImageColor3 = "TabBackground",\n\t\t\t\t}, 0.15)\n\t\t\t\tCreator.Tween(TabObject.UIElements.Main, 0.18, { ImageTransparency = 1 }):Play()\n\t\t\t\tCreator.Tween(TabObject.UIElements.Main.ActiveIndicator, 0.18, { BackgroundTransparency = 1 }):Play()',
    'inactive tab style')
text = once(text,
    '\t\tCreator.SetThemeTag(TabModule.Tabs[TabIndex].UIElements.Main, {\n\t\t\tImageColor3 = "TabBackgroundActive",\n\t\t\tImageTransparency = "TabBackgroundActiveTransparency",\n\t\t}, 0.15)',
    '\t\tCreator.SetThemeTag(TabModule.Tabs[TabIndex].UIElements.Main, {\n\t\t\tImageColor3 = "Primary",\n\t\t}, 0.15)\n\t\tCreator.Tween(TabModule.Tabs[TabIndex].UIElements.Main, 0.18, { ImageTransparency = 0.92 }):Play()\n\t\tCreator.Tween(TabModule.Tabs[TabIndex].UIElements.Main.ActiveIndicator, 0.18, { BackgroundTransparency = 0.08 }):Play()',
    'active tab style')
save(path, text)

# Element cards
path = "src/components/window/Element.lua"
text = load(path)
text = once(text, 'TextSize = Type == "Desc" and 15 or 17,', 'TextSize = Type == "Desc" and 14 or 16,', 'element text sizes')
text = once(text, '\t\t\t\tTween(Hover, 0.12, { ImageTransparency = 0.9 }):Play()\n\t\t\t\tTween(HoverOutline, 0.12, { ImageTransparency = 0.8 }):Play()', '\t\t\t\tTween(Hover, 0.16, { ImageTransparency = 0.94 }):Play()\n\t\t\t\tTween(HoverOutline, 0.16, { ImageTransparency = 0.9 }):Play()', 'quiet element hover')
save(path, text)

# Section cards
path = "src/elements/Section.lua"
text = load(path)
text = once(text, '\t\tTextSize = Config.TextSize or 19,', '\t\tTextSize = Config.TextSize or 18,', 'section title size')
text = once(text, '\t\tDescTextSize = Config.DescTextSize or 16,', '\t\tDescTextSize = Config.DescTextSize or 14,', 'section desc size')
text = once(text, '\t\tHeaderSize = 48,', '\t\tHeaderSize = 44,', 'section header')
text = once(text, '\t\tIconSize = 20,', '\t\tIconSize = 18,', 'section icon')
text = once(text, '\t\tPadding = 10,', '\t\tPadding = 8,', 'section padding')
text = once(text, '\t\t\tImageTransparency = Section.Box and Section.BoxBorder and 0.92 or 1,', '\t\t\tImageTransparency = Section.Box and Section.BoxBorder and 0.95 or 1,', 'section border')
text = many(text, 'Config.Window.ElementConfig.UIPadding + (Config.Window.NewElements and 4 or 0)', 'Config.Window.ElementConfig.UIPadding + (Config.Window.NewElements and 2 or 0)', 4, 'section inner padding')
save(path, text)

# Sliders
path = "src/elements/Slider.lua"
text = load(path)
text = once(text, '\t\tThumbSize = 16,', '\t\tThumbSize = 14,', 'slider thumb')
text = once(text, '\t\tSize = UDim2.new(1, not Slider.IsTextbox and -TotalSliderWidth or (-Slider.TextBoxWidth - 8), 0, 3),', '\t\tSize = UDim2.new(1, not Slider.IsTextbox and -TotalSliderWidth or (-Slider.TextBoxWidth - 8), 0, 2),', 'slider rail')
text = once(text, '\t\t\t\t\tImageTransparency = 0.5,', '\t\t\t\t\tImageTransparency = 0.68,', 'slider thumb highlight')
text = once(text, '\t\t\tTextSize = 15,', '\t\t\tTextSize = 14,', 'slider value size')
text = once(text, 'Size = UDim2.fromOffset(Slider.ThumbSize + 3, Slider.ThumbSize + 3),', 'Size = UDim2.fromOffset(Slider.ThumbSize + 2, Slider.ThumbSize + 2),', 'slider press growth')
save(path, text)

# Dropdown element geometry / icon exposure
path = "src/elements/Dropdown.lua"
text = load(path)
text = once(text, '\tMenuCorner = 15,', '\tMenuCorner = 12,', 'dropdown corner')
text = once(text, '\tMenuPadding = 5,', '\tMenuPadding = 6,', 'dropdown menu padding')
text = once(text, '\tTabPadding = 10,', '\tTabPadding = 9,', 'dropdown tab padding')
text = once(text, '\tSearchBarHeight = 39,', '\tSearchBarHeight = 38,', 'dropdown search height')
text = once(text, '\tTabIcon = 18,', '\tTabIcon = 17,', 'dropdown icon')
text = once(text, '\t\tWidth = 150,', '\t\tWidth = UserInputService.TouchEnabled and 180 or 156,', 'dropdown responsive width')
text = once(text,
    '\n\t-- The internal dropdown button calls DropdownMenu:Open() on every click.\n\t-- Wrap Open so the same button behaves like a true toggle: click once opens,\n\t-- click again closes. MenuCanvas.Visible also catches the short opening delay.\n\tlocal BaseOpen = Dropdown.DropdownMenu.Open\n\tlocal BaseClose = Dropdown.DropdownMenu.Close\n\tfunction Dropdown.DropdownMenu:Open(...)\n\t\tif Dropdown.Opened or Dropdown.UIElements.MenuCanvas.Visible then\n\t\t\treturn BaseClose(self, ...)\n\t\tend\n\t\treturn BaseOpen(self, ...)\n\tend\n',
    '\n',
    'remove dropdown wrapper')
text = once(text, '\t})\n\n\tfunction Dropdown:Lock()', '\t})\n\tDropdown.UIElements.DropdownIcon = DropdownIcon\n\n\tfunction Dropdown:Lock()', 'expose dropdown icon')
save(path, text)

# Dropdown animation / direct toggle
path = "src/components/ui/Dropdown.lua"
text = load(path)
text = once(text, '\t\t\t\t\t\tSize = UDim2.new(1, 0, 0, 36),', '\t\t\t\t\t\tSize = UDim2.new(1, 0, 0, 34),', 'dropdown item height')
text = once(text,
    '\tfunction DropdownModule:Open()\n\t\tif not Dropdown.Locked then\n\t\t\tDropdown.UIElements.Menu.Visible = true\n\t\t\tDropdown.UIElements.MenuCanvas.Visible = true\n\t\t\tDropdown.UIElements.MenuCanvas.Active = true\n\t\t\tDropdown.UIElements.Menu.Size = UDim2.new(1, 0, 0, 0)\n\t\t\tTween(Dropdown.UIElements.Menu, 0.1, {\n\t\t\t\tSize = UDim2.new(1, 0, 1, 0),\n\t\t\t\tImageTransparency = 0,\n\t\t\t}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out):Play()\n\n\t\t\ttask.spawn(function()\n\t\t\t\ttask.wait(0.1)\n\t\t\t\tif Dropdown.Locked then\n\t\t\t\t\treturn\n\t\t\t\tend\n\t\t\t\tDropdown.Opened = true\n\t\t\tend)\n\n\t\t\tUpdatePosition()\n\t\tend\n\tend\n\n\tfunction DropdownModule:Close()\n\t\tDropdown.Opened = false\n\n\t\tTween(Dropdown.UIElements.Menu, 0.25, {\n\t\t\tSize = UDim2.new(1, 0, 0, 0),\n\t\t\tImageTransparency = 1,\n\t\t}, Enum.EasingStyle.Quart, Enum.EasingDirection.Out):Play()\n\n\t\ttask.spawn(function()\n\t\t\ttask.wait(0.1)\n\t\t\tDropdown.UIElements.Menu.Visible = false\n\t\tend)\n\n\t\ttask.spawn(function()\n\t\t\ttask.wait(0.25)\n\t\t\tDropdown.UIElements.MenuCanvas.Visible = false\n\t\t\tDropdown.UIElements.MenuCanvas.Active = false\n\t\tend)\n\tend',
    '\tfunction DropdownModule:Open()\n\t\tif not Dropdown.Locked then\n\t\t\tDropdown.Opened = true\n\t\t\tDropdown.UIElements.Menu.Visible = true\n\t\t\tDropdown.UIElements.MenuCanvas.Visible = true\n\t\t\tDropdown.UIElements.MenuCanvas.Active = true\n\t\t\tDropdown.UIElements.Menu.Size = UDim2.new(1, -6, 1, -6)\n\t\t\tDropdown.UIElements.Menu.Position = UDim2.new(1, 0, 0, 6)\n\t\t\tDropdown.UIElements.Menu.ImageTransparency = 1\n\t\t\tTween(Dropdown.UIElements.Menu, 0.18, {\n\t\t\t\tSize = UDim2.new(1, 0, 1, 0),\n\t\t\t\tPosition = UDim2.new(1, 0, 0, 0),\n\t\t\t\tImageTransparency = 0,\n\t\t\t}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()\n\t\t\tif Dropdown.UIElements.DropdownIcon then\n\t\t\t\tTween(Dropdown.UIElements.DropdownIcon, 0.18, { Rotation = 180 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()\n\t\t\tend\n\t\t\tUpdatePosition()\n\t\tend\n\tend\n\n\tfunction DropdownModule:Close()\n\t\tDropdown.Opened = false\n\t\tTween(Dropdown.UIElements.Menu, 0.14, {\n\t\t\tSize = UDim2.new(1, -4, 1, -4),\n\t\t\tPosition = UDim2.new(1, 0, 0, 4),\n\t\t\tImageTransparency = 1,\n\t\t}, Enum.EasingStyle.Quint, Enum.EasingDirection.In):Play()\n\t\tif Dropdown.UIElements.DropdownIcon then\n\t\t\tTween(Dropdown.UIElements.DropdownIcon, 0.14, { Rotation = 0 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()\n\t\tend\n\t\ttask.delay(0.15, function()\n\t\t\tif not Dropdown.Opened then\n\t\t\t\tDropdown.UIElements.Menu.Visible = false\n\t\t\t\tDropdown.UIElements.MenuCanvas.Visible = false\n\t\t\t\tDropdown.UIElements.MenuCanvas.Active = false\n\t\t\tend\n\t\tend)\n\tend',
    'dropdown motion')
text = once(text, '\t\tfunction()\n\t\t\tDropdownModule:Open()\n\t\tend', '\t\tfunction()\n\t\t\tif Dropdown.Opened or Dropdown.UIElements.MenuCanvas.Visible then\n\t\t\t\tDropdownModule:Close()\n\t\t\telse\n\t\t\t\tDropdownModule:Open()\n\t\t\tend\n\t\tend', 'dropdown direct toggle')
save(path, text)

# Notifications
path = "src/components/Notification.lua"
text = load(path)
text = once(text, '\tSize = UDim2.new(0, 300, 1, -100 - 56),', '\tSize = UDim2.new(0, 280, 1, -100 - 56),', 'notification width')
text = once(text, '\tSizeLower = UDim2.new(0, 300, 1, -56),', '\tSizeLower = UDim2.new(0, 280, 1, -56),', 'notification lower width')
text = once(text, '\tUICorner = 18,', '\tUICorner = 12,', 'notification corner')
text = once(text, '\tUIPadding = 14,', '\tUIPadding = 11,', 'notification padding')
text = once(text, '\t\tPosition = UDim2.new(1, -116 / 4, 0, 56),', '\t\tPosition = UDim2.new(1, -16, 0, 56),', 'notification position')
text = once(text, '\t\t\tPadding = UDim.new(0, 8),', '\t\t\tPadding = UDim.new(0, 6),', 'notification stack gap')
text = once(text, '\t\t\tPaddingBottom = UDim.new(0, 116 / 4),', '\t\t\tPaddingBottom = UDim.new(0, 16),', 'notification bottom padding')
text = once(text, '\t\tIcon.Size = UDim2.new(0, 26, 0, 26)', '\t\tIcon.Size = UDim2.new(0, 22, 0, 22)', 'notification icon')
text = once(text, '\t\t\tSize = UDim2.new(0, 16, 0, 16),', '\t\t\tSize = UDim2.new(0, 14, 0, 14),', 'notification close')
text = once(text, '\tlocal Duration = Creator.NewRoundFrame(NotificationModule.UICorner, "Squircle", {\n\t\tSize = UDim2.new(0, 0, 1, 0),', '\tlocal Duration = Creator.NewRoundFrame(99, "Squircle", {\n\t\tSize = UDim2.new(0, 0, 0, 2),\n\t\tPosition = UDim2.new(0, 0, 1, 0),\n\t\tAnchorPoint = Vector2.new(0, 1),', 'notification duration bar')
text = once(text, '\t\t\tTextSize = 18,', '\t\t\tTextSize = 15,', 'notification title')
text = once(text, '\t\t\tTextSize = 15,', '\t\t\tTextSize = 13,', 'notification content')
text = once(text, '\t\tImageTransparency = 0.05,', '\t\tImageTransparency = 0.08,', 'notification surface')
text = once(text, 'Tween(Main, 0.55, { Position = UDim2.new(2, 0, 1, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()', 'Tween(Main, 0.36, { Position = UDim2.new(2, 0, 1, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()', 'notification close motion')
text = once(text, '\t\tTween(Main, 0.45, { Position = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()', '\t\tTween(Main, 0.32, { Position = UDim2.new(0, 0, 1, 0) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()', 'notification enter motion')
text = once(text, '\t\t\tDuration.Size = UDim2.new(0, Main.DurationFrame.AbsoluteSize.X, 1, 0)', '\t\t\tDuration.Size = UDim2.new(0, Main.DurationFrame.AbsoluteSize.X, 0, 2)', 'notification duration width')
text = once(text, '\t\t\t\t{ Size = UDim2.new(0, 0, 1, 0) },', '\t\t\t\t{ Size = UDim2.new(0, 0, 0, 2) },', 'notification duration tween')
save(path, text)

# Theme surface subtlety
path = "main.lua"
text = load(path)
text = many(text, 'ElementBackgroundTransparency = 0,', 'ElementBackgroundTransparency = 0.08,', 4, 'vanta card transparency')
save(path, text)

# Showcase boxed section
path = "test.lua"
text = load(path)
text = once(text, 'Controls:Section({\n    Title = "Native Controls",\n})', 'Controls:Section({\n    Title = "Native Controls",\n    Desc = "Vanta polish preview",\n    Box = true,\n    BoxBorder = true,\n})', 'showcase section card')
save(path, text)

print("Vanta polish patch applied successfully")
