--- === plugins.core.display ===
---
--- Display Controls.

local require           = require

--local log               = require "hs.logger".new("display")

local i18n              = require "cp.i18n"
local tools             = require "cp.tools"

local pressSystemKey    = tools.pressSystemKey

local plugin = {
    id = "core.display",
    group = "core",
    dependencies = {
        ["core.commands.global"] = "global",
    }
}

function plugin.init(deps)
    deps.global
        :add("brightnessIncrease")
        :whenActivated(function() pressSystemKey("BRIGHTNESS_UP") end)
        :titled(i18n("increase") .. " " .. i18n("brightness"))

    deps.global
        :add("brightnessDecrease")
        :whenActivated(function() pressSystemKey("BRIGHTNESS_DOWN") end)
        :titled(i18n("decrease") .. " " .. i18n("brightness"))

end

return plugin