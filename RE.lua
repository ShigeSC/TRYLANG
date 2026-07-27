--// Auto Rejoin GUI with Teleport Execution
--// Standalone - No dependencies needed

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local GuiService = game:GetService("GuiService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer
local PlaceId = game.PlaceId
local JobId = game.JobId

--// Configuration - YOUR GITHUB URL
local SCRIPT_URL = "https://raw.githubusercontent.com/ShigeSC/TRYLANG/refs/heads/main/RE.lua"

--// Executor Compatibility (from Infinite Yield)
local function missing(t, f, fallback)
	if type(f) == t then return f end
	return fallback
end

local queueteleport = missing("function", queue_on_teleport or (syn and syn.queue_on_teleport) or (fluxus and fluxus.queue_on_teleport))

--// Auto Execute on Teleport (Infinite Yield Logic)
local TeleportCheck = false
local KeepScript = true -- Set to false to disable auto-execute

if KeepScript and queueteleport then
	LocalPlayer.OnTeleport:Connect(function(State)
		if not TeleportCheck then
			TeleportCheck = true
			queueteleport("loadstring(game:HttpGet('" .. SCRIPT_URL .. "'))()")
		end
	end)
end

--// GUI Creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "RejoinGUI"
ScreenGui.Parent = CoreGui
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

--// Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(36, 36, 37)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
MainFrame.Size = UDim2.new(0, 300, 0, 200)
MainFrame.ClipsDescendants = true

--// Corner Radius
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = MainFrame

--// Title Bar
local TitleBar = Instance.new("Frame")
TitleBar.Name = "TitleBar"
TitleBar.Parent = MainFrame
TitleBar.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
TitleBar.BorderSizePixel = 0
TitleBar.Size = UDim2.new(1, 0, 0, 35)

local TitleCorner = Instance.new("UICorner")
TitleCorner.CornerRadius = UDim.new(0, 8)
TitleCorner.Parent = TitleBar

local TitleFix = Instance.new("Frame")
TitleFix.Parent = TitleBar
TitleFix.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
TitleFix.BorderSizePixel = 0
TitleFix.Position = UDim2.new(0, 0, 0.5, 0)
TitleFix.Size = UDim2.new(1, 0, 0.5, 0)

local TitleLabel = Instance.new("TextLabel")
TitleLabel.Name = "Title"
TitleLabel.Parent = TitleBar
TitleLabel.BackgroundTransparency = 1
TitleLabel.Size = UDim2.new(1, 0, 1, 0)
TitleLabel.Font = Enum.Font.GothamBold
TitleLabel.Text = "Auto Rejoin"
TitleLabel.TextColor3 = Color3.new(1, 1, 1)
TitleLabel.TextSize = 16

--// Close Button
local CloseButton = Instance.new("TextButton")
CloseButton.Name = "Close"
CloseButton.Parent = TitleBar
CloseButton.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
CloseButton.BorderSizePixel = 0
CloseButton.Position = UDim2.new(1, -30, 0, 5)
CloseButton.Size = UDim2.new(0, 25, 0, 25)
CloseButton.Font = Enum.Font.GothamBold
CloseButton.Text = "X"
CloseButton.TextColor3 = Color3.new(1, 1, 1)
CloseButton.TextSize = 14

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 6)
CloseCorner.Parent = CloseButton

--// Content Frame
local ContentFrame = Instance.new("Frame")
ContentFrame.Name = "Content"
ContentFrame.Parent = MainFrame
ContentFrame.BackgroundTransparency = 1
ContentFrame.Position = UDim2.new(0, 0, 0, 40)
ContentFrame.Size = UDim2.new(1, 0, 1, -40)

--// Rejoin Button
local RejoinButton = Instance.new("TextButton")
RejoinButton.Name = "RejoinButton"
RejoinButton.Parent = ContentFrame
RejoinButton.BackgroundColor3 = Color3.fromRGB(0, 120, 255)
RejoinButton.BorderSizePixel = 0
RejoinButton.Position = UDim2.new(0.5, -125, 0, 20)
RejoinButton.Size = UDim2.new(0, 250, 0, 50)
RejoinButton.Font = Enum.Font.GothamBold
RejoinButton.Text = "🔄 REJOIN SERVER"
RejoinButton.TextColor3 = Color3.new(1, 1, 1)
RejoinButton.TextSize = 18
RejoinButton.AutoButtonColor = true

