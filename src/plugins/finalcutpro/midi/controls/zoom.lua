--- === plugins.finalcutpro.midi.controls.zoom ===
---
--- Final Cut Pro MIDI Zoom Control.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log               = require("hs.logger").new("zoomMIDI")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp               = require("cp.apple.finalcutpro")
local i18n              = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.midi.controls.zoom.control() -> nil
--- Function
--- Final Cut Pro MIDI Zoom Control
---
--- Parameters:
---  * metadata - table of metadata from the MIDI callback
---
--- Returns:
---  * None
function mod.control(metadata)
    local value
    if metadata.pitchChange then
        value = metadata.pitchChange
    else
        value = metadata.fourteenBitValue
    end
    if type(value) == "number" then
        local appearance = fcp:timeline():toolbar():appearance()
        if appearance then
            --------------------------------------------------------------------------------
            -- MIDI Controller Value (7bit):        0 to 127
            -- MIDI Controller Value (14bit):       0 to 16383
            -- Zoom Slider:                         0 to 10
            --------------------------------------------------------------------------------
            appearance:show():zoomAmount():setValue(value / (16383/10))
        end
    else
        log.ef("Unexpected Value: %s %s", value, value and type(value))
    end
end

--- plugins.finalcutpro.midi.controls.zoom.init() -> nil
--- Function
--- Initialise the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init()

    local params = {
        group = "fcpx",
        text = string.upper(i18n("midi")) .. ": " .. i18n("timelineZoom"),
        subText = i18n("midiTimelineZoomDescription"),
        fn = mod.control,
    }
    mod._manager.controls:new("zoomSlider", params)

    return mod

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.midi.controls.zoom",
    group           = "finalcutpro",
    dependencies    = {
        ["core.midi.manager"] = "manager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    mod._manager = deps.manager
    return mod.init()
end

return plugin
