--- === plugins.core.menu.restart ===
---
--- Core CommandPost functionality

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require
local hs = hs

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local i18n              = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY          = 9999999

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.menu.restart",
    group           = "core",
    dependencies    = {
        ["core.menu.manager"] = "menu",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    deps.menu.bottom:addSeparator(PRIORITY):addItem(PRIORITY + 1, function()
        return { title = i18n("restart"),  fn = hs.reload }
    end)
end

return plugin