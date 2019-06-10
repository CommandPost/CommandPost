--- === plugins.finalcutpro.midi.controls.audio ===
---
--- Final Cut Pro MIDI Audio Controls.

local require = require

local log               = require "hs.logger".new "audio"

local deferred          = require "cp.deferred"
local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"

local tools             = require "cp.tools"

local rescale           = tools.rescale

local plugin = {
    id              = "finalcutpro.midi.controls.audio",
    group           = "finalcutpro",
    dependencies    = {
        ["core.midi.manager"] = "manager",
    }
}

local function createAbsoluteMIDIVolumeSlider()
    local value
    local updateUI = deferred.new(0.01):action(function()
        fcp:inspector():audio():volume():show():value(value)
    end)
    return function(metadata)
        if metadata.fourteenBitCommand or metadata.pitchChange then
            --------------------------------------------------------------------------------
            -- 14bit:
            --------------------------------------------------------------------------------
            local midiValue
            if metadata.pitchChange then
                midiValue = metadata.pitchChange
            else
                midiValue = metadata.fourteenBitValue
            end
            value = rescale(midiValue, 0, 16383, -96, 12)
            updateUI()
        else
            --------------------------------------------------------------------------------
            -- 7bit:
            --------------------------------------------------------------------------------
            local controllerValue = metadata.controllerValue
            if controllerValue == 64 then
                value = 0
            elseif controllerValue > 64 then
                value = rescale(controllerValue, 65, 127, 0.1, 12)
            elseif controllerValue < 64 then
                if controllerValue > 32 then
                    value = rescale(controllerValue, 32, 63, -12, -0.1)
                else
                    value = rescale(controllerValue, 0, 31, -96, -12.1)
                end
            end
            updateUI()
        end
    end
end

function plugin.init(deps)
    local manager = deps.manager
    local params = {
        group = "fcpx",
        text = "Volume (Absolute)",
        subText = "Controls the volume.",
        fn = createAbsoluteMIDIVolumeSlider(),
    }
    manager.controls:new("volume", params)
end

return plugin