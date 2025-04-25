-- Project Sentinel - Server-side Error Handler
-- Logs client errors and helps with debugging

local resourceName = GetCurrentResourceName()
local Logger = exports[resourceName]:getLogger()

-- Handle client errors
RegisterNetEvent('project-sentinel:logClientError')
AddEventHandler('project-sentinel:logClientError', function(errorMessage, errorStack)
    local source = source
    local playerName = GetPlayerName(source) or "Unknown"
    local identifier = GetPlayerIdentifier(source, 0) or "Unknown"
    
    Logger.error("ERROR", string.format("Client error from %s (%s): %s", 
        playerName, identifier, errorMessage))
    
    -- Log to server console
    print("^1[ERROR]^0 Client error from " .. playerName .. ": " .. errorMessage)
    
    -- Optional: Save to a log file
    -- local logPath = GetResourcePath(GetCurrentResourceName()) .. '/logs/errors.log'
    -- local file = io.open(logPath, "a")
    -- if file then
    --     file:write(string.format("[%s] Player %s (%s): %s\n%s\n\n", 
    --         os.date("%Y-%m-%d %H:%M:%S"), playerName, identifier, errorMessage, errorStack))
    --     file:close()
    -- end
    
    TriggerClientEvent('project-sentinel:logClientErrorResponse', source, true)
end)

-- Register client
RegisterNetEvent('project-sentinel:registerErrorHandler')
AddEventHandler('project-sentinel:registerErrorHandler', function()
    local source = source
    Logger.info("SERVER", "Client " .. source .. " registered error handler")
end)
