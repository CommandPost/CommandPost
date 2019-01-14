--- === plugins.core.helpandsupport.errorlog ===
---
--- Error Log Menu Item.

local require = require

local i18n = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "core.helpandsupport.errorlog",
    group = "core",
    dependencies = {
        ["core.menu.manager"] = "menuManager",
        ["core.commands.global"] = "global",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Open Console:
    --------------------------------------------------------------------------------
    local open = function()
        hs.openConsole()
    end

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    deps.global
        :add("cpOpenErrorLog")
        :whenActivated(open)
        :groupedBy("commandPost")

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    deps.menuManager.commandPostHelpAndSupport
        :addItem(1, function() return { title = i18n("openErrorLog"), fn = open } end)
        :addSeparator(2)
end

return plugin
