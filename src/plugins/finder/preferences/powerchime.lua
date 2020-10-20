--- === plugins.finder.preferences.powerchime ===
---
--- General Preferences Panel

local require       = require

local hs            = _G.hs

--local log		    = require("hs.logger").new("powerchime")

local battery       = require "hs.battery"

local i18n          = require "cp.i18n"

local cfpreferences = require "hs._asm.cfpreferences"

local execute       = hs.execute

local plugin = {
    id              = "finder.preferences.powerchime",
    group           = "finder",
    dependencies    = {
        ["finder.preferences.panel"]    = "panel",
    }
}

-- powerChimeDisabled() -> boolean
-- Function
-- Is the power chime disabled?
--
-- Parameters:
--  * None
--
-- Returns:
--  * `true` if disabled otherwise `false`
local function powerChimeDisabled()
    return cfpreferences.getBoolean("ChimeOnNoHardware", "com.apple.PowerChime")
end

-- setPowerChime(disabled) -> none
-- Function
-- Enables or disables the power chime.
--
-- Parameters:
--  * value - `true` to disable otherwise `false`
--
-- Returns:
--  * None
local function setPowerChime(disabled)
    cfpreferences.setValue("ChimeOnNoHardware", disabled, "com.apple.PowerChime")
    execute("killall PowerChime")
end

function plugin.init(deps)
    deps.panel
        :addHeading(100, i18n("advanced"))
        :addCheckbox(101,
            {
                label       = i18n("playPowerChimeSound"),
                checked     = function() return not powerChimeDisabled() end,
                disabled    = function() return not battery.powerSource() end,
                onchange    = function()
                                local value = powerChimeDisabled()
                                setPowerChime(not value)
                              end,
          }
      )
end

return plugin