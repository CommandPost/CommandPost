--- === plugins.core.helpandsupport.userguide ===
---
--- User Guide Menu Item.

local require = require

local i18n = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.helpandsupport.userguide.show() -> nil
--- Function
--- Opens the CommandPost User Guide in your default Browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.show()
    os.execute('open "http://help.commandpost.io/"')
end

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
    -- Commands:
    --------------------------------------------------------------------------------
    deps.global
        :add("cpUserGuide")
        :whenActivated(mod.show)
        :groupedBy("helpandsupport")

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    deps.menuManager.commandPostHelpAndSupport
        :addItem(5, function() return { title = i18n("userGuide"), fn = mod.show } end)

    return mod
end

return plugin
