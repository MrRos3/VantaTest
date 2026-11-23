local SaltyUI = {
	Window = nil,
	Theme = nil,
	Creator = require("./modules/Creator"),
	LocalizationModule = require("./modules/Localization"),
	NotificationModule = require("./components/Notification"),
	Themes = nil,
	Transparent = false,

	TransparencyValue = 0.15,

	UIScale = 1,

	ConfigManager = nil,
	Version = "0.0.0",

	Services = require("./utils/services/Init"),

	OnThemeChangeFunction = nil,

	cloneref = nil,
	UIScaleObj = nil,

	CreateWindow = nil,

	CurrentInput = nil,
}

local cloneref = (cloneref or clonereference or function(instance)
	return instance
end)

SaltyUI.cloneref = cloneref

local HttpService = cloneref(game:GetService("HttpService"))
local Players = cloneref(game:GetService("Players"))
local CoreGui = cloneref(game:GetService("CoreGui"))
local RunService = cloneref(game:GetService("RunService"))
local UserInputService = cloneref(game:GetService("UserInputService"))

function SaltyUI.GenerateGUID()
	return HttpService:GenerateGUID(false)
end

local CurInput = SaltyUI.GenerateGUID()

UserInputService.InputBegan:Connect(function(Input, GameProcessed)
	--[[if GameProcessed then
		return
	end]]

	task.defer(function()
		if
			Input.UserInputType == Enum.UserInputType.MouseButton1
			or Input.UserInputType == Enum.UserInputType.Touch
		then
			if SaltyUI.CurrentInput and SaltyUI.CurrentInput ~= CurInput then
				return
			end

			SaltyUI.CurrentInput = CurInput
			--print(CurInput)
			--SaltyUI.InputStartedOnUI = false
		end
	end)
end)
UserInputService.InputEnded:Connect(function(Input, GameProcessed)
	if Input.UserInputType == Enum.UserInputType.MouseButton1 or Input.UserInputType == Enum.UserInputType.Touch then
		if SaltyUI.CurrentInput and SaltyUI.CurrentInput ~= CurInput then
			return
		end

		SaltyUI.CurrentInput = nil
	end
end)

local LocalPlayer = Players.LocalPlayer or nil

local Package = HttpService:JSONDecode(require("../build/package"))
if Package then
	SaltyUI.Version = Package.version
end

local KeySystem = require("./components/KeySystem")

local Creator = SaltyUI.Creator

local New = Creator.New

--local Tween = Creator.Tween
--local ServicesModule = SaltyUI.Services

local Acrylic = require("./utils/Acrylic/Init")

local ProtectGui = protectgui or (syn and syn.protect_gui) or function() end

local GUIParent = gethui and gethui() or (CoreGui or LocalPlayer:WaitForChild("PlayerGui"))

local UIScaleObj = New("UIScale", {
	Scale = SaltyUI.UIScale,
})

SaltyUI.UIScaleObj = UIScaleObj

SaltyUI.ScreenGui = New("ScreenGui", {
	Name = "SaltyUI",
	Parent = GUIParent,
	IgnoreGuiInset = true,
	ScreenInsets = "None",
	DisplayOrder = -99999,
}, {

	New("Folder", {
		Name = "Window",
	}),
	-- New("Folder", {
	--     Name = "Notifications"
	-- }),
	-- New("Folder", {
	--     Name = "Dropdowns"
	-- }),
	New("Folder", {
		Name = "KeySystem",
	}),
	New("Folder", {
		Name = "Popups",
	}),
	New("Folder", {
		Name = "ToolTips",
	}),
})

SaltyUI.NotificationGui = New("ScreenGui", {
	Name = "SaltyUI/Notifications",
	Parent = GUIParent,
	IgnoreGuiInset = true,
})
SaltyUI.DropdownGui = New("ScreenGui", {
	Name = "SaltyUI/Dropdowns",
	Parent = GUIParent,
	IgnoreGuiInset = true,
})
SaltyUI.TooltipGui = New("ScreenGui", {
	Name = "SaltyUI/Tooltips",
	Parent = GUIParent,
	IgnoreGuiInset = true,
})
ProtectGui(SaltyUI.ScreenGui)
ProtectGui(SaltyUI.NotificationGui)
ProtectGui(SaltyUI.DropdownGui)
ProtectGui(SaltyUI.TooltipGui)

