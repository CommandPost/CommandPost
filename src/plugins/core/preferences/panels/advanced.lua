--- === plugins.core.preferences.panels.advanced ===
---
--- Advanced Preferences Panel

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local image                                     = require("hs.image")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local i18n                                      = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.preferences.panels.advanced",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"]    = "manager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    return deps.manager.addPanel({
        priority    = 2090,
        id          = "advanced",
        label       = i18n("advancedPanelLabel"),
        image       = image.imageFromName("NSAdvanced"),
        tooltip     = i18n("advancedPanelTooltip"),
        height      = 300,
    })
end

return plugin
