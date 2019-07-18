--- === plugins.core.helpandsupport.debugconsole ===
---
--- Debug Console Menu Item.

local require = require

local i18n = require("cp.i18n")

local plugin = {
    id = "core.helpandsupport.debugconsole",
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
        :add("cpOpenDebugConsole")
        :whenActivated(open)
        :groupedBy("commandPost")

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    deps.menuManager.commandPostHelpAndSupport
        :addItem(1, function() return { title = i18n("openDebugConsole"), fn = open } end)
        :addSeparator(2)
end

return plugin
