--// KRNL Auto Rejoin GUI
--// Compatible with KRNL, Synapse X, Fluxus, and most executors

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local CoreGui = game:GetService("CoreGui")
local TweenService = game:GetService("TweenService")
local LocalPlayer = Players.LocalPlayer

--// Configuration
local SCRIPT_URL = "https://raw.githubusercontent.com/ShigeSC/TRYLANG/main/RE.lua"

--// Multi-Executor Support (KRNL uses queue_on_teleport)
local queueteleport = queue_on_teleport 
    or (syn and syn.queue_on_teleport) 
    or (fluxus and fluxus.queue_on_teleport)

--// Setup Auto-Execute on Teleport
local TeleportCheck = false

if queueteleport then
    LocalPlayer.OnTeleport:Connect(function(State)
        if not TeleportCheck then
            TeleportCheck = true
            -- KRNL needs the code as a string
            queueteleport([[
                -- Wait for game to load
                if not game:IsLoaded() then game.Loaded:Wait() end
                task.wait(0.3)
                loadstring(game:HttpGet("]] .. SCRIPT_URL .. [["))()
            ]])
        end
    end)
    print("[Auto-Execute] Queue system ready!")
else
    warn("[Auto-Execute] Executor doesn't support queue_on_teleport!")
end

--// GUI Creation
local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "KRNL_RejoinGUI"
ScreenGui.Parent = CoreGui
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling

--// Main Frame
local MainFrame = Instance.new("Frame")
MainFrame.Name = "MainFrame"
MainFrame.Parent = ScreenGui
MainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 30)
MainFrame.BorderSizePixel = 0
MainFrame.Position = UDim2.new(0.5, -150, 0.5, -100)
MainFrame.Size = UDim2.new(0, 300, 0, 200)

--// Corner
local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 10)
UICorner.Parent = MainFrame

--// Shadow
local Shadow = Instance.new("Frame")
Shadow.Name = "Shadow"
Shadow.Parent = MainFrame
Shadow.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
Shadow.BorderSizePixel = 0
Shadow.Position = UDim2.new(0, 0, 0, 0)
Shadow.Size = UDim2.new(1, 0, 0, 40)

local ShadowCorner = Instance.new("UICorner")
ShadowCorner.CornerRadius = UDim.new(0, 10)
ShadowCorner.Parent = Shadow

local ShadowFix = Instance.new("Frame")
ShadowFix.Parent = Shadow
ShadowFix.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
ShadowFix.BorderSizePixel = 0
ShadowFix.Position = UDim2.new(0, 0, 0.5, 0)
ShadowFix.Size = UDim2.new(1, 0, 0.5, 0)

--// Title
local Title = Instance.new("TextLabel")
Title.Parent = MainFrame
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 10, 0, 5)
Title.Size = UDim2.new(1, -20, 0, 30)
Title.Font = Enum.Font.GothamBold
Title.Text = "🍌 KRNL Rejoin"
Title.TextColor3 = Color3.new(1, 1, 1)
Title.TextSize = 18
Title.TextXAlignment = Enum.TextXAlignment.Left

--// Close Button
local CloseBtn = Instance.new("TextButton")
CloseBtn.Parent = MainFrame
CloseBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 70)
CloseBtn.BorderSizePixel = 0
CloseBtn.Position = UDim2.new(1, -35, 0, 5)
CloseBtn.Size = UDim2.new(0, 30, 0, 30)
CloseBtn.Font = Enum.Font.GothamBold
CloseBtn.Text = "X"
CloseBtn.TextColor3 = Color3.new(1, 1, 1)
CloseBtn.TextSize = 16

local CloseCorner = Instance.new("UICorner")
CloseCorner.CornerRadius = UDim.new(0, 8)
CloseCorner.Parent = CloseBtn

--// Status Label
local StatusLabel = Instance.new("TextLabel")
StatusLabel.Parent = MainFrame
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 10, 0, 50)
StatusLabel.Size = UDim2.new(1, -20, 0, 30)
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.Text = queueteleport and "✅ Auto-execute ready" or "❌ Not supported"
StatusLabel.TextColor3 = queueteleport and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(255, 100, 100)
StatusLabel.TextSize = 14

--// Rejoin Button
local RejoinBtn = Instance.new("TextButton")
RejoinBtn.Parent = MainFrame
RejoinBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
RejoinBtn.BorderSizePixel = 0
RejoinBtn.Position = UDim2.new(0.5, -125, 0, 90)
RejoinBtn.Size = UDim2.new(0, 250, 0, 50)
RejoinBtn.Font = Enum.Font.GothamBold
RejoinBtn.Text = "🔄 REJOIN SERVER"
RejoinBtn.TextColor3 = Color3.new(1, 1, 1)
RejoinBtn.TextSize = 18

local RejoinCorner = Instance.new("UICorner")
RejoinCorner.CornerRadius = UDim.new(0, 8)
RejoinCorner.Parent = RejoinBtn

