--- === plugins.core.application.manager ===
---
--- Application manager.

local require   = require

local fnutils   = require "hs.fnutils"

local config    = require "cp.config"

local copy      = fnutils.copy

local mod = {}

-- applications -> table
-- Variable
-- A table of registered applications.
local applications = {}

--- plugins.core.application.manager.registerApplication(data) -> none
--- Function
--- Registers a new application.
---
--- Parameters:
---  * data - A table containing the information to register.
---
--- Returns:
---  * None
---
--- Notes:
---  * The data table should contain:
---   * displayName - The display name of the application
---   * bundleID - The bundle ID of the application
---   * searchConsoleToolbar - A table containing the Search Console Toolbar information
---   * legacyGroupID - A string containing the legacy group ID (i.e. "fcpx")
function mod.registerApplication(data)
    applications[data.bundleID] = {
        displayName             = data.displayName,
        searchConsoleToolbar    = data.searchConsoleToolbar,
        legacyGroupID           = data.legacyGroupID,
    }
end

--- plugins.core.application.manager.getApplications() -> table
--- Function
--- Gets all the registered applications.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table of all the registered applications.
function mod.getApplications()
    return copy(applications)
end

--- plugins.core.application.manager.getSearchConsoleToolbar(bundleID) -> table
--- Function
--- Gets the Search Console Toolbar data for a specific bundle ID.
---
--- Parameters:
---  * bundleID - The bundle ID of the application you want to get.
---
--- Returns:
---  * A table of the Search Sonole Toolbar data for the specified application.
function mod.getSearchConsoleToolbar(bundleID)
    return applications[bundleID] and applications[bundleID].searchConsoleToolbar
end

--- plugins.core.application.manager.defaultSearchConsoleToolbar() -> table
--- Function
--- Returns the default search toolbar data.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A table
function mod.defaultSearchConsoleToolbar()
    local iconPath = config.basePath .. "/plugins/core/console/images/"
    return {
        global_applications             = { path = iconPath .. "apps.png",              priority = 50},
        global_shortcuts                = { path = iconPath .. "Keyboard.icns",         priority = 51},
        global_mouse                    = { path = iconPath .. "mouse.png",             priority = 52},
        global_gestures                 = { path = iconPath .. "Trackpad.icns",         priority = 53},
        global_snippets                 = { path = iconPath .. "snippets.png",          priority = 54},
        global_keyboardmaestro_macros   = { path = iconPath .. "keyboardmaestro.icns",  priority = 55},
        global_macosshortcuts           = { path = iconPath .. "Shortcuts.icns",        priority = 56},
        global_loupedeck_banks          = { path = iconPath .. "loupedeckbank.png",     priority = 57},
        global_loupedeckbanks           = { path = iconPath .. "loupedeckplusbank.png", priority = 58},
        global_loupedeckct_banks        = { path = iconPath .. "loupedeckctbank.png",   priority = 59},
        global_loupedecklive_banks      = { path = iconPath .. "loupedecklivebank.png", priority = 60},
        global_midibanks                = { path = iconPath .. "midibank.png",          priority = 61},
        global_streamDeckbanks          = { path = iconPath .. "streamdeckbank.png",    priority = 62},
        global_touchbarbanks            = { path = iconPath .. "touchbarbank.png",      priority = 63},
        global_tourbox_banks            = { path = iconPath .. "tourboxbank.png",       priority = 64},
        global_resolvebanks             = { path = iconPath .. "bmdbanks.png",          priority = 65},
    }
end

local plugin = {
    id              = "core.application.manager",
    group           = "core",
    dependencies    = {
    }
}

function plugin.init()
    --------------------------------------------------------------------------------
    -- Register CommandPost itself as an application:
    --------------------------------------------------------------------------------
    mod.registerApplication({
        bundleID = config.bundleID,
        displayName = config.appName,
    })

    return mod
end

return plugin
