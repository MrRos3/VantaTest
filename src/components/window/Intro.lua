local Intro = {}

local Creator = require("../../modules/Creator")
local New = Creator.New
local Tween = Creator.Tween

local function SetZIndex(root, zIndex)
	root.ZIndex = zIndex
	for _, descendant in next, root:GetDescendants() do
		if descendant:IsA("GuiObject") then
			descendant.ZIndex = zIndex
		end
	end
end

function Intro.Play(branding, parent)
	branding = branding or {}
	local introConfig = typeof(branding.Intro) == "table" and branding.Intro or {}
	if branding.Intro == false or introConfig.Enabled == false or not branding.Image then
		return
	end

	local duration = math.max(tonumber(introConfig.Duration) or 2.8, 1.8)
	local title = introConfig.Title or branding.Name or "VANTA"
	local subtitle = introConfig.Subtitle or "SIGNAL ACQUIRED"
	local accent = introConfig.Accent or Color3.fromHex("#5DE7FF")
	local logoSize = math.clamp(tonumber(introConfig.LogoSize) or 196, 132, 260)
	local radius = tonumber(introConfig.Radius) or branding.IconRadius or 20

	local Root = New("CanvasGroup", {
		Name = "VantaBrandIntro",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0,
		GroupTransparency = 0,
		Parent = parent,
		Active = true,
		ZIndex = 100000,
	})

	local Ambient = New("Frame", {
		Size = UDim2.fromScale(1.25, 1.25),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.965,
		ZIndex = 100001,
		Parent = Root,
	}, {
		New("UICorner", { CornerRadius = UDim.new(1, 0) }),
		New("UIGradient", {
			Rotation = 90,
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0.15),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})

	local Content = New("CanvasGroup", {
		Size = UDim2.new(0, math.max(logoSize + 80, 300), 0, logoSize + 122),
		Position = UDim2.new(0.5, 0, 0.5, 14),
		AnchorPoint = Vector2.new(0.5, 0.5),
		BackgroundTransparency = 1,
		GroupTransparency = 1,
		ZIndex = 100002,
		Parent = Root,
	})

	local Halo = New("Frame", {
		Size = UDim2.new(0, logoSize + 22, 0, logoSize + 22),
		Position = UDim2.new(0.5, 0, 0, 0),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.12,
		ZIndex = 100003,
		Parent = Content,
	}, {
		New("UICorner", { CornerRadius = UDim.new(0, radius + 7) }),
		New("UIStroke", {
			Color = accent,
			Transparency = 0.38,
			Thickness = 1.5,
		}),
	})

	local Image = Creator.Image(
		branding.Image,
		"VantaBrand",
		radius,
		branding.Folder or "VantaUI",
		"BrandIntro",
		false,
		false
	)
	Image.Size = UDim2.new(0, logoSize, 0, logoSize)
	Image.Position = UDim2.fromScale(0.5, 0.5)
	Image.AnchorPoint = Vector2.new(0.5, 0.5)
	Image.Parent = Halo
	SetZIndex(Image, 100004)

	local Scanline = New("Frame", {
		Size = UDim2.new(1, -18, 0, 2),
		Position = UDim2.new(0.5, 0, 0, 10),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundColor3 = accent,
		BackgroundTransparency = 0.28,
		ZIndex = 100005,
		Parent = Halo,
	}, {
		New("UIGradient", {
			Transparency = NumberSequence.new({
				NumberSequenceKeypoint.new(0, 1),
				NumberSequenceKeypoint.new(0.5, 0),
				NumberSequenceKeypoint.new(1, 1),
			}),
		}),
	})

	local Title = New("TextLabel", {
		Text = title,
		FontFace = Font.new(Creator.Font, Enum.FontWeight.Bold),
		TextSize = 27,
		TextColor3 = Color3.new(1, 1, 1),
		TextTransparency = 1,
		TextXAlignment = "Center",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 34),
		Position = UDim2.new(0, 0, 0, logoSize + 34),
		ZIndex = 100003,
		Parent = Content,
	})

	local Subtitle = New("TextLabel", {
		Text = subtitle,
		FontFace = Font.new(Creator.Font, Enum.FontWeight.Medium),
		TextSize = 11,
		TextColor3 = accent,
		TextTransparency = 1,
		TextXAlignment = "Center",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 0, 0, 20),
		Position = UDim2.new(0, 0, 0, logoSize + 67),
		ZIndex = 100003,
		Parent = Content,
	})

	local Track = New("Frame", {
		Size = UDim2.new(0, 164, 0, 2),
		Position = UDim2.new(0.5, 0, 1, -2),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.fromRGB(32, 35, 42),
		BackgroundTransparency = 0.15,
		ZIndex = 100003,
		Parent = Content,
	}, {
		New("UICorner", { CornerRadius = UDim.new(1, 0) }),
	})

	local Progress = New("Frame", {
		Size = UDim2.new(0, 0, 1, 0),
		BackgroundColor3 = accent,
		BackgroundTransparency = 0,
		ZIndex = 100004,
		Parent = Track,
	}, {
		New("UICorner", { CornerRadius = UDim.new(1, 0) }),
		New("UIGradient", {
			Color = ColorSequence.new(accent, Color3.new(1, 1, 1)),
		}),
	})

	local imageLabel = Image:FindFirstChildWhichIsA("ImageLabel", true)
	local loadTimeout = tonumber(introConfig.LoadTimeout) or 8
	local loadStarted = os.clock()
	while imageLabel and imageLabel.Image == "" and os.clock() - loadStarted < loadTimeout do
		task.wait()
	end

	Tween(Content, 0.5, {
		GroupTransparency = 0,
		Position = UDim2.new(0.5, 0, 0.5, 0),
	}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
	Tween(Ambient, 0.8, { BackgroundTransparency = 0.985 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
	Tween(Scanline, duration * 0.52, {
		Position = UDim2.new(0.5, 0, 1, -10),
		BackgroundTransparency = 0.7,
	}, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
	task.wait(0.34)

	Tween(Title, 0.38, { TextTransparency = 0 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
	Tween(Subtitle, 0.48, { TextTransparency = 0.18 }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()
	Tween(Progress, math.max(duration - 0.7, 1), { Size = UDim2.fromScale(1, 1) }, Enum.EasingStyle.Quint, Enum.EasingDirection.Out):Play()

	task.wait(math.max(duration - 0.68, 1.1))
	Tween(Root, 0.5, { GroupTransparency = 1 }, Enum.EasingStyle.Quint, Enum.EasingDirection.In):Play()
	task.wait(0.5)
	Root:Destroy()
end

return Intro
