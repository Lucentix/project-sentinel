-- First load our logger
local resourceName = GetCurrentResourceName()
local Logger = exports[resourceName]:getLogger()

local isReportMenuOpen = false
local isAdminMenuOpen = false
local playerAdminRank = nil
local isInAdminMode = false

-- Register key mappings and commands
RegisterKeyMapping('project-sentinel:report', 'Open Report Menu', 'keyboard', 'F3')

RegisterCommand('project-sentinel:report', function()
    Logger.info("CLIENT", "Report command triggered")
    if isReportMenuOpen then
        CloseReportMenu()
    else
        OpenReportMenu()
    end
end, false)

RegisterCommand('admin', function()
    Logger.info("CLIENT", "Admin command triggered, checking permissions...")
    TriggerServerEvent('project-sentinel:checkAdminPermission')
end, false)

function OpenReportMenu()
    Logger.info("CLIENT", "Opening report menu")
    isReportMenuOpen = true
    SendNUIMessage({
        action = "openReportUI"
    })
    SetNuiFocus(true, true)
    Logger.success("CLIENT", "Report menu opened and focus set to NUI")
end

function CloseReportMenu()
    Logger.info("CLIENT", "Closing report menu")
    isReportMenuOpen = false
    SendNUIMessage({
        action = "closeReportMenu"
    })
    SetNuiFocus(false, false)
    Logger.success("CLIENT", "Report menu closed and NUI focus removed")
end

function OpenAdminPanel(rank)
    Logger.info("CLIENT", "Opening admin panel with rank: " .. tostring(rank))
    isAdminMenuOpen = true
    playerAdminRank = rank
    SendNUIMessage({
        action = "openAdminPanel",
        adminRank = rank
    })
    SetNuiFocus(true, true)
    
    Logger.info("CLIENT", "Requesting server statistics")
    TriggerServerEvent('project-sentinel:getServerStats')
    
    Logger.info("CLIENT", "Requesting active reports")
    TriggerServerEvent('project-sentinel:getReports')
    
    Logger.info("CLIENT", "Requesting online players data")
    TriggerServerEvent('project-sentinel:getOnlinePlayers')
    
    if rank == "administrator" or rank == "management" or rank == "leitung" then
        Logger.info("CLIENT", "Requesting admin users list")
        TriggerServerEvent('project-sentinel:getAdminUsers')
    end
    
    Logger.success("CLIENT", "Admin panel initialization complete")
end

function CloseAdminPanel()
    Logger.info("CLIENT", "Closing admin panel")
    isAdminMenuOpen = false
    SendNUIMessage({
        action = "closeAdminPanel"
    })
    SetNuiFocus(false, false)
    Logger.success("CLIENT", "Admin panel closed and NUI focus removed")
end

RegisterNUICallback('closeMenu', function(data, cb)
    Logger.info("CLIENT", "NUI callback: closeMenu received")
    if isReportMenuOpen then
        Logger.info("CLIENT", "Closing report menu via NUI callback")
        CloseReportMenu()
    elseif isAdminMenuOpen then
        Logger.info("CLIENT", "Closing admin menu via NUI callback")
        CloseAdminPanel()
    end
    cb('ok')
end)

RegisterNUICallback('submitReport', function(data, cb)
    Logger.info("CLIENT", "NUI callback: submitReport received")
    Logger.debug("CLIENT", "Received data: " .. json.encode(data))
    
    -- Fix the property access - check both content and description fields
    local title = data.title
    local content = data.content or data.description
    
    if title and content and #title > 0 and #content > 0 then
        Logger.info("CLIENT", "Submitting report: " .. title)
        TriggerServerEvent('project-sentinel:submitReport', title, content)
        CloseReportMenu()
        cb({ success = true })
        Logger.success("CLIENT", "Report submitted successfully")
    else
        Logger.warn("CLIENT", "Report submission failed: Invalid input")
        Logger.debug("CLIENT", "Title: " .. tostring(title) .. ", Content: " .. tostring(content))
        cb({ success = false, error = "Please fill in all fields" })
    end
end)

