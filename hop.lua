-- =====================================================
-- AUTO BUY PET — ScoopHub Style (Custom GUI)
-- Searchable dropdown + Pets bought counter + Auto Server Hop + Config Save
-- KRNL Auto-Rejoin with queue_on_teleport support
-- =====================================================

-- =========================================================
-- KRNL AUTO-REJOIN SETUP (Must be at the very top)
-- =========================================================
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")

-- Detect KRNL and set up queue_on_teleport
local isKRNL = typeof(queue_on_teleport) == "function"
local SCRIPT_URL = "https://raw.githubusercontent.com/ShigeSC/TRYLANG/refs/heads/main/hop.lua"

-- Function to queue this script for execution after teleport
local function setupAutoRejoinQueue()
    if isKRNL and queue_on_teleport then
        -- KRNL specific: queue this script to run after teleport
        local success, err = pcall(function()
            queue_on_teleport([[
                -- Auto-resume script for KRNL
                repeat task.wait() until game:IsLoaded()
                task.wait(2)
                
                -- Fetch and execute the main script
                local success, result = pcall(function()
                    local scriptContent = game:HttpGet("]] .. SCRIPT_URL .. [[")
                    return loadstring(scriptContent)
                end)
                
                if success and result then
                    result()
                else
                    warn("[AutoBuyPet] Failed to load script after teleport: " .. tostring(result))
                end
            ]])
        end)
        
        if success then
            print("[AutoBuyPet] KRNL queue_on_teleport registered successfully")
        else
            warn("[AutoBuyPet] Failed to register queue_on_teleport: " .. tostring(err))
        end
    end
end

-- Set up teleport handler for auto-rejoin
local function setupTeleportHandler()
    -- Listen for teleport events
    LocalPlayer.OnTeleport:Connect(function(teleportState)
        if teleportState == Enum.TeleportState.Started then
            print("[AutoBuyPet] Teleport started - saving state...")
            -- Save settings before teleport
            if saveSettings then
                pcall(saveSettings)
            end
        elseif teleportState == Enum.TeleportState.Failed then
            print("[AutoBuyPet] Teleport failed - will retry...")
            task.wait(3)
            pcall(function()
                TeleportService:Teleport(game.PlaceId, LocalPlayer)
            end)
        end
    end)
end

-- Initialize teleport handler
pcall(setupTeleportHandler)

-- KRNL queue setup. This is intentionally called only immediately before
-- the script itself starts an automatic rejoin.
local function enableKRNLQueue()
    if isKRNL then
        setupAutoRejoinQueue()
    end
end

-- =========================================================
-- SERVICES & MODULES
-- =========================================================
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local GuiService = game:GetService("GuiService")

local Networking = require(ReplicatedStorage.SharedModules.Networking)
local ShovelNet = Networking.Shovel

-- =========================================================
-- THEME
-- =========================================================
local Theme = {
    Bg = Color3.fromRGB(9, 5, 8),
    Panel = Color3.fromRGB(22, 10, 14),
    PanelLine = Color3.fromRGB(154, 44, 53),
    Red = Color3.fromRGB(231, 47, 59),
    RedDark = Color3.fromRGB(145, 28, 39),
    Text = Color3.fromRGB(255, 111, 120),
    TextDim = Color3.fromRGB(190, 73, 84),
    Success = Color3.fromRGB(99, 215, 163),
    White = Color3.fromRGB(246, 244, 252),
    TabBg = Color3.fromRGB(35, 16, 22),
    InputBg = Color3.fromRGB(49, 41, 49),
    InputText = Color3.fromRGB(238, 240, 249),
    Avatar = Color3.fromRGB(124, 106, 115),
    ObsidianTop = Color3.fromRGB(39, 11, 17),
    ObsidianMid = Color3.fromRGB(8, 5, 8),
    ObsidianLow = Color3.fromRGB(34, 8, 11),
    Surface = Color3.fromRGB(22, 10, 14),
    Surface2 = Color3.fromRGB(37, 17, 23),
    Surface3 = Color3.fromRGB(52, 31, 37),
    Stroke = Color3.fromRGB(179, 52, 63),
    Muted = Color3.fromRGB(199, 170, 176),
    Glow = Color3.fromRGB(211, 64, 75),
    Font = Enum.Font.GothamBold,
    FontBody = Enum.Font.Gotham,
}

local Config = {
    Discord = "discord.gg/WxgqUa9Qz",
    DiscordIcon = "rbxassetid://94434236999817",
    Logo = "rbxassetid://90541504618217",
    LogoColor = Color3.fromRGB(255, 255, 255),
    Title = "AUTO BUY PET",
    Version = "V1.6",
    SubTitle = "by ScoopHub",
    HubNameColor = Color3.fromRGB(242, 92, 101),
    SubTitleColor = Color3.fromRGB(166, 174, 187),
}

local function New(className, props, parent)
    local inst = Instance.new(className)
    for prop, value in pairs(props) do
        inst[prop] = value
    end
    if parent then
        inst.Parent = parent
    end
    return inst
end

local function GetGuiParent()
    local ok, gethui_ok = pcall(function() return gethui and gethui() end)
    if ok and gethui_ok then
        return gethui_ok
    end
    return LocalPlayer:WaitForChild("PlayerGui")
end

local function MakeDraggable(handle, frame)
    local dragging, dragStart, startPos = false, nil, nil
    handle.InputBegan:Connect(function(input)
        if input.UserInputType == Enum.UserInputType.MouseButton1
            or input.UserInputType == Enum.UserInputType.Touch then
            dragging = true
            dragStart = input.Position
            startPos = frame.Position
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
            frame.Position = UDim2.new(
                startPos.X.Scale, startPos.X.Offset + delta.X,
                startPos.Y.Scale, startPos.Y.Offset + delta.Y
            )
        end
    end)
end

local function SafeTween(Object, Info, Properties)
    if not Object then return nil end
    local Success, Tween = pcall(function()
        return TweenService:Create(Object, Info, Properties)
    end)
    if Success and Tween then
        local Played = pcall(function() Tween:Play() end)
        if Played then return Tween end
    end
    return nil
end

-- =========================================================
-- STATE
-- =========================================================
local petProtectEnabled = false
local targetPetNames = {"Bunny"}
local maxPetPrice = 50000000
local petWalkSpeed = 32
local petPunchRadius = 16
local petProtectThread = nil
local petsBought = 0
local totalPoints = 0
local autoRejoin = false
local customJobIds = {}
local customJobIndex = 1
local petHistory = {}
-- This records the saved toggle state until the worker function exists.
local resumePetProtectOnLoad = false
local playerStats = {}
local currentPlayerKey = tostring(LocalPlayer.UserId)

local RARITY_POINTS = {
    Common = 5,
    Uncommon = 10,
    Rare = 15,
    Legendary = 25,
    Mythic = 40,
    Super = 500,
}

-- Confirmed fallback for games that do not expose a Rarity attribute on the
-- wild-pet model.
local PET_RARITY_OVERRIDES = {
    Frog = "Common",
    Bunny = "Common",
    Owl = "Uncommon",
    Deer = "Rare",
    Turtle = "Rare",
    Robin = "Legendary",
    Bee = "Legendary",
    Butterfly = "Legendary",
    Wolf = "Legendary",
    Monkey = "Mythic",
    GoldenDragonfly = "Mythic",
    Unicorn = "Mythic",
    Bear = "Mythic",
    BaldEagle = "Mythic",
    Firefly = "Mythic",
    Dog = "Mythic",
    Hedgehog = "Mythic",
    Squirrel = "Mythic",
    Turkey = "Mythic",
    Raccoon = "Super",
    BlackDragon = "Super",
    IceSerpent = "Super",
    Swan = "Super",
    Fox = "Super",
    ShadowDragon = "Super",
}

local function storeCurrentPlayerStats()
    playerStats[currentPlayerKey] = {
        username = LocalPlayer.Name,
        petsBought = petsBought,
        points = totalPoints,
        history = petHistory,
    }
end

local AllPets = {
    "Bunny", "Frog",
    "Owl",
    "Deer", "Turtle",
    "Bee", "Butterfly", "Robin",
    "BaldEagle", "Bear", "Firefly", "GoldenDragonfly", "Monkey", "Unicorn",
    "BlackDragon", "IceSerpent", "Raccoon",
    "Dog", "Dragonfly", "Fox", "Hedgehog", "ShadowDragon", "Squirrel", "Swan", "Turkey", "Wolf"
}

local selectedPets = {}
for _, name in ipairs(targetPetNames) do
    selectedPets[name] = true
end

local function formatList(items)
    if type(items) ~= "table" or #items == 0 then return "None" end
    if #items <= 2 then return table.concat(items, ", ") end
    return items[1] .. ", " .. items[2] .. " +" .. (#items - 2) .. " more"
end

local function Notify(title, content, duration)
    duration = duration or 3
    local notifGui = New("ScreenGui", { Name = "PetNotif", ZIndexBehavior = Enum.ZIndexBehavior.Sibling }, GetGuiParent())
    local frame = New("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = Theme.Surface,
        BorderSizePixel = 0,
        Position = UDim2.new(1, 350, 1, -30),
        Size = UDim2.new(0, 280, 0, 60),
    }, notifGui)
    New("UICorner", { CornerRadius = UDim.new(0, 8) }, frame)
    New("UIStroke", { Color = Theme.Red, Thickness = 1, Transparency = 0.5 }, frame)
    New("TextLabel", {
        Text = title,
        Font = Theme.Font,
        TextSize = 14,
        TextColor3 = Theme.White,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(1, -24, 0, 18),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, frame)
    New("TextLabel", {
        Text = content,
        Font = Theme.FontBody,
        TextSize = 12,
        TextColor3 = Theme.Muted,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 28),
        Size = UDim2.new(1, -24, 0, 24),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    }, frame)

    SafeTween(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Position = UDim2.new(1, -30, 1, -30)
    })
    task.delay(duration, function()
        if notifGui.Parent then
            SafeTween(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
                Position = UDim2.new(1, 350, 1, -30)
            })
            task.delay(0.5, function()
                if notifGui.Parent then notifGui:Destroy() end
            end)
        end
    end)
