--- === plugins.finalcutpro.preferences.manager ===
---
--- Final Cut Pro Preferences Panel Manager.

local require = require

local image                                     = require("hs.image")

local fcp                                       = require("cp.apple.finalcutpro")
local tools                                     = require("cp.tools")
local i18n                                      = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.preferences.manager",
    group           = "finalcutpro",
    dependencies    = {
        ["core.preferences.manager"]    = "manager",
    }
}

function plugin.init(deps)
    local mod = {}

    if fcp:isSupported() then
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
