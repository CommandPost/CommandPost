--- === cp.apple.finalcutpro.export.destinations ===
---
--- Provides access to the list of Share Destinations configured for the user.

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                       = require("hs.logger").new("destinations")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
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
mod.DESTINATIONS_FILE   = "com.apple.FinalCut.UserDestinations.plist"

--- cp.apple.finalcutpro.export.destinations.DESTINATIONS_PATH -> string
--- Constant
--- The Destinations Path.
mod.DESTINATIONS_PATH   = mod.PREFERENCES_PATH .. "/" .. mod.DESTINATIONS_FILE

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
    local destinationsPlist, err = plist.fileToTable(mod.DESTINATIONS_PATH)
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
                if file:sub(string.len(mod.DESTINATIONS_FILE)*-1) == mod.DESTINATIONS_FILE then
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
        mod._details = load()
        watch()
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
    local list = mod.details()
    if list then
        return _.map(list, function(_, e) return e.name end)
    else
        return nil
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