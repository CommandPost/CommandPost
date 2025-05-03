--- === cp.apple.finalcutpro.export.destinations ===
---
--- Provides access to the list of Share Destinations configured for the user.
---
--- UPDATE (5th DECEMBER 2024):
--- ===========================
---
--- Final Cut Pro 11.0.0 is now sandboxed, so the file path has changed.
---
--- I'm also now seeing:
---  * `com.apple.FinalCut.UserDestinations5.plist`
---  * `com.apple.FinalCut.UserDestinations6.plist`
---  * `com.apple.FinalCut.UserDestinations7.plist`
---  * `com.apple.FinalCut.UserDestinations8.plist`
---
--- UPDATE (11th JUNE 2021):
--- ========================
---
--- It seems that as of FCPX 10.5.x, the UserDestinations file can go up to version
--- 5 (i.e. `com.apple.FinalCut.UserDestinations5.plist`). I've left the original
--- explanation below for future reference, as it goes into more detail as to
--- exactly what's happening.
---
--- ----------------------------------------------------------------------------------
---
--- If...
---
--- `~/Library/Preferences/com.apple.FinalCut.UserDestinations3.plist`
---
--- ...doesn't exist, then Final Cut Pro will use:
---
--- `/Applications/Final Cut Pro.app/Contents/Resources/DefaultDestinations.plist`
---
--- ...followed by any 3rd party applications such as:
---
--- `~/Library/Application Support/ProApps/Share Destinations/Vimeo (advanced).fcpxdest`
--- `/Library/Application Support/ProApps/Share Destinations/Xsend Motion.fcpxdest`
---
--- However, when you close Final Cut Pro, or if you open and close the destinations
--- preferences window, a new file will be created:
---
--- `~/Library/Preferences/com.apple.FinalCut.UserDestinations3.plist`
---
--- Also, if, for example, you delete the Xsend Motion destination in the Final Cut Pro
--- user interface, or rename the DVD preset to something else, then it will automatically
--- create a new Preferences file:
---
--- `~/Library/Preferences/com.apple.FinalCut.UserDestinations3.plist`
---
--- It seems that as of FCPX 10.4.6, Final Cut Pro ignores the:
---
--- `~/Preferences/com.apple.FinalCut.UserDestinations.plist`
---
--- ...file (it must be considered legacy). However, if this file exists:
---
--- `~/Preferences/com.apple.FinalCut.UserDestinations2.plist`
---
--- It will read that file, along with any third party applications such as:
---
--- `~/Application Support/ProApps/Share Destinations/Vimeo (advanced).fcpxdest`
--- `/Library/Application Support/ProApps/Share Destinations/Xsend Motion.fcpxdest`
---
--- However, again, if you close Final Cut Pro, or open and close the destinations
--- preferences window, a new file will be created, migrating the data from UserDestinations2:
---
--- `~/Preferences/com.apple.FinalCut.UserDestinations3.plist`
---
--- Long story short, in MOST cases, `UserDestinations3.plist` will be single source of
--- destinations, however, if this file doesn't exist, then `UserDestinations2.plist`
--- will be used, and if this file doesn't exist, then it will read the default values
--- from `DefaultDestinations.plist`, along with any third party share destinations.
---
--- Fun fact: even if you delete third party applications such as "Vimeo (advanced)",
--- and "Xsend Motion" from your Final Cut Pro destinations preferences, they'll come
--- back after you restart FCPX.

----------------------------------------------------------------------------------
-- TODO: This code currently doesn't work with hs.plist, which is why we're still
--       using cp.plist. Will re-investigate once we have hs.plist.readString()
----------------------------------------------------------------------------------

local require               = require

--local log                   = require "hs.logger".new "destinations"

local fs                    = require "hs.fs"

local archiver              = require "cp.plist.archiver"
local fcpApp                = require "cp.apple.finalcutpro.app"
local fcpStrings            = require "cp.apple.finalcutpro.strings"
local plist                 = require "cp.plist"
local tools                 = require "cp.tools"

local moses                 = require "moses"
local semver                = require "semver"

local detect                = moses.detect
local dir                   = fs.dir
local doesDirectoryExist    = tools.doesDirectoryExist
local doesFileExist         = tools.doesFileExist
local fileToTable           = plist.fileToTable
local spairs                = tools.spairs
local tableContains         = tools.tableContains

local mod = {}

-- findDestinationsPaths(path) -> table
-- Function
-- Gets the paths to all the Final Cut Pro Destination Preset files
-- contained within a supplied folder.
--
-- Parameters:
--  * path - The folder to search.
--
-- Returns:
--  * A table of paths.
local function findDestinationsPaths(path)
    local paths = {}
    if doesDirectoryExist(path) then
        for file in dir(path) do
            if file:sub(-9) == ".fcpxdest" then
                table.insert(paths, path .. file)
            end
        end
    end
    return paths