end

-- =========================================================
-- CONFIG SAVE / LOAD
-- =========================================================
local CONFIG_FOLDER = "AutoBuyPet"
local CONFIG_FILE = CONFIG_FOLDER .. "/settings.json"

-- Make saveSettings global so teleport handler can access it
function saveSettings()
    if not (writefile and isfolder and makefolder) then return end

    storeCurrentPlayerStats()

    pcall(function()
        if not isfolder(CONFIG_FOLDER) then
            makefolder(CONFIG_FOLDER)
        end
    end)

    local data = {
        selectedPets = {},
        maxPetPrice = maxPetPrice,
        petWalkSpeed = petWalkSpeed,
        petPunchRadius = petPunchRadius,
        autoRejoin = autoRejoin,
        customJobIds = customJobIds,
        customJobIndex = customJobIndex,
        petProtectEnabled = petProtectEnabled,
        playerStats = playerStats,
    }

    for name, isOn in pairs(selectedPets) do
        if isOn then
            table.insert(data.selectedPets, name)
        end
    end

    local ok, encoded = pcall(function()
        return HttpService:JSONEncode(data)
    end)
    if ok then
        pcall(writefile, CONFIG_FILE, encoded)
    end
end

local function loadSettings()
    if not (readfile and isfile) then return end

    local exists = false
    pcall(function()
        exists = isfile(CONFIG_FILE)
    end)
    if not exists then return end

    local success, data = pcall(function()
        return HttpService:JSONDecode(readfile(CONFIG_FILE))
    end)
    if not success or type(data) ~= "table" then return end

    -- Restore selected pets
    table.clear(selectedPets)
    if type(data.selectedPets) == "table" then
        for _, name in ipairs(data.selectedPets) do
            selectedPets[name] = true
        end
    end
    if next(selectedPets) == nil then
        selectedPets["Bunny"] = true
    end

    maxPetPrice = tonumber(data.maxPetPrice) or 50000000
    petWalkSpeed = tonumber(data.petWalkSpeed) or 32
    petPunchRadius = tonumber(data.petPunchRadius) or 16
    autoRejoin = data.autoRejoin == true
    if type(data.customJobIds) == "table" then
        customJobIds = data.customJobIds
    end
    customJobIndex = math.max(1, tonumber(data.customJobIndex) or 1)
    resumePetProtectOnLoad = data.petProtectEnabled == true
    if type(data.playerStats) == "table" then
        playerStats = data.playerStats
    end
    local savedStats = playerStats[currentPlayerKey]
    if type(savedStats) == "table" then
        petsBought = tonumber(savedStats.petsBought) or 0
        totalPoints = tonumber(savedStats.points) or 0
        if type(savedStats.history) == "table" then
            petHistory = savedStats.history
        end
    end
    -- Keep the in-memory setting identical to the JSON value. The worker is
    -- still started later through setPetProtectEnabled after setup is ready.
    petProtectEnabled = resumePetProtectOnLoad
end

-- =========================================================
-- ROOT GUI
-- =========================================================
local GuiParent = GetGuiParent()
local ExistingGui = GuiParent:FindFirstChild("AutoBuyPetGui")
if ExistingGui then
    ExistingGui:Destroy()
end

local ScreenGui = New("ScreenGui", {
    Name = "AutoBuyPetGui",
    ResetOnSpawn = false,
    ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
}, GuiParent)

local DropShadowHolder = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Size = UDim2.new(0, 520, 0, 500),
    ZIndex = 0,
    Name = "DropShadowHolder",
    Position = UDim2.new(0.5, 0, 0.5, 0),
}, ScreenGui)

local DropShadow = New("ImageLabel", {
    Image = "rbxassetid://6015897843",
    ImageColor3 = Color3.fromRGB(4, 5, 8),
    ImageTransparency = 0.38,
    ScaleType = Enum.ScaleType.Slice,
    SliceCenter = Rect.new(49, 49, 450, 450),
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 520, 0, 500),
    ZIndex = 0,
    Name = "DropShadow",
}, DropShadowHolder)

local Main = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Theme.Bg,
    BackgroundTransparency = 0.04,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 520, 0, 500),
    Name = "Main",
}, DropShadow)

New("UICorner", { CornerRadius = UDim.new(0, 8) }, Main)
New("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.ObsidianTop),
        ColorSequenceKeypoint.new(0.52, Theme.ObsidianMid),
        ColorSequenceKeypoint.new(1, Theme.ObsidianLow),
    }),
    Rotation = 16,
}, Main)

local StarField = New("Frame", {
    Name = "StarField",
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Active = false,
    Size = UDim2.new(1, 0, 1, 0),
    ZIndex = 1,
}, Main)

local starRandom = Random.new(LocalPlayer.UserId)
local starColors = {
    Color3.fromRGB(255, 218, 218),
    Color3.fromRGB(246, 141, 151),
    Color3.fromRGB(255, 205, 156),
}
for i = 1, 80 do
    local bright = starRandom:NextNumber() > 0.76
    local diameter = bright and starRandom:NextInteger(2, 3) or 1
    local star = New("Frame", {
        Name = "Star",
        BackgroundColor3 = starColors[starRandom:NextInteger(1, #starColors)],
        BackgroundTransparency = bright and starRandom:NextNumber(0.18, 0.36) or starRandom:NextNumber(0.48, 0.72),
        BorderSizePixel = 0,
        AnchorPoint = Vector2.new(0.5, 0.5),
        Position = UDim2.new(starRandom:NextNumber(0.01, 0.99), 0, starRandom:NextNumber(0.02, 0.98), 0),
        Size = UDim2.new(0, diameter, 0, diameter),
        ZIndex = 1,
    }, StarField)
    New("UICorner", { CornerRadius = UDim.new(1, 0) }, star)
end

New("UIStroke", {
    Color = Theme.Stroke,
    Thickness = 1,
    Transparency = 0.86,
}, Main)

-- =========================================================
-- TITLE BAR
-- =========================================================
local TitleBar = New("Frame", {
    Name = "TitleBar",
    BackgroundColor3 = Theme.Surface,
    BackgroundTransparency = 0.999,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 0, 38),
}, Main)

local LogoImage = New("ImageLabel", {
    Image = Config.Logo,
    ImageColor3 = Config.LogoColor,
    ImageTransparency = 0,
    ScaleType = Enum.ScaleType.Fit,
    ClipsDescendants = true,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 11, 0.5, 0),
    Size = UDim2.new(0, 26, 0, 26),
    Name = "LogoImage",
}, TitleBar)
New("UICorner", { CornerRadius = UDim.new(0, 6) }, LogoImage)

local HubTitle = New("TextLabel", {
    Font = Theme.Font,
    Text = Config.Title,
    TextColor3 = Config.HubNameColor,
    TextSize = 13,
    TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 40, 0.5, -7),
    Size = UDim2.new(0, 0, 0, 16),
    AutomaticSize = Enum.AutomaticSize.X,
    Name = "HubTitle",
}, TitleBar)
New("UIStroke", { Color = Theme.Red, Thickness = 0.4 }, HubTitle)

-- Keep the release number visually lighter than the main product name.
local TitleVersion = New("TextLabel", {
    Font = Theme.FontBody,
    Text = Config.Version,
    TextColor3 = Color3.fromRGB(241, 153, 160),
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 40, 0.5, -7),
    Size = UDim2.new(0, 0, 0, 16),
    AutomaticSize = Enum.AutomaticSize.X,
    Name = "TitleVersion",
}, TitleBar)

task.defer(function()
    TitleVersion.Position = UDim2.new(0, 44 + HubTitle.TextBounds.X, 0.5, -7)
end)

local HubSubTitle = New("TextLabel", {
    Font = Theme.FontBody,
    Text = Config.SubTitle,
    TextColor3 = Config.SubTitleColor,
    TextSize = 10,
    TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 40, 0.5, 7),
    Size = UDim2.new(0, 0, 0, 12),
    AutomaticSize = Enum.AutomaticSize.X,
    Name = "HubSubTitle",
}, TitleBar)

local DiscordPill = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0.5),
    BackgroundColor3 = Theme.Surface3,
    BackgroundTransparency = 0.08,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 150, 0, 22),
    Name = "DiscordPill",
}, TitleBar)
New("UICorner", { CornerRadius = UDim.new(1, 0) }, DiscordPill)
New("UIStroke", { Color = Theme.Red, Thickness = 1, Transparency = 0.62 }, DiscordPill)

local DiscordIcon = New("ImageLabel", {
    Image = Config.DiscordIcon,
    ImageColor3 = Color3.fromRGB(255, 255, 255),
    ScaleType = Enum.ScaleType.Fit,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0, 0.5),
    Position = UDim2.new(0, 8, 0.5, 0),
    Size = UDim2.new(0, 14, 0, 14),
    Name = "DiscordIcon",
}, DiscordPill)

local DiscordText = New("TextLabel", {
    Font = Theme.Font,
    Text = Config.Discord,
    TextColor3 = Color3.fromRGB(235, 235, 240),
    TextSize = 12,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 27, 0, 0),
    Size = UDim2.new(1, -32, 1, 0),
    Name = "DiscordText",
}, DiscordPill)

