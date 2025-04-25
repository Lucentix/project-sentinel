-- Admin Commands for Project Sentinel

-- Command to set/update a player's admin rank
RegisterCommand('setrank', function(source, args, rawCommand)
    if #args < 2 then
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"System", "Usage: /setrank [player ID or name] [rank]"}
        })
        return
    end

    local targetPlayer = args[1]
    local rank = args[2]
    
    TriggerServerEvent('project-sentinel:setAdminRank', targetPlayer, rank)
end, false)

-- Command to check your current admin rank
RegisterCommand('myrank', function(source, args, rawCommand)
    TriggerServerEvent('project-sentinel:checkMyRank')
end, false)

-- Command to list all available admin ranks
RegisterCommand('listranks', function(source, args, rawCommand)
    TriggerServerEvent('project-sentinel:listAvailableRanks')
end, false)

-- Command to remove admin permissions
RegisterCommand('removerank', function(source, args, rawCommand)
    if #args < 1 then
        TriggerEvent('chat:addMessage', {
            color = {255, 0, 0},
            multiline = true,
            args = {"System", "Usage: /removerank [player ID or name]"}
        })
        return
    end

    local targetPlayer = args[1]
    TriggerServerEvent('project-sentinel:removeAdminRank', targetPlayer)
end, false)
