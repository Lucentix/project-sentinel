-- Project Sentinel - Error Handler
-- This file adds error handling and stability to prevent UI crashes

local resourceName = GetCurrentResourceName()
local Logger = exports[resourceName]:getLogger()

-- Register an event that can be called from the UI when an error occurs
RegisterNUICallback('reportError', function(data, cb)
    local errorMessage = data.message or "Unknown error"
    local errorStack = data.stack or ""
    local errorAction = data.action or "unknown"
    
    Logger.error("UI", "UI reported an error in action: " .. errorAction)
    Logger.error("UI", "Error message: " .. errorMessage)
    Logger.error("UI", "Error stack: " .. errorStack)
    
    -- Log to server
    TriggerServerEvent('project-sentinel:logClientError', errorMessage, errorStack)
    
    -- If this is the filter error, try to fix it
    if string.match(errorMessage, "filter is not a function") then
        Logger.warn("UI", "Detected filter error, sending fix command")
        -- Send a message to reset the dashboard stats
        SendNUIMessage({
            action = "fixFilterError",
            timestamp = os.time()
        })
    end
    
    cb({success = true})
end)

-- Command to reset the UI if it's stuck
RegisterCommand('reset_sentinel', function()
    Logger.info("CLIENT", "Manual reset of Sentinel UI requested")
    
    -- Force close any open interfaces
    if isReportMenuOpen then
        CloseReportMenu()
    end
    
    if isAdminMenuOpen then
        CloseAdminPanel()
    end
    
    -- Force reset NUI focus
    SetNuiFocus(false, false)
    
    Logger.success("CLIENT", "Sentinel UI reset completed")
    TriggerEvent('chat:addMessage', {
        color = {0, 255, 0},
        multiline = true,
        args = {"System", "Sentinel UI has been reset."}
    })
end, false)
