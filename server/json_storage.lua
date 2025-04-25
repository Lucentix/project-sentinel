-- First load our logger
local resourceName = GetCurrentResourceName()
local Logger = nil

-- Wait for the Logger to be ready
Citizen.CreateThread(function()
    while not exports[resourceName] do
        Citizen.Wait(100)
    end
    Logger = exports[resourceName]:getLogger()
    Logger.info("STORAGE", "JSON Storage initializing")
end)

local StorageHandler = {}
local storagePath = GetResourcePath(GetCurrentResourceName()) .. '/data/'

-- Create storage directory if it doesn't exist
Citizen.CreateThread(function()
    if not os.rename(storagePath, storagePath) then
        os.execute("mkdir \"" .. storagePath .. "\"")
        if Logger then
            Logger.success("STORAGE", "Created data storage directory")
        else
            print("^2Created data storage directory for Project Sentinel^0")
        end
    else
        if Logger then
            Logger.info("STORAGE", "Data storage directory already exists")
        end
    end
end)

function StorageHandler.Read(fileName)
    local log = function(level, message)
        if Logger then
            Logger[level]("STORAGE", message)
        else
            print("STORAGE: " .. message)
        end
    end

    log("debug", "Reading file: " .. fileName)
    local filePath = storagePath .. fileName .. '.json'
    
    local file = io.open(filePath, 'r')
    if not file then
        log("warn", "File not found: " .. filePath)
        return {}
    end
    
    local content = file:read('*a')
    file:close()
    
    if content == "" then
        log("warn", "File is empty: " .. filePath)
        return {}
    end
    
    local success, data = pcall(function()
        return json.decode(content)
    end)
    
    if not success then
        log("error", "Error reading JSON file " .. fileName .. ": " .. tostring(data))
        return {}
    end
    
    log("success", string.format("Successfully read %s with %d entries", 
        fileName, type(data) == "table" and #data or 0))
    return data
end

function StorageHandler.Write(fileName, data)
    local log = function(level, message)
        if Logger then
            Logger[level]("STORAGE", message)
        else
            print("STORAGE: " .. message)
        end
    end

    log("debug", "Writing to file: " .. fileName)
    local filePath = storagePath .. fileName .. '.json'
    
    if not data then
        log("error", "Attempted to write nil data to " .. fileName)
        return false
    end
    
    local success, encoded = pcall(function()
        return json.encode(data)
    end)
    
    if not success then
        log("error", "Error encoding data for " .. fileName .. ": " .. tostring(encoded))
        return false
    end
    
    -- Get data count for logging
    local dataCount = 0
    if type(data) == "table" then
        if data[1] ~= nil then -- it's an array
            dataCount = #data
        else -- it's an object
            for _ in pairs(data) do
                dataCount = dataCount + 1
            end
        end
    end
    
    log("debug", string.format("Writing %d items to %s", dataCount, fileName))
    
    local file = io.open(filePath, 'w+')
    if not file then
        log("error", "Failed to open file for writing: " .. filePath)
        return false
    end
    
    file:write(encoded)
    file:close()
    log("success", string.format("Successfully wrote %d items to %s", dataCount, fileName))
    return true
end

function StorageHandler.UpdateEntry(fileName, entryId, updateData)
    local log = function(level, message)
        if Logger then
            Logger[level]("STORAGE", message)
        else
            print("STORAGE: " .. message)
        end
    end

    log("debug", string.format("Updating entry ID %s in %s", entryId, fileName))
    local data = StorageHandler.Read(fileName)
    
    local found = false
    for i, entry in ipairs(data) do
        if entry.id == entryId then
            log("debug", string.format("Found entry ID %s at index %d", entryId, i))
            for key, value in pairs(updateData) do
                entry[key] = value
                log("debug", string.format("Updated field '%s' to '%s'", key, tostring(value)))
            end
            found = true
            break
        end
    end
    
    if found then
        log("success", string.format("Entry ID %s updated in %s", entryId, fileName))
        return StorageHandler.Write(fileName, data)
    else
        log("error", string.format("Entry ID %s not found in %s", entryId, fileName))
        return false
    end
end

function StorageHandler.AddEntry(fileName, entry)
    local log = function(level, message)
        if Logger then
            Logger[level]("STORAGE", message)
        else
            print("STORAGE: " .. message)
        end
    end

    log("debug", string.format("Adding new entry to %s", fileName))
    local data = StorageHandler.Read(fileName)
    
    table.insert(data, entry)
    log("success", string.format("Entry added to %s (new count: %d)", fileName, #data))
    
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
    
    if Logger then
        Logger.debug("STORAGE", string.format("Next ID for %s: %d", fileName, maxId + 1))
    end
    
    return maxId + 1
end

return StorageHandler