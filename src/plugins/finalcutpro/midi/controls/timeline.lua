--- === plugins.finalcutpro.midi.controls.timeline ===
---
--- Final Cut Pro MIDI Timeline Controls.

local require = require

--local log               = require "hs.logger".new "zoomMIDI"

local eventtap          = require "hs.eventtap"

local keyStroke         = eventtap.keyStroke

local function doNextFrame()
    keyStroke({"shift"}, "right", 0)
end

local function doPreviousFrame()
    keyStroke({"shift"}, "left", 0)
end

local function createTimelineScrub()
    local lastValue
    return function(metadata)
        local currentValue = metadata.controllerValue
        if lastValue then
            if currentValue == 0 and lastValue == 0 then
                doPreviousFrame()
            elseif currentValue == 127 and lastValue == 127 then
                doNextFrame()
            elseif lastValue == 127 and currentValue == 0 then
                doNextFrame()
            elseif lastValue == 0 and currentValue == 127 then
                doPreviousFrame()
            elseif currentValue > lastValue then
                doNextFrame()
            elseif currentValue < lastValue then
                doPreviousFrame()
            end
        end
        lastValue = currentValue
    end
end

local plugin = {
    id              = "finalcutpro.midi.controls.timeline",
    group           = "finalcutpro",
    dependencies    = {
        ["core.midi.manager"] = "manager",
    }
}

function plugin.init(deps)
    local manager = deps.manager
    local params = {
        group = "fcpx",
        text = "Scrub Timeline (Relative)",
        subText = "Allows you to move the playhead one frame left or right.",
        fn = createTimelineScrub(),
    }
    manager.controls:new("timelineScrub", params)
end

return plugin
