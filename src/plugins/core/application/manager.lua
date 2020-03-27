--- === plugins.core.application.manager ===
---
--- Application manager.

local require   = require

local config    = require "cp.config"

local mod = {}

mod._applications = {}

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
function mod.registerApplication(data)
    mod._applications[data.bundleID] = {
        displayName             = data.displayName,
        searchConsoleToolbar    = data.searchConsoleToolbar,
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
    return mod._applications
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
    return mod._applications[bundleID] and mod._applications[bundleID].searchConsoleToolbar
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
        global_applications         = { path = iconPath .. "apps.png",              priority = 50},
        global_shortcuts            = { path = iconPath .."Keyboard.icns",          priority = 51},
        global_snippets             = { path = iconPath .. "snippets.png",          priority = 52},
        global_loupedeckbanks       = { path = iconPath .. "loupedeckplusbank.png", priority = 53},
        global_loupedeckct_banks    = { path = iconPath .. "loupedeckctbank.png",   priority = 54},
        global_midibanks            = { path = iconPath .. "midibank.png",          priority = 55},
        global_streamDeckbanks      = { path = iconPath .. "streamdeckbank.png",    priority = 56},
        global_touchbarbanks        = { path = iconPath .. "touchbarbank.png",      priority = 57},
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