--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C O L O R    B O A R D    P L U G I N                    --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.colorboard ===
---
--- Color Board Plugins.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local eventtap                          = require("hs.eventtap")
local timer                             = require("hs.timer")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog                            = require("cp.dialog")
local fcp                               = require("cp.apple.finalcutpro")
local tools                             = require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.timeline.colorboard.selectPuck(aspect, property, whichDirection) -> none
--- Function
--- Color Board - Select Puck
---
--- Parameters:
---  * aspect - "global", "shadows", "midtones" or "highlights"
---  * property - "Color", "Saturation" or "Exposure"
---  * whichDirection - "up" or "down"
---
--- Returns:
---  * None
function mod.selectPuck(aspect, property, whichDirection)

    --------------------------------------------------------------------------------
    -- Show the Color Board with the correct panel
    --------------------------------------------------------------------------------
    local colorBoard = fcp:colorBoard()

    --------------------------------------------------------------------------------
    -- Show the Color Board if it's hidden:
    --------------------------------------------------------------------------------
    if not colorBoard:isShowing() then colorBoard:show() end

    if not colorBoard:isActive() then
        dialog.displayNotification(i18n("pleaseSelectSingleClipInTimeline"))
        return "Failed"
    end

    --------------------------------------------------------------------------------
    -- If a Direction is specified:
    --------------------------------------------------------------------------------
    if whichDirection ~= nil then

        --------------------------------------------------------------------------------
        -- Get shortcut key from plist, press and hold if required:
        --------------------------------------------------------------------------------
        mod.releaseColorBoardDown = false
        timer.doUntil(function() return mod.releaseColorBoardDown end, function()
            if whichDirection == "up" then
                colorBoard:shiftPercentage(aspect, property, 1)
            elseif whichDirection == "down" then
                colorBoard:shiftPercentage(aspect, property, -1)
            elseif whichDirection == "left" then
                colorBoard:shiftAngle(aspect, property, -1)
            elseif whichDirection == "right" then
                colorBoard:shiftAngle(aspect, property, 1)
            end
        end, eventtap.keyRepeatInterval())
    else
        --------------------------------------------------------------------------------
        -- Just select the puck:
        --------------------------------------------------------------------------------
        colorBoard:selectPuck(aspect, property)
    end
end

--- plugins.finalcutpro.timeline.colorboard.colorBoardSelectPuckRelease() -> none
--- Function
--- Color Board Release Keypress
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.colorBoardSelectPuckRelease()
    mod.releaseColorBoardDown = true
end

--- plugins.finalcutpro.timeline.colorboard.mousePuck(aspect, property) -> none
--- Function
--- Color Board - Puck Control Via Mouse
---
--- Parameters:
---  * aspect - "global", "shadows", "midtones" or "highlights"
---  * property - "Color", "Saturation" or "Exposure"
---
--- Returns:
---  * None
function mod.mousePuck(aspect, property)
    --------------------------------------------------------------------------------
    -- Stop Existing Color Pucker:
    --------------------------------------------------------------------------------
    if mod.colorPucker then
        mod.colorPucker:stop()
    end

    --------------------------------------------------------------------------------
    -- Delete any pre-existing highlights:
    --------------------------------------------------------------------------------
    mod.playhead.deleteHighlight()

    local colorBoard = fcp:colorBoard()

    --------------------------------------------------------------------------------
    -- Show the Color Board if it's hidden:
    --------------------------------------------------------------------------------
    if not colorBoard:isShowing() then colorBoard:show() end

    if not colorBoard:isActive() then
        dialog.displayNotification(i18n("pleaseSelectSingleClipInTimeline"))
        return "Failed"
    end

    mod.colorPucker = colorBoard:startPucker(aspect, property)
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
function mod.colorBoardMousePuckRelease()
    if mod.colorPucker then
        mod.colorPucker:stop()
        mod.colorPicker = nil
    end
end

