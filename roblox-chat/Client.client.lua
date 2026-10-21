-- Minimal VantaTest Studio host for the SAME chat.lua module used by example.lua.
-- If your experience already hosts VantaTest, use Chat.Mount(yourChatTab) instead.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")
local Chat = require(ReplicatedStorage:WaitForChild("VantaChatUI"))
local gui = Instance.new("ScreenGui")
gui.Name = "VantaTestChat"
gui.ResetOnSpawn = false
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.ScreenInsets = Enum.ScreenInsets.DeviceSafeInsets
local window = Instance.new("Frame")
window.Name = "VantaTest"
window.AnchorPoint = Vector2.new(0.5, 0.5)
window.Position = UDim2.fromScale(0.5, 0.5)
window.Size = UDim2.new(1, -20, 1, -30)
window.BackgroundColor3 = Color3.fromRGB(12, 10, 10)
window.BorderSizePixel = 0
window.Parent = gui
local constraint = Instance.new("UISizeConstraint")
constraint.MaxSize = Vector2.new(640, 560)
constraint.Parent = window
local rounding = Instance.new("UICorner")
rounding.CornerRadius = UDim.new(0, 16)
rounding.Parent = window
local tabButton = Instance.new("TextButton")
tabButton.Text = "VANTATEST   /   Chat"
tabButton.Font = Enum.Font.GothamBold
tabButton.TextSize = 13
tabButton.TextColor3 = Color3.fromRGB(240, 237, 233)
tabButton.BackgroundTransparency = 1
tabButton.Size = UDim2.new(1, 0, 0, 34)
tabButton.Parent = window
local holder = Instance.new("Frame")
holder.Name = "ChatTab"
holder.BackgroundTransparency = 1
holder.Position = UDim2.fromOffset(4, 34)
holder.Size = UDim2.new(1, -8, 1, -38)
holder.Parent = window
tabButton.Activated:Connect(function() holder.Visible = not holder.Visible end)
gui.Parent = playerGui
Chat.Mount({UIElements = {ContainerFrame = holder}})

