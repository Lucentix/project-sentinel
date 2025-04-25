local Storage = LoadResourceFile(GetCurrentResourceName(), 'server/json_storage.lua')
Storage = load(Storage)()

local activeReports = {}
local reportCounter = 0
local discordWebhook = "YOUR_DISCORD_WEBHOOK_URL_HERE"

local adminRanks = {}

-- Function to ensure ranks file exists
function EnsureRanksFileExists()
    local path = GetResourcePath(GetCurrentResourceName()) .. '/data/ranks.json'
    local file = io.open(path, 'r')
    
    if not file then
        print("^3Creating default ranks.json file^0")
        
        local defaultRanks = {
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
        
        file = io.open(path, 'w+')
        if file then
            file:write(json.encode(defaultRanks, {indent = true}))
            file:close()
            print("^2Default ranks.json file created successfully^0")
        else
            print("^1Failed to create default ranks.json file^0")
        end
        
        return defaultRanks
    else
        local content = file:read('*a')
        file:close()
        
        local success, ranks = pcall(function() return json.decode(content) end)
        if not success then
            print("^1Error parsing ranks.json file: " .. ranks .. "^0")
            return {}
        end
        
        return ranks
    end
end

AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    print('^2Project Sentinel Admin System has started^0')
    
    -- Ensure ranks file exists
    adminRanks = EnsureRanksFileExists()
    LoadAdminRanks()
    LoadReportsFromStorage()
end)

function LoadAdminRanks()
    local path = GetResourcePath(GetCurrentResourceName()) .. '/data/ranks.json'
    local file = io.open(path, 'r')
    if not file then
        print('^1Error: Admin ranks file (ranks.json) not found. Using default ranks.^0')
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
        print('^1Error parsing ranks.json: ' .. (data or "Unknown error") .. '. Using default ranks.^0')
        return
    end
    
    adminRanks = data
    print('^2Admin ranks loaded successfully from ranks.json^0')
end

function LoadReportsFromStorage()
    local savedReports = Storage.Read('reports')
    
    for _, report in ipairs(savedReports) do
        activeReports[report.id] = report
        
        if report.id > reportCounter then
            reportCounter = report.id
        end
    end
    
    print('^2Loaded ' .. #savedReports .. ' reports from storage^0')
end

function GetPlayerAdminRank(source)
    local identifier = GetPlayerIdentifier(source, 0)
    if not identifier then return nil end
    
    local adminUsers = Storage.Read('admin_ranks')
    
    for _, admin in ipairs(adminUsers) do
        if admin.identifier == identifier then
            return admin.rank
        end
    end
    
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
    
    Storage.AddEntry('reports', newReport)
    
    local adminMessage = "New report (#" .. reportId .. ") from " .. playerName .. ": " .. title
    for _, playerId in ipairs(GetPlayers()) do
        local adminRank = GetPlayerAdminRank(playerId)
        if adminRank and adminRanks[adminRank] and adminRanks[adminRank].canSeeReports then
            TriggerClientEvent('project-sentinel:reportNotification', playerId, adminMessage)
        end
    end
    
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
    
    TriggerClientEvent('project-sentinel:reportNotification', source, "Your report has been submitted. Report ID: #" .. reportId)
end)

RegisterNetEvent('project-sentinel:checkAdminPermission')
AddEventHandler('project-sentinel:checkAdminPermission', function()
    local source = source
    local adminRank = GetPlayerAdminRank(source)
    
    if adminRank and adminRanks[adminRank] then
        TriggerClientEvent('project-sentinel:openAdminPanel', source, adminRank)
    else
        TriggerClientEvent('project-sentinel:reportNotification', source, "You don't have permission to access the Admin Panel")
    end
end)

RegisterNetEvent('project-sentinel:getServerStats')
AddEventHandler('project-sentinel:getServerStats', function()
    local source = source
    local adminRank = GetPlayerAdminRank(source)
    
    if not adminRank then return end
    
    local stats = {
        players = {
            online = #GetPlayers(),
            max = GetConvarInt("sv_maxclients", 32)
        },
        reports = {
            total = reportCounter,
            open = 0,
            inProgress = 0,
            closed = 0
        }
    }
    
    for _, report in pairs(activeReports) do
        if report.status == "open" then
            stats.reports.open = stats.reports.open + 1
        elseif report.status == "in_progress" then
            stats.reports.inProgress = stats.reports.inProgress + 1
        elseif report.status == "closed" then
            stats.reports.closed = stats.reports.closed + 1
        end
    end
    
    TriggerClientEvent('project-sentinel:receiveServerStats', source, stats)
end)

RegisterNetEvent('project-sentinel:getReports')
AddEventHandler('project-sentinel:getReports', function()
    local source = source
    local adminRank = GetPlayerAdminRank(source)
    
    if not adminRank or not adminRanks[adminRank] or not adminRanks[adminRank].canSeeReports then
        return
    end
    
    local reportsArray = {}
    for _, report in pairs(activeReports) do
        table.insert(reportsArray, report)
    end
    
    table.sort(reportsArray, function(a, b)
        return a.submittedAt > b.submittedAt
    end)
    
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

RegisterNetEvent('project-sentinel:getOnlinePlayers')
AddEventHandler('project-sentinel:getOnlinePlayers', function()
    local source = source
    local adminRank = GetPlayerAdminRank(source)
    
    if not adminRank or not adminRanks[adminRank] then
        return
    end
    
    local players = {}
    for _, playerId in ipairs(GetPlayers()) do
        table.insert(players, {
            id = playerId,
            name = GetPlayerName(playerId),
            identifier = GetPlayerIdentifier(playerId, 0)
        })
    end
    
    TriggerClientEvent('project-sentinel:receiveOnlinePlayers', source, players)
end)

RegisterNetEvent('project-sentinel:getAdminUsers')
AddEventHandler('project-sentinel:getAdminUsers', function()
    local source = source
    local adminRank = GetPlayerAdminRank(source)
    
    if not adminRank or not adminRanks[adminRank] or not adminRanks[adminRank].canManagePermissions then
        return
    end
    
    local adminUsers = Storage.Read('admin_ranks')
    
    TriggerClientEvent('project-sentinel:receiveAdminUsers', source, adminUsers)
end)