local DiscordTextWidth = math.clamp(#tostring(Config.Discord) * 7, 40, 170)
DiscordPill.Size = UDim2.new(0, math.clamp(DiscordTextWidth + 38, 72, 190), 0, 22)

local DiscordButton = New("TextButton", {
    Font = Theme.Font,
    Text = "",
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Size = UDim2.new(1, 0, 1, 0),
    Name = "DiscordButton",
}, DiscordPill)
DiscordButton.Activated:Connect(function()
    local copyToClipboard = setclipboard or toclipboard or set_clipboard
    local copied = false

    if type(copyToClipboard) == "function" then
        copied = pcall(copyToClipboard, Config.Discord)
    end

    local existingNotification = GuiParent:FindFirstChild("ScoopHubDiscordNotification")
    if existingNotification then
        existingNotification:Destroy()
    end

    local notifGui = New("ScreenGui", {
        Name = "ScoopHubDiscordNotification",
        ZIndexBehavior = Enum.ZIndexBehavior.Sibling,
        ResetOnSpawn = false,
    }, GuiParent)

    local notifFrame = New("Frame", {
        AnchorPoint = Vector2.new(1, 1),
        BackgroundColor3 = Color3.fromRGB(0, 0, 0),
        BorderSizePixel = 0,
        Position = UDim2.new(1, 400, 1, -30),
        Size = UDim2.new(0, 320, 0, 70),
    }, notifGui)
    New("UICorner", { CornerRadius = UDim.new(0, 8) }, notifFrame)

    local titleScoop = New("TextLabel", {
        Font = Theme.Font,
        Text = "ScoopHub",
        TextColor3 = Color3.fromRGB(235, 235, 240),
        TextSize = 14,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(0, 0, 0, 20),
        AutomaticSize = Enum.AutomaticSize.X,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, notifFrame)

    local titleDiscord = New("TextLabel", {
        Font = Theme.Font,
        Text = " Discord",
        TextColor3 = Theme.Red,
        TextSize = 14,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 8),
        Size = UDim2.new(0, 0, 0, 20),
        AutomaticSize = Enum.AutomaticSize.X,
        TextXAlignment = Enum.TextXAlignment.Left,
    }, notifFrame)
    task.defer(function()
        if titleDiscord.Parent then
            titleDiscord.Position = UDim2.new(0, 12 + titleScoop.TextBounds.X, 0, 8)
        end
    end)

    local closeNotif = New("TextButton", {
        Text = "X",
        Font = Theme.Font,
        TextSize = 14,
        TextColor3 = Color3.fromRGB(200, 200, 200),
        BackgroundTransparency = 1,
        AnchorPoint = Vector2.new(1, 0),
        Position = UDim2.new(1, -8, 0, 6),
        Size = UDim2.new(0, 22, 0, 22),
    }, notifFrame)
    closeNotif.Activated:Connect(function()
        notifGui:Destroy()
    end)

    New("TextLabel", {
        Font = Theme.FontBody,
        Text = copied and ("Copied to clipboard: " .. Config.Discord)
            or "Your executor could not copy the Discord invite.",
        TextColor3 = Color3.fromRGB(150, 150, 150),
        TextSize = 13,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 12, 0, 34),
        Size = UDim2.new(1, -24, 0, 28),
        TextXAlignment = Enum.TextXAlignment.Left,
        TextWrapped = true,
    }, notifFrame)

    SafeTween(notifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
        Position = UDim2.new(1, -30, 1, -30),
    })

    task.delay(5, function()
        if notifGui.Parent then
            SafeTween(notifFrame, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
                Position = UDim2.new(1, 400, 1, -30),
            })
            task.delay(0.5, function()
                if notifGui.Parent then notifGui:Destroy() end
            end)
        end
    end)
end)

local MinButton = New("TextButton", {
    Name = "MinimizeButton",
    Text = "-",
    Font = Theme.Font,
    TextSize = 20,
    TextColor3 = Theme.White,
    BackgroundColor3 = Theme.Surface2,
    BackgroundTransparency = 0.25,
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -42, 0.5, 0),
    Size = UDim2.new(0, 25, 0, 25),
    BorderSizePixel = 0,
}, TitleBar)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, MinButton)

local CloseButton = New("TextButton", {
    Name = "CloseButton",
    Text = "X",
    Font = Theme.Font,
    TextSize = 18,
    TextColor3 = Theme.White,
    BackgroundColor3 = Theme.Surface2,
    BackgroundTransparency = 0.25,
    AnchorPoint = Vector2.new(1, 0.5),
    Position = UDim2.new(1, -8, 0.5, 0),
    Size = UDim2.new(0, 25, 0, 25),
    BorderSizePixel = 0,
}, TitleBar)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, CloseButton)

local DecideFrame = New("Frame", {
    AnchorPoint = Vector2.new(0.5, 0),
    BackgroundColor3 = Theme.Red,
    BackgroundTransparency = 0.4,
    BorderSizePixel = 0,
    Position = UDim2.new(0.5, 0, 0, 38),
    Size = UDim2.new(1, 0, 0, 1),
    Name = "DecideFrame",
}, Main)
New("UIGradient", {
    Color = ColorSequence.new({
        ColorSequenceKeypoint.new(0, Theme.ObsidianMid),
        ColorSequenceKeypoint.new(0.5, Theme.Red),
        ColorSequenceKeypoint.new(1, Theme.ObsidianMid),
    }),
}, DecideFrame)

MakeDraggable(TitleBar, DropShadowHolder)

local Body = New("Frame", {
    Name = "Body",
    Position = UDim2.new(0, 0, 0, 39),
    Size = UDim2.new(1, 0, 1, -39),
    BackgroundTransparency = 1,
}, Main)

-- =========================================================
-- HELPERS
-- =========================================================
local function CreatePanel(parent, name, position, size, titleText)
    local Panel = New("Frame", {
        Name = name,
        Position = position,
        Size = size,
        BackgroundColor3 = Theme.Surface,
        BackgroundTransparency = 0.12,
        BorderSizePixel = 0,
        ClipsDescendants = true,
    }, parent)
    New("UICorner", { CornerRadius = UDim.new(0, 8) }, Panel)
    New("UIGradient", {
        Color = ColorSequence.new({
            ColorSequenceKeypoint.new(0, Color3.fromRGB(43, 17, 24)),
            ColorSequenceKeypoint.new(1, Color3.fromRGB(18, 8, 12)),
        }),
        Rotation = 20,
    }, Panel)
    New("UIStroke", { Color = Theme.PanelLine, Thickness = 1.25, Transparency = 0.22 }, Panel)
    New("TextLabel", {
        Text = titleText,
        Font = Theme.Font,
        TextSize = 11,
        TextColor3 = Theme.Text,
        BackgroundTransparency = 1,
        Position = UDim2.new(0, 10, 0, 6),
        Size = UDim2.new(1, -20, 0, 14),
        TextXAlignment = Enum.TextXAlignment.Left,
    }, Panel)
    return Panel
end

-- =========================================================
-- NAVIGATION
-- =========================================================
local TabBar = New("Frame", {
    Name = "TabBar",
    BackgroundColor3 = Theme.Surface2,
    BackgroundTransparency = 0.12,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 12, 0, 8),
    Size = UDim2.new(1, -24, 0, 28),
}, Body)
New("UICorner", { CornerRadius = UDim.new(0, 6) }, TabBar)
New("UIStroke", { Color = Theme.PanelLine, Thickness = 1, Transparency = 0.45 }, TabBar)

local AutoBuyPage = New("Frame", {
    Name = "AutoBuyPage",
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 0, 0, 42),
    Size = UDim2.new(1, 0, 1, -48),
}, Body)

local SettingsPage = New("Frame", {
    Name = "SettingsPage",
    BackgroundTransparency = 1,
    Visible = false,
    Position = UDim2.new(0, 0, 0, 42),
    Size = UDim2.new(1, 0, 1, -48),
}, Body)

local HistoryPage = New("Frame", {
    Name = "HistoryPage",
    BackgroundTransparency = 1,
    Visible = false,
    Position = UDim2.new(0, 0, 0, 42),
    Size = UDim2.new(1, 0, 1, -48),
}, Body)

local updateHistoryUI
local TabButtons = {}
local function CreateTabButton(name, order)
    local button = New("TextButton", {
        Name = name .. "Tab",
        Text = name,
        Font = Theme.Font,
        TextSize = 11,
        TextColor3 = Theme.TextDim,
        BackgroundTransparency = 1,
        BorderSizePixel = 0,
        Position = UDim2.new((order - 1) / 3, 0, 0, 0),
        Size = UDim2.new(1 / 3, 0, 1, 0),
    }, TabBar)
    TabButtons[name] = button
    return button
end

local AutoBuyTab = CreateTabButton("AUTO BUY PET", 1)
local SettingsTab = CreateTabButton("SETTINGS", 2)
local HistoryTab = CreateTabButton("HISTORY", 3)

local function setActiveTab(tabName)
    AutoBuyPage.Visible = tabName == "AUTO BUY PET"
    SettingsPage.Visible = tabName == "SETTINGS"
    HistoryPage.Visible = tabName == "HISTORY"
    for name, button in pairs(TabButtons) do
        local active = name == tabName
        button.TextColor3 = active and Theme.Red or Theme.TextDim
        button.Font = active and Theme.Font or Theme.FontBody
        button.BackgroundColor3 = active and Color3.fromRGB(61, 20, 29) or Theme.Surface2
        button.BackgroundTransparency = active and 0.15 or 1
    end
    if tabName ~= "AUTO BUY PET" then
        local dropdown = Body:FindFirstChild("PetDropdown")
        if dropdown then dropdown.Visible = false end
    end
    if tabName == "HISTORY" and updateHistoryUI then
        updateHistoryUI()
    end
end

AutoBuyTab.Activated:Connect(function() setActiveTab("AUTO BUY PET") end)
SettingsTab.Activated:Connect(function() setActiveTab("SETTINGS") end)
HistoryTab.Activated:Connect(function() setActiveTab("HISTORY") end)
setActiveTab("AUTO BUY PET")

