local isReportMenuOpen = false
local isAdminMenuOpen = false
local playerAdminRank = nil
local isInAdminMode = false

RegisterKeyMapping('project-sentinel:report', 'Open Report Menu', 'keyboard', 'F3')
RegisterCommand('project-sentinel:report', function()
    if isReportMenuOpen then
        CloseReportMenu()
    else
        OpenReportMenu()
    end
end, false)

RegisterCommand('admin', function()
    TriggerServerEvent('project-sentinel:checkAdminPermission')
end, false)

function OpenReportMenu()
    isReportMenuOpen = true
    SendNUIMessage({
        type = "openReportMenu"
    })
    SetNuiFocus(true, true)
end

function CloseReportMenu()
    isReportMenuOpen = false
    SendNUIMessage({
        type = "closeReportMenu"
    })
    SetNuiFocus(false, false)
end

function OpenAdminPanel(rank)
    isAdminMenuOpen = true
    playerAdminRank = rank
    SendNUIMessage({
        type = "openAdminPanel",
        rank = rank
    })
    SetNuiFocus(true, true)
    
    TriggerServerEvent('project-sentinel:getServerStats')
    TriggerServerEvent('project-sentinel:getReports')
    TriggerServerEvent('project-sentinel:getOnlinePlayers')
    
    if rank == "administrator" or rank == "management" or rank == "leitung" then
        TriggerServerEvent('project-sentinel:getAdminUsers')
    end
end

function CloseAdminPanel()
    isAdminMenuOpen = false
    SendNUIMessage({
        type = "closeAdminPanel"
    })
    SetNuiFocus(false, false)
end

RegisterNUICallback('closeMenu', function(data, cb)
    if isReportMenuOpen then
        CloseReportMenu()
    elseif isAdminMenuOpen then
        CloseAdminPanel()
    end
    cb('ok')
end)

RegisterNUICallback('submitReport', function(data, cb)
    local title = data.title
    local description = data.description
    
    if title and description and #title > 0 and #description > 0 then
        TriggerServerEvent('project-sentinel:submitReport', title, description)
        CloseReportMenu()
        cb({ success = true })
    else
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

RegisterNUICallback('refreshData', function(data, cb)
    TriggerServerEvent('project-sentinel:getServerStats')
    TriggerServerEvent('project-sentinel:getReports')
    TriggerServerEvent('project-sentinel:getOnlinePlayers')
    
    if playerAdminRank == "administrator" or playerAdminRank == "management" or playerAdminRank == "leitung" then
        TriggerServerEvent('project-sentinel:getAdminUsers')
    end
    
    cb('ok')
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
    OpenAdminPanel(rank)
end)

RegisterNetEvent('project-sentinel:receiveServerStats')
AddEventHandler('project-sentinel:receiveServerStats', function(stats)
    SendNUIMessage({
        type = "updateServerStats",
        stats = stats
    })
end)

RegisterNetEvent('project-sentinel:receiveReports')
AddEventHandler('project-sentinel:receiveReports', function(reports)
    SendNUIMessage({
        type = "updateReports",
        reports = reports
    })
end)

RegisterNetEvent('project-sentinel:receivePlayerInventory')
AddEventHandler('project-sentinel:receivePlayerInventory', function(data)
    SendNUIMessage({
        type = "displayPlayerInventory",
        data = data
    })
end)

RegisterNetEvent('project-sentinel:receiveOnlinePlayers')
AddEventHandler('project-sentinel:receiveOnlinePlayers', function(players)
    SendNUIMessage({
        type = "updateOnlinePlayers",
        players = players
    })
end)

RegisterNetEvent('project-sentinel:receiveAdminUsers')
AddEventHandler('project-sentinel:receiveAdminUsers', function(adminUsers)
    SendNUIMessage({
        type = "updateAdminUsers",
        adminUsers = adminUsers
    })
end)

RegisterNetEvent('project-sentinel:teleportTo')
AddEventHandler('project-sentinel:teleportTo', function(x, y, z)
    local playerPed = PlayerPedId()
    DoScreenFadeOut(500)
    Wait(600)
    SetEntityCoords(playerPed, x, y, z)
    DoScreenFadeIn(500)
end)