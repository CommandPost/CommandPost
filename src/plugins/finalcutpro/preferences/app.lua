--- === plugins.finalcutpro.preferences.app ===
---
--- Final Cut Pro Preferences Panel

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
local fcp                                       = require("cp.apple.finalcutpro")
local tools                                     = require("cp.tools")
local i18n                                      = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.preferences.app",
    group           = "finalcutpro",
    dependencies    = {
        ["core.preferences.manager"]    = "manager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    local mod = {}

    if fcp:isInstalled() then
        mod.panel = deps.manager.addPanel({
            priority    = 2040,
            id          = "finalcutpro",
            label       = i18n("finalCutProPanelLabel"),
            image       = image.imageFromPath(tools.iconFallback(fcp:getPath() .. "/Contents/Resources/Final Cut.icns")),
            tooltip     = i18n("finalCutProPanelTooltip"),
            height      = 490,
        })
    end

    return mod
end

return plugin
