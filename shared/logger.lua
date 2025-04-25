--[[
    Project Sentinel - Enhanced Logger
    Beautiful, colorful, and informative logging
]]

Logger = {}
Logger.Colors = {
    reset = "^0",
    red = "^1",
    green = "^2",
    yellow = "^3",
    blue = "^4",
    cyan = "^5",
    pink = "^6",
    white = "^7"
}

Logger.Levels = {
    debug = {color = Logger.Colors.blue, prefix = "DEBUG"},
    info = {color = Logger.Colors.cyan, prefix = "INFO"},
    success = {color = Logger.Colors.green, prefix = "SUCCESS"},
    warn = {color = Logger.Colors.yellow, prefix = "WARNING"},
    error = {color = Logger.Colors.red, prefix = "ERROR"},
    critical = {color = Logger.Colors.pink, prefix = "CRITICAL"}
}

-- Format the log message with colors
function Logger.Format(level, module, message)
    local levelInfo = Logger.Levels[level] or Logger.Levels.info
    
    local formatted = string.format(
        "%s[%s]%s %s[%s]%s %s",
        levelInfo.color, levelInfo.prefix, Logger.Colors.reset,
        Logger.Colors.yellow, module, Logger.Colors.reset,
        message
    )
    
    return formatted
end

-- Log a message with specified level
function Logger.Log(level, module, message)
    local formatted = Logger.Format(level, module, message)
    print(formatted)
    
    -- If running on server, also log to file
    if IsDuplicityVersion() then
        -- Server-side logging to file could go here
    end
end

-- Convenience methods for each log level
function Logger.debug(module, message)
    Logger.Log("debug", module, message)
end

function Logger.info(module, message)
    Logger.Log("info", module, message)
end

function Logger.success(module, message)
    Logger.Log("success", module, message)
end

function Logger.warn(module, message)
    Logger.Log("warn", module, message)
end

function Logger.error(module, message)
    Logger.Log("error", module, message)
end

function Logger.critical(module, message)
    Logger.Log("critical", module, message)
end

-- Export our logger so other resources can use it
exports('getLogger', function()
    return Logger
end)

Logger.success("SYSTEM", "Logger initialized")
