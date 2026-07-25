--[[
    Inferno Scanner + Hop
    Never joins a JobId already visited by Acc 1 or Acc 2
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
    MAX_VISITED = 100,
    LOCAL_VISITED_FILE = "visited_servers.txt",
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

local function getMutationName(code)
    if not code or code == "" then return "None" end
    return EnumToName[tostring(code)] or tostring(code)
end

local function getCurrentWeight(base, level)
    if not base or not level then return "?" end
    return string.format("%.2fkg", base * (1 + level * 0.1))
end

local function getJoinLink()
    return string.format(
        "https://www.roblox.com/games/start?placeId=%d&gameInstanceId=%s",
        PlaceId, JobId
    )
end

local function getRobloxLink()
    return string.format(
        "roblox://experiences/start?placeId=%d&gameInstanceId=%s",
        PlaceId, JobId
    )
end

-- ========== Local visited ==========
local function loadLocalVisited()
    local t = {}
    local ok, content = pcall(readfile, CONFIG.LOCAL_VISITED_FILE)
    if ok and content then
        for id in string.gmatch(content, "[^\r\n]+") do
            if id ~= "" then t[id] = true end
        end
    end
    return t
end

local function saveLocalVisited(map)
    local lines = {}
    for id in pairs(map) do
        table.insert(lines, id)
    end
    pcall(writefile, CONFIG.LOCAL_VISITED_FILE, table.concat(lines, "\n"))
end

local localVisited = loadLocalVisited()
localVisited[JobId] = true
saveLocalVisited(localVisited)

-- ========== Shared JSONBin ==========
local function getSharedData()
    if not requestFunc then
        return { servers = {}, visited = {} }
    end

    local response = requestFunc({
        Url = "https://api.jsonbin.io/v3/b/" .. CONFIG.JSONBIN_ID .. "/latest",
        Method = "GET",
        Headers = { ["X-Access-Key"] = CONFIG.JSONBIN_API_KEY }
    })

    if response and response.Body then
        local ok, data = pcall(function()
            return HttpService:JSONDecode(response.Body)
        end)
        if ok and data and data.record then
            return {
                servers = data.record.servers or {},
                visited = data.record.visited or {}
            }
        end
    end
    return { servers = {}, visited = {} }
end

local function saveSharedData(servers, visited)
    if not requestFunc then return false end
    local response = requestFunc({
        Url = "https://api.jsonbin.io/v3/b/" .. CONFIG.JSONBIN_ID,
        Method = "PUT",
        Headers = {
            ["Content-Type"] = "application/json",
            ["X-Access-Key"] = CONFIG.JSONBIN_API_KEY
        },
        Body = HttpService:JSONEncode({
            servers = servers or {},
            visited = visited or {}
        })
    })
    return response and (response.StatusCode == 200 or response.StatusCode == 201)
end

local function addVisited(jobId)
    localVisited[jobId] = true
    saveLocalVisited(localVisited)

    local data = getSharedData()
    local visited = data.visited
    local servers = data.servers

    local found = false
    for _, id in ipairs(visited) do
        if id == jobId then
            found = true
            break
        end
    end

    if not found then
        table.insert(visited, 1, jobId)
        while #visited > CONFIG.MAX_VISITED do
            table.remove(visited)
        end
        saveSharedData(servers, visited)
    end

    return visited, servers
end

local function getFullVisitedMap()
    local data = getSharedData()
    local map = {}

    for id in pairs(localVisited) do
        map[id] = true
    end
    for _, id in ipairs(data.visited or {}) do
        map[id] = true
    end
    for _, s in ipairs(data.servers or {}) do
        if s.jobId then
            map[s.jobId] = true
        end
    end
    map[JobId] = true

    return map, data.visited or {}, data.servers or {}
end

-- ========== Scan ==========
local function scanBooths()
    local results = {}
    local TradeWorld = workspace:FindFirstChild("TradeWorld")
    if not TradeWorld then return results end
    local Booths = TradeWorld:FindFirstChild("Booths")
    if not Booths then return results end

    for _, booth in ipairs(Booths:GetChildren()) do
        pcall(function()
            if ListingController.SetBooth then
                ListingController:SetBooth(booth.Name)
            end
            ListingController.BoothUUID = booth.Name
            if ListingController.RefreshDisplay then
                ListingController:RefreshDisplay()
            end
        end)
        task.wait(0.25)

        local ok, inventory = pcall(function()
            return ListingController:GetInventory()
        end)

        if ok and typeof(inventory) == "table" and #inventory > 0 then
            local owner = tostring(inventory[1].listingOwner or "?")
            local pets = {}

            for _, listing in ipairs(inventory) do
                local data = listing.data or {}
                local petData = data.PetData or {}
                local mutation = getMutationName(petData.MutationType)
                local price = tonumber(listing.listingPrice) or 0

                if mutation == "Inferno"
                and price >= CONFIG.MIN_PRICE
                and price <= CONFIG.MAX_PRICE then
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
                table.insert(results, {
                    owner = owner,
                    pets = pets
                })
            end
        end
    end

    return results
end

-- ========== Upload ==========
local function uploadResults(results)
    addVisited(JobId)

    if #results == 0 then
        print("No matching pets → not uploading")
        return
    end

    local _, visited, servers = getFullVisitedMap()

    for i = #servers, 1, -1 do
        if servers[i].jobId == JobId then
            table.remove(servers, i)
        end
    end

    table.insert(servers, 1, {
        jobId = JobId,
        placeId = PlaceId,
        link = getJoinLink(),
        robloxLink = getRobloxLink(),
        players = #Players:GetPlayers(),
        time = os.date("%H:%M:%S"),
        booths = results
    })

    while #servers > CONFIG.MAX_STORED do
        table.remove(servers)
    end

    if saveSharedData(servers, visited) then
        print("✅ Uploaded | Stored:", #servers)
    else
        print("❌ Upload failed")
    end
end

-- ========== Hop (never revisit) ==========
local function serverHop()
    if not requestFunc then return end

    addVisited(JobId)

    local visitedMap = getFullVisitedMap()
    local tried = {}
    local originalJobId = game.JobId

    local count = 0
    for _ in pairs(visitedMap) do
        count = count + 1
    end
    print("Blocked JobIds:", count)

    for attempt = 1, 50 do
        print("Looking for NEW unvisited server... (" .. attempt .. "/50)")

        if attempt % 3 == 0 then
            visitedMap = getFullVisitedMap()
        end

        local response = requestFunc({
            Url = "https://games.roblox.com/v1/games/" .. PlaceId .. "/servers/Public?sortOrder=Desc&limit=100",
            Method = "GET"
        })

        if response and response.Body then
            local ok, list = pcall(function()
                return HttpService:JSONDecode(response.Body)
            end)

            if ok and list and list.data then
                for _, server in ipairs(list.data) do
                    local sid = server.id

                    if server.playing >= CONFIG.MIN_PLAYERS
                    and server.playing <= CONFIG.MAX_PLAYERS
                    and sid ~= originalJobId
                    and not tried[sid]
                    and not visitedMap[sid] then

                        -- mark BEFORE teleport so other account skips it
                        tried[sid] = true
                        addVisited(sid)
                        visitedMap[sid] = true

                        print("Hopping →", sid, "| Players:", server.playing)

                        pcall(function()
                            TeleportService:TeleportToPlaceInstance(PlaceId, sid, LocalPlayer)
                        end)

                        for i = 1, 7 do
                            task.wait(1)
                            if game.JobId ~= originalJobId then
                                print("Teleport success →", game.JobId)
                                addVisited(game.JobId)
                                return
                            end
                        end

                        print("Teleport failed, trying next unvisited...")
                    end
                end
            end
        end

        task.wait(2)
    end

    -- NO random Teleport(PlaceId) fallback
    print("No new unvisited server found — waiting 8s then retrying hop")
    task.wait(8)
    serverHop()
end

-- ========== Main ==========
print("Current JobId:", JobId)
addVisited(JobId)

local results = scanBooths()
uploadResults(results)

print("Waiting", CONFIG.HOP_DELAY, "s before hop...")
task.wait(CONFIG.HOP_DELAY)
serverHop()
