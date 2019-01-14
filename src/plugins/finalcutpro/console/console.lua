--- === plugins.finalcutpro.console ===
---
--- Final Cut Pro Console

local require = require

local tools = require("cp.tools")

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
