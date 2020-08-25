--- === plugins.finalcutpro.timeline.colorboard ===
---
--- Color Board Plugins.

local require = require

local log                   = require "hs.logger".new "colorBoard"

local eventtap              = require "hs.eventtap"
local timer                 = require "hs.timer"

local dialog                = require "cp.dialog"
local fcp                   = require "cp.apple.finalcutpro"
local i18n                  = require "cp.i18n"
local tools                 = require "cp.tools"

local doWhile               = timer.doWhile
local format                = string.format
local playErrorSound        = tools.playErrorSound

local mod = {}

--- plugins.finalcutpro.timeline.colorboard.startShiftingPuck(puck, percentShift, angleShift) -> none
--- Function
--- Starts shifting the puck, repeating at the keyboard repeat rate. Runs until `stopShiftingPuck()` is called.
---
--- Parameters:
---  * puck         - The puck to shift
---  * property     - The property to shift (typically the `percent` or `angle` value for the puck)
---  * amount       - The amount to shift the property.
---
--- Returns:
---  * None
function mod.startShiftingPuck(puck, property, amount)
    fcp.colorBoard:show()
    if not puck:select():isShowing() then
        playErrorSound()
        return false
    end

    mod.puckShifting = true
    doWhile(function() return mod.puckShifting end, function()
        local value = property()
        if value ~= nil then property(value + amount) end
    end, eventtap.keyRepeatInterval())
end

-- shiftPuck(puck, percentShift, angleShift) -> none
-- Function
-- Shifts a puck.
--
-- Parameters:
--  * puck         - The puck to shift
--  * property     - The property to shift (typically the `percent` or `angle` value for the puck)
--  * amount       - The amount to shift the property.
--
-- Returns:
--  * None
local function shiftPuck(puck, property, amount)
    fcp.colorBoard:show()
    if not puck:select():isShowing() then
        playErrorSound()
        return false
    end
    local value = property()
    if value ~= nil then property(value + amount) end
end

--- plugins.finalcutpro.timeline.colorboard.stopShiftingPuck() -> none
--- Function
--- Stops the puck from shifting with the keyboard.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stopShiftingPuck()
    mod.puckShifting = false
end

--- plugins.finalcutpro.timeline.colorboard.startMousePuck(aspect, property) -> none
--- Function
--- Color Board - Puck Control Via Mouse
---
--- Parameters:
---  * aspect - "global", "shadows", "midtones" or "highlights"
---  * property - "Color", "Saturation" or "Exposure"
---
--- Returns:
---  * None
function mod.startMousePuck(puck)
    --------------------------------------------------------------------------------
    -- Delete any pre-existing highlights:
    --------------------------------------------------------------------------------
    mod.playhead.deleteHighlight()

    fcp.colorBoard:show()
    if not fcp.colorBoard:isActive() then
        playErrorSound()
        return false
    end

    --------------------------------------------------------------------------------
    -- Start the puck:
    --------------------------------------------------------------------------------
    puck:start()
    mod.colorPuck = puck
    return true
end

--- plugins.finalcutpro.timeline.colorboard.colorBoardMousePuckRelease() -> none
--- Function
--- Color Board Mouse Puck Release
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.stopMousePuck()
    if mod.colorPuck then
        mod.colorPuck:stop()
        mod.colorPuck = nil
    end
end

--- plugins.finalcutpro.timeline.colorboard.nextAspect() -> none
--- Function
--- Goes to the next Color Board aspect.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.nextAspect()
    --------------------------------------------------------------------------------
    -- Show the Color Board if it's hidden:
    --------------------------------------------------------------------------------
    local colorBoard = fcp.colorBoard
    if not colorBoard:show():isActive() then
        dialog.displayNotification(i18n("colorBoardCouldNotBeActivated"))
        return "Failed"
    end
    colorBoard:nextAspect()
end

local plugin = {
    id = "finalcutpro.timeline.colorboard",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]            = "fcpxCmds",
        ["finalcutpro.browser.playhead"]    = "playhead",
    }
}

