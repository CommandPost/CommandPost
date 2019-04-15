--- === plugins.core.tangent.os.display ===
---
--- Tangent Display Functions.

local require = require

local brightness            = require("hs.brightness")

local dialog                = require("cp.dialog")
local i18n                  = require("cp.i18n")

local format                = string.format


local mod = {}

--- plugins.core.tangent.os.display.init() -> self
--- Function
--- Initialise the module.
---
--- Parameters:
---  * deps - Dependancies
---
--- Returns:
---  * Self
function mod.init(deps)
    mod._displayGroup = deps.osGroup:group(i18n("display"))

    mod._displayGroup:parameter(0x0AD00001)
        :name(i18n("brightness"))
        :name9(i18n("brightness9"))
        :name10(i18n("brightness10"))
        :minValue(0)
        :maxValue(100)
        :stepSize(5)
        :onGet(function() return brightness.get() end)
        :onChange(function(increment)
            brightness.set(brightness.get() + increment)
            local brightnessValue = brightness.get()
            if brightnessValue and mod._lastBrightnessValue ~= brightnessValue then
                dialog.displayNotification(format(i18n("brightness") .. ": %s", brightnessValue))
                mod._lastBrightnessValue = brightnessValue
            end
        end)
        :onReset(function() brightness.set(brightness.ambient()) end)

    return mod
end


local plugin = {
    id = "core.tangent.os.display",
    group = "core",
    dependencies = {
        ["core.tangent.os"] = "osGroup",
    }
}

function plugin.init(deps)
    return mod.init(deps)
end

return plugin
