--- === plugins.core.helpandsupport.facebook ===
---
--- Facebook Group Menu Item.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local i18n                  = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.helpandsupport.facebook.show() -> nil
--- Function
--- Opens the CommandPost Developer Guide in the Default Browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.show()
    os.execute('open "https://www.facebook.com/groups/commandpost/"')
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.helpandsupport.facebook",
    group           = "core",
    dependencies    = {
        ["core.menu.manager"] = "menuManager",
        ["core.commands.global"] = "global",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    local global = deps.global
    if global then
        global:add("cpFacebookGroup")
            :whenActivated(mod.show)
            :groupedBy("helpandsupport")
    end

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    local helpandsupport = deps.menuManager.commandPostHelpAndSupport
        helpandsupport
            :addItem(8, function() return { title = i18n("cpFacebookGroup_title"), fn = mod.show } end)
            :addSeparator(9)

    return mod
end

return plugin
