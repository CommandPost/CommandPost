--- === plugins.core.helpandsupport.credits ===
---
--- Credits Menu Item.

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- PRIORITY -> number
-- Constant
-- The menubar position priority.
local PRIORITY = 3

--- plugins.core.helpandsupport.credits.show() -> nil
--- Function
--- Opens the CommandPost Credits in a browser
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.show()
    os.execute('open "http://help.commandpost.io/getting_started/credits/"')
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.helpandsupport.credits",
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
    global:add("cpCredits")
        :whenActivated(mod.show)
        :groupedBy("helpandsupport")

    deps.helpandsupport:addItem(PRIORITY, function()
        return { title = i18n("credits"),   fn = mod.show }
    end)
    return mod

end

return plugin