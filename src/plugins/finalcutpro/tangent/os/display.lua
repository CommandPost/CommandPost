--- === plugins.finalcutpro.tangent.os.display ===
---
--- Tangent Display Functions.

local require = require

local brightness            = require "hs.brightness"

local dialog                = require "cp.dialog"
local fcp                   = require "cp.apple.finalcutpro"
local i18n                  = require "cp.i18n"

local format                = string.format

local mod = {}

--- plugins.finalcutpro.tangent.os.display.init() -> self
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
    id = "finalcutpro.tangent.os.display",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.os"] = "osGroup",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    return mod.init(deps)
end

return plugin
