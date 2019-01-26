--- === plugins.finalcutpro.hud.panels.info ===
---
--- Button Panel for the Final Cut Pro HUD.

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
    id              = "finalcutpro.hud.panels.info",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.hud.manager"]    = "manager",
    }
}

function plugin.init(deps)
    if fcp:isSupported() then
        local panel = deps.manager.addPanel({
            priority    = 1,
            id          = "info",
            label       = "Info Panel",
            image       = image.imageFromName("NSInfo"),
            tooltip     = "Info Panel",
            height      = 150,
        })
    end
end

return plugin
