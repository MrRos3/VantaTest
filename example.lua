--[[
    VantaTest UI Laboratory
    A standalone showcase of every registered VantaTest element.
    Loads VantaTest exclusively; no VantaUI source or runtime is modified.
    Run through: loadstring(game:HttpGet(
       "https://raw.githubusercontent.com/MrRos3/VantaTest/main/example.lua?v=" .. os.time()
    ))()
]]

local BASE = "https://raw.githubusercontent.com/MrRos3/VantaTest/main/"
local versionToken = tostring(os.time()) .. "-" .. tostring(math.random(100000, 999999))
local VantaTest = assert(loadstring(game:HttpGet(BASE .. "main.lua?v=" .. versionToken)))()
assert(type(VantaTest) == "table" and type(VantaTest.CreateWindow) == "function", "VantaTest library did not initialize")

local Window = VantaTest:CreateWindow({
    Title = "VantaTest LAB",
    Theme = "Salty Special",
    Size = UDim2.fromOffset(700, 465),
    StartupTab = 1,
    Branding = {
        Name = "VANTATEST",
        Image = VantaTest.Brand.Image,
        Folder = "VantaTest",
        IconSize = 24,
        IconRadius = 7,
        OpenButtonIconRadius = 8,
        Intro = false,
    },
    OpenButton = {
        Title = "Open VantaTest",
        Icon = VantaTest.Brand.Image,
        ImageZoom = 1,
        Enabled = true,
        OnlyMobile = false,
        OnlyIcon = true,
        Draggable = true,
    },
    Sounds = { Enabled = true, Preset = "Soft", Volume = 0.45 },
})

local function toast(title, body, icon, duration, canClose)
    local ok, err = pcall(function()
        VantaTest:Notify({
            Title = tostring(title),
            Content = tostring(body or ""),
            Icon = icon or "check",
            Duration = duration or 5,
            CanClose = canClose ~= false,
        })
    end)
    if not ok then warn("[VantaTest LAB / Notification] " .. tostring(err)) end
end

