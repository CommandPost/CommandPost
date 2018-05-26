--- === cp.json ===
---
--- A collection of handy JSON tools.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                                       = require("hs.logger").new("json")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local fs                                        = require("hs.fs")
local json                                      = require("hs.json")

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
    if path and data then
        local encodedData = json.encode(data)
        if encodedData then
            local file = io.open(path, "w")
            if file then
                file:write(encodedData)
                file:close()
                return true
            end
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

--- hs.json.decode(jsonString) -> table
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

return mod