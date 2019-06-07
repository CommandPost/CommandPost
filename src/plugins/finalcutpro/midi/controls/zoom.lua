--- === plugins.finalcutpro.midi.controls.zoom ===
---
--- Final Cut Pro MIDI Zoom Control.

local require = require

local log               = require "hs.logger".new "zoomMIDI"

local deferred          = require "cp.deferred"
local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"

local plugin = {
    id              = "finalcutpro.midi.controls.zoom",
    group           = "finalcutpro",
    dependencies    = {
        ["core.midi.manager"] = "manager",
    }
}

function plugin.init(deps)
    local manager = deps.manager

    local cachedValue

    local updateUI = deferred.new(0.01):action(function()
        if cachedValue then
            fcp:timeline():toolbar():appearance():show():zoomAmount():setValue(cachedValue / (16383/10))
        end
    end)

    local control = function(metadata)
        local value
        if metadata.pitchChange then
            value = metadata.pitchChange
        else
            value = metadata.fourteenBitValue
        end
        cachedValue = value
        updateUI()
    end

    local params = {
        group = "fcpx",
        text = i18n("timelineZoom") .. " (" .. i18n("absolute") .. ")",
        subText = i18n("midiTimelineZoomDescription"),
        fn = control,
    }
    manager.controls:new("zoomSlider", params)
end

return plugin
