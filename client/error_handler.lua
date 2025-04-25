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
    
    -- Log the error to server console as well
    TriggerServerEvent("project-sentinel:logClientError", errorMessage, errorStack)
    
    cb({success = true})
    
    -- If we detect the specific filter error, try to recover automatically
    if string.find(errorMessage, "filter is not a function") then
        Logger.warn("UI", "Detected filter error - trying to recover UI automatically")
        Citizen.SetTimeout(1000, function()
            SendNUIMessage({
                action = "fixFilterError",
                timestamp = GetGameTimer()
            })
        end)
    end
end)

-- Register a command to reset the UI if it gets stuck
RegisterCommand('reset_admin', function()
    Logger.info("CLIENT", "Manually resetting admin UI")
    
    if isAdminMenuOpen then
        CloseAdminPanel()
    end
    SetNuiFocus(false, false)
    
    -- Wait a bit before allowing reopening
    Citizen.Wait(1000)
    
    isUiErrored = false
    Logger.success("CLIENT", "Admin UI reset complete")
end, false)

-- Add server event handler
RegisterNetEvent('project-sentinel:logClientErrorResponse')
AddEventHandler('project-sentinel:logClientErrorResponse', function(success)
    if success then
        Logger.info("CLIENT", "Error was logged on the server")
    end
end)

-- Register with server
AddEventHandler('onClientResourceStart', function(resourceName)
    if(GetCurrentResourceName() ~= resourceName) then
        return
    end
    
    TriggerServerEvent('project-sentinel:registerErrorHandler')
    Logger.success("CLIENT", "Error handler initialized")
end)