-- =========================================================
-- LEFT PANEL — SELECT PETS
-- =========================================================
local PetsPanel = CreatePanel(AutoBuyPage, "PetsPanel", UDim2.new(0, 12, 0, 12), UDim2.new(0, 240, 0, 126), "SELECT PETS")

local SelectPetsButton = New("TextButton", {
    Name = "SelectPetsButton",
    Text = "Bunny",
    Font = Theme.Font,
    TextSize = 14,
    TextColor3 = Theme.InputText,
    TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundColor3 = Theme.InputBg,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Position = UDim2.new(0, 10, 0, 30),
    Size = UDim2.new(1, -52, 0, 28),
}, PetsPanel)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, SelectPetsButton)
New("UIPadding", { PaddingLeft = UDim.new(0, 10) }, SelectPetsButton)

local RefreshPetsButton = New("TextButton", {
    Name = "RefreshPetsButton",
    Text = "",
    Font = Theme.Font,
    TextSize = 16,
    TextColor3 = Theme.White,
    BackgroundColor3 = Theme.RedDark,
    BorderSizePixel = 0,
    Position = UDim2.new(1, -34, 0, 30),
    Size = UDim2.new(0, 24, 0, 28),
}, PetsPanel)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, RefreshPetsButton)
New("UIStroke", { Color = Theme.Red, Thickness = 1 }, RefreshPetsButton)

New("ImageLabel", {
    Name = "RefreshIcon",
    Image = "rbxassetid://122032243989747",
    ImageColor3 = Theme.White,
    ScaleType = Enum.ScaleType.Fit,
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    AnchorPoint = Vector2.new(0.5, 0.5),
    Position = UDim2.new(0.5, 0, 0.5, 0),
    Size = UDim2.new(0, 14, 0, 14),
}, RefreshPetsButton)

local SelectedCountLabel = New("TextLabel", {
    Name = "SelectedCountLabel",
    Text = "1 pet selected",
    Font = Theme.FontBody,
    TextSize = 12,
    TextColor3 = Theme.Muted,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 10, 0, 66),
    Size = UDim2.new(1, -20, 0, 18),
    TextXAlignment = Enum.TextXAlignment.Left,
}, PetsPanel)

local SelectAllPetsButton = New("TextButton", {
    Name = "SelectAllPetsButton",
    Text = "SELECT ALL",
    Font = Theme.Font,
    TextSize = 11,
    TextColor3 = Theme.White,
    BackgroundColor3 = Theme.RedDark,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 10, 0, 92),
    Size = UDim2.new(0.5, -14, 0, 24),
}, PetsPanel)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, SelectAllPetsButton)

local RemoveAllPetsButton = New("TextButton", {
    Name = "RemoveAllPetsButton",
    Text = "REMOVE ALL",
    Font = Theme.Font,
    TextSize = 11,
    TextColor3 = Theme.White,
    BackgroundColor3 = Theme.Surface3,
    BorderSizePixel = 0,
    Position = UDim2.new(0.5, 4, 0, 92),
    Size = UDim2.new(0.5, -14, 0, 24),
}, PetsPanel)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, RemoveAllPetsButton)

-- =========================================================
-- REJOIN PANEL (now single toggle)
-- =========================================================
local RejoinPanel = CreatePanel(
    AutoBuyPage,
    "RejoinPanel",
    UDim2.new(0, 12, 0, 148),
    UDim2.new(0, 240, 0, 64),
    "SERVER HOP"
)

local RejoinToggle = New("TextButton", {
    Name = "RejoinToggle",
    Text = "SERVER HOP: OFF",
    Font = Theme.Font,
    TextSize = 12,
    TextColor3 = Theme.White,
    BackgroundColor3 = Theme.RedDark,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 10, 0, 28),
    Size = UDim2.new(1, -20, 0, 28),
}, RejoinPanel)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, RejoinToggle)

local function updateRejoinUI()
    if autoRejoin then
        RejoinToggle.Text = "AUTO HOP: ON"
        RejoinToggle.BackgroundColor3 = Theme.Success
    else
        RejoinToggle.Text = "AUTO HOP: OFF"
        RejoinToggle.BackgroundColor3 = Theme.RedDark
    end
end

RejoinToggle.Activated:Connect(function()
    autoRejoin = not autoRejoin
    updateRejoinUI()
    saveSettings()
    
    if autoRejoin then
        Notify("Auto Server Hop", "Will hop when no pets left: " .. tostring(isKRNL) .. "", 2)
    else
        Notify("Auto Server Hop", "Disabled", 2)
    end
end)

local QuickGuidePanel = CreatePanel(AutoBuyPage, "QuickGuidePanel", UDim2.new(0, 264, 0, 12), UDim2.new(1, -276, 0, 200), "QUICK GUIDE")
New("TextLabel", {
    Text = "1. Select the wild pets you want to secure.\n\n2. Enable Auto Buy Pet when you are ready.\n\n3. Use Settings for price, movement, and saved server Job IDs.",
    Font = Theme.FontBody,
    TextSize = 12,
    TextColor3 = Theme.Muted,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 32),
    Size = UDim2.new(1, -24, 0, 118),
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
}, QuickGuidePanel)
New("TextLabel", {
    Text = "HISTORY SAVES PER PLAYER",
    Font = Theme.Font,
    TextSize = 10,
    TextColor3 = Theme.Success,
    BackgroundColor3 = Color3.fromRGB(22, 58, 43),
    BackgroundTransparency = 0.1,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 12, 1, -34),
    Size = UDim2.new(1, -24, 0, 22),
    TextXAlignment = Enum.TextXAlignment.Center,
}, QuickGuidePanel)

-- Dropdown
local PetDropdown = New("Frame", {
    Name = "PetDropdown",
    BackgroundColor3 = Theme.Surface2,
    BorderSizePixel = 0,
    ClipsDescendants = true,
    Visible = false,
    ZIndex = 50,
    Position = UDim2.new(0, 0, 0, 0),
    Size = UDim2.new(0, 220, 0, 240),
}, Body)
New("UICorner", { CornerRadius = UDim.new(0, 6) }, PetDropdown)
New("UIStroke", { Color = Theme.Red, Thickness = 1.5 }, PetDropdown)

local PetSearchBox = New("TextBox", {
    Name = "PetSearchBox",
    PlaceholderText = "Search pets...",
    Text = "",
    Font = Theme.FontBody,
    TextSize = 13,
    TextColor3 = Theme.White,
    PlaceholderColor3 = Color3.fromRGB(160, 160, 165),
    TextXAlignment = Enum.TextXAlignment.Left,
    BackgroundColor3 = Theme.Surface3,
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    Position = UDim2.new(0, 4, 0, 4),
    Size = UDim2.new(1, -8, 0, 26),
    ZIndex = 51,
}, PetDropdown)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, PetSearchBox)
New("UIPadding", { PaddingLeft = UDim.new(0, 8) }, PetSearchBox)

local PetDropdownScroll = New("ScrollingFrame", {
    Name = "PetDropdownScroll",
    BackgroundTransparency = 1,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 4, 0, 34),
    Size = UDim2.new(1, -8, 1, -38),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 3,
    ScrollBarImageColor3 = Theme.Red,
    ZIndex = 51,
}, PetDropdown)
New("UIListLayout", { Padding = UDim.new(0, 2), SortOrder = Enum.SortOrder.LayoutOrder }, PetDropdownScroll)

local function rebuildTargetList()
    targetPetNames = {}
    for name, isOn in pairs(selectedPets) do
        if isOn then
            table.insert(targetPetNames, name)
        end
    end
    table.sort(targetPetNames)

    local count = #targetPetNames
    if count == 0 then
        SelectPetsButton.Text = "Select pets..."
        SelectedCountLabel.Text = "0 pets selected"
    elseif count == 1 then
        SelectPetsButton.Text = targetPetNames[1]
        SelectedCountLabel.Text = "1 pet selected"
    else
        SelectPetsButton.Text = formatList(targetPetNames)
        SelectedCountLabel.Text = count .. " pets selected"
    end
    saveSettings()
end

SelectAllPetsButton.Activated:Connect(function()
    for _, petName in ipairs(AllPets) do
        selectedPets[petName] = true
    end
    rebuildTargetList()
    PetDropdown.Visible = false
end)

RemoveAllPetsButton.Activated:Connect(function()
    table.clear(selectedPets)
    rebuildTargetList()
    PetDropdown.Visible = false
end)

local function UpdatePetDropdownPosition()
    local success = pcall(function()
        local basePos = Body.AbsolutePosition
        local btnPos = SelectPetsButton.AbsolutePosition
        local btnSize = SelectPetsButton.AbsoluteSize
        local x = btnPos.X - basePos.X
        local y = btnPos.Y - basePos.Y + btnSize.Y + 4
        PetDropdown.Position = UDim2.new(0, x, 0, y)
        PetDropdown.Size = UDim2.new(0, btnSize.X + 34, 0, PetDropdown.Size.Y.Offset)
    end)
    if not success then
        PetDropdown.Position = UDim2.new(0, 22, 0, 78)
    end
end