function plugin.init(deps)

    mod.playhead = deps.playhead

    local fcpxCmds = deps.fcpxCmds
    local colorBoard = fcp.colorBoard

    local colorBoardAspects = {
        { id = "color", title = "Color", i18n = i18n("color"), control = colorBoard.color, hasAngle = true },
        { id = "saturation", title = "Saturation", i18n = i18n("saturation"), control = colorBoard.saturation },
        { id = "exposure", title = "Exposure", i18n = i18n("exposure"), control = colorBoard.exposure },
    }

    local pucks = {
        { id = "master", title = "Master", i18n = i18n("master"), shortcut = "m" },
        { id = "shadows", title = "Shadows", i18n = i18n("shadows"), shortcut = "," },
        { id = "midtones", title = "Midtones", i18n = i18n("midtones"), shortcut = "." },
        { id = "highlights", title = "Highlights", i18n = i18n("highlights"), shortcut = "/" },
    }

    for i,puck in ipairs(pucks) do
        local iWord = tools.numberToWord(i)
        fcpxCmds:add("cpSelectColorBoardPuck" .. iWord)
            :titled(i18n("cpSelectColorBoardPuck_customTitle", {count = i}))
            :groupedBy("colorboard")
            :whenActivated(function() colorBoard:current()[puck.id]():select() end)

        fcpxCmds:add("cpPuck" .. iWord .. "Mouse")
            :titled(i18n("cpPuckMouse_customTitle", {count = i}))
            :groupedBy("colorboard")
            :whenActivated(function() mod.startMousePuck(colorBoard:current()[puck.id]()) end)
            :whenReleased(function() mod.stopMousePuck() end)

        for _, aspect in ipairs(colorBoardAspects) do
            --------------------------------------------------------------------------------
            -- Find the puck for the current aspect (eg. "color > master"):
            --------------------------------------------------------------------------------
            local puckControl = aspect.control[puck.id]()
            if not puckControl then
                log.ef("Unable to find the %s puck control for the %s aspect.", puck.title, aspect.title)
            end

            fcpxCmds:add("cp" .. aspect.title .. "Puck" .. iWord)
                :titled(i18n("cpPuck_customTitle", {count = i, panel = aspect.title}))
                :groupedBy("colorboard")
                :whenActivated(function() puckControl:select() end)

            fcpxCmds:add("cp" .. aspect.title .. "Puck" .. iWord .. "Up")
                :titled(i18n("cpPuckDirection_customTitle", {count = i, panel = aspect.title, direction = "Up"}) .. " (" .. i18n("keyboardShortcut") .. ")")
                :groupedBy("colorboard")
                :whenActivated(function() mod.startShiftingPuck(puckControl, puckControl.percent, 1) end)
                :whenReleased(function() mod.stopShiftingPuck() end)

            fcpxCmds:add("cp" .. aspect.title .. "Puck" .. iWord .. "Down")
                :titled(i18n("cpPuckDirection_customTitle", {count = i, panel = aspect.title, direction = "Down"}) .. " (" .. i18n("keyboardShortcut") .. ")")
                :groupedBy("colorboard")
                :whenActivated(function() mod.startShiftingPuck(puckControl, puckControl.percent, -1) end)
                :whenReleased(function() mod.stopShiftingPuck() end)

            if aspect.hasAngle then
                fcpxCmds:add("cp" .. aspect.title .. "Puck" .. iWord .. "Left")
                    :titled(i18n("cpPuckDirection_customTitle", {count = i, panel = aspect.title, direction = "Left"}) .. " (" .. i18n("keyboardShortcut") .. ")")
                    :groupedBy("colorboard")
                    :whenActivated(function() mod.startShiftingPuck(puckControl, puckControl.angle, -1) end)
                    :whenReleased(function() mod.stopShiftingPuck() end)

                fcpxCmds:add("cp" .. aspect.title .. "Puck" .. iWord .. "Right")
                    :titled(i18n("cpPuckDirection_customTitle", {count = i, panel = aspect.title, direction = "Right"}) .. " (" .. i18n("keyboardShortcut") .. ")")
                    :groupedBy("colorboard")
                    :whenActivated(function() mod.startShiftingPuck(puckControl, puckControl.angle, 1) end)
                    :whenReleased(function() mod.stopShiftingPuck() end)
            end

            fcpxCmds:add("cp" .. aspect.title .. "Puck" .. iWord .. "Mouse")
                :titled(i18n("cpPuckMousePanel_customTitle", {count = i, panel = aspect.title}) .. " (" .. i18n("keyboardShortcut") .. ")")
                :groupedBy("colorboard")
                :whenActivated(function() mod.startMousePuck(puckControl) end)
                :whenReleased(function() mod.stopMousePuck() end)

            --------------------------------------------------------------------------------
            -- Non-Keyboard Actions (such as MIDI):
            --------------------------------------------------------------------------------
            fcpxCmds:add("cpGeneric" .. aspect.title .. "Puck" .. iWord .. "Up")
                :titled(i18n("cpPuckDirection_customTitle", {count = i, panel = aspect.title, direction = "Up"}))
                :groupedBy("colorboard")
                :whenActivated(function() shiftPuck(puckControl, puckControl.percent, 1) end)

            fcpxCmds:add("cpGeneric" .. aspect.title .. "Puck" .. iWord .. "Down")
                :titled(i18n("cpPuckDirection_customTitle", {count = i, panel = aspect.title, direction = "Down"}))
                :groupedBy("colorboard")
                :whenActivated(function() shiftPuck(puckControl, puckControl.percent, -1) end)

            if aspect.hasAngle then
                fcpxCmds:add("cpGeneric" .. aspect.title .. "Puck" .. iWord .. "Left")
                    :titled(i18n("cpPuckDirection_customTitle", {count = i, panel = aspect.title, direction = "Left"}))
                    :groupedBy("colorboard")
                    :whenActivated(function() shiftPuck(puckControl, puckControl.angle, -1) end)

                fcpxCmds:add("cpGeneric" .. aspect.title .. "Puck" .. iWord .. "Right")
                    :titled(i18n("cpPuckDirection_customTitle", {count = i, panel = aspect.title, direction = "Right"}))
                    :groupedBy("colorboard")
                    :whenActivated(function() shiftPuck(puckControl, puckControl.angle, 1) end)
            end

        end
    end

    --------------------------------------------------------------------------------
    -- Toggle Color Board Panel:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("cpToggleColorBoard")
        :groupedBy("colorboard")
        :whenActivated(mod.nextAspect)

    --------------------------------------------------------------------------------
    -- Reset Color Board - Current Pucks:
    --------------------------------------------------------------------------------
    local iReset, iColorBoard = i18n("reset"), i18n("colorBoard")

    for _,puck in ipairs(pucks) do
        fcpxCmds:add("cpResetColorBoardCurrent" .. puck.title)
        :titled(format("%s %s %s", iReset, iColorBoard, puck.i18n))
        :groupedBy("colorboard")
        :whenActivated(colorBoard:doResetCurrent(puck.id))

        -- register commands for resetting each specific aspect
        for _,aspect in ipairs(colorBoardAspects) do
            fcpxCmds:add("cpResetColorBoard" .. aspect.title .. puck.title)
            :titled(format("%s %s %s %s", iReset, iColorBoard, aspect.i18n, puck.i18n))
            :groupedBy("colorboard")
            :whenActivated(function()
                local puckControl = aspect.control[puck.id]()
                puckControl:show():reset()
            end)
        end
    end
end

return plugin