end

-- readDestinationFile(path) -> table
-- Function
-- Reads the contents of a Final Cut Pro Destination Property List file.
--
-- Parameters:
--  * path - The path to the property list file.
--
-- Returns:
--  * A table of unarchived property list data.
local function readDestinationFile(path)
    local destinations = {}
    local destinationsPlist = fileToTable(path)
    if destinationsPlist and destinationsPlist.FFShareDestinationsKey then
        local data = archiver.unarchiveBase64(destinationsPlist.FFShareDestinationsKey)
        if data and data.root then
            destinations = data.root
        end
    end
    return destinations
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

    local path = "~/Library/Preferences/com.apple.FinalCut.UserDestinations%s.plist"
    if fcpApp:version() >= semver("11.0.0") then
        -----------------------------------------------------
        -- Final Cut Pro 11:
        --
        -- Note that in FCP11 trial, it still users the same filename:
        -- ~/Library/Containers/com.apple.FinalCutTrial/Data/Library/Preferences/com.apple.FinalCut.UserDestinations8.plist
        -----------------------------------------------------
        local containerPath = string.format("~/Library/Containers/%s/Data/Library/Preferences/", fcpApp:bundleID())
        path = containerPath .. "com.apple.FinalCut.UserDestinations%s.plist"
    end

    local defaultPath   = fcpApp:path() .. "/Contents/Resources/DefaultDestinations.plist"
    local userPath      = os.getenv("HOME") .. "/Library/Application Support/ProApps/Share Destinations/"
    local systemPath    = "/Library/Application Support/ProApps/Share Destinations/"

    local destinations
    local extraDestinations = {}
    local result = {}

    -----------------------------------------------------
    -- Find the latest and greatest UserDestinations
    -- file:
    -----------------------------------------------------
    for i=50, 1, -1 do
        local currentPath = string.format(path, i)
        if doesFileExist(currentPath) then
            destinations = readDestinationFile(currentPath)
            break
        end
    end
    if not destinations then
        -----------------------------------------------------
        -- Using defaults:
        -----------------------------------------------------
        destinations = readDestinationFile(defaultPath)
    end

    -----------------------------------------------------
    -- Read the contents of the destination file:
    -----------------------------------------------------
    for _, v in pairs(destinations) do
        if v.name and v.originalSettingsName and v.name == v.originalSettingsName then
            local name = fcpStrings:find(v.originalSettingsName)
            if name then
                -----------------------------------------------------
                -- Using the 'originalSettingsName' value:
                -----------------------------------------------------
                table.insert(result, name)
            end
        elseif v.name and v.name == "" then
            if v.userHasChangedTheName == false and v.originalSettingsName then
                local name = fcpStrings:find(v.originalSettingsName)
                if name then
                    -----------------------------------------------------
                    -- Using the 'originalSettingsName' value:
                    -----------------------------------------------------
                    table.insert(result, name)
                end
            end
        elseif v.name and v.name ~= "" then
            if v.name:sub(1, 2) == "FF" then
                local name = fcpStrings:find(v.name)
                if name then
                    -----------------------------------------------------
                    -- Using the i18n 'name' value:
                    -----------------------------------------------------
                    table.insert(result, name)
                end
            else
                -----------------------------------------------------
                -- Using the 'name' value:
                -----------------------------------------------------
                table.insert(result, v.name)
            end
        end
    end

    -----------------------------------------------------
    -- Insert User Share Destinations:
    -----------------------------------------------------
    local userPaths = findDestinationsPaths(userPath)
    for _, p in pairs(userPaths) do
        local data = archiver.unarchiveFile(p)
        if data and data.root and data.root.name then
            table.insert(extraDestinations, data.root.name)
        end
    end

    -----------------------------------------------------
    -- Insert System Share Destinations:
    -----------------------------------------------------
    local systemPaths = findDestinationsPaths(systemPath)
    for _, p in pairs(systemPaths) do
        local data = archiver.unarchiveFile(p)
        if data and data.root and data.root.name then
            table.insert(extraDestinations, data.root.name)
        end
    end

    -----------------------------------------------------
    -- Sort and Insert User & System Share Destinations:
    -----------------------------------------------------
    for _, name in spairs(extraDestinations) do
        -----------------------------------------------------
        -- We only add these if they don't already exist:
        -----------------------------------------------------
        if not tableContains(result, name) then
            table.insert(result, name)
        end
    end

    return result
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
    local list = mod.names()
    return list and detect(list, function(e) return e == name end)
end

return mod
