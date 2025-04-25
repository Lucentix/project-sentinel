-- Debug Tools for Project Sentinel
-- This file adds useful commands to help with debugging

-- Command to manually trigger the admin panel (for testing)
RegisterCommand('test_admin', function(source, args, rawCommand)
    local testRank = args[1] or "administrator"
    print("[DEBUG] Testing admin panel with rank: " .. testRank)
    TriggerEvent('project-sentinel:openAdminPanel', testRank)
end, false)

-- Command to check NUI state
RegisterCommand('check_nui', function(source, args, rawCommand)
    local nuiFocus = IsPauseMenuActive()
    print("[DEBUG] NUI Focus: " .. tostring(nuiFocus))
end, false)

-- Command to force reload the UI (useful during development)
RegisterCommand('reload_ui', function(source, args, rawCommand)
    print("[DEBUG] Force reloading UI...")
    SendNUIMessage({
        action = "forceReload"
    })
end, false)

-- Command to simulate receiving server data (for testing UI without server)
RegisterCommand('test_data', function(source, args, rawCommand)
    print("[DEBUG] Simulating server data reception...")
    
    local mockStats = {
        players = {
            online = 25,
            max = 64
        },
        reports = {
            total = 15,
            open = 5,
            inProgress = 3,
            closed = 7
        }
    }
    
    SendNUIMessage({
        action = "receiveServerStats",
        stats = mockStats
    })
    
    print("[DEBUG] Mock stats data sent to UI")
end, false)

-- Command to check current script state
RegisterCommand('check_state', function(source, args, rawCommand)
    print("[DEBUG] Checking script state...")
    print("Report menu open: " .. tostring(isReportMenuOpen))
    print("Admin menu open: " .. tostring(isAdminMenuOpen))
    print("Admin rank: " .. tostring(playerAdminRank))
    print("Admin mode: " .. tostring(isInAdminMode))
end, false)

print("[DEBUG] Project Sentinel debug tools loaded")
