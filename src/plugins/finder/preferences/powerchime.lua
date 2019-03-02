--- === plugins.finder.preferences.powerchime ===
---
--- General Preferences Panel

local require       = require

local hs            = hs

local log		    = require("hs.logger").new("powerchime")

local battery       = require("hs.battery")

local i18n          = require("cp.i18n")
local tools         = require("cp.tools")

local execute       = hs.execute
local trim          = tools.trim

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
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
function powerChimeDisabled()
    local o, s, t, r = execute("defaults read com.apple.PowerChime ChimeOnNoHardware")
    if o and s and t == "exit" and r == 0 then
        if trim(o) == "1" then
            return true
        end
    end
    return false
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
function setPowerChime(disabled)
    execute("defaults write com.apple.PowerChime ChimeOnNoHardware -bool " .. tostring(disabled))
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