RegisterNUICallback('updateReportStatus', function(data, cb)
    local reportId = data.reportId
    local status = data.status
    local notes = data.notes
    
    TriggerServerEvent('project-sentinel:updateReportStatus', reportId, status, notes)
    cb('ok')
end)

RegisterNUICallback('teleportToReport', function(data, cb)
    local reportId = data.reportId
    TriggerServerEvent('project-sentinel:teleportToReport', reportId)
    cb('ok')
end)

RegisterNUICallback('teleportToPlayer', function(data, cb)
    local playerId = data.playerId
    TriggerServerEvent('project-sentinel:teleportToPlayer', playerId)
    cb('ok')
end)

RegisterNUICallback('summonPlayer', function(data, cb)
    local playerId = data.playerId
    TriggerServerEvent('project-sentinel:summonPlayer', playerId)
    cb('ok')
end)

RegisterNUICallback('getPlayerInventory', function(data, cb)
    local playerId = data.playerId
    TriggerServerEvent('project-sentinel:getPlayerInventory', playerId)
    cb('ok')
end)

RegisterNUICallback('updatePlayerRank', function(data, cb)
    local targetIdentifier = data.targetIdentifier
    local newRank = data.newRank
    
    TriggerServerEvent('project-sentinel:updatePlayerRank', targetIdentifier, newRank)
    cb('ok')
end)

RegisterNUICallback('toggleAdminMode', function(data, cb)
    isInAdminMode = not isInAdminMode
    
    if isInAdminMode then
        TriggerServerEvent('project-sentinel:toggleAdminOutfit', data.outfitType or "standard")
    else
        RestorePlayerOutfit()
    end
    
    cb({ isInAdminMode = isInAdminMode })
end)

RegisterNUICallback('getServerStats', function(data, cb)
    Logger.info("CLIENT", "NUI callback: getServerStats received")
    TriggerServerEvent('project-sentinel:getServerStats')
    cb({ success = true })
end)

RegisterNUICallback('getReports', function(data, cb)
    Logger.info("CLIENT", "NUI callback: getReports received")
    TriggerServerEvent('project-sentinel:getReports')
    cb({ success = true })
end)

RegisterNUICallback('getOnlinePlayers', function(data, cb)
    Logger.info("CLIENT", "NUI callback: getOnlinePlayers received")
    TriggerServerEvent('project-sentinel:getOnlinePlayers')
    cb({ success = true })
end)

RegisterNUICallback('getAdminUsers', function(data, cb)
    Logger.info("CLIENT", "NUI callback: getAdminUsers received")
    TriggerServerEvent('project-sentinel:getAdminUsers')
    cb({ success = true })
end)

RegisterNUICallback('refreshData', function(data, cb)
    Logger.info("CLIENT", "NUI callback: refreshData received")
    TriggerServerEvent('project-sentinel:getServerStats')
    TriggerServerEvent('project-sentinel:getReports')
    TriggerServerEvent('project-sentinel:getOnlinePlayers')
    
    if playerAdminRank == "administrator" or playerAdminRank == "management" or playerAdminRank == "leitung" then
        TriggerServerEvent('project-sentinel:getAdminUsers')
    end
    
    cb({ success = true })
end)

function RestorePlayerOutfit()
    ESX.TriggerServerCallback('esx_skin:getPlayerSkin', function(skin)
        TriggerEvent('skinchanger:loadSkin', skin)
    end)
end

RegisterNetEvent('project-sentinel:reportNotification')
AddEventHandler('project-sentinel:reportNotification', function(message)
    SetNotificationTextEntry('STRING')
    AddTextComponentString(message)
    DrawNotification(false, true)
    
    SendNUIMessage({
        type = "showNotification",
        message = message
    })
    
    PlaySound(-1, "Event_Message_Purple", "GTAO_FM_Events_Soundset", 0, 0, 1)
end)

