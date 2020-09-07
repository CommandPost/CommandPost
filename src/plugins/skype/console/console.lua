--- === plugins.skype.console ===
---
--- Skype Search Console

local require               = require

local application           = require "hs.application"

local config                = require "cp.config"
local tools                 = require "cp.tools"

local infoForBundleID       = application.infoForBundleID
local insert                = table.insert
local split                 = tools.split

local mod = {}

local plugin = {
    id              = "skype.console",
    group           = "skype",
    dependencies    = {
        ["core.action.manager"]         = "actionmanager",
        ["core.console"]                = "console",
        ["core.application.manager"]    = "appmanager",
    }
}

function plugin.init(deps)
    local bundleID = "com.skype.skype"
    if infoForBundleID(bundleID) then
        --------------------------------------------------------------------------------
        -- Register a After Effects specific activator for the Search Console:
        --------------------------------------------------------------------------------
        deps.console.register(bundleID, function()
            if not mod.activator then
                local actionmanager = deps.actionmanager
                mod.activator = actionmanager.getActivator("skype.console")

                --------------------------------------------------------------------------------
                -- Allow specific handlers in the Search Console:
                --------------------------------------------------------------------------------
                local allowedHandlers = {}
                local handlerIds = actionmanager.handlerIds()
                for _,id in pairs(handlerIds) do
                    local handlerTable = split(id, "_")
                    if handlerTable[1] == "global" or handlerTable[1] == "skype" then
                        if handlerTable[2]~= "widgets" then
                            insert(allowedHandlers, id)
                        end
                    end
                end
                mod.activator:allowHandlers(table.unpack(allowedHandlers))

                --------------------------------------------------------------------------------
                -- Allow specific toolbar icons in the Search Console:
                --------------------------------------------------------------------------------
                local iconPath = config.basePath .. "/plugins/skype/console/images/"

                local toolbarIcons = deps.appmanager.defaultSearchConsoleToolbar()

                toolbarIcons["skype_shortcuts"] = { path = iconPath .. "shortcut.png", priority = 1}

                mod.activator:toolbarIcons(toolbarIcons)
            end
            return mod.activator
        end)
    end
    return mod
end

return plugin