local failures = {}
local function add(parent, kind, config)
    local ok, result = pcall(function()
        assert(type(parent[kind]) == "function", kind .. " is not registered")
        return parent[kind](parent, config or {})
    end)
    if ok then return result end
    failures[#failures + 1] = kind .. ": " .. tostring(result)
    warn("[VantaTest LAB] " .. failures[#failures])
    -- Never allow one unfinished component to hide the rest of the showcase.
    if kind ~= "Paragraph" and type(parent.Paragraph) == "function" then
        pcall(function()
            parent:Paragraph({ Title = kind .. " failed", Desc = tostring(result) })
        end)
    end
    return nil
end

local function tab(title, icon, desc)
    return Window:Tab({ Title = title, Icon = icon, Desc = desc })
end

-- HOME -----------------------------------------------------------------------
local Home = tab("Home", "house", "VantaTest component playground")
add(Home, "Section", {
    Title = "VantaTest UI Laboratory",
    Desc = "An editable showcase for comparing controls, layout, colors and animations.",
    Icon = "flask-conical",
})
add(Home, "Paragraph", {
    Title = "Live component tests",
    Desc = "Open any tab on the left. Every major control has a usable example; actions display their state in notifications. This showcase loads ONLY VantaTest.",
})
local tally = 0
local tallyLabel = add(Home, "Paragraph", { Title = "Test clicks: 0", Desc = "Use the button below to verify that callbacks are working." })
add(Home, "Button", {
    Title = "Run click test",
    Desc = "Increment an on-screen counter",
    Icon = "mouse-pointer-click",
    Callback = function()
        tally = tally + 1
        if tallyLabel and tallyLabel.SetTitle then
            tallyLabel:SetTitle("Test clicks: " .. tally)
        end
        toast("Button working", "Click number " .. tally, "check")
    end,
})
add(Home, "Button", {
    Title = "Preview OLED notification",
    Desc = "Black card, burgundy full-height countdown and lower-right placement",
    Icon = "bell",
    Callback = function() toast("VantaTest", "OLED notification preview • 5 seconds", "check", 5) end,
})
add(Home, "Paragraph", {
    Title = "Runtime",
    Desc = "VantaTest v" .. tostring(VantaTest.Version) .. " | Theme: Salty Special | All examples stay in this test repository.",
})
add(Home, "Divider", {})
add(Home, "Section", { Title = "What's inside", Desc = "Nameplate, buttons, toggles, keybinds, sliders, progress bars, dropdowns, inputs, themes, layouts, images and more." })

-- NAMEPLATE ------------------------------------------------------------------
-- Client-only BillboardGui above the local player's head, recreated on respawn.
-- This does NOT replicate to friends in arbitrary Roblox games.
local NameplateTab = tab("Nameplate", "user-round", "Floating customizable nameplate over your character")
add(NameplateTab, "Section", {
    Title = "Your floating nameplate",
    Desc = "Vanta Edge: cut corners, crimson glow, real health, and a distant name-only mode.",
    Icon = "user-round",
})
local NameplateModule
local NameplateController
local okNameplate, nameplateError = pcall(function()
    local moduleSource = game:HttpGet(BASE .. "nameplate.lua?v=" .. versionToken)
    NameplateModule = assert(loadstring(moduleSource))()
    assert(type(NameplateModule.new) == "function", "Nameplate module is not ready")
    NameplateController = NameplateModule.new({
        Enabled = true,
        Tag = "VANTA",
        Style = "Crimson",
        ShowUsername = true,
        Scale = 100,
        MaxDistance = 100,
        Height = 2.65,
        Subtitle = "MEMBER",
        LoadRemoteImage = VantaTest.Creator and VantaTest.Creator.LoadRemoteImage,
    })
end)
if not okNameplate then
    warn("[VantaTest LAB / Nameplate] " .. tostring(nameplateError))
    add(NameplateTab, "Paragraph", {
        Title = "Nameplate couldn't load",
        Desc = tostring(nameplateError),
    })
end
local function updateNameplate(method, value)
    if not NameplateController then
        toast("Nameplate", "Nameplate module is unavailable.", "alert-triangle", 3)
        return
    end
    local ok, err = pcall(function()
        NameplateController[method](NameplateController, value)
    end)
    if not ok then
        warn("[VantaTest LAB / Nameplate] " .. tostring(err))
        toast("Nameplate error", tostring(err), "alert-triangle", 4)
    end
end
local nameplateVisible = true
local nameplateToggle
local topbarEyeButton
local topbarEyeImage
local EYE_VISIBLE = "rbxassetid://75816651251769" -- SaltyIcons eye.png
local EYE_HIDDEN  = "rbxassetid://94392100296471" -- SaltyIcons eye-off.png

local function syncNameplateVisibility(show, fromTopbar)
    if not NameplateController then
        toast("Nameplate", "Nameplate isn't available.", "alert-triangle", 3)
        return
    end
    nameplateVisible = not not show
    updateNameplate("SetEnabled", nameplateVisible)
    if fromTopbar and nameplateToggle and type(nameplateToggle.Set) == "function" then
        -- Synchronize the visual toggle without calling its callback a second time.
        nameplateToggle:Set(nameplateVisible, false, true)
    end
    if topbarEyeImage then
        topbarEyeImage.Image = nameplateVisible and EYE_VISIBLE or EYE_HIDDEN
        topbarEyeImage.ImageColor3 = nameplateVisible
            and Color3.fromRGB(255, 77, 112) or Color3.fromRGB(154, 146, 153)
    end
    if topbarEyeButton then
        topbarEyeButton:SetAttribute("NameplateVisible", nameplateVisible)
        topbarEyeButton:SetAttribute("Tooltip", nameplateVisible
            and "Hide nameplate" or "Show nameplate")
    end
end

nameplateToggle = add(NameplateTab, "Toggle", {
    Title = "Show nameplate",
    Desc = "Synced with the eye button beside the window traffic lights",
    Value = true,
    Callback = function(value) syncNameplateVisibility(value, false) end,
})

-- Small Vanta-only topbar utility directly LEFT of Mac traffic dots.
-- Its published SaltyIcons assets never depend on handmade icon drawings.
local rightOk, rightError = pcall(function()
    local right = Window.UIElements.Main.Main.Topbar.Right
    assert(right and right:FindFirstChildOfClass("UIListLayout"), "Topbar right-side layout unavailable")
    local slot = Instance.new("Frame")
    slot.Name = "NameplateVisibilitySlot"
    slot.Size = UDim2.fromOffset(27, 24)
    slot.BackgroundTransparency = 1
    slot.LayoutOrder = 996 -- existing Mac dots start at 997; eye sits adjacent
    slot.Parent = right

    local button = Instance.new("TextButton")
    button.Name = "NameplateVisibilityButton"
    button.Size = UDim2.fromOffset(23, 23)
    button.Position = UDim2.fromOffset(2, 0)
    button.BackgroundColor3 = Color3.fromRGB(18, 15, 20)
    button.BackgroundTransparency = 0.08
    button.AutoButtonColor = true
    button.Text = ""
    button.BorderSizePixel = 0
    button.ZIndex = 10000
    button.Parent = slot
    local radius = Instance.new("UICorner")
    radius.CornerRadius = UDim.new(0, 8)
    radius.Parent = button
    local border = Instance.new("UIStroke")
    border.Color = Color3.fromRGB(122, 49, 68)
    border.Transparency = 0.22
    border.Thickness = 1
    border.Parent = button

    local icon = Instance.new("ImageLabel")
    icon.Name = "SaltyIconsEye"
    icon.BackgroundTransparency = 1
    icon.Size = UDim2.fromOffset(15, 15)
    icon.AnchorPoint = Vector2.new(0.5, 0.5)
    icon.Position = UDim2.fromScale(0.5, 0.5)
    icon.Image = EYE_VISIBLE
    icon.ImageColor3 = Color3.fromRGB(255, 77, 112)
    icon.ZIndex = 10001
    icon.Parent = button

    topbarEyeButton = button
    topbarEyeImage = icon
    button:SetAttribute("Tooltip", "Hide nameplate")
    button:SetAttribute("NameplateVisible", true)
    button.MouseButton1Click:Connect(function()
        syncNameplateVisibility(not nameplateVisible, true)
    end)
end)
if not rightOk then
    warn("[VantaTest LAB / Nameplate topbar] " .. tostring(rightError))
end
add(NameplateTab, "Dropdown", {
    Title = "Nameplate theme",
    Desc = "Three clean styles inspired by Vanta",
    Values = { "Crimson", "OLED", "Steel" },
    Value = "Crimson",
    Callback = function(value) updateNameplate("SetStyle", value) end,
})
add(NameplateTab, "Input", {
    Title = "Small tag",
    Desc = "Solid crimson corner badge, up to 18 characters",
    Value = "VANTA",
    Placeholder = "VANTA",
    Callback = function(value) updateNameplate("SetTag", value) end,
})
add(NameplateTab, "Input", {
    Title = "Status or rank",
    Desc = "Second line when display name and username match; enter your own rank or level",
    Value = "MEMBER",
    Placeholder = "MEMBER",
    Callback = function(value) updateNameplate("SetSubtitle", value) end,
})
add(NameplateTab, "Toggle", {
    Title = "Show @username",
    Desc = "Show the real @username only if it differs from your display name",
    Value = true,
    Callback = function(value) updateNameplate("SetShowUsername", value) end,
})
add(NameplateTab, "Slider", {
    Title = "Nameplate size",
    Desc = "Scale the complete card without changing your character",
    Value = { Min = 70, Max = 140, Default = 100 },
    Step = 5,
    Callback = function(value) updateNameplate("SetScale", value) end,
})
add(NameplateTab, "Slider", {
    Title = "Height above head",
    Desc = "Adjust upward offset in tenths of a stud",
    Value = { Min = 15, Max = 45, Default = 27 },
    Step = 1,
    Callback = function(value) updateNameplate("SetHeight", value / 10) end,
})
add(NameplateTab, "Slider", {
    Title = "Visibility distance",
    Desc = "Full nameplate up close; shrinks past 40 studs and becomes name-only past 65",
    Value = { Min = 30, Max = 150, Default = 100 },
    Step = 10,
    Callback = function(value) updateNameplate("SetDistance", value) end,
})
add(NameplateTab, "Paragraph", {
    Title = "Local-only display",
    Desc = "This nameplate renders only for you. Health comes from your Humanoid, and the status dot turns red briefly after damage. Other players don't see this client-only GUI.",
})

-- BUTTONS --------------------------------------------------------------------
local Buttons = tab("Buttons", "mouse-pointer-2", "Clickable elements, locking and notifications")
add(Buttons, "Section", { Title = "Button variations", Icon = "square-mouse-pointer" })
add(Buttons, "Button", {
    Title = "Primary action", Desc = "Shows a success notification", Icon = "check-circle",
    Callback = function() toast("Primary button", "Button callback succeeded!", "check") end,
})
add(Buttons, "Button", {
    Title = "Warning action", Desc = "Try a different icon and message", Icon = "alert-triangle",
    Callback = function() toast("Attention", "Warning button pressed.", "alert-triangle") end,
})
add(Buttons, "Button", {
    Title = "Long notification", Desc = "Shows a 12-second countdown", Icon = "clock",
    Callback = function() toast("Long countdown", "Watch the burgundy overlay shrink.", "timer", 12) end,
})
add(Buttons, "Button", {
    Title = "Non-closable toast", Desc = "Dismisses itself after 4 seconds", Icon = "eye",
    Callback = function() toast("Automatic close", "This notification hides its X button.", "info", 4, false) end,
})
local lockable = add(Buttons, "Button", {
    Title = "Lockable action", Desc = "Toggle the lock with the next button", Icon = "lock-keyhole-open",
    Callback = function() toast("Unlocked button", "The lockable button works.", "unlock") end,
})
local locked = false
add(Buttons, "Button", {
    Title = "Lock / Unlock",
    Desc = "Test the Lock() and Unlock() methods",
    Icon = "lock",
    Callback = function()
        if not lockable then return end
        locked = not locked
        if locked then lockable:Lock() else lockable:Unlock() end
        toast("Button lock", locked and "Locked" or "Unlocked", locked and "lock" or "unlock")
    end,
})
add(Buttons, "Paragraph", {
    Title = "Paragraph actions",
    Desc = "Paragraphs can also contain quick-action buttons.",
    Buttons = {
        { Title = "Notify", Icon = "bell", Callback = function() toast("Inline action", "Paragraph button works.") end },
    },
})

-- TOGGLES --------------------------------------------------------------------
local Toggles = tab("Toggles", "toggle-right", "Switches, checkboxes, and hotkeys")
add(Toggles, "Section", { Title = "Switch controls" })
add(Toggles, "Toggle", {
    Title = "Enable animations", Desc = "Interactive switch with a callback",
    Value = true,
    Callback = function(value) toast("Animations", value and "Enabled" or "Disabled", "toggle-right", 3) end,
})
add(Toggles, "Toggle", {
    Title = "Compact mode", Desc = "Second independently tracked toggle",
    Value = false,
    Callback = function(value) toast("Compact mode", tostring(value), "settings-2", 3) end,
})
add(Toggles, "Toggle", {
    Title = "Checkbox style", Desc = "Same toggle element using its Checkbox type",
    Type = "Checkbox",
    Value = false,
    Callback = function(value) toast("Checkbox", value and "Checked" or "Unchecked", "check-square", 3) end,
})
add(Toggles, "Divider", {})
add(Toggles, "Section", { Title = "Keyboard shortcuts", Desc = "Try the binding and change its assigned key." })
add(Toggles, "Keybind", {
    Title = "Notification shortcut", Desc = "Press K to show a notification, or click the key to rebind.",
    Value = "K",
    Callback = function(key) toast("Keybind fired", "You pressed " .. tostring(key), "keyboard", 3) end,
})

-- SLIDERS --------------------------------------------------------------------
local Sliders = tab("Sliders", "sliders-horizontal", "Live values and progress")
add(Sliders, "Section", { Title = "Interactive value controls", Icon = "gauge" })
local progress = add(Sliders, "ProgressBar", {
    Title = "Live progress",
    Desc = "Follows the primary slider.",
    Value = { Min = 0, Max = 100, Default = 50 },
    DisplayMode = "Percent",
})
add(Sliders, "Slider", {
    Title = "Progress / intensity",
    Desc = "Drag to update the progress bar",
    Value = { Min = 0, Max = 100, Default = 50 }, Step = 1,
    Callback = function(value)
        if progress then progress:Set(value) end
    end,
})
add(Sliders, "Slider", {
    Title = "Fine adjustment", Desc = "Fractional steps from 0 to 1",
    Value = { Min = 0, Max = 1, Default = 0.5 }, Step = 0.05,
    Callback = function(value) print("[VantaTest LAB] Fine slider:", value) end,
})
add(Sliders, "Slider", {
    Title = "Volume preview", Desc = "Adjust UI sound volume live",
    Value = { Min = 0, Max = 100, Default = 45 }, Step = 5,
    Callback = function(value) VantaTest:SetSoundVolume(value / 100) end,
})
add(Sliders, "Divider", {})
add(Sliders, "ProgressBar", {
    Title = "Fraction progress", Desc = "Alternate progress label style",
    Value = { Min = 0, Max = 20, Default = 13 }, DisplayMode = "Fraction",
})
add(Sliders, "ProgressBar", {
    Title = "Loading animation", Desc = "Indeterminate progress preview",
    Indeterminate = true, IndeterminateText = "Working...",
})

-- DROPDOWNS ------------------------------------------------------------------
local Dropdowns = tab("Dropdowns", "list-filter", "Single, multiple, and searchable selections")
add(Dropdowns, "Section", { Title = "Selection controls" })
add(Dropdowns, "Dropdown", {
    Title = "Select quality",
    Desc = "Single selection",
    Values = { "Low", "Medium", "High", "Ultra" }, Value = "High",
    Callback = function(value) toast("Quality selected", tostring(value), "list-checks", 3) end,
})
add(Dropdowns, "Dropdown", {
    Title = "Choose features",
    Desc = "Multi-select with checkmarks",
    Values = { "Animations", "Sounds", "Blur", "Shadows", "Tooltips" },
    Value = { "Animations", "Sounds" }, Multi = true, AllowNone = true,
    Callback = function(values)
        toast("Features selected", type(values) == "table" and table.concat(values, ", ") or tostring(values), "list-checks", 3)
    end,
})
local refreshable = add(Dropdowns, "Dropdown", {
    Title = "Refreshable list", Desc = "Options can be replaced while the app is open",
    Values = { "Option A", "Option B", "Option C" }, Value = "Option A",
    Callback = function(value) toast("Selected", tostring(value), "check", 3) end,
})
local showingAlt = false
add(Dropdowns, "Button", {
    Title = "Replace dropdown choices",
    Desc = "Test the Refresh() method",
    Icon = "refresh-cw",
    Callback = function()
        if not refreshable or not refreshable.DropdownMenu then return end
        showingAlt = not showingAlt
        refreshable.DropdownMenu:Refresh(showingAlt
            and { "Red", "Burgundy", "Black" }
            or { "Option A", "Option B", "Option C" })
        toast("Dropdown refreshed", "New choices loaded.", "check", 3)
    end,
})
add(Dropdowns, "Dropdown", {
    Title = "Searchable choices",
    Desc = "Try filtering a longer list",
    Values = { "Apple", "Apricot", "Blueberry", "Cherry", "Grape", "Kiwi", "Lemon", "Mango", "Peach", "Pear", "Strawberry" },
    Value = "Apple", SearchBarEnabled = true,
    Callback = function(value) toast("Fruit selected", tostring(value), "search", 3) end,
})

-- INPUTS ---------------------------------------------------------------------
local Inputs = tab("Inputs", "text-cursor-input", "Text, multiline fields, colors and validation")
add(Inputs, "Section", { Title = "Typing and editing" })
add(Inputs, "Input", {
    Title = "Display name", Desc = "Enter a new test name",
    Placeholder = "Type any name...", Value = "Salty",
    Callback = function(value) print("[VantaTest LAB] Name:", tostring(value)) end,
})
add(Inputs, "Input", {
    Title = "Multiline notes", Desc = "Test a larger text entry",
    Type = "Textarea", Placeholder = "Write your notes here...",
    Callback = function(value) print("[VantaTest LAB] Notes:", tostring(value)) end,
})
add(Inputs, "Divider", {})
add(Inputs, "Section", { Title = "Color selection" })
add(Inputs, "Colorpicker", {
    Title = "Accent color", Desc = "Pick any color from the selector",
    Default = Color3.fromHex("#251016"),
    Callback = function(color)
        toast("Accent picked", "#" .. color:ToHex(), "palette", 3)
    end,
})
add(Inputs, "Colorpicker", {
    Title = "Transparency color", Desc = "Color picker with an alpha control",
    Default = Color3.fromHex("#A1162F"), Transparency = 0.2,
    Callback = function(color, transparency)
        toast("Color and alpha", "#" .. color:ToHex() .. " / alpha " .. tostring(transparency), "palette", 3)
    end,
})

-- THEMES ---------------------------------------------------------------------
local Themes = tab("Themes", "palette", "Switch between bundled themes and sounds")
add(Themes, "Section", { Title = "Live theme gallery", Desc = "Select a theme to restyle the entire window." })
for _, item in ipairs({
    { "Salty Special", "heart" },
    { "Vanta Smoked", "cloud-fog" },
    { "Vanta Dark", "moon" },
    { "Vanta AMOLED", "circle-dot" },
    { "Vanta Violet", "wand-sparkles" },
}) do
    local themeName, iconName = item[1], item[2]
    add(Themes, "Button", {
        Title = themeName, Icon = iconName, Desc = "Apply " .. themeName,
        Callback = function()
            local result = VantaTest:SetTheme(themeName)
            toast("Theme applied", result and themeName or "Theme unavailable", iconName, 3)
        end,
    })
end
add(Themes, "Divider", {})
add(Themes, "Section", { Title = "Sound system" })
add(Themes, "Toggle", {
    Title = "Interface sounds", Desc = "Mute or enable UI control sounds",
    Value = true,
    Callback = function(value) VantaTest:SetSoundEnabled(value) end,
})
add(Themes, "Button", {
    Title = "Test notification variants",
    Desc = "Displays multiple notifications with different durations",
    Icon = "bell-ring",
    Callback = function()
        toast("Short", "3-second preview", "check", 3)
        task.delay(0.25, function() toast("Medium", "6-second preview", "info", 6) end)
        task.delay(0.5, function() toast("Long", "10-second preview", "clock", 10) end)
    end,
})

-- LAYOUTS --------------------------------------------------------------------
local Layouts = tab("Layouts", "layout-grid", "Sections, dividers, spaces, groups and stacks")
add(Layouts, "Section", { Title = "Layout primitives", Desc = "Test grouping and the new rounded element arrangement." })
add(Layouts, "Paragraph", { Title = "Ordinary paragraph", Desc = "A text element with a heading and explanatory body." })
add(Layouts, "Divider", {})
add(Layouts, "Space", { Columns = 2 })
local section = add(Layouts, "Section", {
    Title = "Expandable section",
    Desc = "Click this header to collapse or expand the nested content.",
    Icon = "chevron-down",
    Box = true,
    BoxBorder = true,
    Opened = true,
})
if section then
    add(section, "Button", {
        Title = "Nested button", Icon = "layers",
        Callback = function() toast("Nested layout", "Button inside a section works.", "check") end,
    })
    add(section, "Toggle", {
        Title = "Nested toggle", Value = false,
        Callback = function(v) toast("Nested toggle", tostring(v), "toggle-right", 3) end,
    })
end
local group = add(Layouts, "Group", {})
if group then
    add(group, "Button", {
        Title = "Group left", Icon = "arrow-left",
        Callback = function() toast("Group", "Left button!", "check") end,
    })
    add(group, "Button", {
        Title = "Group right", Icon = "arrow-right",
        Callback = function() toast("Group", "Right button!", "check") end,
    })
end
local horizontal = add(Layouts, "HStack", {})
if horizontal then
    add(horizontal, "Button", { Title = "HStack A", Callback = function() toast("HStack", "A") end })
    add(horizontal, "Button", { Title = "HStack B", Callback = function() toast("HStack", "B") end })
end
local vertical = add(Layouts, "VStack", {})
if vertical then
    add(vertical, "Paragraph", { Title = "VStack", Desc = "Vertically arranged elements." })
    add(vertical, "Button", { Title = "VStack button", Callback = function() toast("VStack", "Working!") end })
end

-- MEDIA + ADVANCED ------------------------------------------------------------
local Advanced = tab("Advanced", "box", "Images, code blocks, and 3D viewport")
add(Advanced, "Section", { Title = "Media widgets", Desc = "Image loading and a rotating-capable Roblox viewport." })
add(Advanced, "Image", {
    Image = BASE .. "assets/vanta-brand-v2.jpeg",
    AspectRatio = "16:9",
    Radius = 12,
})
local model = Instance.new("Model")
model.Name = "VantaTestDemoObject"
local block = Instance.new("Part")
block.Name = "BurgundyCube"
block.Anchored = true
block.CanCollide = false
block.Size = Vector3.new(3, 3, 3)
block.Color = Color3.fromRGB(80, 20, 34)
block.Material = Enum.Material.SmoothPlastic
block.Parent = model
local camera = Instance.new("Camera")
camera.CFrame = CFrame.lookAt(Vector3.new(7, 5, 8), Vector3.new(0, 0, 0))
add(Advanced, "Viewport", {
    Object = model,
    Camera = camera,
    Height = 165,
    Interactive = true,
})
add(Advanced, "Divider", {})
add(Advanced, "Section", { Title = "Code display and copy" })
add(Advanced, "Code", {
    Title = "Notification example",
    Code = 'VantaTest:Notify({\n    Title = "Example",\n    Content = "Hello from VantaTest!",\n    Icon = "check"\n})',
    CodeSize = 14, Height = UDim.new(0, 165),
    OnCopy = function() toast("Code copied", "The example was sent to the clipboard, if supported.", "copy", 3) end,
})
add(Advanced, "Button", {
    Title = "Check component errors", Icon = "bug",
    Desc = "Reports components that could not be created on this executor.",
    Callback = function()
        if #failures == 0 then
            toast("Component diagnostics", "All registered showcase controls were created without errors.", "check", 5)
        else
            toast("Component diagnostics", tostring(#failures) .. " controls failed; check the executor console.", "alert-triangle", 8)
            for _, issue in ipairs(failures) do warn("[VantaTest LAB] " .. issue) end
        end
    end,
})

if type(Window.Tag) == "function" then
    pcall(function()
        Window:Tag({ Title = "LAB v" .. tostring(VantaTest.Version), Icon = VantaTest.Brand.Image, Color = Color3.fromHex("#251016"), Border = true })
    end)
end

print("[VantaTest LAB] Showcase ready. Components failed:", #failures)




