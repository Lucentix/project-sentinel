-- Console Logger for Project Sentinel
-- This file adds enhanced logging capabilities

local enableDebugLogs = true -- Set to false to disable debug logs in production

-- Enhanced print function with timestamps and categories
function Logger(category, message, level)
    if not enableDebugLogs and level == "debug" then return end
    
    local timestamp = os.date("%H:%M:%S")
    local prefix = ""
    
    if level == "error" then
        prefix = "^1[ERROR]^7"
    elseif level == "warn" then
        prefix = "^3[WARN]^7"
    elseif level == "info" then
        prefix = "^5[INFO]^7"
    elseif level == "success" then
        prefix = "^2[SUCCESS]^7"
    else
        prefix = "^7[DEBUG]^7"
    end
    
    print(prefix .. " " .. timestamp .. " [" .. category .. "] " .. message)
end

-- Export the logger functions so they can be used in other scripts
exports('LogDebug', function(category, message)
    Logger(category, message, "debug")
end)

exports('LogInfo', function(category, message)
    Logger(category, message, "info")
end)

exports('LogWarn', function(category, message)
    Logger(category, message, "warn")
end)

exports('LogError', function(category, message)
    Logger(category, message, "error")
end)

exports('LogSuccess', function(category, message)
    Logger(category, message, "success")
end)

-- Add global event listeners for easier logging from any script
RegisterNetEvent('project-sentinel:logMessage')
AddEventHandler('project-sentinel:logMessage', function(category, message, level)
    Logger(category, message, level or "info")
end)

if enableDebugLogs then
    Logger("LOGGER", "Enhanced logging system initialized", "success")
end

-- Register a command to toggle debug logs at runtime
RegisterCommand('toggle_debug', function(source, args, rawCommand)
    enableDebugLogs = not enableDebugLogs
    if enableDebugLogs then
        Logger("LOGGER", "Debug logs enabled", "success")
    else
        Logger("LOGGER", "Debug logs disabled", "info")
    end
end, false)
