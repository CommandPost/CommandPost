--- === plugins.core.console ===
---
--- Global Console

local require = require

local tools = require("cp.tools")


local mod = {}

-- GROUP -> string
-- Constant
-- Group ID.
local GROUP = "global"

-- WIDGETS -> string
-- Constant
-- Widgets Group ID.
local WIDGETS = "widgets"

--- plugins.core.console.show() -> none
--- Function
--- Shows the Console
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.show()

    if not mod.activator then
        mod.activator = mod.actionmanager.getActivator("core.console")
            :preloadChoices()

        --------------------------------------------------------------------------------
        -- Restrict Allowed Handlers for Activator to current group:
        --------------------------------------------------------------------------------
        local allowedHandlers = {}
        local handlerIds = mod.actionmanager.handlerIds()
        for _,id in pairs(handlerIds) do
            local handlerTable = tools.split(id, "_")
            if handlerTable[2]~= WIDGETS and handlerTable[1] == GROUP then
                table.insert(allowedHandlers, id)
            end
        end
        mod.activator:allowHandlers(table.unpack(allowedHandlers)) -- luacheck: ignore

    end
    mod.activator:show()

end


local plugin = {
    id              = "core.console",
    group           = "core",
    dependencies    = {
        ["core.commands.global"]        = "global",
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
    deps.global:add("cpGlobalConsole")
        :groupedBy("commandPost")
        :whenActivated(function() mod.show() end)
        :activatedBy():ctrl():option():cmd("space")

    return mod

end

return plugin
