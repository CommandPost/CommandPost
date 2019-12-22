--- === plugins.finalcutpro.console ===
---
--- Final Cut Pro Search Console

local require   = require

local config    = require "cp.config"
local fcp       = require "cp.apple.finalcutpro"
local tools     = require "cp.tools"

local mod = {}

local plugin = {
    id              = "finalcutpro.console",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "fcpxCmds",
        ["core.action.manager"]         = "actionmanager",
        ["core.console"]                = "console",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Register a Final Cut Pro specific activator for the Search Console:
    --------------------------------------------------------------------------------
    local bundleID = fcp:bundleID()
    deps.console.register(bundleID, function()
        if not mod.activator then
            local actionmanager = deps.actionmanager
            mod.activator = actionmanager.getActivator("finalcutpro.console"):preloadChoices()

            --------------------------------------------------------------------------------
            -- Don't show widgets in the Final Cut Pro Search Console:
            --------------------------------------------------------------------------------
            local allowedHandlers = {}
            local handlerIds = actionmanager.handlerIds()
            for _,id in pairs(handlerIds) do
                local handlerTable = tools.split(id, "_")
                if handlerTable[2]~= "widgets" and id ~= "global_menuactions" and id ~= "global_shortcuts" then
                    table.insert(allowedHandlers, id)
                end
            end
            mod.activator:allowHandlers(table.unpack(allowedHandlers))

            --------------------------------------------------------------------------------
            -- Allow specific toolbar icons in the Console:
            --------------------------------------------------------------------------------
            local coreIconPath = config.basePath .. "/plugins/core/console/images/"
            local iconPath = config.basePath .. "/plugins/finalcutpro/console/images/"
            local toolbarIcons = {
                global_applications = { path = coreIconPath .. "apps.png",      priority = 1},
                fcpx_videoEffect    = { path = iconPath .. "videoEffect.png",   priority = 2},
                fcpx_audioEffect    = { path = iconPath .. "audioEffect.png",   priority = 3},
                fcpx_generator      = { path = iconPath .. "generator.png",     priority = 4},
                fcpx_title          = { path = iconPath .. "title.png",         priority = 5},
                fcpx_transition     = { path = iconPath .. "transition.png",    priority = 6},
                fcpx_fonts          = { path = iconPath .. "font.png",          priority = 7},
                fcpx_shortcuts      = { path = iconPath .. "shortcut.png",      priority = 8},
                fcpx_menu           = { path = iconPath .. "menu.png",          priority = 9},
            }
            mod.activator:toolbarIcons(toolbarIcons)
        end
        return mod.activator
    end)

    --------------------------------------------------------------------------------
    -- Add a Final Cut Pro specific action to open the Search Console:
    --------------------------------------------------------------------------------
    local cmds = deps.fcpxCmds
    cmds:add("cpConsole")
        :groupedBy("commandPost")
        :whenActivated(function()
            deps.console.show()
        end)
        :activatedBy():ctrl("space")

    return mod
end

return plugin
