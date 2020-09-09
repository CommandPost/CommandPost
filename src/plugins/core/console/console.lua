--- === plugins.core.console ===
---
--- Search Console

local require           = require

local application       = require "hs.application"

local config            = require "cp.config"
local tools             = require "cp.tools"

local mergeTable        = tools.mergeTable
local unpack            = table.unpack

local mod = {}

-- plugins.core.console._appConsoles -> table
-- Variable
-- Table of application specific Search Consoles.
mod._appConsoles = {}

--- plugins.core.console.register(bundleID, activator) -> none
--- Function
--- Registers an application specific Search Console.
---
--- Parameters:
---  * bundleID - The bundle ID of the application
---  * activatorFn - A function that returns an activator.
---
--- Returns:
---  * None
function mod.register(bundleID, activator)
    mod._appConsoles[bundleID] = activator
end

--- plugins.core.console.show() -> none
--- Function
--- Shows the Search Console.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.show()
    --------------------------------------------------------------------------------
    -- Check to see if there's any application specific activators:
    --------------------------------------------------------------------------------
    local frontmostApplication = application.frontmostApplication()
    local bundleID = frontmostApplication and frontmostApplication:bundleID()
    if bundleID and mod._appConsoles[bundleID] then
        local activator = mod._appConsoles[bundleID]()
        if activator then
            activator:toggle()
            return
        end
    end

    --------------------------------------------------------------------------------
    -- Get the group ID of the current application:
    --------------------------------------------------------------------------------
    local apps = mod.appmanager.getApplications()
    local selectedApp = apps and apps[bundleID] and apps[bundleID] and apps[bundleID]
    local handlerID = selectedApp and selectedApp.legacyGroupID or bundleID
    local searchConsoleToolbar = selectedApp and selectedApp.searchConsoleToolbar

    --------------------------------------------------------------------------------
    -- If not, use the global one:
    --------------------------------------------------------------------------------
    if not mod.activator then
        mod.activator = mod.actionmanager.getActivator("core.console")

        --------------------------------------------------------------------------------
        -- Restrict Allowed Handlers for Activator to current group:
        --------------------------------------------------------------------------------
        local allowedHandlers = {}
        local handlerIds = mod.actionmanager.handlerIds()
        for _,id in pairs(handlerIds) do
            local handlerTable = tools.split(id, "_")
            if handlerTable[1] == "global" or handlerTable[1] == handlerID then
                if handlerTable[2]~= "widgets" and id ~= "global_shortcuts" then
                    table.insert(allowedHandlers, id)
                end
            end
        end
        mod.activator:allowHandlers(unpack(allowedHandlers))

        --------------------------------------------------------------------------------
        -- Allow specific toolbar icons in the Console:
        --------------------------------------------------------------------------------
        local defaultSearchConsoleToolbar = mod.appmanager.defaultSearchConsoleToolbar()
        if searchConsoleToolbar then
            defaultSearchConsoleToolbar = mergeTable(defaultSearchConsoleToolbar, searchConsoleToolbar)
        end
        local iconPath = config.basePath .. "/plugins/core/console/images/"
        local toolbarIcons = {
            global_menuactions = { path = iconPath .. "menu.png", priority = 2},
        }
        local combinedToolbarIcons = mergeTable(defaultSearchConsoleToolbar, toolbarIcons)
        combinedToolbarIcons["global_shortcuts"] = nil
        mod.activator:toolbarIcons(combinedToolbarIcons)

    end
    mod.activator:toggle()
end

local plugin = {
    id              = "core.console",
    group           = "core",
    dependencies    = {
        ["core.commands.global"]        = "global",
        ["core.action.manager"]         = "actionmanager",
        ["core.application.manager"]    = "appmanager",
    }
}

function plugin.init(deps)
    mod.actionmanager = deps.actionmanager
    mod.appmanager = deps.appmanager

    --------------------------------------------------------------------------------
    -- Add the command trigger:
    --------------------------------------------------------------------------------
    deps.global:add("cpGlobalConsole")
        :groupedBy("commandPost")
        :whenActivated(mod.show)
        :activatedBy():ctrl():option():cmd("space")

    return mod
end

return plugin
