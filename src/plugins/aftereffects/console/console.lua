--- === plugins.aftereffects.console ===
---
--- After Effects Search Console

local require               = require

local application           = require "hs.application"

local ae                    = require "cp.adobe.aftereffects"
local config                = require "cp.config"
local fcp                   = require "cp.apple.finalcutpro"
local tools                 = require "cp.tools"

local infoForBundleID       = application.infoForBundleID
local insert                = table.insert
local split                 = tools.split

local mod = {}

local plugin = {
    id              = "aftereffects.console",
    group           = "aftereffects",
    dependencies    = {
        ["core.action.manager"]         = "actionmanager",
        ["core.console"]                = "console",
        ["core.application.manager"]    = "appmanager",
    }
}

function plugin.init(deps)
    local bundleID = ae:bundleID()
    if infoForBundleID(bundleID) then
        --------------------------------------------------------------------------------
        -- Register a After Effects specific activator for the Search Console:
        --------------------------------------------------------------------------------
        deps.console.register(bundleID, function()
            if not mod.activator then
                local actionmanager = deps.actionmanager
                mod.activator = actionmanager.getActivator("aftereffects.console")

                --------------------------------------------------------------------------------
                -- Allow specific handlers in the Search Console:
                --------------------------------------------------------------------------------
                local allowedHandlers = {}
                local handlerIds = actionmanager.handlerIds()
                for _,id in pairs(handlerIds) do
                    local handlerTable = split(id, "_")
                    if handlerTable[1] == "global" or handlerTable[1] == "aftereffects" then
                        if handlerTable[2]~= "widgets" then
                            insert(allowedHandlers, id)
                        end
                    end
                end
                mod.activator:allowHandlers(table.unpack(allowedHandlers))

                --------------------------------------------------------------------------------
                -- Allow specific toolbar icons in the Search Console:
                --------------------------------------------------------------------------------
                local iconPath = config.basePath .. "/plugins/aftereffects/console/images/"

                local toolbarIcons = deps.appmanager.defaultSearchConsoleToolbar()

                toolbarIcons["aftereffects_effects"] = { path = iconPath .. "fx.png", priority = 1}
                toolbarIcons["aftereffects_shortcuts"] = { path = iconPath .. "shortcut.png", priority = 2}

                mod.activator:toolbarIcons(toolbarIcons)
            end
            return mod.activator
        end)
    end
    return mod
end

return plugin
