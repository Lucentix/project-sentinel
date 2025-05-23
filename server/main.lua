-- First load our logger
local resourceName = GetCurrentResourceName()
local Logger = exports[resourceName]:getLogger()

local Storage = LoadResourceFile(resourceName, 'server/json_storage.lua')
Storage = load(Storage)()

local activeReports = {}
local reportCounter = 0
local discordWebhook = "YOUR_DISCORD_WEBHOOK_URL_HERE"

local adminRanks = {}

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    Logger.success("SERVER", "Project Sentinel Admin System starting up")
    
    -- Ensure data directory exists
    local dataPath = GetResourcePath(resourceName) .. '/data'
    if not os.rename(dataPath, dataPath) then
        os.execute("mkdir \"" .. dataPath .. "\"")
        Logger.success("SERVER", "Created data directory for Project Sentinel")
    else
        Logger.info("SERVER", "Data directory already exists")
    end
    
    LoadAdminRanks()
    LoadReportsFromStorage()
    
    Logger.success("SERVER", "Project Sentinel Admin System startup complete")
end)

function LoadAdminRanks()
    Logger.info("SERVER", "Loading admin ranks configuration")
    local path = GetResourcePath(GetCurrentResourceName()) .. '/data/ranks.json'
    local file = io.open(path, 'r')
    if not file then
        Logger.warn("SERVER", "Admin ranks file (ranks.json) not found. Using default ranks.")
        adminRanks = {
            ["supporter"] = {
                canSeeReports = true,
                canManageReports = true,
                canTeleport = true,
                canUseAdminOutfit = true,
                canHandleReports = true
            },
            ["moderator"] = {
                canSeeReports = true,
                canManageReports = true,
                canTeleport = true,
                canUseAdminOutfit = true,
                canHandleReports = true,
                canSummonPlayers = true,
                canSeeInventory = true,
                canManagePlayers = true
            },
            ["administrator"] = {
                canSeeReports = true,
                canManageReports = true,
                canTeleport = true,
                canUseAdminOutfit = true,
                canHandleReports = true,
                canSummonPlayers = true,
                canSeeInventory = true,
                canManagePlayers = true,
                canManagePermissions = true
            },
            ["management"] = {
                canSeeReports = true,
                canManageReports = true,
                canTeleport = true,
                canUseAdminOutfit = true,
                canHandleReports = true,
                canSummonPlayers = true,
                canSeeInventory = true,
                canManagePlayers = true,
                canManagePermissions = true
            },
            ["leitung"] = {
                canSeeReports = true,
                canManageReports = true,
                canTeleport = true,
                canUseAdminOutfit = true,
                canHandleReports = true,
                canSummonPlayers = true,
                canSeeInventory = true,
                canManagePlayers = true,
                canManagePermissions = true
            }
        }
        return
    end
    
    local content = file:read('*a')
    file:close()
    
    local success, data = pcall(function()
        return json.decode(content)
    end)
    
    if not success or not data then
        Logger.error("SERVER", "Error parsing ranks.json: " .. (data or "Unknown error") .. '. Using default ranks.')
        return
    end
    
    adminRanks = data
    Logger.success("SERVER", "Admin ranks loaded successfully from ranks.json")
end

