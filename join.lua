--[[
    Inferno Viewer GUI
    - Shows up to 20 servers
    - Working Search bar
    - Join button (copies roblox:// link)
]]

local CONFIG = {
    JSONBIN_ID = "6a63b2fcda38895dfe8b51c7",
    JSONBIN_API_KEY = "$2a$10$nYqa4kNpOA9gvcy1vopkGuZyNZiIhAf2LYj1zRQqUzIOAzYxWHfp2",
    REFRESH_EVERY = 8,
}

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

local currentServers = {}
local currentFilter = ""

local function getData()
    local requestFunc = request or http_request or (syn and syn.request)
    if not requestFunc then return nil end

    local response = requestFunc({
        Url = "https://api.jsonbin.io/v3/b/" .. CONFIG.JSONBIN_ID .. "/latest",
        Method = "GET",
        Headers = { ["X-Access-Key"] = CONFIG.JSONBIN_API_KEY }
    })

    if response and response.Body then
        local ok, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
        if ok and data and data.record and data.record.servers then
            return data.record.servers
        end
    end
    return nil
end

local function createGUI()
    if PlayerGui:FindFirstChild("InfernoViewerGUI") then
        PlayerGui.InfernoViewerGUI:Destroy()
    end

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "InfernoViewerGUI"
    screenGui.ResetOnSpawn = false
    screenGui.Parent = PlayerGui

    local main = Instance.new("Frame")
    main.Name = "Main"
    main.Size = UDim2.new(0, 400, 0, 460)
    main.Position = UDim2.new(0.5, -200, 0.5, -230)
    main.BackgroundColor3 = Color3.fromRGB(16, 16, 20)
    main.Active = true
    main.Draggable = true
    main.Parent = screenGui
    Instance.new("UICorner", main).CornerRadius = UDim.new(0, 12)

    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 38)
    title.BackgroundColor3 = Color3.fromRGB(28, 28, 34)
    title.Text = "  🔥 Inferno Finds"
    title.TextColor3 = Color3.new(1,1,1)
    title.Font = Enum.Font.GothamBold
    title.TextSize = 16
    title.TextXAlignment = Enum.TextXAlignment.Left
    title.Parent = main
    Instance.new("UICorner", title).CornerRadius = UDim.new(0, 12)

    -- Search box
    local searchBox = Instance.new("TextBox")
    searchBox.Name = "SearchBox"
    searchBox.Size = UDim2.new(1, -20, 0, 32)
    searchBox.Position = UDim2.new(0, 10, 0, 48)
    searchBox.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    searchBox.PlaceholderText = "Search pet / owner..."
    searchBox.Text = ""
    searchBox.TextColor3 = Color3.new(1,1,1)
    searchBox.PlaceholderColor3 = Color3.fromRGB(120, 120, 130)
    searchBox.Font = Enum.Font.Gotham
    searchBox.TextSize = 14
    searchBox.ClearTextOnFocus = false
    searchBox.Parent = main
    Instance.new("UICorner", searchBox).CornerRadius = UDim.new(0, 8)

    -- Status
    local status = Instance.new("TextLabel")
    status.Name = "Status"
    status.Size = UDim2.new(1, -20, 0, 18)
    status.Position = UDim2.new(0, 10, 0, 86)
    status.BackgroundTransparency = 1
    status.Text = "Loading..."
    status.TextColor3 = Color3.fromRGB(140, 140, 150)
    status.Font = Enum.Font.Gotham
    status.TextSize = 12
    status.TextXAlignment = Enum.TextXAlignment.Left
    status.Parent = main

    -- List
    local list = Instance.new("ScrollingFrame")
    list.Name = "List"
    list.Size = UDim2.new(1, -20, 1, -140)
    list.Position = UDim2.new(0, 10, 0, 108)
    list.BackgroundColor3 = Color3.fromRGB(22, 22, 28)
    list.ScrollBarThickness = 3
    list.CanvasSize = UDim2.new(0, 0, 0, 0)
    list.Parent = main
    Instance.new("UICorner", list).CornerRadius = UDim.new(0, 8)

    local layout = Instance.new("UIListLayout")
    layout.Padding = UDim.new(0, 8)
    layout.Parent = list
    layout:GetPropertyChangedSignal("AbsoluteContentSize"):Connect(function()
        list.CanvasSize = UDim2.new(0, 0, 0, layout.AbsoluteContentSize.Y + 12)
    end)

    -- Close
    local closeBtn = Instance.new("TextButton")
    closeBtn.Size = UDim2.new(0, 70, 0, 28)
    closeBtn.Position = UDim2.new(1, -80, 1, -36)
    closeBtn.BackgroundColor3 = Color3.fromRGB(50, 50, 60)
    closeBtn.Text = "Close"
    closeBtn.TextColor3 = Color3.new(1,1,1)
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.TextSize = 13
    closeBtn.Parent = main
    Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 6)
    closeBtn.MouseButton1Click:Connect(function()
        screenGui:Destroy()
    end)

    return screenGui, searchBox
end

local function clearList(list)
    for _, child in ipairs(list:GetChildren()) do
        if child:IsA("Frame") then child:Destroy() end
    end
end

