-- Project Sentinel - Server Error Handler

local resourceName = GetCurrentResourceName()
local Logger = exports[resourceName]:getLogger()

-- Handle client error reports
RegisterNetEvent('project-sentinel:logClientError')
AddEventHandler('project-sentinel:logClientError', function(errorMessage, errorStack)
    local source = source
    local playerName = GetPlayerName(source) or "Unknown"
    local identifier = GetPlayerIdentifier(source, 0) or "Unknown"
    
    -- Log the error with player information
    print("^1[ERROR]^0 ^3Client error from^0 " .. playerName .. " (" .. identifier .. "): " .. errorMessage)
    
    -- Store in server log file (optional)
    -- Uncomment to enable file logging
    --[[
    local logPath = GetResourcePath(resourceName) .. '/logs/'
    if not os.rename(logPath, logPath) then
        os.execute("mkdir \"" .. logPath .. "\"")
    end
    
    local file = io.open(logPath .. 'errors.log', 'a')
    if file then
        local timestamp = os.date('%Y-%m-%d %H:%M:%S')
        file:write(timestamp .. ' - Player: ' .. playerName .. ' (' .. identifier .. ')\n')
        file:write('Error: ' .. errorMessage .. '\n')
        file:write('Stack: ' .. errorStack .. '\n\n')
        file:close()
    end
    --]]
end)