local function BuildPetDropdown(filterText)
    for _, child in ipairs(PetDropdownScroll:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("TextLabel") then
            child:Destroy()
        end
    end

    local query = string.lower(tostring(filterText or ""))
    local filtered = {}
    for _, name in ipairs(AllPets) do
        if query == "" or string.find(string.lower(name), query, 1, true) then
            table.insert(filtered, name)
        end
    end

    if #filtered == 0 then
        New("TextLabel", {
            Text = "No matches",
            Font = Theme.FontBody,
            TextSize = 14,
            TextColor3 = Theme.TextDim,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 30),
        }, PetDropdownScroll)
        PetDropdownScroll.CanvasSize = UDim2.new(0, 0, 0, 30)
        return
    end

    for i, petName in ipairs(filtered) do
        local isSelected = selectedPets[petName] == true
        local row = New("TextButton", {
            Name = "PetOption",
            Text = "",
            Font = Theme.Font,
            TextSize = 14,
            BackgroundColor3 = isSelected and Color3.fromRGB(55, 22, 30) or Theme.Surface2,
            BackgroundTransparency = 0,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 30),
            LayoutOrder = i,
            ZIndex = 52,
            AutoButtonColor = false,
        }, PetDropdownScroll)
        New("UICorner", { CornerRadius = UDim.new(0, 4) }, row)

        local check = New("TextLabel", {
            Text = isSelected and "✓" or "",
            Font = Theme.Font,
            TextSize = 14,
            TextColor3 = Theme.Success,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 8, 0, 0),
            Size = UDim2.new(0, 18, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 53,
        }, row)

        New("TextLabel", {
            Text = petName,
            Font = Theme.Font,
            TextSize = 14,
            TextColor3 = Theme.White,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 28, 0, 0),
            Size = UDim2.new(1, -36, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
            ZIndex = 53,
        }, row)

        row.MouseEnter:Connect(function()
            if not selectedPets[petName] then
                row.BackgroundColor3 = Theme.RedDark
            end
        end)
        row.MouseLeave:Connect(function()
            row.BackgroundColor3 = selectedPets[petName] and Color3.fromRGB(55, 22, 30) or Theme.Surface2
        end)

        row.Activated:Connect(function()
            selectedPets[petName] = not selectedPets[petName]
            check.Text = selectedPets[petName] and "✓" or ""
            row.BackgroundColor3 = selectedPets[petName] and Color3.fromRGB(55, 22, 30) or Theme.Surface2
            rebuildTargetList()
        end)
    end

    PetDropdownScroll.CanvasSize = UDim2.new(0, 0, 0, #filtered * 32)
end

local function ClosePetDropdown()
    PetDropdown.Visible = false
end

SelectPetsButton.Activated:Connect(function()
    PetDropdown.Visible = not PetDropdown.Visible
    if PetDropdown.Visible then
        UpdatePetDropdownPosition()
        PetSearchBox.Text = ""
        BuildPetDropdown("")
    end
end)

RefreshPetsButton.Activated:Connect(function()
    BuildPetDropdown(PetSearchBox.Text)
end)

PetSearchBox:GetPropertyChangedSignal("Text"):Connect(function()
    BuildPetDropdown(PetSearchBox.Text)
end)

UserInputService.InputBegan:Connect(function(input)
    if input.UserInputType ~= Enum.UserInputType.MouseButton1
        and input.UserInputType ~= Enum.UserInputType.Touch then
        return
    end
    if not PetDropdown.Visible then return end
    task.defer(function()
        local mousePos = UserInputService:GetMouseLocation()
        local hitObjects = GuiService:GetGuiObjectsAtPosition(mousePos.X, mousePos.Y)
        local clickedInside = false
        for _, obj in ipairs(hitObjects) do
            if obj == PetDropdown or obj:IsDescendantOf(PetDropdown)
                or obj == SelectPetsButton or obj == RefreshPetsButton then
                clickedInside = true
                break
            end
        end
        if not clickedInside then
            ClosePetDropdown()
        end
    end)
end)

-- =========================================================
-- RIGHT PANEL — SETTINGS
-- =========================================================
local SettingsPanel = CreatePanel(SettingsPage, "SettingsPanel", UDim2.new(0, 12, 0, 12), UDim2.new(1, -24, 0, 200), "BUY & MOVEMENT")

New("TextLabel", {
    Text = "Max Price",
    Font = Theme.Font,
    TextSize = 12,
    TextColor3 = Theme.TextDim,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 28),
    Size = UDim2.new(1, -24, 0, 14),
    TextXAlignment = Enum.TextXAlignment.Left,
}, SettingsPanel)

local PriceBox = New("TextBox", {
    Name = "PriceBox",
    Text = "50000000",
    PlaceholderText = "50000000",
    Font = Theme.Font,
    TextSize = 14,
    TextColor3 = Theme.InputText,
    PlaceholderColor3 = Theme.Muted,
    BackgroundColor3 = Theme.InputBg,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 12, 0, 46),
    Size = UDim2.new(1, -24, 0, 28),
    ClearTextOnFocus = false,
}, SettingsPanel)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, PriceBox)
New("UIPadding", { PaddingLeft = UDim.new(0, 8) }, PriceBox)

PriceBox.FocusLost:Connect(function()
    local num = tonumber(PriceBox.Text)
    if num then
        maxPetPrice = num
        saveSettings()
    else
        PriceBox.Text = tostring(maxPetPrice)
    end
end)

New("TextLabel", {
    Text = "Walk Speed (28-40 recommended)",
    Font = Theme.Font,
    TextSize = 12,
    TextColor3 = Theme.TextDim,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 84),
    Size = UDim2.new(1, -24, 0, 14),
    TextXAlignment = Enum.TextXAlignment.Left,
}, SettingsPanel)

local SpeedBox = New("TextBox", {
    Name = "SpeedBox",
    Text = "32",
    PlaceholderText = "32",
    Font = Theme.Font,
    TextSize = 14,
    TextColor3 = Theme.InputText,
    PlaceholderColor3 = Theme.Muted,
    BackgroundColor3 = Theme.InputBg,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 12, 0, 102),
    Size = UDim2.new(1, -24, 0, 28),
    ClearTextOnFocus = false,
}, SettingsPanel)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, SpeedBox)
New("UIPadding", { PaddingLeft = UDim.new(0, 8) }, SpeedBox)

SpeedBox.FocusLost:Connect(function()
    local num = tonumber(SpeedBox.Text)
    if num then
        petWalkSpeed = math.clamp(num, 16, 100)
        SpeedBox.Text = tostring(petWalkSpeed)
        saveSettings()
    else
        SpeedBox.Text = tostring(petWalkSpeed)
    end
end)

New("TextLabel", {
    Text = "Punch Radius",
    Font = Theme.Font,
    TextSize = 12,
    TextColor3 = Theme.TextDim,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 140),
    Size = UDim2.new(1, -24, 0, 14),
    TextXAlignment = Enum.TextXAlignment.Left,
}, SettingsPanel)

local RadiusBox = New("TextBox", {
    Name = "RadiusBox",
    Text = "16",
    PlaceholderText = "16",
    Font = Theme.Font,
    TextSize = 14,
    TextColor3 = Theme.InputText,
    PlaceholderColor3 = Theme.Muted,
    BackgroundColor3 = Theme.InputBg,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 12, 0, 158),
    Size = UDim2.new(1, -24, 0, 28),
    ClearTextOnFocus = false,
}, SettingsPanel)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, RadiusBox)
New("UIPadding", { PaddingLeft = UDim.new(0, 8) }, RadiusBox)

RadiusBox.FocusLost:Connect(function()
    local num = tonumber(RadiusBox.Text)
    if num then
        petPunchRadius = math.clamp(num, 8, 40)
        RadiusBox.Text = tostring(petPunchRadius)
        saveSettings()
    else
        RadiusBox.Text = tostring(petPunchRadius)
    end
end)

-- =========================================================
-- SETTINGS TAB — OPTIONAL SERVER ROTATION
-- =========================================================
local JobIdPanel = CreatePanel(SettingsPage, "JobIdPanel", UDim2.new(0, 12, 0, 224), UDim2.new(1, -24, 0, 176), "SERVER HOP ROTATION")

New("TextLabel", {
    Text = "Add Job IDs to hop through them in order. Leave empty for random 1-6 player servers.",
    Font = Theme.FontBody,
    TextSize = 11,
    TextColor3 = Theme.Muted,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 27),
    Size = UDim2.new(1, -24, 0, 26),
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
}, JobIdPanel)

local JobIdInput = New("TextBox", {
    Name = "JobIdInput",
    Text = "",
    PlaceholderText = "Paste a server Job ID...",
    Font = Theme.FontBody,
    TextSize = 12,
    TextColor3 = Theme.InputText,
    PlaceholderColor3 = Theme.Muted,
    BackgroundColor3 = Theme.InputBg,
    BorderSizePixel = 0,
    ClearTextOnFocus = false,
    Position = UDim2.new(0, 12, 0, 60),
    Size = UDim2.new(1, -112, 0, 28),
}, JobIdPanel)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, JobIdInput)
New("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8) }, JobIdInput)

local AddJobIdButton = New("TextButton", {
    Text = "ADD ID",
    Font = Theme.Font,
    TextSize = 11,
    TextColor3 = Theme.White,
    BackgroundColor3 = Theme.Red,
    BorderSizePixel = 0,
    Position = UDim2.new(1, -92, 0, 60),
    Size = UDim2.new(0, 80, 0, 28),
}, JobIdPanel)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, AddJobIdButton)

local JobIdsLabel = New("TextLabel", {
    Name = "JobIdsLabel",
    Text = "No saved Job IDs — random hopping is active.",
    Font = Theme.FontBody,
    TextSize = 11,
    TextColor3 = Theme.TextDim,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 98),
    Size = UDim2.new(1, -112, 0, 60),
    TextWrapped = true,
    TextXAlignment = Enum.TextXAlignment.Left,
    TextYAlignment = Enum.TextYAlignment.Top,
}, JobIdPanel)

local ClearJobIdsButton = New("TextButton", {
    Text = "CLEAR\nIDS",
    Font = Theme.Font,
    TextSize = 10,
    TextColor3 = Theme.White,
    BackgroundColor3 = Theme.RedDark,
    BorderSizePixel = 0,
    Position = UDim2.new(1, -92, 0, 104),
    Size = UDim2.new(0, 80, 0, 42),
    TextWrapped = true,
}, JobIdPanel)
New("UICorner", { CornerRadius = UDim.new(0, 5) }, ClearJobIdsButton)

