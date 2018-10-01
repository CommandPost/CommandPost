--- === plugins.compressor.menu.heading ===
---
--- The top heading of the menubar.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local compressor                = require("cp.apple.compressor")
local i18n                      = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PRIORITY -> number
-- Constant
-- The menubar position priority.
local PRIORITY = 0.1

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "compressor.menu.heading",
    group           = "compressor",
    dependencies    = {
        ["core.menu.manager"]               = "manager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(dependencies)

    --------------------------------------------------------------------------------
    -- Create the Timeline section:
    --------------------------------------------------------------------------------
    local shortcuts = dependencies.manager.addSection(PRIORITY)

    --------------------------------------------------------------------------------
    -- Disable the section if the Timeline option is disabled:
    --------------------------------------------------------------------------------
    shortcuts:setDisabledFn(function() return not compressor.app:frontmost() end)

    --------------------------------------------------------------------------------
    -- Add the separator and title for the section:
    --------------------------------------------------------------------------------
    shortcuts:addApplicationHeading(i18n("compressor"))

    return shortcuts
end

return plugin