Creator.Init(SaltyUI)

function SaltyUI:SetParent(parent)
	if SaltyUI.ScreenGui then
		SaltyUI.ScreenGui.Parent = parent
	end
	if SaltyUI.NotificationGui then
		SaltyUI.NotificationGui.Parent = parent
	end
	if SaltyUI.DropdownGui then
		SaltyUI.DropdownGui.Parent = parent
	end
	if SaltyUI.TooltipGui then
		SaltyUI.TooltipGui.Parent = parent
	end
end
math.clamp(SaltyUI.TransparencyValue, 0, 1)

local Holder = SaltyUI.NotificationModule.Init(SaltyUI.NotificationGui)

function SaltyUI:Notify(Config)
	Config.Holder = Holder.Frame
	Config.Window = SaltyUI.Window
	--Config.SaltyUI = SaltyUI
	return SaltyUI.NotificationModule.New(Config)
end

function SaltyUI:SetNotificationLower(Val)
	Holder.SetLower(Val)
end

function SaltyUI:SetFont(FontId)
	Creator.UpdateFont(FontId)
end

function SaltyUI:OnThemeChange(func)
	SaltyUI.OnThemeChangeFunction = func
end

function SaltyUI:AddTheme(LTheme)
	SaltyUI.Themes[LTheme.Name] = LTheme
	return LTheme
end

function SaltyUI:SetTheme(Value)
	if SaltyUI.Themes[Value] then
		SaltyUI.Theme = SaltyUI.Themes[Value]
		Creator.SetTheme(SaltyUI.Themes[Value])

		if SaltyUI.OnThemeChangeFunction then
			SaltyUI.OnThemeChangeFunction(Value)
		end

		return SaltyUI.Themes[Value]
	end
	return nil
end

function SaltyUI:GetThemes()
	return SaltyUI.Themes
end
function SaltyUI:GetCurrentTheme()
	return SaltyUI.Theme.Name
end
function SaltyUI:GetTransparency()
	return SaltyUI.Transparent or false
end
function SaltyUI:GetWindowSize()
	return SaltyUI.Window.UIElements.Main.Size
end
function SaltyUI:Localization(LocalizationConfig)
	return SaltyUI.LocalizationModule:New(LocalizationConfig, Creator)
end

function SaltyUI:SetLanguage(Value)
	if Creator.Localization then
		return Creator.SetLanguage(Value)
	end
	return false
end

function SaltyUI:ToggleAcrylic(Value)
	if SaltyUI.Window and SaltyUI.Window.AcrylicPaint and SaltyUI.Window.AcrylicPaint.Model then
		SaltyUI.Window.Acrylic = Value
		SaltyUI.Window.AcrylicPaint.Model.Transparency = Value and 0.98 or 1
		if Value then
			Acrylic.Enable()
		else
			Acrylic.Disable()
		end
	end
end

function SaltyUI:Gradient(stops, props)
	local colorSequence = {}
	local transparencySequence = {}

	for posStr, stop in next, stops do
		local position = tonumber(posStr)
		if position then
			position = math.clamp(position / 100, 0, 1)

			local color = stop.Color
			if typeof(color) == "string" and string.sub(color, 1, 1) == "#" then
				color = Color3.fromHex(color)
			end

			local transparency = stop.Transparency or 0

			table.insert(colorSequence, ColorSequenceKeypoint.new(position, color))
			table.insert(transparencySequence, NumberSequenceKeypoint.new(position, transparency))
		end
	end

	table.sort(colorSequence, function(a, b)
		return a.Time < b.Time
	end)
	table.sort(transparencySequence, function(a, b)
		return a.Time < b.Time
	end)

	if #colorSequence < 2 then
		table.insert(colorSequence, ColorSequenceKeypoint.new(1, colorSequence[1].Value))
		table.insert(transparencySequence, NumberSequenceKeypoint.new(1, transparencySequence[1].Value))
	end

	local gradientData = {
		Color = ColorSequence.new(colorSequence),
		Transparency = NumberSequence.new(transparencySequence),
	}

	if props then
		for k, v in pairs(props) do
			gradientData[k] = v
		end
	end

	return gradientData
