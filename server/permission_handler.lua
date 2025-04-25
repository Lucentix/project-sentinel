-- Permission Handler for Project Sentinel

local Storage = LoadResourceFile(GetCurrentResourceName(), 'server/json_storage.lua')
Storage = load(Storage)()

-- Function to find a player by ID or partial name
local function FindPlayer(identifier)
    -- If input is a number, try to find by ID
    if tonumber(identifier) then
        local id = tonumber(identifier)
        if GetPlayerName(id) then
            return id, GetPlayerIdentifier(id, 0)
        end
    end
    
    -- Otherwise try to find by name (can be partial)
    local players = GetPlayers()
    for _, playerId in ipairs(players) do
        local name = GetPlayerName(playerId)
        if name and string.find(string.lower(name), string.lower(identifier)) then
            return playerId, GetPlayerIdentifier(playerId, 0)
        end
    end
    
    return nil
end

-- Function to check if a player has permissions to manage admins
local function CanManageAdmins(source)
    local adminRank = GetPlayerAdminRank(source)
    if not adminRank then return false end
    
    -- Load admin ranks from config
    local path = GetResourcePath(GetCurrentResourceName()) .. '/data/ranks.json'
    local file = io.open(path, 'r')
    if not file then return false end
    
    local content = file:read('*a')
    file:close()
    
    local success, ranks = pcall(function() return json.decode(content) end)
    if not success then return false end
    
    -- Check if player's rank has permission to manage permissions
    if ranks[adminRank] and ranks[adminRank].canManagePermissions then
        return true
    end
    
    return false
end

-- Register server event for setting admin rank
RegisterNetEvent('project-sentinel:setAdminRank')
AddEventHandler('project-sentinel:setAdminRank', function(targetIdentifier, rank)
    local source = source
    
    -- Check if the source has permission to set ranks
    if not CanManageAdmins(source) then
        TriggerClientEvent('project-sentinel:reportNotification', source, "You don't have permission to manage admin ranks")
        return
    end
    
    -- Validate the requested rank exists
    local path = GetResourcePath(GetCurrentResourceName()) .. '/data/ranks.json'
    local file = io.open(path, 'r')
    if not file then
        TriggerClientEvent('project-sentinel:reportNotification', source, "Error: Could not load rank definitions")
        return
    end
    
    local content = file:read('*a')
    file:close()
    
    local success, ranks = pcall(function() return json.decode(content) end)
    if not success or not ranks[rank] then
        TriggerClientEvent('project-sentinel:reportNotification', source, "Invalid rank specified: " .. rank)
        return
    end
    
    -- Find player by ID or name
    local playerId, playerIdentifier = FindPlayer(targetIdentifier)
    if not playerId then
        TriggerClientEvent('project-sentinel:reportNotification', source, "Player not found")
        return
    end
    
    -- Update player rank
    local playerName = GetPlayerName(playerId)
    local adminName = GetPlayerName(source)
    local adminIdentifier = GetPlayerIdentifier(source, 0)
    
    -- Load existing admin users
    local adminUsers = Storage.Read('admin_ranks')
    
    -- Update or add the player's rank
    local playerFound = false
    for i, admin in ipairs(adminUsers) do
        if admin.identifier == playerIdentifier then
            admin.rank = rank
            admin.name = playerName
            admin.assignedBy = adminName
            admin.updatedAt = os.date('!%Y-%m-%dT%H:%M:%S.000Z')
            playerFound = true
            break
        end
    end
    
    if not playerFound then
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
    Storage.Write('admin_ranks', adminUsers)
    
    -- Notify the admin and target player
    TriggerClientEvent('project-sentinel:reportNotification', source, "Set " .. playerName .. "'s rank to " .. rank)
    TriggerClientEvent('project-sentinel:reportNotification', playerId, "Your admin rank has been set to: " .. rank .. " by " .. adminName)
    
    -- Log the action
    print("^2[ADMIN]^0 " .. adminName .. " (" .. adminIdentifier .. ") set " .. playerName .. "'s rank to " .. rank)
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
