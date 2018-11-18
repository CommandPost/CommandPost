--- === plugins.core.helpandsupport.donate ===
---
--- Donate Menu Item.

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
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PRIORITY -> number
-- Constant
-- The menubar position priority.
local PRIORITY = 9999998

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.helpandsupport.donate.show() -> nil
--- Function
--- Opens the CommandPost Donations URL in your default Browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.show()
    os.execute('open "https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=HQK87KLKY8EVN"')
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.helpandsupport.donate",
    group           = "core",
    dependencies    = {
        ["core.menu.manager"]    = "menu",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    deps.menu.bottom
        :addItem(PRIORITY, function()
            return { title = i18n("donateToDevelopers"), fn = mod.show }
        end)
        :addSeparator(PRIORITY+0.1)

    return mod
end

return plugin