local function updateJobIdsUI()
    if #customJobIds == 0 then
        JobIdsLabel.Text = "No saved Job IDs — random hopping is active."
        return
    end
    local lines = {}
    for index, jobId in ipairs(customJobIds) do
        local marker = index == customJobIndex and "Next: " or "      "
        table.insert(lines, marker .. index .. ". " .. tostring(jobId))
    end
    JobIdsLabel.Text = table.concat(lines, "\n")
end

local function addJobId()
    local jobId = tostring(JobIdInput.Text or ""):gsub("%s+", "")
    if jobId == "" then
        Notify("Server Hop", "Paste a Job ID first.", 2)
        return
    end
    for _, existingId in ipairs(customJobIds) do
        if existingId == jobId then
            Notify("Server Hop", "That Job ID is already in the rotation.", 2)
            return
        end
    end
    table.insert(customJobIds, jobId)
    JobIdInput.Text = ""
    updateJobIdsUI()
    saveSettings()
end

AddJobIdButton.Activated:Connect(addJobId)
JobIdInput.FocusLost:Connect(function(enterPressed)
    if enterPressed then addJobId() end
end)
ClearJobIdsButton.Activated:Connect(function()
    table.clear(customJobIds)
    customJobIndex = 1
    updateJobIdsUI()
    saveSettings()
    Notify("Server Hop", "Custom Job ID rotation cleared.", 2)
end)

local function getNextCustomJobId()
    if #customJobIds == 0 then return nil end
    customJobIndex = math.clamp(customJobIndex, 1, #customJobIds)
    for _ = 1, #customJobIds do
        local jobId = customJobIds[customJobIndex]
        customJobIndex = (customJobIndex % #customJobIds) + 1
        if jobId ~= game.JobId then
            updateJobIdsUI()
            return jobId
        end
    end
    return nil
end

-- =========================================================
-- STATUS + TOGGLE PANEL
-- =========================================================
local StatusPanel = CreatePanel(AutoBuyPage, "StatusPanel", UDim2.new(0, 12, 0, 222), UDim2.new(1, -24, 1, -234), "STATUS")

local StatusLabel = New("TextLabel", {
    Name = "StatusLabel",
    Text = "Protection: OFF",
    Font = Theme.Font,
    TextSize = 14,
    TextColor3 = Theme.TextDim,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 28),
    Size = UDim2.new(1, -24, 0, 20),
    TextXAlignment = Enum.TextXAlignment.Left,
}, StatusPanel)

local BoughtLabel = New("TextLabel", {
    Name = "BoughtLabel",
    Text = "Pets Bought From This (" .. LocalPlayer.Name .. "): 0",
    Font = Theme.Font,
    TextSize = 14,
    TextColor3 = Theme.Success,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 48),
    Size = UDim2.new(1, -24, 0, 18),
    TextXAlignment = Enum.TextXAlignment.Left,
}, StatusPanel)

local PointsLabel = New("TextLabel", {
    Name = "PointsLabel",
    Text = "ysteystem: 0",
    Font = Theme.Font,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(255, 208, 105),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 68),
    Size = UDim2.new(1, -24, 0, 18),
    TextXAlignment = Enum.TextXAlignment.Left,
}, StatusPanel)

local ShecklesLabel = New("TextLabel", {
    Name = "ShecklesLabel",
    Text = "Sheckles: Loading...",
    Font = Theme.Font,
    TextSize = 14,
    TextColor3 = Color3.fromRGB(123, 222, 151),
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 88),
    Size = UDim2.new(1, -24, 0, 18),
    TextXAlignment = Enum.TextXAlignment.Left,
}, StatusPanel)

local TargetLabel = New("TextLabel", {
    Name = "TargetLabel",
    Text = "Targets: Bunny",
    Font = Theme.FontBody,
    TextSize = 12,
    TextColor3 = Theme.Muted,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 0, 108),
    Size = UDim2.new(1, -24, 0, 18),
    TextXAlignment = Enum.TextXAlignment.Left,
    TextTruncate = Enum.TextTruncate.AtEnd,
}, StatusPanel)

local ToggleButton = New("TextButton", {
    Name = "ToggleButton",
    Text = "ENABLE AUTO BUY PET",
    Font = Theme.Font,
    TextSize = 13,
    TextColor3 = Theme.White,
    BackgroundColor3 = Theme.Red,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 12, 1, -48),
    Size = UDim2.new(1, -24, 0, 34),
}, StatusPanel)
New("UICorner", { CornerRadius = UDim.new(0, 6) }, ToggleButton)
New("UIStroke", { Color = Color3.fromRGB(255, 150, 157), Thickness = 1, Transparency = 0.55 }, ToggleButton)

-- =========================================================
-- HISTORY TAB
-- =========================================================
local HistoryPanel = CreatePanel(HistoryPage, "HistoryPanel", UDim2.new(0, 12, 0, 12), UDim2.new(1, -24, 1, -24), "PET HISTORY")

local HistoryTotalLabel = New("TextLabel", {
    Name = "HistoryTotalLabel",
    Text = "Total pets: 0",
    Font = Theme.Font,
    TextSize = 13,
    TextColor3 = Theme.Success,
    BackgroundTransparency = 1,
    Position = UDim2.new(0, 12, 1, -44),
    Size = UDim2.new(0.5, -12, 0, 20),
    TextXAlignment = Enum.TextXAlignment.Left,
}, HistoryPanel)

local HistoryPointsLabel = New("TextLabel", {
    Name = "HistoryPointsLabel",
    Text = "Total points: 0",
    Font = Theme.Font,
    TextSize = 13,
    TextColor3 = Color3.fromRGB(255, 208, 105),
    BackgroundTransparency = 1,
    Position = UDim2.new(0.5, 0, 1, -44),
    Size = UDim2.new(0.5, -12, 0, 20),
    TextXAlignment = Enum.TextXAlignment.Right,
}, HistoryPanel)

local HistoryScroll = New("ScrollingFrame", {
    Name = "HistoryScroll",
    BackgroundColor3 = Theme.Surface2,
    BackgroundTransparency = 0.22,
    BorderSizePixel = 0,
    Position = UDim2.new(0, 12, 0, 28),
    Size = UDim2.new(1, -24, 1, -80),
    CanvasSize = UDim2.new(0, 0, 0, 0),
    ScrollBarThickness = 4,
    ScrollBarImageColor3 = Theme.Red,
    AutomaticCanvasSize = Enum.AutomaticSize.Y,
}, HistoryPanel)
New("UICorner", { CornerRadius = UDim.new(0, 6) }, HistoryScroll)
New("UIPadding", {
    PaddingTop = UDim.new(0, 5),
    PaddingBottom = UDim.new(0, 5),
    PaddingLeft = UDim.new(0, 6),
    PaddingRight = UDim.new(0, 6),
}, HistoryScroll)
New("UIListLayout", { Padding = UDim.new(0, 4), SortOrder = Enum.SortOrder.Name }, HistoryScroll)

