-- Project Sentinel - Error Handler
-- This file adds error handling and stability to prevent UI crashes

local resourceName = GetCurrentResourceName()
local Logger = exports[resourceName]:getLogger()

local isUiErrored = false
local lastErrorTime = 0

-- Register an event that can be called from the UI when an error occurs
RegisterNUICallback('reportError', function(data, cb)
    local errorMessage = data.message or "Unknown error"
    local errorStack = data.stack or ""
    
    isUiErrored = true
    lastErrorTime = GetGameTimer()
    
    Logger.error("UI", "UI reported an error: " .. errorMessage)
    Logger.error("UI", "Error stack: " .. errorStack)
    
    -- You could report this to your server for logging
    TriggerServerEvent("project-sentinel:logClientError", errorMessage, errorStack)
    
    cb({success = true})
end)

-- Register a command to reset the UI if it gets stuck
RegisterCommand('reset_admin', function()
    Logger.info("CLIENT", "Manually resetting admin UI")
    
    CloseAdminPanel()
    SetNuiFocus(false, false)
    
    -- Wait a bit before allowing reopening
    Citizen.Wait(1000)
    
    isUiErrored = false
    Logger.success("CLIENT", "Admin UI reset complete")
end, false)

-- Background thread to monitor for UI errors and auto-recover
Citizen.CreateThread(function()
    while true do
        Citizen.Wait(5000) -- Check every 5 seconds
        
        if isUiErrored and GetGameTimer() - lastErrorTime > 10000 then
            -- If more than 10 seconds passed since the error, try to recover
            Logger.info("CLIENT", "Attempting to auto-recover UI after error")
            
            CloseAdminPanel()
            SetNuiFocus(false, false)
            isUiErrored = false
            
            Logger.success("CLIENT", "UI auto-recovery complete")
        end
    end
end)
