--- === plugins.finalcutpro.console ===
---
--- Final Cut Pro Search Console

local require   = require

local config    = require "cp.config"
local tools     = require "cp.tools"

local plugin = {
    id              = "finalcutpro.console",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "fcpxCmds",
        ["core.action.manager"]         = "actionmanager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Initialise Module:
    --------------------------------------------------------------------------------
    local activator
    local cmds = deps.fcpxCmds
    local actionmanager = deps.actionmanager

    --------------------------------------------------------------------------------
    -- Add the command trigger:
    --------------------------------------------------------------------------------
    cmds:add("cpConsole")
        :groupedBy("commandPost")
        :whenActivated(function()
            if not activator then
                activator = actionmanager.getActivator("finalcutpro.console")
                    :preloadChoices()

                --------------------------------------------------------------------------------
                -- Don't show widgets in the console:
                --------------------------------------------------------------------------------
                local allowedHandlers = {}
                local handlerIds = actionmanager.handlerIds()
                for _,id in pairs(handlerIds) do
                    local handlerTable = tools.split(id, "_")
                    if handlerTable[2]~= "widgets" then
                        table.insert(allowedHandlers, id)
                    end
                end
                activator:allowHandlers(table.unpack(allowedHandlers))

                --------------------------------------------------------------------------------
                -- Allow specific toolbar icons in the Console:
                --------------------------------------------------------------------------------
                local iconPath = config.basePath .. "/plugins/finalcutpro/console/images/"
                local toolbarIcons = {
                    fcpx_videoEffect    = { path = iconPath .. "videoEffect.png",   priority = 1},
                    fcpx_audioEffect    = { path = iconPath .. "audioEffect.png",   priority = 2},
                    fcpx_generator      = { path = iconPath .. "generator.png",     priority = 3},
                    fcpx_title          = { path = iconPath .. "title.png",         priority = 4},
                    fcpx_transition     = { path = iconPath .. "transition.png",    priority = 5},
                    fcpx_fonts          = { path = iconPath .. "font.png",          priority = 6},
                    fcpx_shortcuts      = { path = iconPath .. "shortcut.png",      priority = 7},
                    fcpx_menu           = { path = iconPath .. "menu.png",          priority = 8},
                }
                activator:toolbarIcons(toolbarIcons)

            end

            activator:toggle()

        end)
        :activatedBy():ctrl("space")

    return mod
end

return plugin
