--- === plugins.finalcutpro.hud.panels.button ===
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
    id              = "finalcutpro.hud.panels.buttons",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.hud.manager"]    = "manager",
    }
}

function plugin.init(deps)
    if fcp:isSupported() then
        local panel = deps.manager.addPanel({
            priority    = 2,
            id          = "buttons",
            label       = "Buttons",
            tooltip     = "Buttons",
            image       = image.imageFromPath(tools.iconFallback(fcp:getPath() .. "/Contents/Resources/Final Cut.icns")),
            height      = 300,
        })
    end
end

return plugin