local RejoinCorner = Instance.new("UICorner")
RejoinCorner.CornerRadius = UDim.new(0, 8)
RejoinCorner.Parent = RejoinButton

--// Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "Status"
StatusLabel.Parent = ContentFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 0, 0, 85)
StatusLabel.Size = UDim2.new(1, 0, 0, 20)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = "Ready - Script will auto-execute after rejoin"
StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
StatusLabel.TextSize = 12

--// Auto Rejoin Toggle
local AutoRejoinButton = Instance.new("TextButton")
AutoRejoinButton.Name = "AutoRejoinButton"
AutoRejoinButton.Parent = ContentFrame
AutoRejoinButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
AutoRejoinButton.BorderSizePixel = 0
AutoRejoinButton.Position = UDim2.new(0.5, -125, 0, 115)
AutoRejoinButton.Size = UDim2.new(0, 250, 0, 40)
AutoRejoinButton.Font = Enum.Font.GothamBold
AutoRejoinButton.Text = "⛔ AUTO REJOIN: OFF"
AutoRejoinButton.TextColor3 = Color3.new(1, 1, 1)
AutoRejoinButton.TextSize = 14

local AutoCorner = Instance.new("UICorner")
AutoCorner.CornerRadius = UDim.new(0, 8)
AutoCorner.Parent = AutoRejoinButton

--// Dragging Functionality
local dragging = false
local dragInput, dragStart, startPos

TitleBar.InputBegan:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = true
		dragStart = input.Position
		startPos = MainFrame.Position
	end
end)

TitleBar.InputChanged:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		dragInput = input
	end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
	if input == dragInput and dragging then
		local delta = input.Position - dragStart
		MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
	end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
	if input.UserInputType == Enum.UserInputType.MouseButton1 then
		dragging = false
	end
end)

--// Button Hover Effects
local function ButtonHover(button, defaultColor, hoverColor)
	button.MouseEnter:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = hoverColor}):Play()
	end)
	button.MouseLeave:Connect(function()
		TweenService:Create(button, TweenInfo.new(0.2), {BackgroundColor3 = defaultColor}):Play()
	end)
end

ButtonHover(RejoinButton, Color3.fromRGB(0, 120, 255), Color3.fromRGB(0, 150, 255))
ButtonHover(CloseButton, Color3.fromRGB(255, 70, 70), Color3.fromRGB(255, 100, 100))

--// Rejoin Function (Infinite Yield Logic)
local function Rejoin()
	StatusLabel.Text = "Rejoining..."
	StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
	
	task.spawn(function()
		-- Queue teleport before rejoining (Infinite Yield method)
		if queueteleport and not TeleportCheck then
			TeleportCheck = true
			queueteleport("loadstring(game:HttpGet('" .. SCRIPT_URL .. "'))()")
		end
		
		-- Small delay to ensure teleport is queued
		task.wait(0.5)
		
		if #Players:GetPlayers() <= 1 then
			LocalPlayer:Kick("\nRejoining...")
			task.wait(0.5)
			TeleportService:Teleport(PlaceId, LocalPlayer)
		else
			TeleportService:TeleportToPlaceInstance(PlaceId, JobId, LocalPlayer)
		end
	end)
end

--// Auto Rejoin Toggle
local AutoRejoinEnabled = false
local AutoRejoinConnection

local function ToggleAutoRejoin()
	AutoRejoinEnabled = not AutoRejoinEnabled
	
	if AutoRejoinEnabled then
		AutoRejoinButton.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
		AutoRejoinButton.Text = "✅ AUTO REJOIN: ON"
		StatusLabel.Text = "Auto rejoin enabled - Will rejoin on kick/error"
		StatusLabel.TextColor3 = Color3.fromRGB(0, 255, 100)
		
		-- Connect to error message changed
		AutoRejoinConnection = GuiService.ErrorMessageChanged:Connect(function()
			task.wait(0.5)
			Rejoin()
		end)
	else
		AutoRejoinButton.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		AutoRejoinButton.Text = "⛔ AUTO REJOIN: OFF"
		StatusLabel.Text = "Ready - Script will auto-execute after rejoin"
		StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
		
		if AutoRejoinConnection then
			AutoRejoinConnection:Disconnect()
			AutoRejoinConnection = nil
		end
	end
