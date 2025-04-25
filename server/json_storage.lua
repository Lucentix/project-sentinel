local StorageHandler = {}

local storagePath = GetResourcePath(GetCurrentResourceName()) .. '/data/'

Citizen.CreateThread(function()
    if not os.rename(storagePath, storagePath) then
        os.execute("mkdir \"" .. storagePath .. "\"")
        print("^2Created data storage directory for Project Sentinel^0")
    end
end)

function StorageHandler.Read(fileName)
    local filePath = storagePath .. fileName .. '.json'
    local file = io.open(filePath, 'r')
    if not file then
        return {}
    end
    
    local content = file:read('*a')
    file:close()
    
    if content == "" then
        return {}
    end
    
    local success, data = pcall(function()
        return json.decode(content)
    end)
    
    if not success then
        print("^1Error reading JSON file " .. fileName .. ": " .. tostring(data) .. "^0")
        return {}
    end
    
    return data
end

function StorageHandler.Write(fileName, data)
    local filePath = storagePath .. fileName .. '.json'
    
    if not data then
        print("^1Attempted to write nil data to " .. fileName .. "^0")
        return false
    end
    
    local success, encoded = pcall(function()
        return json.encode(data)
    end)
    
    if not success then
        print("^1Error encoding data for " .. fileName .. ": " .. tostring(encoded) .. "^0")
        return false
    end
    
    local file = io.open(filePath, 'w+')
    if not file then
        print("^1Failed to open file for writing: " .. filePath .. "^0")
        return false
    end
    
    file:write(encoded)
    file:close()
    return true
end

function StorageHandler.UpdateEntry(fileName, entryId, updateData)
    local data = StorageHandler.Read(fileName)
    
    local found = false
    for i, entry in ipairs(data) do
        if entry.id == entryId then
            for key, value in pairs(updateData) do
                entry[key] = value
            end
            found = true
            break
        end
    end
    
    if found then
        return StorageHandler.Write(fileName, data)
    else
        print("^1Entry with ID " .. entryId .. " not found in " .. fileName .. "^0")
        return false
    end
end

function StorageHandler.AddEntry(fileName, entry)
    local data = StorageHandler.Read(fileName)
    
    table.insert(data, entry)
    
    return StorageHandler.Write(fileName, data)
end

function StorageHandler.GetNextId(fileName)
    local data = StorageHandler.Read(fileName)
    
    local maxId = 0
    for _, entry in ipairs(data) do
        if entry.id and entry.id > maxId then
            maxId = entry.id
        end
    end
    
    return maxId + 1
end

return StorageHandler