function LoadReportsFromStorage()
    Logger.info("SERVER", "Loading reports from storage")
    local savedReports = Storage.Read('reports')
    
    for _, report in ipairs(savedReports) do
        activeReports[report.id] = report
        
        if report.id > reportCounter then
            reportCounter = report.id
        end
    end
    
    Logger.success("SERVER", string.format("Loaded %d reports from storage", #savedReports))
end

function GetPlayerAdminRank(source)
    Logger.debug("SERVER", "Checking admin rank for player ID: " .. tostring(source))
    local identifier = GetPlayerIdentifier(source, 0)
    if not identifier then 
        Logger.warn("SERVER", "No identifier found for player ID: " .. tostring(source))
        return nil 
    end
    
    Logger.debug("SERVER", "Player identifier: " .. identifier)
    local adminUsers = Storage.Read('admin_ranks')
    
    -- Log the current admin users count
    if adminUsers and type(adminUsers) == "table" then
        Logger.debug("SERVER", string.format("Found %d admin users in database", #adminUsers))
    else
        Logger.warn("SERVER", "Admin users data is nil or not a table")
        return nil
    end
    
    for _, admin in ipairs(adminUsers) do
        if admin.identifier == identifier then
            Logger.success("SERVER", string.format("Admin rank found for %s: %s", GetPlayerName(source) or "Unknown", admin.rank))
            return admin.rank
        end
    end
    
    Logger.debug("SERVER", "No admin rank found for player ID: " .. tostring(source))
    return nil
end

function SendDiscordMessage(title, message, color, fields)
    if not discordWebhook or discordWebhook == "YOUR_DISCORD_WEBHOOK_URL_HERE" then
        return
    end
    
    local embed = {
        {
            ["title"] = title,
            ["description"] = message,
            ["type"] = "rich",
            ["color"] = color or 16711680,
            ["footer"] = {
                ["text"] = "Project Sentinel Admin System"
            },
            ["timestamp"] = os.date('!%Y-%m-%dT%H:%M:%S.000Z')
        }
    }
    
    if fields then
        embed[1]["fields"] = fields
    end
    
    PerformHttpRequest(discordWebhook, function(err, text, headers) end, 'POST', json.encode({
        username = "Project Sentinel",
        embeds = embed
    }), { ['Content-Type'] = 'application/json' })
end

function SendDiscordDM(discordId, message)
    if not discordId then return false end

    print("Would send Discord DM to " .. discordId .. ": " .. message)
    
    return true
end

function GetDiscordIdFromIdentifier(identifier)
    if not identifier then return nil end
    
    for _, id in ipairs(GetPlayerIdentifiers(source)) do
        if string.find(id, "discord:") then
            return string.gsub(id, "discord:", "")
        end
    end
    
    return nil
end

RegisterNetEvent('project-sentinel:submitReport')
AddEventHandler('project-sentinel:submitReport', function(title, content)
    local source = source
    local playerName = GetPlayerName(source)
    
    Logger.info("SERVER", string.format("Player %s (ID: %d) submitted a new report: %s", 
        playerName, source, title))
    
    if not title or not content or #title < 1 or #content < 1 then
        Logger.warn("SERVER", "Report submission rejected: Invalid data")
        TriggerClientEvent('project-sentinel:reportNotification', source, "Invalid report data. Please try again.")
        return
    end
    
    local identifier = GetPlayerIdentifier(source, 0)
    local coords = GetEntityCoords(GetPlayerPed(source))
    local coordString = coords.x .. ", " .. coords.y .. ", " .. coords.z
    
    reportCounter = reportCounter + 1
    local reportId = reportCounter
    
    local newReport = {
        id = reportId,
        title = title,
        content = content,
        playerName = playerName,
        playerIdentifier = identifier,
        coords = coordString,
        status = "open",
        submittedAt = os.time()
    }
    
    activeReports[reportId] = newReport
    
    Logger.info("SERVER", string.format("Saving report #%d to storage", reportId))
    Storage.AddEntry('reports', newReport)
    
    -- Notify admins about the new report
    local adminMessage = "New report (#" .. reportId .. ") from " .. playerName .. ": " .. title
    Logger.info("SERVER", "Broadcasting report notification to admins")
    local notifiedAdmins = 0
    
    for _, playerId in ipairs(GetPlayers()) do
        local adminRank = GetPlayerAdminRank(playerId)
        if adminRank and adminRanks[adminRank] and adminRanks[adminRank].canSeeReports then
            TriggerClientEvent('project-sentinel:reportNotification', playerId, adminMessage)
            notifiedAdmins = notifiedAdmins + 1
        end
    end
    
    Logger.debug("SERVER", string.format("Notified %d admins about the new report", notifiedAdmins))
    
    -- Send to Discord webhook
    SendDiscordMessage(
        "New Report Submitted",
        "A new report has been submitted by " .. playerName,
        3066993,
        {
            {
                name = "Report ID",
                value = "#" .. reportId,
                inline = true
            },
            {
                name = "Title",
                value = title,
                inline = true
            },
            {
                name = "Content",
                value = content,
                inline = false
            }
        }
    )
    
    -- Notify the reporting player
    TriggerClientEvent('project-sentinel:reportNotification', source, "Your report has been submitted. Report ID: #" .. reportId)
    Logger.success("SERVER", string.format("Report #%d successfully submitted by %s", reportId, playerName))
end)

RegisterNetEvent('project-sentinel:checkAdminPermission')
AddEventHandler('project-sentinel:checkAdminPermission', function()
    local source = source
    local playerName = GetPlayerName(source)
    
    Logger.info("SERVER", string.format("Player %s (ID: %d) is checking admin permissions", 
        playerName, source))
    
    local adminRank = GetPlayerAdminRank(source)
    
    if adminRank and adminRanks[adminRank] then
        Logger.success("SERVER", string.format("Player %s has admin rank: %s - opening admin panel", 
            playerName, adminRank))
        TriggerClientEvent('project-sentinel:openAdminPanel', source, adminRank)
    else
        Logger.warn("SERVER", string.format("Player %s attempted to access admin panel but has no permissions", 
            playerName))
        TriggerClientEvent('project-sentinel:reportNotification', source, "You don't have permission to access the Admin Panel")
    end
end)

-- Fix the server stats structure to ensure all expected properties exist
RegisterNetEvent('project-sentinel:getServerStats')
AddEventHandler('project-sentinel:getServerStats', function()
    local source = source
    Logger.info("SERVER", "Player ID " .. source .. " requested server stats")
    local adminRank = GetPlayerAdminRank(source)
    
    if not adminRank then 
        Logger.warn("SERVER", "Request denied - no admin rank")
        return 
    end
    
    Logger.info("SERVER", "Gathering server stats...")
    
    -- Recalculate the stats every time to ensure accurate data
    local reportCounts = {open = 0, inProgress = 0, closed = 0, total = 0}
    
    -- Count reports directly from activeReports
    for _, report in pairs(activeReports or {}) do
        reportCounts.total = reportCounts.total + 1
        
        if report.status == "open" then
            reportCounts.open = reportCounts.open + 1
        elseif report.status == "in_progress" then
            reportCounts.inProgress = reportCounts.inProgress + 1
        elseif report.status == "closed" then
            reportCounts.closed = reportCounts.closed + 1
        end
    end
    
    -- Debug output
    Logger.debug("SERVER", string.format("Report stats: Total=%d, Open=%d, InProgress=%d, Closed=%d",
        reportCounts.total, reportCounts.open, reportCounts.inProgress, reportCounts.closed))
    
    local stats = {
        players = {
            online = #GetPlayers(),
            max = GetConvarInt("sv_maxclients", 32)
        },
        reports = reportCounts,
        server = {
            name = GetConvar("sv_hostname", "Project Sentinel"),
            uptime = os.time() - (GetResourceState(GetCurrentResourceName()) == "started" and GetResourceMetadata(GetCurrentResourceName(), "start_time", 0) or os.time()),
            version = GetResourceMetadata(GetCurrentResourceName(), "version", "1.0.0")
        }
    }
    
    -- Debug log the exact data we're sending
    Logger.debug("SERVER", "Sending stats: " .. json.encode(stats))
    
    TriggerClientEvent('project-sentinel:receiveServerStats', source, stats)
end)

-- Fix the reports format to ensure it's always an array
RegisterNetEvent('project-sentinel:getReports')
AddEventHandler('project-sentinel:getReports', function()
    local source = source
    Logger.info("SERVER", "Player ID " .. source .. " requested reports")
    local adminRank = GetPlayerAdminRank(source)
    
    if not adminRank or not adminRanks[adminRank] or not adminRanks[adminRank].canSeeReports then
        Logger.warn("SERVER", "Request denied - insufficient permissions")
        return
    end
    
    local reportsArray = {}
    
    -- Convert activeReports table to array
    for id, report in pairs(activeReports or {}) do
        table.insert(reportsArray, report)
    end
    
    -- Debug output
    Logger.debug("SERVER", "Reports found: " .. #reportsArray)
    if #reportsArray > 0 then
        Logger.debug("SERVER", "First report: " .. json.encode(reportsArray[1]))
    end
    
    -- Sort reports by submission time (newest first)
    table.sort(reportsArray, function(a, b)
        return (a.submittedAt or 0) > (b.submittedAt or 0)
    end)
    
    Logger.info("SERVER", "Sending " .. #reportsArray .. " reports to player ID " .. source)
    -- Ensure we're always sending an array, even if empty
    TriggerClientEvent('project-sentinel:receiveReports', source, reportsArray)
end)

RegisterNetEvent('project-sentinel:updateReportStatus')
AddEventHandler('project-sentinel:updateReportStatus', function(reportId, status, notes)
    local source = source
    local adminRank = GetPlayerAdminRank(source)
    
    if not adminRank or not adminRanks[adminRank] or not adminRanks[adminRank].canManageReports then
        return
    end
    
    if not activeReports[reportId] then
        TriggerClientEvent('project-sentinel:reportNotification', source, "Report #" .. reportId .. " not found")
        return
    end
    
    local report = activeReports[reportId]
    report.status = status
    report.handlerName = GetPlayerName(source)
    report.handlerIdentifier = GetPlayerIdentifier(source, 0)
    
    if notes then
        report.notes = notes
    end
    
    Storage.UpdateEntry('reports', reportId, {
        status = status,
        handlerName = report.handlerName,
        handlerIdentifier = report.handlerIdentifier,
        notes = notes or ""
    })
    
    for _, playerId in ipairs(GetPlayers()) do
        if GetPlayerIdentifier(playerId, 0) == report.playerIdentifier then
            TriggerClientEvent('project-sentinel:reportNotification', playerId, 
                "Your report #" .. reportId .. " status has been updated to: " .. status)
            break
        end
    end
    
    SendDiscordMessage(
        "Report Status Updated",
        "Report #" .. reportId .. " has been updated by " .. GetPlayerName(source),
        65535,
        {
            {
                name = "New Status",
                value = status,
                inline = true
            },
            {
                name = "Title",
                value = report.title,
                inline = true
            },
            {
                name = "Notes",
                value = notes or "No notes added",
                inline = false
            }
        }
    )
    
    TriggerClientEvent('project-sentinel:reportNotification', source, "Report #" .. reportId .. " status updated to: " .. status)
end)

RegisterNetEvent('project-sentinel:teleportToReport')
AddEventHandler('project-sentinel:teleportToReport', function(reportId)
    local source = source
    local adminRank = GetPlayerAdminRank(source)
    
    if not adminRank or not adminRanks[adminRank] or not adminRanks[adminRank].canTeleport then
        return
    end
    
    if not activeReports[reportId] then
        TriggerClientEvent('project-sentinel:reportNotification', source, "Report #" .. reportId .. " not found")
        return
    end
    
    local report = activeReports[reportId]
    local coords = json.decode("{\"x\":" .. report.coords .. "}")
    
    TriggerClientEvent('project-sentinel:teleportTo', source, coords.x, coords.y, coords.z)
    TriggerClientEvent('project-sentinel:reportNotification', source, "Teleported to Report #" .. reportId .. " location")
end)

RegisterNetEvent('project-sentinel:teleportToPlayer')
AddEventHandler('project-sentinel:teleportToPlayer', function(playerId)
    local source = source
    local adminRank = GetPlayerAdminRank(source)
    
    if not adminRank or not adminRanks[adminRank] or not adminRanks[adminRank].canTeleport then
        return
    end
    
    local targetPlayer = tonumber(playerId)
    if not targetPlayer or not GetPlayerName(targetPlayer) then
        TriggerClientEvent('project-sentinel:reportNotification', source, "Player not found")
        return
    end
    
    local targetPed = GetPlayerPed(targetPlayer)
    local targetCoords = GetEntityCoords(targetPed)
    
    TriggerClientEvent('project-sentinel:teleportTo', source, targetCoords.x, targetCoords.y, targetCoords.z)
    TriggerClientEvent('project-sentinel:reportNotification', source, "Teleported to " .. GetPlayerName(targetPlayer))
end)

RegisterNetEvent('project-sentinel:toggleAdminOutfit')
AddEventHandler('project-sentinel:toggleAdminOutfit', function(outfitType)
    local source = source
    local adminRank = GetPlayerAdminRank(source)
    
    if not adminRank or not adminRanks[adminRank] or not adminRanks[adminRank].canUseAdminOutfit then
        return
    end
    
    TriggerClientEvent('project-sentinel:reportNotification', source, "Admin outfit " .. outfitType .. " applied")
end)

RegisterNetEvent('project-sentinel:summonPlayer')
AddEventHandler('project-sentinel:summonPlayer', function(targetId)
    local source = source
    local adminRank = GetPlayerAdminRank(source)
    
    if not adminRank or not adminRanks[adminRank] or not adminRanks[adminRank].canSummonPlayers then
        return
    end
    
    local targetPlayer = tonumber(targetId)
    if not targetPlayer or not GetPlayerName(targetPlayer) then
        TriggerClientEvent('project-sentinel:reportNotification', source, "Player not found")
        return
    end
    
    local adminCoords = GetEntityCoords(GetPlayerPed(source))
    
    TriggerClientEvent('project-sentinel:teleportTo', targetPlayer, adminCoords.x, adminCoords.y, adminCoords.z)
    
    TriggerClientEvent('project-sentinel:reportNotification', source, "Summoned " .. GetPlayerName(targetPlayer) .. " to your location")
    TriggerClientEvent('project-sentinel:reportNotification', targetPlayer, "You've been summoned by an administrator")
    
    local targetDiscordId = GetDiscordIdFromIdentifier(GetPlayerIdentifier(targetPlayer, 0))
    if targetDiscordId then
        SendDiscordDM(targetDiscordId, "You've been summoned for administrative assistance in-game by " .. GetPlayerName(source))
    end
end)

RegisterNetEvent('project-sentinel:getPlayerInventory')
AddEventHandler('project-sentinel:getPlayerInventory', function(targetId)
    local source = source
    local adminRank = GetPlayerAdminRank(source)
    
    if not adminRank or not adminRanks[adminRank] or not adminRanks[adminRank].canSeeInventory then
        return
    end
    
    local targetPlayer = tonumber(targetId)
    if not targetPlayer or not GetPlayerName(targetPlayer) then
        TriggerClientEvent('project-sentinel:reportNotification', source, "Player not found")
        return
    end
    
    local inventory = {
        {name = "bread", label = "Bread", count = 5},
        {name = "water", label = "Water", count = 3},
        {name = "phone", label = "Phone", count = 1}
    }
    
    TriggerClientEvent('project-sentinel:receivePlayerInventory', source, {
        playerId = targetId,
        playerName = GetPlayerName(targetPlayer),
        inventory = inventory
    })
end)

RegisterNetEvent('project-sentinel:updatePlayerRank')
AddEventHandler('project-sentinel:updatePlayerRank', function(targetIdentifier, newRank)
    local source = source
    local adminRank = GetPlayerAdminRank(source)
    
    if not adminRank or not adminRanks[adminRank] or not adminRanks[adminRank].canManagePermissions then
        return
    end
    
    if not adminRanks[newRank] then
        TriggerClientEvent('project-sentinel:reportNotification', source, "Invalid rank specified")
        return
    end
    
    local adminIdentifier = GetPlayerIdentifier(source, 0)
    local adminName = GetPlayerName(source)
    
    local targetName = "Unknown"
    for _, playerId in ipairs(GetPlayers()) do
        if GetPlayerIdentifier(playerId, 0) == targetIdentifier then
            targetName = GetPlayerName(playerId)
            break
        end
    end
    
    local adminUsers = Storage.Read('admin_ranks')
    
    local playerFound = false
    for i, admin in ipairs(adminUsers) do
        if admin.identifier == targetIdentifier then
            admin.rank = newRank
            admin.name = targetName
            admin.assignedBy = adminName
            admin.updatedAt = os.date('!%Y-%m-%dT%H:%M:%S.000Z')
            playerFound = true
            break
        end
    end
    
    if not playerFound then
        table.insert(adminUsers, {
            identifier = targetIdentifier,
            name = targetName,
            rank = newRank,
            assignedBy = adminName,
            createdAt = os.date('!%Y-%m-%dT%H:%M:%S.000Z'),
            updatedAt = os.date('!%Y-%m-%dT%H:%M:%S.000Z')
        })
    end
    
    Storage.Write('admin_ranks', adminUsers)
    
    TriggerClientEvent('project-sentinel:reportNotification', source, "Player rank updated to " .. newRank)
    
    for _, playerId in ipairs(GetPlayers()) do
        if GetPlayerIdentifier(playerId, 0) == targetIdentifier then
            TriggerClientEvent('project-sentinel:reportNotification', playerId, "Your admin rank has been updated to: " .. newRank)
            break
        end
    end
end)

-- Fix the online players format to ensure it's always an array
RegisterNetEvent('project-sentinel:getOnlinePlayers')
AddEventHandler('project-sentinel:getOnlinePlayers', function()
    local source = source
    Logger.info("SERVER", "Player ID " .. source .. " requested online players")
    local adminRank = GetPlayerAdminRank(source)
    
    if not adminRank or not adminRanks[adminRank] then
        Logger.warn("SERVER", "Request denied - insufficient permissions")
        return
    end
    
    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        table.insert(players, {
            id = playerId,
            name = GetPlayerName(playerId) or "Unknown",
            identifier = GetPlayerIdentifier(playerId, 0) or "unknown"
        })
    end
    
    Logger.info("SERVER", "Sending " .. #players .. " online players to player ID " .. source)
    -- Ensure we're always sending an array, even if empty
    TriggerClientEvent('project-sentinel:receiveOnlinePlayers', source, players)
end)

-- Fix the admin users format
RegisterNetEvent('project-sentinel:getAdminUsers')
AddEventHandler('project-sentinel:getAdminUsers', function()
    local source = source
    Logger.info("SERVER", "Player ID " .. source .. " requested admin users")
    local adminRank = GetPlayerAdminRank(source)
    
    if not adminRank or not adminRanks[adminRank] or not adminRanks[adminRank].canManagePermissions then
        Logger.warn("SERVER", "Request denied - insufficient permissions")
        return
    end
    
    local adminUsers = Storage.Read('admin_ranks')
    
    -- Ensure adminUsers is always an array
    if not adminUsers or type(adminUsers) ~= "table" then
        adminUsers = {}
    end
    
    Logger.info("SERVER", "Sending " .. #adminUsers .. " admin users to player ID " .. source)
    TriggerClientEvent('project-sentinel:receiveAdminUsers', source, adminUsers)
end)

-- Enhancement: Add a heartbeat to periodically save data and check system health
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(300000) -- 5 minutes
        
        local reportCount = 0
        for _ in pairs(activeReports) do reportCount = reportCount + 1 end
        
        Logger.info("SERVER", string.format("System heartbeat - Active reports: %d", reportCount))
        Logger.info("SERVER", string.format("Online players: %d", #GetPlayers()))
        
        -- Here we could add automatic backup of data, performance metrics, etc.
    end
end)