function mod.toggleColorBoard()

    --------------------------------------------------------------------------------
    -- Show the Color Board if it's hidden:
    --------------------------------------------------------------------------------
    local colorBoard = fcp:colorBoard()
    if not colorBoard:isShowing() then colorBoard:show() end

    if not colorBoard:isActive() then
        dialog.displayNotification(i18n("colorBoardCouldNotBeActivated"))
        return "Failed"
    end

    colorBoard:togglePanel()

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.timeline.colorboard",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]            = "fcpxCmds",
        ["finalcutpro.browser.playhead"]    = "playhead",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    mod.playhead = deps.playhead

    local colorFunction = {
        [1] = "global",
        [2] = "shadows",
        [3] = "midtones",
        [4] = "highlights",
    }

    local selectColorBoardPuckDefaultShortcuts = {
        [1] = "m",
        [2] = ",",
        [3] = ".",
        [4] = "/",
    }

    local colorBoardPanel = {"Color", "Saturation", "Exposure"}

    for i=1, 4 do
        deps.fcpxCmds:add("cpSelectColorBoardPuck" .. tools.numberToWord(i))
            :titled(i18n("cpSelectColorBoardPuck_customTitle", {count = i}))
            :groupedBy("colorboard")
            :activatedBy():ctrl():option():cmd(selectColorBoardPuckDefaultShortcuts[i])
            :whenActivated(function() mod.selectPuck("*", colorFunction[i]) end)

        deps.fcpxCmds:add("cpPuck" .. tools.numberToWord(i) .. "Mouse")
            :titled(i18n("cpPuckMouse_customTitle", {count = i}))
            :groupedBy("colorboard")
            :whenActivated(function() mod.mousePuck("*", colorFunction[i]) end)
            :whenReleased(function() mod.colorBoardMousePuckRelease() end)

        for _, whichPanel in ipairs(colorBoardPanel) do
            deps.fcpxCmds:add("cp" .. whichPanel .. "Puck" .. tools.numberToWord(i))
                :titled(i18n("cpPuck_customTitle", {count = i, panel = whichPanel}))
                :groupedBy("colorboard")
                :whenActivated(function() mod.selectPuck(string.lower(whichPanel), colorFunction[i]) end)

            deps.fcpxCmds:add("cp" .. whichPanel .. "Puck" .. tools.numberToWord(i) .. "Up")
                :titled(i18n("cpPuckDirection_customTitle", {count = i, panel = whichPanel, direction = "Up"}))
                :groupedBy("colorboard")
                :whenActivated(function() mod.selectPuck(string.lower(whichPanel), colorFunction[i], "up") end)
                :whenReleased(function() mod.colorBoardSelectPuckRelease() end)

            deps.fcpxCmds:add("cp" .. whichPanel .. "Puck" .. tools.numberToWord(i) .. "Down")
                :titled(i18n("cpPuckDirection_customTitle", {count = i, panel = whichPanel, direction = "Down"}))
                :groupedBy("colorboard")
                :whenActivated(function() mod.selectPuck(string.lower(whichPanel), colorFunction[i], "down") end)
                :whenReleased(function() mod.colorBoardSelectPuckRelease() end)

            if whichPanel == "Color" then
                deps.fcpxCmds:add("cp" .. whichPanel .. "Puck" .. tools.numberToWord(i) .. "Left")
                    :titled(i18n("cpPuckDirection_customTitle", {count = i, panel = whichPanel, direction = "Left"}))
                    :groupedBy("colorboard")
                    :whenActivated(function() mod.selectPuck(string.lower(whichPanel), colorFunction[i], "left") end)
                    :whenReleased(function() mod.colorBoardSelectPuckRelease() end)

                deps.fcpxCmds:add("cp" .. whichPanel .. "Puck" .. tools.numberToWord(i) .. "Right")
                    :titled(i18n("cpPuckDirection_customTitle", {count = i, panel = whichPanel, direction = "Right"}))
                    :groupedBy("colorboard")
                    :whenActivated(function() mod.selectPuck(string.lower(whichPanel), colorFunction[i], "right") end)
                    :whenReleased(function() mod.colorBoardSelectPuckRelease() end)
            end

            deps.fcpxCmds:add("cp" .. whichPanel .. "Puck" .. tools.numberToWord(i) .. "Mouse")
                :titled(i18n("cpPuckMousePanel_customTitle", {count = i, panel = whichPanel}))
                :groupedBy("colorboard")
                :whenActivated(function() mod.mousePuck(string.lower(whichPanel), colorFunction[i]) end)
                :whenReleased(function() mod.colorBoardMousePuckRelease() end)
        end
    end

    deps.fcpxCmds
        :add("cpToggleColorBoard")
        :groupedBy("colorboard")
        :whenActivated(mod.toggleColorBoard)

    return mod

end

return plugin