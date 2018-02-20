--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                       M I D I    C O N T R O L S                           --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.midi.controls.colorwheels ===
---
--- Final Cut Pro MIDI Color Controls.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log             = require("hs.logger").new("colorMIDI")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp               = require("cp.apple.finalcutpro")
local tools             = require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.midi.controls.colorwheels.init() -> nil
--- Function
--- Initialise the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(deps)

    --------------------------------------------------------------------------------
    -- MIDI Controller Value:          0 to 127
    -- Percentage Slider:           -255 to 255
    --------------------------------------------------------------------------------

    local wheel = {
        [1] = "Master",
        [2] = "Shadows",
        [3] = "Midtones",
        [4] = "Highlights",
    }

    local colors = {
        [1] = "Red",
        [2] = "Green",
        [3] = "Blue",
    }

    for i=1, 4 do
        for v=1, 3 do
            deps.manager.controls:new("wheels" .. wheel[i] .. colors[v], {
                group = "fcpx",
                text = string.upper(i18n("midi")) .. ": " .. wheel[i] .. " " .. colors[v] .. " " .. i18n("color"),
                subText = i18n("midiColorWheelDescription"),
                fn = function(metadata)
                    if metadata.controllerValue then
                        local colorWheels = fcp:inspector():color():colorWheels()
                        if colorWheels then
                            local value = tools.round(metadata.controllerValue / 127*255*2-255)
                            if metadata.controllerValue == 128/2 then value = 0 end
                            colorWheels:show():color(wheel[i], colors[v], value)
                        end
                    end
                end,
            })
        end
    end

    return mod
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.midi.controls.colorwheels",
    group           = "finalcutpro",
    dependencies    = {
        ["core.midi.manager"] = "manager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    return mod.init(deps)
end

return plugin