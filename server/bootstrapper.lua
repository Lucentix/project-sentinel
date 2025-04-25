-- Bootstrapper for Project Sentinel - ensures everything is set up correctly

-- Function to ensure a directory exists
function EnsureDirectoryExists(path)
    print("[BOOTSTRAP] Ensuring directory exists: " .. path)
    if not os.rename(path, path) then
        os.execute("mkdir \"" .. path .. "\"")
        print("[BOOTSTRAP] Created directory: " .. path)
        return true
    else
        print("[BOOTSTRAP] Directory already exists: " .. path)
        return false
    end
end

-- Function to ensure a file exists with default content
function EnsureFileExists(path, defaultContent)
    print("[BOOTSTRAP] Ensuring file exists: " .. path)
    local file = io.open(path, 'r')
    if not file then
        print("[BOOTSTRAP] File does not exist, creating: " .. path)
        file = io.open(path, 'w+')
        if file then
            file:write(defaultContent or "")
            file:close()
            print("[BOOTSTRAP] Created file with default content: " .. path)
            return true
        else
            print("[BOOTSTRAP] Failed to create file: " .. path)
            return false
        end
    else
        file:close()
        print("[BOOTSTRAP] File already exists: " .. path)
        return false
    end
end

-- Set up the data structure when the resource starts
AddEventHandler('onResourceStart', function(resourceName)
    if (GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    print("[BOOTSTRAP] Setting up Project Sentinel...")
    
    -- Ensure data directory exists
    local dataPath = GetResourcePath(GetCurrentResourceName()) .. '/data'
    EnsureDirectoryExists(dataPath)
    
    -- Ensure admin_ranks.json exists
    local adminRanksPath = dataPath .. '/admin_ranks.json'
    EnsureFileExists(adminRanksPath, '[]')
    
    -- Ensure ranks.json exists with default ranks
    local ranksPath = dataPath .. '/ranks.json'
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
    
    local file = io.open(ranksPath, 'r')
    if not file then
        file = io.open(ranksPath, 'w+')
        if file then
            file:write(json.encode(defaultRanks, {indent = true}))
            file:close()
            print("[BOOTSTRAP] Created default ranks.json file")
        else
            print("[BOOTSTRAP] Failed to create ranks.json file")
        end
    else
        file:close()
        print("[BOOTSTRAP] ranks.json already exists")
    end
    
    -- Ensure reports file exists
    local reportsPath = dataPath .. '/reports.json'
    EnsureFileExists(reportsPath, '[]')
    
    print("[BOOTSTRAP] Project Sentinel setup complete")
end)

-- Command to force check a player's admin rank
RegisterCommand('check_admin_rank', function(source, args, rawCommand)
    if source == 0 then -- If console
        if #args < 1 then
            print("Usage: check_admin_rank [player id]")
            return
        end
        
        local targetId = tonumber(args[1])
        if not targetId then
            print("Invalid player ID")
            return
        end
        
        local adminRank = GetPlayerAdminRank(targetId)
        print("Player " .. targetId .. " admin rank: " .. tostring(adminRank))
    else
        local adminRank = GetPlayerAdminRank(source)
        if adminRank and (adminRank == "administrator" or adminRank == "management" or adminRank == "leitung") then
            if #args < 1 then
                TriggerClientEvent('project-sentinel:reportNotification', source, "Usage: /check_admin_rank [player id]")
                return
            end
            
            local targetId = tonumber(args[1])
            if not targetId then
                TriggerClientEvent('project-sentinel:reportNotification', source, "Invalid player ID")
                return
            end
            
            local targetRank = GetPlayerAdminRank(targetId)
            TriggerClientEvent('project-sentinel:reportNotification', source, "Player " .. targetId .. " admin rank: " .. tostring(targetRank))
        else
            TriggerClientEvent('project-sentinel:reportNotification', source, "You don't have permission to use this command")
        end
    end
end, true)

-- Add a server command to grant admin to a player
RegisterCommand('grant_admin', function(source, args, rawCommand)
    if source ~= 0 then -- Not console
        print("This command can only be executed from server console")
        return
    end
    
    if #args < 2 then
        print("Usage: grant_admin [player id] [rank]")
        return
    end
    
    local playerId = tonumber(args[1])
    local rank = args[2]
    
    if not playerId or not GetPlayerName(playerId) then
        print("Player not found")
        return
    end
    
    local path = GetResourcePath(GetCurrentResourceName()) .. '/data/ranks.json'
    local file = io.open(path, 'r')
    if not file then
        print("Ranks file not found")
        return
    end
    
    local content = file:read('*a')
    file:close()
    
    local success, ranks = pcall(function() return json.decode(content) end)
    if not success or not ranks[rank] then
        print("Invalid rank specified: " .. rank)
        return
    end
    
    local playerName = GetPlayerName(playerId)
    local playerIdentifier = GetPlayerIdentifier(playerId, 0)
    
    if not playerIdentifier then
        print("Could not get player identifier")
        return
    end
    
    -- Load existing admin users
    local Storage = LoadResourceFile(GetCurrentResourceName(), 'server/json_storage.lua')
    Storage = load(Storage)()
    local adminUsers = Storage.Read('admin_ranks')
    
    -- Create empty array if nil
    if not adminUsers then
        adminUsers = {}
    end
    
    -- Update or add the player's rank
    local playerFound = false
    for i, admin in ipairs(adminUsers) do
        if admin.identifier == playerIdentifier then
            admin.rank = rank
            admin.name = playerName
            admin.assignedBy = "Server Console"
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
            assignedBy = "Server Console",
            createdAt = os.date('!%Y-%m-%dT%H:%M:%S.000Z'),
            updatedAt = os.date('!%Y-%m-%dT%H:%M:%S.000Z')
        })
    end
    
    -- Save the updated admin ranks
    local saveSuccess = Storage.Write('admin_ranks', adminUsers)
    
    if saveSuccess then
        print("Set " .. playerName .. "'s rank to " .. rank)
        TriggerClientEvent('project-sentinel:reportNotification', playerId, "Your admin rank has been set to: " .. rank .. " by Server Console")
    else
        print("Failed to save admin ranks")
    end
end, true)

print("[BOOTSTRAP] Bootstrapper initialized")
