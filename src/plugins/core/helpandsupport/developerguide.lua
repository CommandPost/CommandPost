--- === plugins.core.helpandsupport.developerguide ===
---
--- Developer Guide Menu Item.

local require = require

local i18n = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.helpandsupport.developerguide.show() -> nil
--- Function
--- Opens the CommandPost Developer Guide in the Default Browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.show()
    os.execute('open "http://dev.commandpost.io/"')
end

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
    -- Commands:
    --------------------------------------------------------------------------------
    deps.global
        :add("cpDeveloperGuide")
        :whenActivated(mod.show)
        :groupedBy("helpandsupport")

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    deps.menuManager.commandPostHelpAndSupport
        :addItem(6, function() return { title = i18n("developerGuide"), fn = mod.show } end)
        :addSeparator(7)

    return mod
end

return plugin