updateHistoryUI = function()
    for _, child in ipairs(HistoryScroll:GetChildren()) do
        if child.Name == "HistoryRow" or child.Name == "HistoryEmpty" then
            child:Destroy()
        end
    end

    HistoryTotalLabel.Text = "Total pets: " .. petsBought
    HistoryPointsLabel.Text = "Total points: " .. totalPoints

    local names = {}
    for petName, count in pairs(petHistory) do
        if tonumber(count) and tonumber(count) > 0 then
            table.insert(names, petName)
        end
    end
    table.sort(names)

    if #names == 0 then
        New("TextLabel", {
            Name = "HistoryEmpty",
            Text = "No pets secured yet.",
            Font = Theme.FontBody,
            TextSize = 13,
            TextColor3 = Theme.Muted,
            BackgroundTransparency = 1,
            Size = UDim2.new(1, 0, 0, 32),
            TextXAlignment = Enum.TextXAlignment.Center,
        }, HistoryScroll)
        return
    end

    for _, petName in ipairs(names) do
        local row = New("Frame", {
            Name = "HistoryRow",
            BackgroundColor3 = Theme.Surface3,
            BackgroundTransparency = 0.22,
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 30),
        }, HistoryScroll)
        New("UICorner", { CornerRadius = UDim.new(0, 5) }, row)
        New("TextLabel", {
            Text = petName,
            Font = Theme.Font,
            TextSize = 13,
            TextColor3 = Theme.White,
            BackgroundTransparency = 1,
            Position = UDim2.new(0, 10, 0, 0),
            Size = UDim2.new(0.7, -10, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Left,
        }, row)
        New("TextLabel", {
            Text = "x" .. tostring(petHistory[petName]),
            Font = Theme.Font,
            TextSize = 13,
            TextColor3 = Theme.Success,
            BackgroundTransparency = 1,
            Position = UDim2.new(0.7, 0, 0, 0),
            Size = UDim2.new(0.3, -10, 1, 0),
            TextXAlignment = Enum.TextXAlignment.Right,
        }, row)
    end
end

local shecklesValueObject = nil

local function readNumber(value)
    if type(value) == "number" then return value end
    if type(value) == "string" then
        return tonumber(value:gsub("[^%d%-%.]", ""))
    end
    return nil
end

local function formatSheckles(value)
    local suffixes = {
        { 1000000000000, "T" },
        { 1000000000, "B" },
        { 1000000, "M" },
        { 1000, "K" },
    }
    for _, unit in ipairs(suffixes) do
        if value >= unit[1] then
            local text = string.format("%.1f", value / unit[1]):gsub("%.0$", "")
            return text .. unit[2]
        end
    end
    return tostring(math.floor(value))
end

local function getSheckles()
    -- Prefer the actual replicated player stat, then fall back to a matching
    -- player attribute.  The found ValueBase is cached for cheap live updates.
    if shecklesValueObject and shecklesValueObject.Parent then
        return readNumber(shecklesValueObject.Value)
    end

    local directAttribute = readNumber(LocalPlayer:GetAttribute("Sheckles"))
        or readNumber(LocalPlayer:GetAttribute("Scheckles"))
    if directAttribute ~= nil then return directAttribute end

    for _, item in ipairs(LocalPlayer:GetDescendants()) do
        local name = string.lower(item.Name)
        if (name == "sheckles" or name == "scheckles") and item:IsA("ValueBase") then
            shecklesValueObject = item
            return readNumber(item.Value)
        end
    end
    return nil
end

local function updateShecklesUI()
    local sheckles = getSheckles()
    ShecklesLabel.Text = sheckles and ("Sheckles: " .. formatSheckles(sheckles)) or "Sheckles: Not found"
end

local function updateStatusUI()
    if petProtectEnabled then
        StatusLabel.Text = "Protection: ON"
        StatusLabel.TextColor3 = Theme.Success
        ToggleButton.Text = "DISABLE AUTO BUY PET"
        ToggleButton.BackgroundColor3 = Theme.RedDark
    else
        StatusLabel.Text = "Protection: OFF"
        StatusLabel.TextColor3 = Theme.TextDim
        ToggleButton.Text = "ENABLE AUTO BUY PET"
        ToggleButton.BackgroundColor3 = Theme.Red
    end
    BoughtLabel.Text = "Pets Bought By " .. LocalPlayer.Name .. ": " .. petsBought
    PointsLabel.Text = "Points: " .. totalPoints
    updateShecklesUI()
    TargetLabel.Text = "Targets: " .. formatList(targetPetNames)
end

local function normalizeRarity(value)
    if type(value) ~= "string" then return nil end
    local lowered = string.lower(value)
    for rarity in pairs(RARITY_POINTS) do
        if lowered == string.lower(rarity) then
            return rarity
        end
    end
    return nil
end

local function findRarityOverride(petName)
    if type(petName) ~= "string" or petName == "" then return nil end

    local exact = PET_RARITY_OVERRIDES[petName]
    if exact then return exact end

    -- Wild-pet models can be named "Bunny_123", "Bunny (1)", etc.
    -- Compare normalized names so these still match the confirmed table.
    local normalizedName = string.lower(petName):gsub("[^%a%d]", "")
    for configuredName, rarity in pairs(PET_RARITY_OVERRIDES) do
        local normalizedConfigured = string.lower(configuredName):gsub("[^%a%d]", "")
        if normalizedName == normalizedConfigured
            or string.find(normalizedName, normalizedConfigured, 1, true) then
            return rarity
        end
    end
    return nil
end

local function getWildPetSpeciesName(pet)
    -- Spawn names follow: WildPet_<Species>_WildPet_<random id>
    -- Example: WildPet_Bunny_WildPet_ce4fb5c1-...
    local species = pet.Name:match("^WildPet_([^_]+)_WildPet_")
    return species or pet.Name
end

local function getPetRarityAndPoints(pet)
    -- Try the model name first, then common species/name attributes used by
    -- wild-pet containers in case the model itself has a generic name.
    local candidateNames = { getWildPetSpeciesName(pet), pet.Name }
    for _, attributeName in ipairs({ "PetName", "Species", "PetSpecies" }) do
        local attributeValue = pet:GetAttribute(attributeName)
        if type(attributeValue) == "string" then
            table.insert(candidateNames, attributeValue)
        end
    end
    for _, candidateName in ipairs(candidateNames) do
        local override = findRarityOverride(candidateName)
        if override and RARITY_POINTS[override] then
            return override, RARITY_POINTS[override]
        end
    end

    for _, attributeName in ipairs({ "Rarity", "PetRarity", "Tier" }) do
        local rarity = normalizeRarity(pet:GetAttribute(attributeName))
        if rarity then return rarity, RARITY_POINTS[rarity] end

        local valueObject = pet:FindFirstChild(attributeName, true)
        if valueObject and valueObject:IsA("StringValue") then
            rarity = normalizeRarity(valueObject.Value)
            if rarity then return rarity, RARITY_POINTS[rarity] end
        end
    end

    for rarity, points in pairs(RARITY_POINTS) do
        if string.find(string.lower(pet.Name), string.lower(rarity), 1, true) then
            return rarity, points
        end
    end

    return "Unknown", 0
end

-- =========================================================
-- PET PROTECT LOGIC + AUTO SERVER HOP
-- =========================================================
local function findLowPopulationServer()
    local candidates = {}
    local cursor = nil

    -- Check a few pages of public servers. Population is live data, so a
    -- server can change slightly between this check and arrival.
    for _ = 1, 3 do
        local url = "https://games.roblox.com/v1/games/" .. game.PlaceId
            .. "/servers/Public?sortOrder=Asc&limit=100&excludeFullGames=true"
        if cursor then
            url = url .. "&cursor=" .. HttpService:UrlEncode(cursor)
        end

        local requestOk, responseBody = pcall(function()
            return game:HttpGet(url)
        end)
        if not requestOk or type(responseBody) ~= "string" then
            break
        end

        local decodeOk, page = pcall(function()
            return HttpService:JSONDecode(responseBody)
        end)
        if not decodeOk or type(page) ~= "table" then
            break
        end

        for _, server in ipairs(page.data or {}) do
            local players = tonumber(server.playing) or 0
            if server.id ~= game.JobId and players >= 1 and players <= 6 then
                table.insert(candidates, server)
            end
        end

        if #candidates > 0 or not page.nextPageCursor then
            break
        end
        cursor = page.nextPageCursor
    end

    if #candidates == 0 then
        return nil
    end
    return candidates[math.random(1, #candidates)]
end

local function setPetProtectEnabled(enabled)
    petProtectEnabled = enabled == true
    rebuildTargetList()
    updateStatusUI()
    saveSettings()

    if petProtectEnabled then
        if #targetPetNames == 0 then
            Notify("Error", "Select at least one pet first!", 3)
            petProtectEnabled = false
            updateStatusUI()
            saveSettings()
            return
        end

        Notify("Buy Protect", "Started — Buying and Protecting: " .. formatList(targetPetNames), 3)

        petProtectThread = task.spawn(function()
            local character = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()
            local humanoid = character:WaitForChild("Humanoid")
            local hrp = character:WaitForChild("HumanoidRootPart")
            local backpack = LocalPlayer:WaitForChild("Backpack")

            local FOLLOW_DISTANCE = 1.0
            local RETURN_DISTANCE = 9
            local MIN_Y = -20
            local NO_PET_TIMEOUT = 18 -- seconds with no pets before rejoin

            local RUN_SPEED = petWalkSpeed
            humanoid.WalkSpeed = RUN_SPEED
            humanoid.AutoRotate = true

            local runTarget = nil
            local noPetTimer = 0
            local targetSpawnConn = nil

            for _, tool in ipairs(backpack:GetChildren()) do
                if tool:IsA("Tool") and string.find(string.lower(tool.Name), "shovel") then
                    humanoid:EquipTool(tool)
                    break
                end
            end

            local groundReferences = {}
            local baseplateModel = workspace:FindFirstChild("Baseplate")
            if baseplateModel then
                local topLayer = baseplateModel:FindFirstChild("TopLayer")
                table.insert(groundReferences, topLayer or baseplateModel)
            end
            if workspace:FindFirstChild("Terrain") then
                table.insert(groundReferences, workspace.Terrain)
            end

            local groundRaycastParams = nil
            if #groundReferences > 0 then
                groundRaycastParams = RaycastParams.new()
                groundRaycastParams.FilterType = Enum.RaycastFilterType.Include
                groundRaycastParams.FilterDescendantsInstances = groundReferences
            end

            local function getGroundY(position)
                if not groundRaycastParams then return -math.huge end
                local result = workspace:Raycast(
                    position + Vector3.new(0, 50, 0),
                    Vector3.new(0, -2000, 0),
                    groundRaycastParams
                )
                return result and result.Position.Y or -math.huge
            end

            local GROUND_CLEARANCE = (humanoid.HipHeight or 2) + (hrp.Size.Y / 2) + 0.05

            local function forceRun()
                if not humanoid then return end
                -- Some in-game interfaces temporarily put the character in a
                -- non-walkable state.  Like the older script, clear this on
                -- every heartbeat so the opening game GUI cannot leave the
                -- character frozen before a pet is found.
                humanoid.PlatformStand = false
                humanoid.Sit = false
                humanoid.AutoRotate = true
                if hrp then
                    hrp.Anchored = false
                end
                humanoid.WalkSpeed = RUN_SPEED

                -- No matching pet: do not submit a MoveTo command. The player
                -- keeps full manual control while the script waits.
                if not runTarget then return end
                humanoid:MoveTo(runTarget)
                local groundY = getGroundY(hrp.Position)
                if groundY > -math.huge then
                    local minY = groundY + GROUND_CLEARANCE
                    if hrp.Position.Y < minY then
                        hrp.CFrame = CFrame.new(hrp.Position.X, minY, hrp.Position.Z)
                            * (hrp.CFrame - hrp.CFrame.Position)
                    end
                end
            end

            local function forceNoclip()
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") then
                        part.CanCollide = false
                    end
                end
            end

            local walkConn = RunService.Heartbeat:Connect(forceRun)
            local noclipConn = RunService.Stepped:Connect(forceNoclip)

            local function getTargetPart(model)
                return model and (model.PrimaryPart or model:FindFirstChildWhichIsA("BasePart"))
            end

            -- Start walking as soon as a requested wild pet appears.  This is
            -- intentionally independent of any game or hub GUI being open;
            -- GUI focus must not delay the trip to the pet.
            local function isRequestedWildPet(pet)
                if not pet or not pet:IsA("Model") then return false end
                local petName = string.lower(getWildPetSpeciesName(pet))
                for _, requestedName in ipairs(targetPetNames) do
                    if string.find(petName, string.lower(requestedName), 1, true) then
                        return true
                    end
                end
                return false
            end

            local wildPetSpawns = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("WildPetSpawns")
            if wildPetSpawns then
                targetSpawnConn = wildPetSpawns.ChildAdded:Connect(function(pet)
                    if not petProtectEnabled or not isRequestedWildPet(pet) then return end
                    task.defer(function()
                        local targetPart = getTargetPart(pet)
                        if targetPart and pet.Parent and petProtectEnabled then
                            runTarget = targetPart.Position
                        end
                    end)
                end)
            end

            local function findWildPets(names)
                local spawns = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("WildPetSpawns")
                if not spawns or not names or #names == 0 then return {} end
                local lowerNames = {}
                for _, n in ipairs(names) do
                    table.insert(lowerNames, string.lower(n))
                end
                local matches = {}
                for _, pet in ipairs(spawns:GetChildren()) do
                    if pet:IsA("Model") then
                        local lowerPetName = string.lower(getWildPetSpeciesName(pet))
                        for _, n in ipairs(lowerNames) do
                            if string.find(lowerPetName, n) then
                                table.insert(matches, pet)
                                break
                            end
                        end
                    end
                end
                return matches
            end

            local function isInsideSafeZone(pos)
                local zones = workspace:FindFirstChild("Map") and workspace.Map:FindFirstChild("SafeZones")
                if not zones then return false end
                for _, zone in ipairs(zones:GetDescendants()) do
                    if zone:IsA("BasePart") then
                        local size = zone.Size / 2
                        local rel = zone.CFrame:PointToObjectSpace(pos)
                        if math.abs(rel.X) <= size.X and math.abs(rel.Y) <= size.Y and math.abs(rel.Z) <= size.Z then
                            return true
                        end
                    end
                end
                return false
            end

            local function getPromptPrice(prompt)
                if not prompt or not prompt.ObjectText then return nil end
                local text = prompt.ObjectText:gsub("[¢,\s]", ""):upper()
                local num = tonumber(text:match("[%d%.]+"))
                if not num then return nil end
                if text:find("K") then num = num * 1000
                elseif text:find("M") then num = num * 1000000
                elseif text:find("B") then num = num * 1000000000 end
                return num
            end

            local function getClosestIntruder(petPos)
                local closest, closestDist = nil, petPunchRadius
                for _, other in ipairs(Players:GetPlayers()) do
                    if other ~= LocalPlayer and other.Character then
                        local otherHRP = other.Character:FindFirstChild("HumanoidRootPart")
                        if otherHRP then
                            local dist = (otherHRP.Position - petPos).Magnitude
                            if dist < closestDist then
                                closestDist = dist
                                closest = other
                            end
                        end
                    end
                end
                return closest
            end

            local function getShovelTool()
                for _, tool in ipairs(backpack:GetChildren()) do
                    if tool:IsA("Tool") and string.find(string.lower(tool.Name), "shovel") then
                        return tool
                    end
                end
                for _, tool in ipairs(character:GetChildren()) do
                    if tool:IsA("Tool") and string.find(string.lower(tool.Name), "shovel") then
                        return tool
                    end
                end
                return nil
            end

            local function securePet(pet)
                Notify("Target Locked", "Now Buying And Protecting: " .. getWildPetSpeciesName(pet), 2)
                noPetTimer = 0

                while petProtectEnabled do
                    if not pet then
                        break
                    end
                    if not pet.Parent then
                        runTarget = nil
                        local rarity, points = getPetRarityAndPoints(pet)
                        local petName = getWildPetSpeciesName(pet)
                        petsBought = petsBought + 1
                        totalPoints = totalPoints + points
                        petHistory[petName] = (tonumber(petHistory[petName]) or 0) + 1
                        print("[AutoBuyPet] Scored", petName, rarity, "+" .. points, "Total:", totalPoints)
                        saveSettings()
                        updateStatusUI()
                        if updateHistoryUI then updateHistoryUI() end
                        Notify("Secured!", petName .. " bought! " .. rarity .. " +" .. points .. " points", 2)
                        break
                    end

                    local targetPart = getTargetPart(pet)
                    if not targetPart then break end

                    local petPos = targetPart.Position

                    if hrp.Position.Y < MIN_Y then
                        hrp.CFrame = CFrame.new(petPos + Vector3.new(0, 5, 0))
                        task.wait(0.1)
                        continue
                    end

                    local distanceToPet = (hrp.Position - petPos).Magnitude
                    local prompt = pet:FindFirstChildWhichIsA("ProximityPrompt", true)

                    if distanceToPet > RETURN_DISTANCE then
                        runTarget = petPos
                        task.wait(0.05)
                        continue
                    end

                    local intruder = getClosestIntruder(petPos)

                    if intruder and intruder.Character then
                        local otherHRP = intruder.Character:FindFirstChild("HumanoidRootPart")
                        if otherHRP then
                            runTarget = otherHRP.Position
                            pcall(function() ShovelNet.HitPlayer:Fire(intruder.UserId) end)
                            pcall(function() ShovelNet.SwingShovel:Fire(intruder.Character) end)

                            local shovelTool = getShovelTool()
                            if shovelTool then
                                local equipped = character:FindFirstChildOfClass("Tool")
                                if equipped ~= shovelTool then
                                    humanoid:EquipTool(shovelTool)
                                end
                                pcall(function() shovelTool:Activate() end)
                            end
                        end
                    else
                        if distanceToPet > FOLLOW_DISTANCE then
                            runTarget = petPos
                        end

                        if prompt and prompt.Enabled then
                            local price = getPromptPrice(prompt)
                            if not price or price < maxPetPrice then
                                fireproximityprompt(prompt)
                                task.wait(0.25)
                            end
                        end
                    end

                    task.wait(0.06)
                end
            end

            while petProtectEnabled do
                local matches = findWildPets(targetPetNames)

                if #matches == 0 then
                    -- No target is alive: stop the previous MoveTo target so
                    -- the player regains normal movement while waiting.
                    runTarget = nil
                    humanoid:MoveTo(hrp.Position)
                    noPetTimer = noPetTimer + 1
                    if autoRejoin and noPetTimer >= NO_PET_TIMEOUT then
                        local customJobId = getNextCustomJobId()
                        if customJobId then
                            Notify("Server Hop", "No pets left — hopping to the next saved Job ID.", 3)
                            if isKRNL then
                                enableKRNLQueue()
                            end
                            saveSettings()
                            task.wait(1.2)
                            pcall(function()
                                TeleportService:TeleportToPlaceInstance(game.PlaceId, customJobId, LocalPlayer)
                            end)
                            break
                        end

                        local server = findLowPopulationServer()
                        Notify("Server Hop", "No pets left — looking for a 1-6 player server...", 3)
                        if not server then
                            Notify("Server Hop", "No server with 1-6 players found. Staying here.", 3)
                            noPetTimer = 0
                            task.wait(3)
                        else
                        -- Set up KRNL queue before teleporting
                        if isKRNL then
                            enableKRNLQueue()
                        end
                        
                        saveSettings()
                        task.wait(1.2)
                        pcall(function()
                            TeleportService:TeleportToPlaceInstance(game.PlaceId, server.id, LocalPlayer)
                        end)
                        break
                        end
                    end
                    task.wait(1)
                else
                    noPetTimer = 0
                    securePet(matches[1])
                end
            end

            walkConn:Disconnect()
            noclipConn:Disconnect()
            if targetSpawnConn then
                targetSpawnConn:Disconnect()
            end
            humanoid.WalkSpeed = 16
            for _, part in ipairs(character:GetDescendants()) do
                if part:IsA("BasePart") then
                    part.CanCollide = true
                end
            end
        end)
    else
        Notify("Pet Protect", "Stopped", 3)
    end
end

ToggleButton.Activated:Connect(function()
    setPetProtectEnabled(not petProtectEnabled)
end)

-- =========================================================
-- Minimize / Close
-- =========================================================
local minimized = false
MinButton.Activated:Connect(function()
    minimized = not minimized
    Body.Visible = not minimized
    local size = minimized and UDim2.new(0, 520, 0, 38) or UDim2.new(0, 520, 0, 500)
    SafeTween(Main, TweenInfo.new(0.2), { Size = size })
    SafeTween(DropShadowHolder, TweenInfo.new(0.2), { Size = size })
    SafeTween(DropShadow, TweenInfo.new(0.2), { Size = size })
end)

CloseButton.Activated:Connect(function()
    ScreenGui.Enabled = false
    if petProtectEnabled then
        setPetProtectEnabled(false)
    end
    saveSettings()
end)

-- =========================================================
-- INIT — Load saved settings
-- =========================================================
loadSettings()

-- Apply loaded values to UI
PriceBox.Text = tostring(maxPetPrice)
SpeedBox.Text = tostring(petWalkSpeed)
RadiusBox.Text = tostring(petPunchRadius)

rebuildTargetList()
updateRejoinUI()
updateStatusUI()
updateJobIdsUI()
if updateHistoryUI then updateHistoryUI() end

-- Currency can change without any action in this hub, so refresh just this
-- status line in the background instead of waiting for another UI update.
task.spawn(function()
    while ScreenGui.Parent do
        updateShecklesUI()
        task.wait(0.5)
    end
end)

-- Restore exactly what the user chose before the previous teleport.
-- Do this immediately: rebuildTargetList above saves the temporary OFF
-- setup state, so deferring this restoration can leave it saved as OFF.
if resumePetProtectOnLoad then
    setPetProtectEnabled(true)
end

print("[AutoBuyPet] Loaded: " .. tostring(isKRNL) .. " | SERVER HOPPING: " .. tostring(autoRejoin))
Notify("Loaded", "Settings restored: " .. tostring(isKRNL), 3)