local function addServerCard(list, server)
    local card = Instance.new("Frame")
    card.Size = UDim2.new(1, -8, 0, 0)
    card.BackgroundColor3 = Color3.fromRGB(30, 30, 38)
    card.Parent = list
    Instance.new("UICorner", card).CornerRadius = UDim.new(0, 8)

    local cardLayout = Instance.new("UIListLayout")
    cardLayout.Padding = UDim.new(0, 3)
    cardLayout.Parent = card

    local pad = Instance.new("UIPadding")
    pad.PaddingTop = UDim.new(0, 10)
    pad.PaddingBottom = UDim.new(0, 10)
    pad.PaddingLeft = UDim.new(0, 12)
    pad.PaddingRight = UDim.new(0, 12)
    pad.Parent = card

    -- Header
    local header = Instance.new("Frame")
    header.Size = UDim2.new(1, 0, 0, 28)
    header.BackgroundTransparency = 1
    header.Parent = card

    local timeLabel = Instance.new("TextLabel")
    timeLabel.Size = UDim2.new(1, -80, 1, 0)
    timeLabel.BackgroundTransparency = 1
    timeLabel.Text = string.format("%s  •  %s players", server.time or "?", server.players or "?")
    timeLabel.TextColor3 = Color3.fromRGB(160, 160, 170)
    timeLabel.Font = Enum.Font.Gotham
    timeLabel.TextSize = 12
    timeLabel.TextXAlignment = Enum.TextXAlignment.Left
    timeLabel.Parent = header

    local joinBtn = Instance.new("TextButton")
    joinBtn.Size = UDim2.new(0, 70, 0, 26)
    joinBtn.Position = UDim2.new(1, -70, 0, 1)
    joinBtn.BackgroundColor3 = Color3.fromRGB(50, 120, 220)
    joinBtn.Text = "Join"
    joinBtn.TextColor3 = Color3.new(1,1,1)
    joinBtn.Font = Enum.Font.GothamBold
    joinBtn.TextSize = 13
    joinBtn.Parent = header
    Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(0, 6)

    local robloxLink = server.robloxLink or string.format(
        "roblox://experiences/start?placeId=%s&gameInstanceId=%s",
        tostring(server.placeId), tostring(server.jobId)
    )

joinBtn.MouseButton1Click:Connect(function()
    local placeId = tonumber(server.placeId)
    local jobId = server.jobId

    if not placeId or not jobId then
        joinBtn.Text = "Invalid"
        task.delay(1, function()
            if joinBtn and joinBtn.Parent then joinBtn.Text = "Join" end
        end)
        return
    end

    joinBtn.Text = "Joining..."
    
    local TeleportService = game:GetService("TeleportService")
    local ok, err = pcall(function()
        TeleportService:TeleportToPlaceInstance(placeId, jobId, LocalPlayer)
    end)

    if not ok then
        warn("Teleport failed:", err)
        joinBtn.Text = "Failed"
        -- still copy link as backup
        if setclipboard then
            local link = string.format(
                "roblox://experiences/start?placeId=%s&gameInstanceId=%s",
                tostring(placeId), tostring(jobId)
            )
            setclipboard(link)
        end
        task.delay(1.5, function()
            if joinBtn and joinBtn.Parent then joinBtn.Text = "Join" end
        end)
    end
end)

    -- Booths / pets
    for _, booth in ipairs(server.booths or {}) do
        local owner = Instance.new("TextLabel")
        owner.Size = UDim2.new(1, 0, 0, 18)
        owner.BackgroundTransparency = 1
        owner.Text = "👤 " .. tostring(booth.owner)
        owner.TextColor3 = Color3.fromRGB(255, 190, 90)
        owner.Font = Enum.Font.GothamBold
        owner.TextSize = 13
        owner.TextXAlignment = Enum.TextXAlignment.Left
        owner.Parent = card

        for _, pet in ipairs(booth.pets or {}) do
            local row = Instance.new("TextLabel")
            row.Size = UDim2.new(1, 0, 0, 16)
            row.BackgroundTransparency = 1
            row.Text = string.format("  • %s (%s) | %s | Lv.%s | %s Tokens",
                pet.type, pet.name, pet.weight, pet.level, pet.price)
            row.TextColor3 = Color3.fromRGB(210, 210, 220)
            row.Font = Enum.Font.Gotham
            row.TextSize = 12
            row.TextXAlignment = Enum.TextXAlignment.Left
            row.Parent = card
        end
    end

    task.defer(function()
        card.Size = UDim2.new(1, -8, 0, cardLayout.AbsoluteContentSize.Y + 20)
    end)
end

local function matchesFilter(server, filter)
    if filter == "" then return true end
    filter = string.lower(filter)

    for _, booth in ipairs(server.booths or {}) do
        if string.find(string.lower(tostring(booth.owner)), filter, 1, true) then
            return true
        end
        for _, pet in ipairs(booth.pets or {}) do
            if string.find(string.lower(tostring(pet.type)), filter, 1, true)
            or string.find(string.lower(tostring(pet.name)), filter, 1, true) then
                return true
            end
        end
    end
    return false
end

local function renderList(gui)
    local main = gui:FindFirstChild("Main")
    if not main then return end
    local list = main:FindFirstChild("List")
    local status = main:FindFirstChild("Status")
    if not list or not status then return end

    clearList(list)

    local shown = 0
    for _, server in ipairs(currentServers) do
        if matchesFilter(server, currentFilter) then
            addServerCard(list, server)
            shown = shown + 1
        end
    end

    status.Text = string.format("Showing %d / %d servers", shown, #currentServers)
end

local gui, searchBox = createGUI()
print("Viewer GUI started")

searchBox:GetPropertyChangedSignal("Text"):Connect(function()
    currentFilter = searchBox.Text
    renderList(gui)
end)

task.spawn(function()
    while gui and gui.Parent do
        local servers = getData()
        if servers then
            currentServers = servers
            renderList(gui)
        end
        task.wait(CONFIG.REFRESH_EVERY)
    end
end)
