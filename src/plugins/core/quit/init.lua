--- === plugins.core.quit ===
---
--- Core CommandPost functionality

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config            = require("cp.config")
local i18n              = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY          = 9999999

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.quit.quit() -> nil
--- Function
--- Quit's CommandPost
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.quit()
    config.application():kill()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.quit",
    group           = "core",
    dependencies    = {
        ["core.menu.bottom"] = "bottom",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    deps.bottom:addSeparator(9999998):addItem(PRIORITY, function()
        return { title = i18n("quit"),  fn = mod.quit }
    end)

    return mod
end

return plugin
