--- === cp.json ===
---
--- A collection of handy JSON tools.

local require = require

local log                                       = require("hs.logger").new("json")

local fs                                        = require("hs.fs")
local json                                      = require("hs.json")

local prop                                      = require("cp.prop")
local tools                                     = require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- cp.json.read(path) -> table | nil
--- Function
--- Attempts to read the specified path as a JSON file.
--- If the file cannot be found, `nil` is returned. If the file is
--- not a JSON file, an error will occur.
---
--- Parameters:
---  * path      - The JSON file path.
---
--- Returns:
---  * The JSON file converted into table, or `nil`.
function mod.read(path)
    if not path then
        log.ef("Path is required for `cp.json.read`.")
        return false
    end
    if path then
        local filePath = fs.pathToAbsolute(path)
        if filePath then
            local file = io.open(filePath, "r")
            if file then
                local content = file:read("*all")
                file:close()
                return json.decode(content)
            end
        end
    end
    return nil
end

--- cp.json.write(path, data) -> boolean
--- Function
--- Writes data to a JSON file.
---
--- Parameters:
---  * path - The path to where you want to save the JSON file.
---  * data - A table containing data to be encoded as JSON.
---
--- Returns:
---  * `true` if successfully saved, otherwise `false`.
function mod.write(path, data)
    if not data then
        log.ef("Data is required for `cp.json.write`.")
        return false
    end
    if data and type(data) ~= "table" then
        log.ef("Data must be a table, not a '%s' for `cp.json.write`.", type(data))
        return false
    end
    if not path then
        log.ef("Path is required for `cp.json.write`.")
        return false
    end
    local encodedData = json.encode(data, true)
    if encodedData then
        local file = io.open(path, "w")
        if file then
            file:write(encodedData)
            file:close()
            return true
        end
    end
    return false
end

--- cp.json.encode(val[, prettyprint]) -> string
--- Function
--- Encodes a table as JSON
---
--- Parameters:
---  * val - A table containing data to be encoded as JSON
---  * prettyprint - An optional boolean, true to format the JSON for human readability, false to format the JSON for size efficiency. Defaults to false
---
--- Returns:
---  * A string containing a JSON representation of the supplied table
---
--- Notes:
---  * This is useful for storing some of the more complex lua table structures as a persistent setting (see `hs.settings`)
function mod.encode(...)
    return json.encode(...)
end

--- cp.json.decode(jsonString) -> table
--- Function
--- Decodes JSON into a table
---
--- Parameters:
---  * jsonString - A string containing some JSON data
---
--- Returns:
---  * A table representing the supplied JSON data
---
--- Notes:
---  * This is useful for retrieving some of the more complex lua table structures as a persistent setting (see `hs.settings`)
function mod.decode(...)
    return json.decode(...)
end

--- cp.json.prop(path, folder, filename, defaultValue) -> cp.prop
--- Function
--- Returns a `cp.prop` instance for a JSON file.
---
--- Parameters:
---  * path - The path to the JSON folder (i.e. "~/Library/Caches")
---  * folder - The folder containing the JSON file (i.e. "Final Cut Pro")
---  * filename - The filename of the JSON file (i.e. "Test.json")
---  * defaultValue - The default value if the JSON file doesn't exist yet.
---
--- Returns:
---  * A `cp.prop` instance.
function mod.prop(path, folder, filename, defaultValue)

    if not path then
        log.ef("Folder is required for `cp.json.prop`.")
        return nil
    end
    if not filename then
        log.ef("Filename is required for `cp.json.prop`.")
        return nil
    end

    local fullPath = path .. "/" .. folder
    local fullFilePath = path .. "/" .. folder .. "/" .. filename

    return prop.new(function()
    --------------------------------------------------------------------------------
    -- Getter:
    --------------------------------------------------------------------------------
        if tools.ensureDirectoryExists(path, folder) then
            if tools.doesFileExist(fullFilePath) then
                local result = mod.read(fullFilePath)
                if result then
                    return result
                else
                    log.ef("Failed to read JSON file: %s", fullFilePath)
                end
            end
        else
            log.ef("Failed to create JSON folder: %s", fullPath)
        end
        --------------------------------------------------------------------------------
        -- Return Default Value:
        --------------------------------------------------------------------------------
        return defaultValue
    end,
    function(value)
    --------------------------------------------------------------------------------
    -- Setter:
    --------------------------------------------------------------------------------
        if tools.ensureDirectoryExists(path, folder) then
            local result = mod.write(fullFilePath, value)
            if not result then
                log.ef("Failed to save JSON file: %s", fullFilePath)
            end
        else
            log.ef("Failed to create JSON folder: %s", fullPath)
        end
    end):deepTable()

end

return mod
