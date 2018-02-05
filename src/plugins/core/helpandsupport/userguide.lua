--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                         U S E R     G U I D E                              --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.helpandsupport.userguide ===
---
--- User Guide Menu Item.

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY          = 1

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
        ["core.menu.helpandsupport.commandpost"]    = "helpandsupport",
        ["core.commands.global"]                    = "global",
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
    global:add("cpUserGuide")
        :whenActivated(mod.show)
        :groupedBy("helpandsupport")

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    deps.helpandsupport:addItem(PRIORITY, function()
        return { title = i18n("userGuide"), fn = mod.show }
    end)

    return mod
end

return plugin