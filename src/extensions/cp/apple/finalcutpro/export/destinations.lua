--- === cp.apple.finalcutpro.export.destinations ===
---
--- Provides access to the list of Share Destinations configured for the user.

local require       = require

local log           = require "hs.logger".new "destinations"

local fs            = require "hs.fs"
local pathwatcher   = require "hs.pathwatcher"

local plist         = require "cp.plist"
local archiver      = require "cp.plist.archiver"

local moses         = require "moses"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- PREFERENCES_PATH -> string
-- Constant
-- The Preferences Path
local PREFERENCES_PATH = "~/Library/Preferences"

-- DESTINATIONS_FILE -> string
-- Constant
-- The Destinations File.
local DESTINATIONS_FILE = "com.apple.FinalCut.UserDestinations"

-- DESTINATIONS_PATTERN -> string
-- Constant
-- Destinations File Pattern.
local DESTINATIONS_PATTERN = ".*" .. DESTINATIONS_FILE .. "[1-9]%.plist"

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
    local path = PREFERENCES_PATH .. "/"
    local iterFn, dirObj = fs.dir(path)
    local files = {}
    if iterFn then
        for file in iterFn, dirObj do
            if file:sub(1, DESTINATIONS_FILE:len()) == DESTINATIONS_FILE and file:sub(-6) == ".plist" then
                table.insert(files, file)
            end
        end
    end
    local selectedFile
    local selectedFileModification
    for _, file in pairs(files) do
        local attr = fs.attributes(path .. file)
        if not selectedFile then
            selectedFile = path .. file
            selectedFileModification = attr.modification
        else
            if attr.modification > selectedFileModification then
                selectedFile = path .. file
                selectedFileModification = attr.modification
            end
        end
    end
    return selectedFile
end

-- loadDestination() -> table | nil, string
-- Function
-- Loads the Destinations Property List.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A table
--  * If an error occurs an error string will also be returned.
local function loadDestination()
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
        mod._watcher = pathwatcher.new(PREFERENCES_PATH, function(files)
            for _,file in pairs(files) do
                if file:match(DESTINATIONS_PATTERN) ~= nil then
                    local err
                    mod._details, err = loadDestination()
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
        local list, err = loadDestination()
        if list then
            mod._details = list
            watch()
        else
            return list, err
        end
    end
    return mod._details
end

--- cp.apple.finalcutpro.export.destinations.names() -> table | nil, string
--- Function
--- Returns an array of the names of destinations, in their current order.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The table of Share Destination names, or `nil` if an error has occurred.
---  * An error message as a string.
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
        return moses.detect(list, function(e) return e.name == name end)
    else
        return nil
    end
end

return mod
