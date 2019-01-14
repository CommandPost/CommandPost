--- === plugins.core.helpandsupport.userguide ===
---
--- User Guide Menu Item.

local require = require

local i18n = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.helpandsupport.userguide",
    group           = "core",
    dependencies    = {
        ["core.menu.manager"] = "menuManager",
        ["core.commands.global"] = "global",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Show Help:
    --------------------------------------------------------------------------------
    local show = function()
        os.execute('open "http://help.commandpost.io/"')
    end

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    deps.global
        :add("cpUserGuide")
        :whenActivated(show)
        :groupedBy("helpandsupport")

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    deps.menuManager.commandPostHelpAndSupport
        :addItem(5, function() return { title = i18n("userGuide"), fn = show } end)
end

return plugin
