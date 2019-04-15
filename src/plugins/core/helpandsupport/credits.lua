--- === plugins.core.helpandsupport.credits ===
---
--- Credits Menu Item.

local require = require

local i18n = require("cp.i18n")


local plugin = {
    id = "core.helpandsupport.credits",
    group = "core",
    dependencies = {
        ["core.menu.manager"] = "menuManager",
        ["core.commands.global"] = "global",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Open Credits:
    --------------------------------------------------------------------------------
    local show = function()
        os.execute('open "http://help.commandpost.io/getting_started/credits/"')
    end

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    deps.global
        :add("cpCredits")
        :whenActivated(show)
        :groupedBy("helpandsupport")

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    deps.menuManager.commandPostHelpAndSupport
        :addItem(10, function() return { title = i18n("credits"), fn = show } end)
end

return plugin
