--- === plugins.finalcutpro.midi.controls.zoom ===
---
--- Final Cut Pro MIDI Zoom Control.

local require = require

--local log               = require "hs.logger".new "zoomMIDI"

local deferred          = require "cp.deferred"
local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local tools             = require "cp.tools"

local rescale           = tools.rescale

local function createAbsoluteMIDIZoomSlider()
    local value

    local appearance = fcp.timeline.toolbar.appearance

    local hide = deferred.new(1.5):action(function()
        appearance:hide()
    end)

    local updateUI = deferred.new(0.01):action(function()
        appearance:show()
        appearance.zoomAmount(value)
        hide()
    end)
    return function(metadata)
        if metadata.fourteenBitCommand or metadata.pitchChange then
            --------------------------------------------------------------------------------
            -- 14bit:
            --------------------------------------------------------------------------------
            local midiValue = metadata.pitchChange or metadata.fourteenBitValue
            value = rescale(midiValue, 0, 16383, 0, 10)
            updateUI()
        else
            --------------------------------------------------------------------------------
            -- 7bit:
            --------------------------------------------------------------------------------
            local controllerValue = metadata.controllerValue
            value = rescale(controllerValue, 0, 127, 0, 10)
            updateUI()
        end
    end
end

local plugin = {
    id              = "finalcutpro.midi.controls.zoom",
    group           = "finalcutpro",
    dependencies    = {
        ["core.midi.manager"] = "manager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    local manager = deps.manager

    local params = {
        group = "fcpx",
        text = i18n("timelineZoom") .. " (" .. i18n("absolute") .. ")",
        subText = i18n("midiTimelineZoomDescription"),
        fn = createAbsoluteMIDIZoomSlider(),
    }
    manager.controls:new("zoomSlider", params)
end

return plugin
