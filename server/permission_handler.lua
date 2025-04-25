-- Permission Handler for Project Sentinel

-- First load our logger
local resourceName = GetCurrentResourceName()
local Logger = exports[resourceName]:getLogger()

local Storage = LoadResourceFile(GetCurrentResourceName(), 'server/json_storage.lua')
Storage = load(Storage)()

Logger.info("PERMISSIONS", "Initializing permission handler")

-- Function to find a player by ID or partial name
local function FindPlayer(identifier)
    Logger.debug("PERMISSIONS", "Looking for player with identifier: " .. tostring(identifier))
    
    -- If input is a number, try to find by ID
    if tonumber(identifier) then
        local id = tonumber(identifier)
        if GetPlayerName(id) then
            local playerIdentifier = GetPlayerIdentifier(id, 0)
            Logger.success("PERMISSIONS", string.format("Found player by ID: %d - %s with identifier %s", 
                id, GetPlayerName(id), playerIdentifier))
            return id, playerIdentifier
        end
    end
    
    -- Otherwise try to find by name (can be partial)
    local players = GetPlayers()
    Logger.debug("PERMISSIONS", string.format("Searching %d online players for name match", #players))
    
    for _, playerId in ipairs(players) do
        local name = GetPlayerName(playerId)
        if name and string.find(string.lower(name), string.lower(identifier)) then
            local playerIdentifier = GetPlayerIdentifier(playerId, 0)
            Logger.success("PERMISSIONS", string.format("Found player by name: %s (ID: %s) with identifier %s", 
                name, playerId, playerIdentifier))
            return playerId, playerIdentifier
        end
    end
    
    Logger.warn("PERMISSIONS", "Player not found: " .. tostring(identifier))
    return nil
end

-- Function to check if a player has permissions to manage admins
local function CanManageAdmins(source)
    local playerName = GetPlayerName(source) or "Unknown"
    Logger.debug("PERMISSIONS", string.format("Checking if player %s (ID: %d) can manage admins", 
        playerName, source))
        
    local adminRank = GetPlayerAdminRank(source)
    if not adminRank then 
        Logger.debug("PERMISSIONS", string.format("Player %s has no admin rank", playerName))
        return false 
    end
    
    Logger.debug("PERMISSIONS", string.format("Player %s has rank: %s", playerName, adminRank))
    
    -- Load admin ranks from config
    local path = GetResourcePath(GetCurrentResourceName()) .. '/data/ranks.json'
    local file = io.open(path, 'r')
    if not file then 
        Logger.error("PERMISSIONS", "Could not open ranks file")
        return false 
    end
    
    local content = file:read('*a')
    file:close()
    
    local success, ranks = pcall(function() return json.decode(content) end)
    if not success then 
        Logger.error("PERMISSIONS", string.format("Error parsing ranks JSON: %s", tostring(ranks)))
        return false 
    end
    
    -- Check if player's rank has permission to manage permissions
    if ranks[adminRank] and ranks[adminRank].canManagePermissions then
        Logger.success("PERMISSIONS", string.format("Player %s with rank %s can manage admins", 
            playerName, adminRank))
        return true
    end
    
    Logger.warn("PERMISSIONS", string.format("Player %s with rank %s cannot manage admins", 
        playerName, adminRank))
    return false
end

-- Register server event for setting admin rank
RegisterNetEvent('project-sentinel:setAdminRank')
AddEventHandler('project-sentinel:setAdminRank', function(targetIdentifier, rank)
    local source = source
    local adminName = GetPlayerName(source) or "Unknown"
    
    Logger.info("PERMISSIONS", string.format("Player %s (ID: %d) is attempting to set %s to rank %s", 
        adminName, source, targetIdentifier, rank))
    
    -- Check if the source has permission to set ranks
    if not CanManageAdmins(source) then
        Logger.warn("PERMISSIONS", "Permission denied - player cannot manage admins")
        TriggerClientEvent('project-sentinel:reportNotification', source, "You don't have permission to manage admin ranks")
        return
    end
    
    -- Validate the requested rank exists
    local path = GetResourcePath(GetCurrentResourceName()) .. '/data/ranks.json'
    local file = io.open(path, 'r')
    if not file then
        Logger.error("PERMISSIONS", "Error: Could not load rank definitions")
        TriggerClientEvent('project-sentinel:reportNotification', source, "Error: Could not load rank definitions")
        return
    end
    
    local content = file:read('*a')
    file:close()
    
    local success, ranks = pcall(function() return json.decode(content) end)
    if not success or not ranks[rank] then
        Logger.warn("PERMISSIONS", string.format("Invalid rank specified: %s", rank))
        TriggerClientEvent('project-sentinel:reportNotification', source, "Invalid rank specified: " .. rank)
        return
    end
    
    -- Find player by ID or name
    local playerId, playerIdentifier = FindPlayer(targetIdentifier)
    if not playerId or not playerIdentifier then
        Logger.warn("PERMISSIONS", string.format("Player %s tried to set rank for non-existent player: %s", 
            adminName, targetIdentifier))
        TriggerClientEvent('project-sentinel:reportNotification', source, "Player not found")
        return
    end
    
    -- Update player rank
    local playerName = GetPlayerName(playerId)
    local adminIdentifier = GetPlayerIdentifier(source, 0)
    
    Logger.info("PERMISSIONS", string.format("Updating rank for %s (ID: %d) to %s", 
        playerName, playerId, rank))
    
    -- Load existing admin users
    local adminUsers = Storage.Read('admin_ranks')
    Logger.debug("PERMISSIONS", string.format("Current admin users: %s", json.encode(adminUsers)))
    
    -- Create empty array if nil
    if not adminUsers then
        Logger.debug("PERMISSIONS", "Admin users array was nil, creating empty array")
        adminUsers = {}
    end
    
    -- Update or add the player's rank
    local playerFound = false
    for i, admin in ipairs(adminUsers) do
        if admin.identifier == playerIdentifier then
            Logger.debug("PERMISSIONS", "Updating existing admin entry")
            admin.rank = rank
            admin.name = playerName
            admin.assignedBy = adminName
            admin.updatedAt = os.date('!%Y-%m-%dT%H:%M:%S.000Z')
            playerFound = true
            break
        end
    end
    
    if not playerFound then
        Logger.debug("PERMISSIONS", "Adding new admin entry")
        table.insert(adminUsers, {
            identifier = playerIdentifier,
            name = playerName,
            rank = rank,
            assignedBy = adminName,
            createdAt = os.date('!%Y-%m-%dT%H:%M:%S.000Z'),
            updatedAt = os.date('!%Y-%m-%dT%H:%M:%S.000Z')
        })
    end
    
    -- Save the updated admin ranks
    Logger.info("PERMISSIONS", "Saving updated admin ranks")
    local saveSuccess = Storage.Write('admin_ranks', adminUsers)
    
    if not saveSuccess then
        Logger.error("PERMISSIONS", "Failed to save admin ranks")
        TriggerClientEvent('project-sentinel:reportNotification', source, "Error: Failed to save admin ranks")
        return
    end
    
    -- Notify the admin and target player
    Logger.success("PERMISSIONS", string.format("Admin %s set %s's rank to %s", 
        adminName, playerName, rank))
    
    TriggerClientEvent('project-sentinel:reportNotification', source, "Set " .. playerName .. "'s rank to " .. rank)
    TriggerClientEvent('project-sentinel:reportNotification', playerId, "Your admin rank has been set to: " .. rank .. " by " .. adminName)
    
    -- Log the action
    Logger.info("PERMISSIONS", string.format("Admin action: %s (%s) set %s's rank to %s", 
        adminName, adminIdentifier, playerName, rank))
end)

-- Remove admin rank from player
RegisterNetEvent('project-sentinel:removeAdminRank')
AddEventHandler('project-sentinel:removeAdminRank', function(targetIdentifier)
    local source = source
    
    -- Check if the source has permission to manage admins
    if not CanManageAdmins(source) then
        TriggerClientEvent('project-sentinel:reportNotification', source, "You don't have permission to manage admin ranks")
        return
    end
    
    -- Find player by ID or name
    local playerId, playerIdentifier = FindPlayer(targetIdentifier)
    if not playerId then
        TriggerClientEvent('project-sentinel:reportNotification', source, "Player not found")
        return
    end
    
    -- Load admin users
    local adminUsers = Storage.Read('admin_ranks')
    local playerName = GetPlayerName(playerId)
    local adminName = GetPlayerName(source)
    
    -- Find and remove the player from admin list
    local playerRemoved = false
    for i, admin in ipairs(adminUsers) do
        if admin.identifier == playerIdentifier then
            table.remove(adminUsers, i)
            playerRemoved = true
            break
        end
    end
    
    if playerRemoved then
        -- Save the updated admin ranks
        Storage.Write('admin_ranks', adminUsers)
        
        -- Notify the admin and target player
        TriggerClientEvent('project-sentinel:reportNotification', source, "Removed admin rank from " .. playerName)
        TriggerClientEvent('project-sentinel:reportNotification', playerId, "Your admin rank has been removed by " .. adminName)
    else
        TriggerClientEvent('project-sentinel:reportNotification', source, playerName .. " doesn't have an admin rank")
    end
end)

-- Check your own admin rank
RegisterNetEvent('project-sentinel:checkMyRank')
AddEventHandler('project-sentinel:checkMyRank', function()
    local source = source
    local adminRank = GetPlayerAdminRank(source)
    
    if adminRank then
        TriggerClientEvent('project-sentinel:reportNotification', source, "Your admin rank is: " .. adminRank)
    else
        TriggerClientEvent('project-sentinel:reportNotification', source, "You don't have an admin rank")
    end
end)

-- List all available ranks
RegisterNetEvent('project-sentinel:listAvailableRanks')
AddEventHandler('project-sentinel:listAvailableRanks', function()
    local source = source
    
    -- Check if the source has permission to see ranks
    local adminRank = GetPlayerAdminRank(source)
    if not adminRank then
        TriggerClientEvent('project-sentinel:reportNotification', source, "You don't have permission to view admin ranks")
        return
    end
    
    -- Load rank definitions
    local path = GetResourcePath(GetCurrentResourceName()) .. '/data/ranks.json'
    local file = io.open(path, 'r')
    if not file then
        TriggerClientEvent('project-sentinel:reportNotification', source, "Error: Could not load rank definitions")
        return
    end
    
    local content = file:read('*a')
    file:close()
    
    local success, ranks = pcall(function() return json.decode(content) end)
    if not success then
        TriggerClientEvent('project-sentinel:reportNotification', source, "Error parsing rank definitions")
        return
    end
    
    -- Build rank list
    local rankList = "Available Ranks: "
    local rankNames = {}
    for rank, _ in pairs(ranks) do
        table.insert(rankNames, rank)
    end
    
    -- Sort the ranks alphabetically
    table.sort(rankNames)
    rankList = rankList .. table.concat(rankNames, ", ")
    
    TriggerClientEvent('project-sentinel:reportNotification', source, rankList)
end)

Logger.success("PERMISSIONS", "Permission handler initialized")
