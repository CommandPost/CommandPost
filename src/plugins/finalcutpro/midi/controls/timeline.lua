--- === plugins.finalcutpro.midi.controls.timeline ===
---
--- Final Cut Pro MIDI Timeline Controls.

local require = require

--local log               = require "hs.logger".new "timeline"

local eventtap          = require "hs.eventtap"

local axutils		    = require "cp.ui.axutils"
local deferred          = require "cp.deferred"
local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local tools             = require "cp.tools"

local childWithRole     = axutils.childWithRole
local keyStroke         = eventtap.keyStroke
local rescale           = tools.rescale

-- MAX_14BIT -> number
-- Constant
-- Maximum 14bit Limit (16383)
local MAX_14BIT = 0x3FFF


-- MAX_7BIT -> number
-- Constant
-- Maximum 7bit Limit (127)
local MAX_7BIT  = 0x7F

-- doNextFrame() -> none
-- Function
-- Triggers keyboard shortcuts to go to the next frame.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function doNextFrame()
    keyStroke({"shift"}, "right", 0)
end

-- doPreviousFrame() -> none
-- Function
-- Triggers keyboard shortcuts to go to the previous frame.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function doPreviousFrame()
    keyStroke({"shift"}, "left", 0)
end

-- createTimelineScrub() -> function
-- Function
-- Returns the Timeline Scrub callback.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
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
        text = i18n("scrubTimeline") .. " (" .. i18n("relative") .. ")",
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

    --------------------------------------------------------------------------------
    -- Timeline Scroll:
    --------------------------------------------------------------------------------
    local updateTimelineScrollValue
    local updateTimelineScroll = deferred.new(0.01):action(function()
        local timelineUI = fcp:timeline():UI()
        local splitGroup = timelineUI and childWithRole(timelineUI, "AXSplitGroup")
        local scrollArea = splitGroup and childWithRole(splitGroup, "AXScrollArea")
        local scrollBar = scrollArea and childWithRole(scrollArea, "AXScrollBar")
        if scrollBar then
            scrollBar:setAttributeValue("AXValue", tonumber(updateTimelineScrollValue))
        end
    end)

    manager.controls:new("verticalTimelineScroll", {
        group = "fcpx",
        text = i18n("verticalTimelineScroll"),
        subText = i18n("verticalTimelineScrollDescription"),
        fn = function(metadata)
            if metadata.fourteenBitCommand or metadata.pitchChange then
                --------------------------------------------------------------------------------
                -- 14bit:
                --------------------------------------------------------------------------------
                local midiValue = metadata.pitchChange or metadata.fourteenBitValue
                if type(midiValue) == "number" then
                    updateTimelineScrollValue = rescale(midiValue, 0, MAX_14BIT, 0, 1)
                end
            else
                --------------------------------------------------------------------------------
                -- 7bit:
                --------------------------------------------------------------------------------
                local midiValue = metadata.controllerValue
                if type(midiValue) == "number" then
                    updateTimelineScrollValue = rescale(midiValue, 0, MAX_7BIT, 0, 1)
                end
            end
            updateTimelineScroll()
        end,
    })

end

return plugin
