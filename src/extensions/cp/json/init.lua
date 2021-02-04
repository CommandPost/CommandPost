--- === cp.json ===
---
--- A collection of handy JSON tools.

local require                   = require

local log                       = require "hs.logger".new "json"

local fs                        = require "hs.fs"
local json                      = require "hs.json"

local prop                      = require "cp.prop"
local tools                     = require "cp.tools"

local ensureDirectoryExists     = tools.ensureDirectoryExists

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
    else
        local filePath = fs.pathToAbsolute(path)
        if filePath then
            return json.read(path)
        end
    end
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
    return json.write(data, path, true, true)
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

--- cp.json.prop(path, folder, filename, defaultValue[, errorCallbackFn]) -> cp.prop
--- Function
--- Returns a `cp.prop` instance for a JSON file.
---
--- Parameters:
---  * path - The path to the JSON folder (i.e. "~/Library/Caches")
---  * folder - The folder containing the JSON file (i.e. "Final Cut Pro")
---  * filename - The filename of the JSON file (i.e. "Test.json")
---  * defaultValue - The default value if the JSON file doesn't exist yet.
---  * errorCallbackFn - An optional function that's triggered if something goes wrong.
---
--- Returns:
---  * A `cp.prop` instance.
---
--- Notes:
---  * The optional `errorCallbackFn` should accept one parameter, a string with
---    the error message.
function mod.prop(path, folder, filename, defaultValue, errorCallbackFn)

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
        if ensureDirectoryExists(path, folder) then
            if tools.doesFileExist(fullFilePath) then
                local result = mod.read(fullFilePath)
                if result then
                    return result
                else
                    local errorMessage = string.format("Failed to read JSON file: %s", fullFilePath)
                    if type(errorCallbackFn) == "function" then
                        errorCallbackFn(errorMessage)
                    else
                        log.ef(errorMessage)
                    end
                end
            else
                local errorMessage = string.format("Failed to read JSON file: %s", fullFilePath)
                if type(errorCallbackFn) == "function" then
                    errorCallbackFn(errorMessage)
                end
            end
        else
            local errorMessage = string.format("Failed to create JSON folder: %s", fullPath)
            if type(errorCallbackFn) == "function" then
                errorCallbackFn(errorMessage)
            else
                log.ef(errorMessage)
            end
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
        if ensureDirectoryExists(path, folder) then
            local result = mod.write(fullFilePath, value)
            if not result then
                local errorMessage = string.format("Failed to save JSON file: %s", fullFilePath)
                if type(errorCallbackFn) == "function" then
                    errorCallbackFn(errorMessage)
                else
                    log.ef(errorMessage)
                end
            end
        else
            local errorMessage = string.format("Failed to create JSON folder: %s", fullPath)
            if type(errorCallbackFn) == "function" then
                errorCallbackFn(errorMessage)
            end

        end
    end):deepTable():cached()

end

return mod
