-- =====================================================
--  AUTO-REJOIN SCRIPT
--  Re-executes itself automatically after any rejoin/teleport,
--  plus a small GUI with a manual Rejoin button.
-- =====================================================

local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local UserInputService = game:GetService("UserInputService")
local LocalPlayer = Players.LocalPlayer

-- >>> IMPORTANT: put the raw URL to THIS script here (e.g. your GitHub raw
-- link) so it knows what to re-run after teleporting into the next server. <<<
local SCRIPT_URL = "https://raw.githubusercontent.com/ShigeSC/TRYLANG/refs/heads/main/RE.lua"

-- =========================================================
-- Executor-agnostic queue_on_teleport
-- =========================================================
local queueteleport = (queue_on_teleport)
    or (syn and syn.queue_on_teleport)
    or (fluxus and fluxus.queue_on_teleport)

-- =========================================================
-- Auto re-execute after any teleport (rejoin, server hop, etc)
-- =========================================================
local TeleportCheck = false -- one-shot guard so it doesn't queue more than once

LocalPlayer.OnTeleport:Connect(function(_State)
    if (not TeleportCheck) and queueteleport then
        TeleportCheck = true
        queueteleport("loadstring(game:HttpGet('" .. SCRIPT_URL .. "'))()")
    end
end)

-- =========================================================
-- GUI
-- =========================================================
local function GetGuiParent()
    local ok, hui = pcall(function() return gethui and gethui() end)
    if ok and hui then
        return hui
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local GuiParent = GetGuiParent()

local existing = GuiParent:FindFirstChild("AutoRejoinGui")
if existing then existing:Destroy() end

local ScreenGui = Instance.new("ScreenGui")
ScreenGui.Name = "AutoRejoinGui"
ScreenGui.ResetOnSpawn = false
ScreenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
ScreenGui.Parent = GuiParent

local Frame = Instance.new("Frame")
Frame.Name = "MainFrame"
Frame.AnchorPoint = Vector2.new(0.5, 0.5)
Frame.Position = UDim2.new(0.5, 0, 0.5, 0)
Frame.Size = UDim2.new(0, 220, 0, 112)
Frame.BackgroundColor3 = Color3.fromRGB(18, 18, 18)
Frame.BorderSizePixel = 0
Frame.Active = true
Frame.Parent = ScreenGui

local UICorner = Instance.new("UICorner")
UICorner.CornerRadius = UDim.new(0, 8)
UICorner.Parent = Frame

local UIStroke = Instance.new("UIStroke")
UIStroke.Color = Color3.fromRGB(190, 22, 22)
UIStroke.Thickness = 1.5
UIStroke.Parent = Frame

local Title = Instance.new("TextLabel")
Title.Name = "Title"
Title.Text = "AUTO-REJOIN"
Title.Font = Enum.Font.GothamBold
Title.TextSize = 15
Title.TextColor3 = Color3.fromRGB(235, 235, 235)
Title.BackgroundTransparency = 1
Title.Position = UDim2.new(0, 12, 0, 8)
Title.Size = UDim2.new(1, -24, 0, 20)
Title.TextXAlignment = Enum.TextXAlignment.Left
Title.Active = true
Title.Parent = Frame

local StatusLabel = Instance.new("TextLabel")
StatusLabel.Name = "StatusLabel"
StatusLabel.Text = queueteleport
    and "Ready -- will auto-run after rejoin"
    or "Executor doesn't support auto re-run"
StatusLabel.Font = Enum.Font.Gotham
StatusLabel.TextSize = 12
StatusLabel.TextWrapped = true
StatusLabel.TextColor3 = queueteleport and Color3.fromRGB(130, 220, 150) or Color3.fromRGB(215, 60, 60)
StatusLabel.BackgroundTransparency = 1
StatusLabel.Position = UDim2.new(0, 12, 0, 30)
StatusLabel.Size = UDim2.new(1, -24, 0, 36)
StatusLabel.TextXAlignment = Enum.TextXAlignment.Left
StatusLabel.Parent = Frame

local RejoinButton = Instance.new("TextButton")
RejoinButton.Name = "RejoinButton"
RejoinButton.Text = "REJOIN"
RejoinButton.Font = Enum.Font.GothamBold
RejoinButton.TextSize = 14
RejoinButton.TextColor3 = Color3.fromRGB(255, 255, 255)
RejoinButton.BackgroundColor3 = Color3.fromRGB(190, 22, 22)
RejoinButton.BorderSizePixel = 0
RejoinButton.Position = UDim2.new(0, 12, 1, -36)
RejoinButton.Size = UDim2.new(1, -24, 0, 28)
RejoinButton.Parent = Frame

local RejoinCorner = Instance.new("UICorner")
RejoinCorner.CornerRadius = UDim.new(0, 5)
RejoinCorner.Parent = RejoinButton

-- Draggable window (drag by the title bar)
local dragging, dragStart, startPos = false, nil, nil

Title.InputBegan:Connect(function(input)
    if input.UserInputType == Enum.UserInputType.MouseButton1
        or input.UserInputType == Enum.UserInputType.Touch then
        dragging = true
        dragStart = input.Position
        startPos = Frame.Position

        input.Changed:Connect(function()
            if input.UserInputState == Enum.UserInputState.End then
                dragging = false
            end
        end)
    end
end)

UserInputService.InputChanged:Connect(function(input)
    if dragging and (input.UserInputType == Enum.UserInputType.MouseMovement
        or input.UserInputType == Enum.UserInputType.Touch) then
        local delta = input.Position - dragStart
        Frame.Position = UDim2.new(
            startPos.X.Scale, startPos.X.Offset + delta.X,
            startPos.Y.Scale, startPos.Y.Offset + delta.Y
        )
    end
end)

-- Manual rejoin: teleports back into the same place (new server instance)
RejoinButton.Activated:Connect(function()
    StatusLabel.Text = "Rejoining..."
    StatusLabel.TextColor3 = Color3.fromRGB(150, 150, 150)

    task.spawn(function()
        local success, err = pcall(function()
            TeleportService:Teleport(game.PlaceId, LocalPlayer)
        end)
        if not success then
            StatusLabel.Text = "Rejoin failed: " .. tostring(err)
            StatusLabel.TextColor3 = Color3.fromRGB(215, 60, 60)
        end
    end)
end)

print("[AutoRejoin] Loaded. queue_on_teleport support: " .. tostring(queueteleport ~= nil))
