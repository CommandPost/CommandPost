--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--      F I N A L    C U T    P R O    P R E F E R E N C E S    P A N E L     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.preferences.app ===
---
--- Final Cut Pro Preferences Panel

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local image                                     = require("hs.image")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp                                       = require("cp.apple.finalcutpro")
local tools                                     = require("cp.tools")

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
            height      = 410,
        })
    end

    return mod
end

return plugin