-- Project Sentinel Data Debugger
-- This tool helps identify and fix data issues

local Logger = exports[GetCurrentResourceName()]:getLogger()
Logger.info("DEBUG", "Data Debugger initialized")

-- Command to dump all received data
RegisterCommand('sentinel_debug_data', function()
    TriggerEvent('project-sentinel:debug_dump_data')
end, false)

RegisterNetEvent('project-sentinel:debug_dump_data')
AddEventHandler('project-sentinel:debug_dump_data', function()
    Logger.info("DEBUG", "Dumping all current data states:")
    
    -- Request fresh data
    TriggerServerEvent('project-sentinel:getServerStats')
    TriggerServerEvent('project-sentinel:getReports')
    TriggerServerEvent('project-sentinel:getOnlinePlayers')
    
    -- Output current UI state info
    Logger.info("DEBUG", "UI state: adminMenuOpen=" .. tostring(isAdminMenuOpen) .. ", reportMenuOpen=" .. tostring(isReportMenuOpen))
    Logger.info("DEBUG", "Admin rank: " .. tostring(playerAdminRank))
end)

-- Command to force refresh UI
RegisterCommand('sentinel_refresh_ui', function()
    Logger.info("DEBUG", "Forcing UI refresh")
    
    -- Send the refreshData event to the NUI
    SendNUIMessage({
        action = "forceRefresh"
    })
    
    -- Re-request all data
    TriggerServerEvent('project-sentinel:getServerStats')
    TriggerServerEvent('project-sentinel:getReports')
    TriggerServerEvent('project-sentinel:getOnlinePlayers')
    
    if playerAdminRank == "administrator" or playerAdminRank == "management" or playerAdminRank == "leitung" then
        TriggerServerEvent('project-sentinel:getAdminUsers')
    end
    
    Logger.success("DEBUG", "Refresh commands sent")
end, false)

-- Command to fix UI if stuck
RegisterCommand('sentinel_fix_ui', function()
    Logger.info("DEBUG", "Attempting to fix UI")
    
    -- Clear all UI state
    if isReportMenuOpen then
        CloseReportMenu()
    end
    
    if isAdminMenuOpen then
        CloseAdminPanel()
    end
    
    -- Reset NUI focus in case it's stuck
    SetNuiFocus(false, false)
    
    Logger.success("DEBUG", "UI reset complete")
end, false)