--// Auto Rejoin Toggle
local AutoRejoinBtn = Instance.new("TextButton")
AutoRejoinBtn.Parent = MainFrame
AutoRejoinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
AutoRejoinBtn.BorderSizePixel = 0
AutoRejoinBtn.Position = UDim2.new(0.5, -125, 0, 150)
AutoRejoinBtn.Size = UDim2.new(0, 250, 0, 40)
AutoRejoinBtn.Font = Enum.Font.GothamBold
AutoRejoinBtn.Text = "⛔ Auto Rejoin: OFF"
AutoRejoinBtn.TextColor3 = Color3.new(1, 1, 1)
AutoRejoinBtn.TextSize = 14

local AutoCorner = Instance.new("UICorner")
AutoCorner.CornerRadius = UDim.new(0, 8)
AutoCorner.Parent = AutoRejoinBtn

--// Dragging
local dragging = false
local dragStart, startPos

Shadow.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = true
        dragStart = input.Position
        startPos = MainFrame.Position
    end
end)

game:GetService("UserInputService").InputChanged:Connect(function(input)
    if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
        local delta = input.Position - dragStart
        MainFrame.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
    end
end)

game:GetService("UserInputService").InputEnded:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        dragging = false
    end
end)

--// Hover Effects
local function hoverEffect(btn, color1, color2)
    btn.MouseEnter:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color2}):Play()
    end)
    btn.MouseLeave:Connect(function()
        TweenService:Create(btn, TweenInfo.new(0.2), {BackgroundColor3 = color1}):Play()
    end)
end

hoverEffect(RejoinBtn, Color3.fromRGB(0, 150, 255), Color3.fromRGB(0, 180, 255))
hoverEffect(CloseBtn, Color3.fromRGB(255, 70, 70), Color3.fromRGB(255, 100, 100))

--// Rejoin Function
local function Rejoin()
    if not queueteleport then
        StatusLabel.Text = "❌ Executor not supported!"
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        return
    end
    
    StatusLabel.Text = "🔄 Rejoining..."
    StatusLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
    
    -- CRITICAL: Queue FIRST, then wait, then teleport
    if not TeleportCheck then
        TeleportCheck = true
        queueteleport([[
            if not game:IsLoaded() then game.Loaded:Wait() end
            task.wait(0.3)
            loadstring(game:HttpGet("]] .. SCRIPT_URL .. [["))()
        ]])
    end
    
    task.wait(0.5) -- Let KRNL register the queue
    
    -- Teleport
    local success, err = pcall(function()
        if #Players:GetPlayers() <= 1 then
            LocalPlayer:Kick("\nRejoining...")
            task.wait(0.5)
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        else
            TeleportService:TeleportToPlaceInstance(game.PlaceId, game.JobId, LocalPlayer)
        end
    end)
    
    if not success then
        StatusLabel.Text = "❌ Error: " .. tostring(err)
        StatusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
        TeleportCheck = false -- Reset so they can try again
    end
end

--// Auto Rejoin
local AutoRejoinEnabled = false
local AutoRejoinConnection

local function ToggleAutoRejoin()
    AutoRejoinEnabled = not AutoRejoinEnabled
    
    if AutoRejoinEnabled then
        AutoRejoinBtn.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
        AutoRejoinBtn.Text = "✅ Auto Rejoin: ON"
        StatusLabel.Text = "✅ Will auto-rejoin on kick"
        StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        
        AutoRejoinConnection = game:GetService("GuiService").ErrorMessageChanged:Connect(function()
            task.wait(0.5)
            Rejoin()
        end)
    else
        AutoRejoinBtn.BackgroundColor3 = Color3.fromRGB(60, 60, 60)
        AutoRejoinBtn.Text = "⛔ Auto Rejoin: OFF"
        StatusLabel.Text = "✅ Auto-execute ready"
        StatusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
        
        if AutoRejoinConnection then
            AutoRejoinConnection:Disconnect()
        end
    end
end

--// Button Connections
RejoinBtn.MouseButton1Click:Connect(function()
    -- Animation
    TweenService:Create(RejoinBtn, TweenInfo.new(0.1), {Size = UDim2.new(0, 240, 0, 45)}):Play()
    task.wait(0.1)
    TweenService:Create(RejoinBtn, TweenInfo.new(0.1), {Size = UDim2.new(0, 250, 0, 50)}):Play()
    
    Rejoin()
end)

AutoRejoinBtn.MouseButton1Click:Connect(ToggleAutoRejoin)

CloseBtn.MouseButton1Click:Connect(function()
    TweenService:Create(MainFrame, TweenInfo.new(0.3), {Size = UDim2.new(0, 300, 0, 0)}):Play()
    task.wait(0.3)
    ScreenGui:Destroy()
end)

--// Keybind (RightShift)
game:GetService("UserInputService").InputBegan:Connect(function(input, gameProcessed)
    if not gameProcessed and input.KeyCode == Enum.KeyCode.RightShift then
        ScreenGui.Enabled = not ScreenGui.Enabled
    end
end)

--// Intro Animation
MainFrame.Size = UDim2.new(0, 300, 0, 0)
TweenService:Create(MainFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {Size = UDim2.new(0, 300, 0, 200)}):Play()

print("[KRNL Rejoin] Script loaded!")
print("[KRNL Rejoin] Press RightShift to toggle GUI")
print("[KRNL Rejoin] Executor support: " .. (queueteleport and "YES" or "NO"))