RegisterNetEvent('project-sentinel:openAdminPanel')
AddEventHandler('project-sentinel:openAdminPanel', function(rank)
    Logger.info("CLIENT", "Received event to open admin panel with rank: " .. tostring(rank))
    OpenAdminPanel(rank)
end)

-- Add extra debug for received data
RegisterNetEvent('project-sentinel:receiveServerStats')
AddEventHandler('project-sentinel:receiveServerStats', function(stats)
    Logger.info("CLIENT", "Received server statistics data")
    Logger.debug("CLIENT", "Raw stats data: " .. json.encode(stats))
    
    local playersInfo = string.format("Players: %d/%d", stats.players.online, stats.players.max)
    local reportsInfo = string.format("Reports: %d total (%d open, %d in progress, %d closed)", 
        stats.reports.total, stats.reports.open, stats.reports.inProgress, stats.reports.closed)
    
    Logger.debug("CLIENT", "Stats details - " .. playersInfo)
    Logger.debug("CLIENT", "Stats details - " .. reportsInfo)
    
    -- Send only the stats object without wrapping it in another object
    SendNUIMessage({
        action = "receiveServerStats",
        stats = stats
    })
end)

RegisterNetEvent('project-sentinel:receiveReports')
AddEventHandler('project-sentinel:receiveReports', function(reports)
    Logger.info("CLIENT", string.format("Received %d reports from server", #reports))
    Logger.debug("CLIENT", "Raw reports data: " .. json.encode(reports))
    
    -- Log some details about the reports
    local openCount, inProgressCount, closedCount = 0, 0, 0
    for _, report in ipairs(reports) do
        if report.status == "open" then openCount = openCount + 1
        elseif report.status == "in_progress" then inProgressCount = inProgressCount + 1
        elseif report.status == "closed" then closedCount = closedCount + 1 end
    end
    
    Logger.debug("CLIENT", string.format("Reports breakdown: %d open, %d in progress, %d closed", 
        openCount, inProgressCount, closedCount))
    
    -- Send only the reports array without wrapping it
    SendNUIMessage({
        action = "receiveReports",
        reports = reports
    })
end)

RegisterNetEvent('project-sentinel:receivePlayerInventory')
AddEventHandler('project-sentinel:receivePlayerInventory', function(data)
    Logger.info("CLIENT", "Received inventory for player ID: " .. tostring(data.playerId))
    SendNUIMessage({
        action = "receivePlayerInventory",
        data = data
    })
end)

RegisterNetEvent('project-sentinel:receiveOnlinePlayers')
AddEventHandler('project-sentinel:receiveOnlinePlayers', function(players)
    Logger.info("CLIENT", string.format("Received %d online players data", #players))
    Logger.debug("CLIENT", "Raw players data: " .. json.encode(players))
    
    -- Send only the players array without wrapping it
    SendNUIMessage({
        action = "receiveOnlinePlayers",
        players = players
    })
end)

RegisterNetEvent('project-sentinel:receiveAdminUsers')
AddEventHandler('project-sentinel:receiveAdminUsers', function(adminUsers)
    Logger.info("CLIENT", string.format("Received %d admin users data", #adminUsers))
    SendNUIMessage({
        action = "receiveAdminUsers",
        adminUsers = adminUsers
    })
end)

RegisterNetEvent('project-sentinel:teleportTo')
AddEventHandler('project-sentinel:teleportTo', function(x, y, z)
    Logger.info("CLIENT", string.format("Teleporting to coordinates: %.2f, %.2f, %.2f", x, y, z))
    local playerPed = PlayerPedId()
    DoScreenFadeOut(500)
    Wait(600)
    SetEntityCoords(playerPed, x, y, z)
    DoScreenFadeIn(500)
    Logger.success("CLIENT", "Teleport completed successfully")
end)

-- Hook into game initialization
Citizen.CreateThread(function()
    Logger.info("CLIENT", "Project Sentinel client initializing")
    -- Add any initialization code here
    Logger.success("CLIENT", "Project Sentinel client initialized successfully")
end)