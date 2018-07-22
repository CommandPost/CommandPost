--- === cp.apple.finalcutpro.export.destinations ===
---
--- Provides access to the list of Share Destinations configured for the user.

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local require                   = require
local log                       = require("hs.logger").new("destinations")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local fs                        = require("hs.fs")
local pathwatcher               = require("hs.pathwatcher")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local plist                     = require("cp.plist")
local archiver                  = require("cp.plist.archiver")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local _                         = require("moses")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- cp.apple.finalcutpro.export.destinations.PREFERENCES_PATH -> string
--- Constant
--- The Preferences Path
mod.PREFERENCES_PATH    = "~/Library/Preferences"

--- cp.apple.finalcutpro.export.destinations.DESTINATIONS_FILE -> string
--- Constant
--- The Destinations File.
mod.DESTINATIONS_FILE   = "com.apple.FinalCut.UserDestinations"

--- cp.apple.finalcutpro.export.destinations.DESTINATIONS_PATTERN -> string
--- Constant
--- Destinations File Pattern.
mod.DESTINATIONS_PATTERN = ".*" .. mod.DESTINATIONS_FILE .. "[1-9]%.plist"

--- cp.apple.finalcutpro.export.destinations.DESTINATIONS_PATH -> string
--- Constant
--- The Destinations Path.
mod.DESTINATIONS_PATH   = mod.PREFERENCES_PATH .. "/" .. mod.DESTINATIONS_FILE .. ".plist"

-- findDestinationsPath() -> string | nil
-- Function
-- Gets the Final Cut Pro Destination Property List Path.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The Final Cut Pro Destination Property List Path as a string or `nil` if the file cannot be found.
local function findDestinationsPath()
    --------------------------------------------------------------------------------
    -- For some strange reason Final Cut Pro creates a file called
    -- `com.apple.FinalCut.UserDestinations2.plist` on most/all machines which is
    -- where the actual User Destinations are stored.
    --------------------------------------------------------------------------------
    local path = fs.pathToAbsolute(mod.PREFERENCES_PATH .. "/" .. mod.DESTINATIONS_FILE .. "2.plist")
    if not path then
        path = fs.pathToAbsolute(mod.DESTINATIONS_PATH)
    end
    return path
end

-- load() -> table | nil, string
-- Function
-- Loads the Destinations Property List.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function load()
    local destinationsPlist, err = plist.fileToTable(findDestinationsPath())
    if destinationsPlist then
        return archiver.unarchiveBase64(destinationsPlist.FFShareDestinationsKey).root
    else
        return nil, err
    end
end

-- watch() -> none
-- Function
-- Sets up a new Path Watcher.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function watch()
    if not mod._watcher then
        mod._watcher = pathwatcher.new(mod.PREFERENCES_PATH, function(files)
            for _,file in pairs(files) do
                if file:match(mod.DESTINATIONS_PATTERN) ~= nil then
                    local err
                    mod._details, err = load()
                    if err then
                        log.wf("Unable to load FCPX User Destinations")
                    end
                    return
                end
            end
        end):start()
    end
end

--- cp.apple.finalcutpro.export.destinations.details() -> table
--- Function
--- Returns the full details of the current Share Destinations as a table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The table of Share Destinations.
function mod.details()
    if not mod._details then
        local list, err = load()
        if list then
            mod._details = list
            watch()
        else
            return list, err
        end
    end
    return mod._details
end

--- cp.apple.finalcutpro.export.destinations.names() -> table
--- Function
--- Returns an array of the names of destinations, in their current order.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The table of Share Destination names.
function mod.names()
    local list, err = mod.details()
    if list then
        local result = {}
        for _, v in pairs(list) do
            if v.name and v.name ~= "" then
                table.insert(result, v.name)
            end
        end
        return result
    else
        return nil, err
    end
end

--- cp.apple.finalcutpro.export.destinations.indexOf(name) -> number
--- Function
--- Returns the index of the Destination with the specified name, or `nil` if not found.
---
--- Parameters:
---  * `name`   - The name of the Destination
---
--- Returns:
---  * The index of the named Destination, or `nil`.
function mod.indexOf(name)
    local list = mod.details()
    if list then
        return _.detect(list, function(e) return e.name == name end)
    else
        return nil
    end
end

return mod
