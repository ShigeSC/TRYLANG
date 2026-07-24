--[[
    Inferno Scanner + Hop
    Stores up to 20 servers (removes oldest)
]]

local TRADE_WORLD_PLACE_ID = 129954712878723
if game.PlaceId ~= TRADE_WORLD_PLACE_ID then return end

local CONFIG = {
    JSONBIN_ID = "6a63b2fcda38895dfe8b51c7",
    JSONBIN_API_KEY = "$2a$10$nYqa4kNpOA9gvcy1vopkGuZyNZiIhAf2LYj1zRQqUzIOAzYxWHfp2",
    HOP_DELAY = 8,
    MIN_PLAYERS = 15,
    MAX_PLAYERS = 25,
    MIN_PRICE = 400,
    MAX_PRICE = 800,
    MAX_STORED = 20,
    VISITED_FILE = "visited_servers.txt",
}

print("=== Scanner Starting ===")
task.wait(12)

local Modules = game.ReplicatedStorage:WaitForChild("Modules", 20)
if not Modules then return end
local TradeBoothControllers = Modules:WaitForChild("TradeBoothControllers", 10)
if not TradeBoothControllers then return end

local ListingController = require(TradeBoothControllers:WaitForChild("TradeBoothListingController"))
local PetMutationRegistry = require(game.ReplicatedStorage.Data.PetRegistry.PetMutationRegistry)
local EnumToName = PetMutationRegistry.EnumToPetMutation or {}

local HttpService = game:GetService("HttpService")
local TeleportService = game:GetService("TeleportService")
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local PlaceId = game.PlaceId
local JobId = game.JobId

local requestFunc = request or http_request or (syn and syn.request)

local function loadVisited()
    local visited = {}
    local ok, content = pcall(readfile, CONFIG.VISITED_FILE)
    if ok and content then
        for id in string.gmatch(content, "[^\r\n]+") do
            if id ~= "" then visited[id] = true end
        end
    end
    return visited
end

local function saveVisited(visited)
    local lines = {}
    for id in pairs(visited) do table.insert(lines, id) end
    pcall(writefile, CONFIG.VISITED_FILE, table.concat(lines, "\n"))
end

local visitedServers = loadVisited()
visitedServers[JobId] = true
saveVisited(visitedServers)

local function getMutationName(code)
    if not code or code == "" then return "None" end
    return EnumToName[tostring(code)] or tostring(code)
end

local function getCurrentWeight(base, level)
    if not base or not level then return "?" end
    return string.format("%.2fkg", base * (1 + level * 0.1))
end

local function getJoinLink()
    return string.format("https://www.roblox.com/games/start?placeId=%d&gameInstanceId=%s", PlaceId, JobId)
end

local function scanBooths()
    local results = {}
    local TradeWorld = workspace:FindFirstChild("TradeWorld")
    if not TradeWorld then return results end
    local Booths = TradeWorld:FindFirstChild("Booths")
    if not Booths then return results end

    for _, booth in ipairs(Booths:GetChildren()) do
        pcall(function()
            if ListingController.SetBooth then ListingController:SetBooth(booth.Name) end
            ListingController.BoothUUID = booth.Name
            if ListingController.RefreshDisplay then ListingController:RefreshDisplay() end
        end)
        task.wait(0.25)

        local ok, inventory = pcall(function() return ListingController:GetInventory() end)
        if ok and typeof(inventory) == "table" and #inventory > 0 then
            local owner = tostring(inventory[1].listingOwner or "?")
            local pets = {}
            for _, listing in ipairs(inventory) do
                local data = listing.data or {}
                local petData = data.PetData or {}
                local mutation = getMutationName(petData.MutationType)
                local price = tonumber(listing.listingPrice) or 0
                if mutation == "Inferno" and price >= CONFIG.MIN_PRICE and price <= CONFIG.MAX_PRICE then
                    table.insert(pets, {
                        type = tostring(data.PetType or "?"),
                        name = tostring(petData.Name or "?"),
                        weight = getCurrentWeight(petData.BaseWeight, petData.Level),
                        level = tostring(petData.Level or "?"),
                        price = price
                    })
                end
            end
            if #pets > 0 then
                table.insert(results, {owner = owner, pets = pets})
            end
        end
    end
    return results
end

local function getStoredServers()
    if not requestFunc then return {} end
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
    return {}
end

local function uploadResults(results)
    if #results == 0 then
        print("No matching pets → not uploading")
        return
    end
    if not requestFunc then return end

    local servers = getStoredServers()

    -- Remove if same jobId already exists
    for i = #servers, 1, -1 do
        if servers[i].jobId == JobId then
            table.remove(servers, i)
        end
    end

    -- Add new server at the front
    table.insert(servers, 1, {
        jobId = JobId,
        placeId = PlaceId,
        link = getJoinLink(),
        robloxLink = string.format("roblox://experiences/start?placeId=%d&gameInstanceId=%s", PlaceId, JobId),
        players = #Players:GetPlayers(),
        time = os.date("%H:%M:%S"),
        booths = results
    })

    -- Keep only last 20
    while #servers > CONFIG.MAX_STORED do
        table.remove(servers) -- remove oldest (end of list)
    end

    local payload = { servers = servers }

    local response = requestFunc({
        Url = "https://api.jsonbin.io/v3/b/" .. CONFIG.JSONBIN_ID,
        Method = "PUT",
        Headers = {
            ["Content-Type"] = "application/json",
            ["X-Access-Key"] = CONFIG.JSONBIN_API_KEY
        },
        Body = HttpService:JSONEncode(payload)
    })

    if response and (response.StatusCode == 200 or response.StatusCode == 201) then
        print("✅ Uploaded | Total servers stored:", #servers)
    else
        print("❌ Upload failed:", response and response.StatusCode)
    end
end

local function serverHop()
    if not requestFunc then return end
    local tried = {}
    local originalJobId = game.JobId

    for attempt = 1, 35 do
        local response = requestFunc({
            Url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100",
            Method = "GET"
        })
        if response and response.Body then
            local ok, data = pcall(function() return HttpService:JSONDecode(response.Body) end)
            if ok and data and data.data then
                for _, server in ipairs(data.data) do
                    local sid = server.id
                    if server.playing >= CONFIG.MIN_PLAYERS and server.playing <= CONFIG.MAX_PLAYERS
                    and sid ~= originalJobId and not tried[sid] and not visitedServers[sid] then
                        tried[sid] = true
                        print("Hopping →", sid, server.playing)
                        pcall(function()
                            TeleportService:TeleportToPlaceInstance(PlaceId, sid, LocalPlayer)
                        end)
                        for i = 1, 6 do
                            task.wait(1)
                            if game.JobId ~= originalJobId then return end
                        end
                    end
                end
            end
        end
        task.wait(1.5)
    end
    pcall(function() TeleportService:Teleport(PlaceId) end)
end

local results = scanBooths()
uploadResults(results)
task.wait(CONFIG.HOP_DELAY)
serverHop()
