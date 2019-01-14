--- === plugins.core.helpandsupport.developerguide ===
---
--- Developer Guide Menu Item.

local require = require

local i18n = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.helpandsupport.developerguide",
    group           = "core",
    dependencies    = {
        ["core.menu.manager"] = "menuManager",
        ["core.commands.global"] = "global",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Open Developers Guide:
    --------------------------------------------------------------------------------
    local show = function()
        os.execute('open "http://dev.commandpost.io/"')
    end

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    deps.global
        :add("cpDeveloperGuide")
        :whenActivated(show)
        :groupedBy("helpandsupport")

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    deps.menuManager.commandPostHelpAndSupport
        :addItem(6, function() return { title = i18n("developerGuide"), fn = show } end)
        :addSeparator(7)
end

return plugin
