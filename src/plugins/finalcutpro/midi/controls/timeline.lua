--- === plugins.finalcutpro.midi.controls.timeline ===
---
--- Final Cut Pro MIDI Timeline Controls.

local require = require

--local log               = require "hs.logger".new "timeline"

local eventtap          = require "hs.eventtap"

local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"

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

    --------------------------------------------------------------------------------
    -- Scrub Timeline:
    --------------------------------------------------------------------------------
    local manager = deps.manager
    manager.controls:new("timelineScrub", {
        group = "fcpx",
        text = i18n("scrubTimeline") .. " ()" .. i18n("relative") .. ")",
        subText = i18n("scrubTimelineDescription"),
        fn = createTimelineScrub(),
    })

    --------------------------------------------------------------------------------
    -- Trim Toggle:
    --------------------------------------------------------------------------------
    manager.controls:new("trimToggle", {
        group = "fcpx",
        text = i18n("trimToggle"),
        subText = i18n("trimToggleDescription"),
        fn = function(metadata)
            if metadata.controllerValue == 127 then
                fcp:doShortcut("SelectToolTrim"):Now()
            elseif metadata.controllerValue == 0 then
                fcp:doShortcut("SelectToolArrowOrRangeSelection"):Now()
            end
        end,
    })

end

return plugin
