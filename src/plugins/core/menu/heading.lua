--- === plugins.core.menu.heading ===
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
local app                       = require("cp.app")
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
    id              = "core.menu.heading",
    group           = "core",
    dependencies    = {
        ["core.menu.manager"] = "manager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(dependencies)
    local commandPost = app.forBundleID(hs.processInfo.bundleID)
    local shortcuts = dependencies.manager.addSection(PRIORITY)
    shortcuts:setDisabledFn(function() return not commandPost:frontmost() end)
    shortcuts:addApplicationHeading(i18n("appName"))
    return shortcuts
end

return plugin
