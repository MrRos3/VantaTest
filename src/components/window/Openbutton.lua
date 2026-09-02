local OpenButton = {}

local Creator = require("../../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween

local cloneref = (cloneref or clonereference or function(instance) return instance end)
local UserInputService = cloneref(game:GetService("UserInputService"))

function OpenButton.New(Window)
    local OpenButtonMain = {
        Button = nil,
        Icon = nil,
        Hitbox = nil,
        Dragging = false,
        WasDragged = false,
        OnlyIcon = false,
    }

    local Icon

    local Title = New("TextLabel", {
        Text = Window.Title,
        TextSize = 16,
        FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
        BackgroundTransparency = 1,
        AutomaticSize = "XY",
    })

    local Drag = New("Frame", {
        Size = UDim2.new(0, 44 - 8, 0, 44 - 8),
        BackgroundTransparency = 1,
        Name = "Drag",
    }, {
        New("ImageLabel", {
            Image = Creator.Icon("move")[1],
            ImageRectOffset = Creator.Icon("move")[2].ImageRectPosition,
            ImageRectSize = Creator.Icon("move")[2].ImageRectSize,
            Size = UDim2.new(0, 18, 0, 18),
            BackgroundTransparency = 1,
            Position = UDim2.new(0.5, 0, 0.5, 0),
            AnchorPoint = Vector2.new(0.5, 0.5),
            ThemeTag = {
                ImageColor3 = "Icon",
            },
            ImageTransparency = .4,
        })
    })

    local Divider = New("Frame", {
        Size = UDim2.new(0, 1, 1, 0),
        Position = UDim2.new(0, 20 + 16, 0.5, 0),
        AnchorPoint = Vector2.new(0, 0.5),
        BackgroundColor3 = Color3.new(1, 1, 1),
        BackgroundTransparency = .88,
    })

    local Container = New("Frame", {
        Size = UDim2.new(0, 0, 0, 0),
        Position = UDim2.new(0.5, 0, 0, 6 + 44 / 2),
        AnchorPoint = Vector2.new(0.5, 0.5),
        Parent = Window.Parent,
        BackgroundTransparency = 1,
        Active = true,
        Visible = false,
    })

    local UIScale = New("UIScale", {
        Scale = 1,
    })

    local Button = New("Frame", {
        Size = UDim2.new(0, 0, 0, 44),
        AutomaticSize = "X",
        Parent = Container,
        Active = true,
        BackgroundTransparency = .12,
        ZIndex = 99,
        BackgroundColor3 = Color3.fromHex("#0B0E14"),
        ClipsDescendants = true,
    }, {
        UIScale,
        New("UICorner", {
            CornerRadius = UDim.new(1, 0)
        }),
        New("UIGradient", {
            Rotation = 90,
            Color = ColorSequence.new(Color3.fromHex("#151923"), Color3.fromHex("#0B0E14")),
        }),
        New("UIStroke", {
            Thickness = 1,
            ApplyStrokeMode = "Border",
            Color = Color3.new(1, 1, 1),
            Transparency = .15,
        }, {
            New("UIGradient", {
                Color = ColorSequence.new(Color3.fromHex("#5DE7FF"), Color3.fromHex("#7C8CFF"))
            })
        }),
        Drag,
        Divider,

        New("UIListLayout", {
            Padding = UDim.new(0, 4),
            FillDirection = "Horizontal",
            VerticalAlignment = "Center",
        }),

        New("TextButton", {
            AutomaticSize = "XY",
            Active = true,
            BackgroundTransparency = 1,
            Size = UDim2.new(0, 0, 0, 44 - (4 * 2)),
            BackgroundColor3 = Color3.new(1, 1, 1),
            ClipsDescendants = true,
        }, {
            New("UICorner", {
                CornerRadius = UDim.new(1, -4)
            }),
            Icon,
            New("UIListLayout", {
                Padding = UDim.new(0, Window.UIPadding),
                FillDirection = "Horizontal",
                VerticalAlignment = "Center",
            }),
            Title,
            New("UIPadding", {
                PaddingLeft = UDim.new(0, 7 + 4),
                PaddingRight = UDim.new(0, 7 + 4),
            }),
        }),
        New("UIPadding", {
            PaddingLeft = UDim.new(0, 4),
            PaddingRight = UDim.new(0, 4),
        })
    })

    local Hitbox = New("TextButton", {
        Name = "DragHitbox",
        Size = UDim2.fromScale(1, 1),
        Position = UDim2.fromScale(0, 0),
        BackgroundTransparency = 1,
        Text = "",
        AutoButtonColor = false,
        Active = true,
        ZIndex = 10050,
        Parent = Button,
    })

    OpenButtonMain.Button = Button
    OpenButtonMain.Hitbox = Hitbox

    function OpenButtonMain:SetIcon(newIcon)
        if newIcon == OpenButtonMain.Icon and Icon then
            return
        end
        if Icon then
            Icon:Destroy()
        end
        if newIcon then
            local isBrandIcon = Window.BrandImage
                and (newIcon == Window.BrandImage or newIcon == Window.Branding.OpenButtonIcon)
            local iconRadius = isBrandIcon
                and (Window.Branding.OpenButtonIconRadius or Window.Branding.IconRadius or 7)
                or 0

            Icon = Creator.Image(
                newIcon,
                Window.Title,
                iconRadius,
                Window.Folder,
                "OpenButton",
                true,
                Window.IconThemed
            )
            Icon.Size = UDim2.new(0, 22, 0, 22)
            Icon.LayoutOrder = -1
            Icon.Parent = OpenButtonMain.OnlyIcon and OpenButtonMain.Button or OpenButtonMain.Button.TextButton

            if isBrandIcon and Icon.ImageLabel then
                Icon.ImageLabel.ScaleType = Enum.ScaleType.Crop
                Icon.ImageLabel.Size = UDim2.fromScale(1, 1)
                Icon.ImageLabel.Position = UDim2.fromScale(0.5, 0.5)
                Icon.ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            end
        end
        OpenButtonMain.Icon = newIcon
    end

    if Window.Icon then
        OpenButtonMain:SetIcon(Window.Icon)
    end

    Creator.AddSignal(Button:GetPropertyChangedSignal("AbsoluteSize"), function()
        Container.Size = UDim2.new(
            0, Button.AbsoluteSize.X,
            0, Button.AbsoluteSize.Y
        )
    end)

    Creator.AddSignal(Hitbox.MouseEnter, function()
        Tween(Button.TextButton, .16, { BackgroundTransparency = .9 }):Play()
    end)
    Creator.AddSignal(Hitbox.MouseLeave, function()
        Tween(Button.TextButton, .16, { BackgroundTransparency = 1 }):Play()
    end)

    -- Dedicated badge dragging. The full transparent hitbox owns every pixel
    -- and follows the pointer directly on both mouse and touch.
    local dragEnabled = true
    local dragging = false
    local dragStart
    local dragStartPosition
    local activeInput

    Creator.AddSignal(Hitbox.InputBegan, function(input)
        if not dragEnabled or dragging then
            return
        end
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            OpenButtonMain.Dragging = true
            OpenButtonMain.WasDragged = false
            activeInput = input
            dragStart = input.Position
            dragStartPosition = Container.Position
        end
    end)

    Creator.AddSignal(UserInputService.InputChanged, function(input)
        if not dragging or not dragEnabled or not activeInput then
            return
        end

        local valid = false
        if activeInput.UserInputType == Enum.UserInputType.MouseButton1 then
            valid = input.UserInputType == Enum.UserInputType.MouseMovement
        elseif activeInput.UserInputType == Enum.UserInputType.Touch then
            valid = input == activeInput
        end
        if not valid then
            return
        end

        local delta = input.Position - dragStart
        if math.abs(delta.X) > 2 or math.abs(delta.Y) > 2 then
            OpenButtonMain.WasDragged = true
        end
        Container.Position = UDim2.new(
            dragStartPosition.X.Scale,
            dragStartPosition.X.Offset + delta.X,
            dragStartPosition.Y.Scale,
            dragStartPosition.Y.Offset + delta.Y
        )
    end)

    Creator.AddSignal(UserInputService.InputEnded, function(input)
        if not dragging or not activeInput then
            return
        end
        local ended = input == activeInput
            or (activeInput.UserInputType == Enum.UserInputType.MouseButton1
                and input.UserInputType == Enum.UserInputType.MouseButton1)
        if not ended then
            return
        end

        dragging = false
        OpenButtonMain.Dragging = false
        activeInput = nil

        if OpenButtonMain.WasDragged then
            task.delay(0.18, function()
                OpenButtonMain.WasDragged = false
            end)
        end
    end)

    Creator.AddSignal(Hitbox.MouseButton1Click, function()
        if OpenButtonMain.WasDragged or OpenButtonMain.Dragging then
            return
        end
        if Window.Open then
            Window:Open()
        end
    end)

    local DragModule = {}
    function DragModule:Set(v)
        dragEnabled = v ~= false
        if not dragEnabled then
            dragging = false
            OpenButtonMain.Dragging = false
            activeInput = nil
        end
    end

    function OpenButtonMain:Visible(v)
        Container.Visible = v
    end

    function OpenButtonMain:SetScale(scale)
        UIScale.Scale = scale
    end

    function OpenButtonMain:Edit(OpenButtonConfig)
        local OpenButtonModule = {
            Title = OpenButtonConfig.Title,
            Icon = OpenButtonConfig.Icon,
            Enabled = OpenButtonConfig.Enabled,
            Position = OpenButtonConfig.Position,
            OnlyIcon = OpenButtonConfig.OnlyIcon or false,
            Draggable = OpenButtonConfig.Draggable,
            OnlyMobile = OpenButtonConfig.OnlyMobile,
            CornerRadius = OpenButtonConfig.CornerRadius or UDim.new(1, 0),
            StrokeThickness = OpenButtonConfig.StrokeThickness or 1,
            Scale = OpenButtonConfig.Scale or 1,
            ImageZoom = OpenButtonConfig.ImageZoom or 1.5,
            Color = OpenButtonConfig.Color
                or ColorSequence.new(Color3.fromHex("#5DE7FF"), Color3.fromHex("#7C8CFF")),
        }

        if OpenButtonModule.Enabled == false then
            Window.IsOpenButtonEnabled = false
        end

        if OpenButtonModule.OnlyMobile ~= false then
            OpenButtonModule.OnlyMobile = true
        else
            Window.IsPC = false
        end

        OpenButtonMain.OnlyIcon = OpenButtonModule.OnlyIcon == true

        local dragEnabled = OpenButtonModule.Draggable ~= false
        if Drag and Divider then
            -- The branded icon-only badge never needs a visible handle.
            local showDragHandle = dragEnabled and OpenButtonModule.OnlyIcon ~= true
            Drag.Visible = showDragHandle
            Divider.Visible = showDragHandle
        end
        if DragModule then
            DragModule:Set(dragEnabled)
        end

        if OpenButtonModule.Position and Container then
            Container.Position = OpenButtonModule.Position
        end

        if OpenButtonModule.OnlyIcon == true and Title then
            Title.Visible = false

            -- Turn icon-only mode into a true full-bleed 44x44 badge.
            Button.AutomaticSize = Enum.AutomaticSize.None
            Button.Size = UDim2.fromOffset(44, 44)
            Button.UIPadding.PaddingLeft = UDim.new(0, 0)
            Button.UIPadding.PaddingRight = UDim.new(0, 0)

            Button.TextButton.Visible = false
            Button.TextButton.Active = false

            if Icon then
                Icon.Parent = Button
                Icon.Size = UDim2.fromScale(1, 1)
                Icon.Position = UDim2.fromScale(0.5, 0.5)
                Icon.AnchorPoint = Vector2.new(0.5, 0.5)
                Icon.ZIndex = 100
                if Icon.ImageLabel then
                    Icon.ImageLabel.ZIndex = 100
                    Icon.ImageLabel.ScaleType = Enum.ScaleType.Crop
                    Icon.ImageLabel.Size = UDim2.fromScale(OpenButtonModule.ImageZoom, OpenButtonModule.ImageZoom)
                    Icon.ImageLabel.Position = UDim2.fromScale(0.5, 0.5)
                    Icon.ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
                end
            end
        elseif OpenButtonModule.OnlyIcon == false then
            Title.Visible = true
            Button.AutomaticSize = Enum.AutomaticSize.X
            Button.Size = UDim2.new(0, 0, 0, 44)
            Button.UIPadding.PaddingLeft = UDim.new(0, 4)
            Button.UIPadding.PaddingRight = UDim.new(0, 4)

            Button.TextButton.Visible = true
            Button.TextButton.Active = true
            Button.TextButton.AutomaticSize = Enum.AutomaticSize.XY
            Button.TextButton.Size = UDim2.new(0, 0, 0, 44 - (4 * 2))
            Button.TextButton.UIPadding.PaddingLeft = UDim.new(0, 7 + 4)
            Button.TextButton.UIPadding.PaddingRight = UDim.new(0, 7 + 4)

            if Icon then
                Icon.Parent = Button.TextButton
                Icon.Size = UDim2.new(0, 22, 0, 22)
                Icon.Position = UDim2.new(0, 0, 0, 0)
                Icon.AnchorPoint = Vector2.new(0, 0)
            end
        end

        if Title then
            if OpenButtonModule.Title then
                Title.Text = OpenButtonModule.Title
                Creator:ChangeTranslationKey(Title, OpenButtonModule.Title)
            elseif OpenButtonModule.Title == nil then
                -- Keep the window title.
            end
        end

        if OpenButtonModule.Icon then
            OpenButtonMain:SetIcon(OpenButtonModule.Icon)
        end

        -- SetIcon may recreate the image after the mode was configured.
        if Icon and OpenButtonModule.OnlyIcon == true then
            Icon.Parent = Button
            Icon.Size = UDim2.fromScale(1, 1)
            Icon.ZIndex = 100
            Icon.Position = UDim2.fromScale(0.5, 0.5)
            Icon.AnchorPoint = Vector2.new(0.5, 0.5)
            if Icon.ImageLabel then
                Icon.ImageLabel.ScaleType = Enum.ScaleType.Crop
                Icon.ImageLabel.Size = UDim2.fromScale(OpenButtonModule.ImageZoom, OpenButtonModule.ImageZoom)
                Icon.ImageLabel.Position = UDim2.fromScale(0.5, 0.5)
                Icon.ImageLabel.AnchorPoint = Vector2.new(0.5, 0.5)
            end
        end

        Button.UIStroke.UIGradient.Color = OpenButtonModule.Color
        Button.UICorner.CornerRadius = OpenButtonModule.CornerRadius
        Button.TextButton.UICorner.CornerRadius = OpenButtonModule.CornerRadius
        Button.UIStroke.Thickness = OpenButtonModule.StrokeThickness

        OpenButtonMain:SetScale(OpenButtonModule.Scale)
    end

    return OpenButtonMain
end

return OpenButton