end

function SaltyUI:Popup(PopupConfig)
	PopupConfig.SaltyUI = SaltyUI
	return require("./components/popup/Init").new(PopupConfig, SaltyUI.ScreenGui.Popups)
end

SaltyUI.Themes = require("./themes/Init")(SaltyUI, Creator)

Creator.Themes = SaltyUI.Themes

SaltyUI:SetTheme("Dark")
SaltyUI:SetLanguage(Creator.Language)

function SaltyUI:CreateWindow(Config)
	local CreateWindow = require("./components/window/Init")

	if not RunService:IsStudio() and writefile then
		if not isfolder("WindUI") then
			makefolder("WindUI")
		end
		if Config.Folder then
			makefolder(Config.Folder)
		else
			makefolder(Config.Title)
		end
	end

	Config.SaltyUI = SaltyUI
	Config.Window = SaltyUI.Window
	Config.Parent = SaltyUI.ScreenGui.Window

	if SaltyUI.Window then
		warn("You cannot create more than one window")
		return
	end

	local CanLoadWindow = true

	local Theme = SaltyUI.Themes[Config.Theme or "Dark"]

	--SaltyUI.Theme = Theme
	Creator.SetTheme(Theme)

	local hwid = gethwid or function()
		return Players.LocalPlayer.UserId
	end

	local Filename = hwid()

	if Config.KeySystem then
		CanLoadWindow = false

		local function loadKeysystem()
			KeySystem.new(Config, Filename, function(c)
				CanLoadWindow = c
			end)
		end

		local keyPath = (Config.Folder or "Temp") .. "/" .. Filename .. ".key"

		if Config.KeySystem.KeyValidator then
			if Config.KeySystem.SaveKey and isfile(keyPath) then
				local savedKey = readfile(keyPath)
				local isValid = Config.KeySystem.KeyValidator(savedKey)

				if isValid then
					CanLoadWindow = true
				else
					loadKeysystem()
				end
			else
				loadKeysystem()
			end
		elseif not Config.KeySystem.API then
			if Config.KeySystem.SaveKey and isfile(keyPath) then
				local savedKey = readfile(keyPath)
				local isKey = (type(Config.KeySystem.Key) == "table") and table.find(Config.KeySystem.Key, savedKey)
					or tostring(Config.KeySystem.Key) == tostring(savedKey)

				if isKey then
					CanLoadWindow = true
				else
					loadKeysystem()
				end
			else
				loadKeysystem()
			end
		else
			if isfile(keyPath) then
				local fileKey = readfile(keyPath)
				local isSuccess = false

				for _, i in next, Config.KeySystem.API do
					local serviceData = SaltyUI.Services[i.Type]
					if serviceData then
						local args = {}
						for _, argName in next, serviceData.Args do
							table.insert(args, i[argName])
						end

						local service = serviceData.New(table.unpack(args))
						local success = service.Verify(fileKey)
						if success then
							isSuccess = true
							break
						end
					end
				end

				CanLoadWindow = isSuccess
				if not isSuccess then
					loadKeysystem()
				end
			else
				loadKeysystem()
			end
		end

		repeat
			task.wait()
		until CanLoadWindow
	end

	local Window = CreateWindow(Config)

	SaltyUI.Transparent = Config.Transparent
	SaltyUI.Window = Window

	if Config.Acrylic then
		Acrylic.init()
	end

	-- function Window:ToggleTransparency(Value)
	--     SaltyUI.Transparent = Value
	--     SaltyUI.Window.Transparent = Value

	--     Window.UIElements.Main.Background.BackgroundTransparency = Value and SaltyUI.TransparencyValue or 0
	--     Window.UIElements.Main.Background.ImageLabel.ImageTransparency = Value and SaltyUI.TransparencyValue or 0
	--     Window.UIElements.Main.Gradient.UIGradient.Transparency = NumberSequence.new{
	--         NumberSequenceKeypoint.new(0, 1),
	--         NumberSequenceKeypoint.new(1, Value and 0.85 or 0.7),
	--     }
	-- end

	return Window
end

return SaltyUI
