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

local function createAbsoluteMIDISlider(param, min, max)
    local value
    local updateUI = deferred.new(0.01):action(function()
        param:value(value)
    end)
    return function(metadata)
        value = metadata.pitchChange or metadata.fourteenBitValue
        value = rescale(value, 0, 16383, min, max)
        updateUI()
    end
end

function plugin.init(deps)
    local manager = deps.manager
    local params = {
        group = "fcpx",
        text = "Volume (Absolute)",
        subText = "Controls the volume.",
        fn = createAbsoluteMIDISlider(fcp:inspector():audio():volume(), -95, 12),
    }
    manager.controls:new("volume", params)
end

return plugin