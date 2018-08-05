--- === plugins.core.tangent.os.display ===
---
--- Tangent Display Functions.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local brightness            = require("hs.brightness")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local i18n                  = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "core.tangent.os.display",
    group = "core",
    dependencies = {
        ["core.tangent.os"] = "osGroup",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    local displayGroup = deps.osGroup:group(i18n("display"))

    displayGroup:parameter(0x0AD00001)
        :name(i18n("brightness"))
        :name9(i18n("brightness9"))
        :name10(i18n("brightness10"))
        :minValue(0)
        :maxValue(100)
        :stepSize(5)
        :onGet(function() return brightness.get() end)
        :onChange(function(increment)
            brightness.set(brightness.get() + increment)
        end)
        :onReset(function() brightness.set(brightness.ambient()) end)

    return displayGroup
end

return plugin
