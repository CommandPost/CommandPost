--- === plugins.finalcutpro.midi.controls.audio ===
---
--- Final Cut Pro MIDI Audio Controls.

local require = require

--local log               = require "hs.logger".new "audio"

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
        fcp.inspector:audio():volume():show():value(value)
    end)
    return function(metadata)
        if metadata.fourteenBitCommand or metadata.pitchChange then
            --------------------------------------------------------------------------------
            -- 14bit:
            --------------------------------------------------------------------------------
            local midiValue = metadata.pitchChange or metadata.fourteenBitValue
            if midiValue == 8192 then
                value = 0
            elseif midiValue > 8192 then
                value = rescale(midiValue, 8193, 16383, 0.1, 12)
            elseif midiValue < 8192 then
                if midiValue > 4096 then
                    value = rescale(midiValue, 4096, 63, -12, -0.1)
                else
                    value = rescale(midiValue, 0, 4095, -96, -12.1)
                end
            end
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
        text = i18n("volume") .. "(" .. i18n("absolute") .. ")",
        subText = i18n("midiVolumeDescription"),
        fn = createAbsoluteMIDIVolumeSlider(),
    }
    manager.controls:new("volume", params)
end

return plugin
