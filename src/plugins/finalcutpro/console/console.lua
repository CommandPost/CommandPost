--- === plugins.finalcutpro.console ===
---
--- Final Cut Pro Console

local require   = require

local config    = require "cp.config"
local tools     = require "cp.tools"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.console.show() -> none
--- Function
--- Shows the Final Cut Pro Console.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.show()
    if not mod.activator then
        mod.activator = mod.actionmanager.getActivator("finalcutpro.console")
            :preloadChoices()

        --------------------------------------------------------------------------------
        -- Don't show widgets in the console:
        --------------------------------------------------------------------------------
        local allowedHandlers = {}
        local handlerIds = mod.actionmanager.handlerIds()
        for _,id in pairs(handlerIds) do
            local handlerTable = tools.split(id, "_")
            if handlerTable[2]~= "widgets" then
                table.insert(allowedHandlers, id)
            end
        end
        mod.activator:allowHandlers(table.unpack(allowedHandlers))

        --------------------------------------------------------------------------------
        -- Allow specific toolbar icons in the Console:
        --------------------------------------------------------------------------------
        local iconPath = config.basePath .. "/plugins/finalcutpro/console/images/"
        local toolbarIcons = {
            ["fcpx_audioEffect"]    = iconPath .. "audioEffect.png",
            ["fcpx_generator"]      = iconPath .. "generator.png",
            ["fcpx_title"]          = iconPath .. "title.png",
            ["fcpx_transition"]     = iconPath .. "transition.png",
            ["fcpx_videoEffect"]    = iconPath .. "videoEffect.png",
            ["fcpx_menu"]           = iconPath .. "menu.png",
            ["fcpx_font"]           = iconPath .. "font.png",
            ["fcpx_shortcuts"]      = iconPath .. "shortcut.png",
        }
        mod.activator:toolbarIcons(toolbarIcons)

    end
    mod.activator:show()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
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
    mod.actionmanager = deps.actionmanager

    --------------------------------------------------------------------------------
    -- Add the command trigger:
    --------------------------------------------------------------------------------
    deps.fcpxCmds:add("cpConsole")
        :groupedBy("commandPost")
        :whenActivated(function() mod.show() end)
        :activatedBy():ctrl("space")

    return mod
end

return plugin