end

--// Button Connections
RejoinButton.MouseButton1Click:Connect(function()
	-- Button click animation
	TweenService:Create(RejoinButton, TweenInfo.new(0.1), {Size = UDim2.new(0, 240, 0, 45)}):Play()
	task.wait(0.1)
	TweenService:Create(RejoinButton, TweenInfo.new(0.1), {Size = UDim2.new(0, 250, 0, 50)}):Play()
	
	Rejoin()
end)

AutoRejoinButton.MouseButton1Click:Connect(ToggleAutoRejoin)

CloseButton.MouseButton1Click:Connect(function()
	-- Close animation
	TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 300, 0, 0)}):Play()
	task.wait(0.3)
	ScreenGui:Destroy()
end)

--// Keybind to Toggle GUI (RightShift)
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
	if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
		ScreenGui.Enabled = not ScreenGui.Enabled
	end
end)

--// Intro Animation
MainFrame.Size = UDim2.new(0, 300, 0, 0)
TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Size = UDim2.new(0, 300, 0, 200)}):Play()

--// Notification Function
local function Notify(title, message, duration)
	duration = duration or 3
	
	local NotifGui = Instance.new("ScreenGui")
	NotifGui.Name = "Notification"
	NotifGui.Parent = CoreGui
	
	local NotifFrame = Instance.new("Frame")
	NotifFrame.BackgroundColor3 = Color3.fromRGB(46, 46, 47)
	NotifFrame.BorderSizePixel = 0
	NotifFrame.Position = UDim2.new(1, 20, 0, 20)
	NotifFrame.Size = UDim2.new(0, 250, 0, 60)
	
	local NotifCorner = Instance.new("UICorner")
	NotifCorner.CornerRadius = UDim.new(0, 8)
	NotifCorner.Parent = NotifFrame
	
	local NotifTitle = Instance.new("TextLabel")
	NotifTitle.BackgroundTransparency = 1
	NotifTitle.Position = UDim2.new(0, 10, 0, 5)
	NotifTitle.Size = UDim2.new(1, -20, 0, 20)
	NotifTitle.Font = Enum.Font.GothamBold
	NotifTitle.Text = title
	NotifTitle.TextColor3 = Color3.fromRGB(0, 150, 255)
	NotifTitle.TextSize = 14
	NotifTitle.TextXAlignment = Enum.TextXAlignment.Left
	NotifTitle.Parent = NotifFrame
	
	local NotifText = Instance.new("TextLabel")
	NotifText.BackgroundTransparency = 1
	NotifText.Position = UDim2.new(0, 10, 0, 28)
	NotifText.Size = UDim2.new(1, -20, 0, 25)
	NotifText.Font = Enum.Font.Gotham
	NotifText.Text = message
	NotifText.TextColor3 = Color3.new(1, 1, 1)
	NotifText.TextSize = 12
	NotifText.TextXAlignment = Enum.TextXAlignment.Left
	NotifText.Parent = NotifFrame
	
	NotifFrame.Parent = NotifGui
	
	-- Slide in
	TweenService:Create(NotifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {Position = UDim2.new(1, -270, 0, 20)}):Play()
	
	task.wait(duration)
	
	-- Slide out
	TweenService:Create(NotifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {Position = UDim2.new(1, 20, 0, 20)}):Play()
	task.wait(0.5)
	NotifGui:Destroy()
end

--// Initial Notification
Notify("Auto Rejoin", "Script loaded! Press RightShift to toggle GUI.", 3)

print("[Auto Rejoin] Script loaded successfully!")
print("[Auto Rejoin] Auto-execute on teleport: " .. (KeepScript and "ENABLED" or "DISABLED"))
print("[Auto Rejoin] Press RightShift to toggle GUI")
