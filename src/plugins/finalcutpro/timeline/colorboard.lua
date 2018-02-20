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
local log								= require("hs.logger").new("p_colorboard")

local eventtap                          = require("hs.eventtap")
local timer                             = require("hs.timer")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog                            = require("cp.dialog")
local tools                             = require("cp.tools")

local fcp                               = require("cp.apple.finalcutpro")
local ColorBoardAspect					= require("cp.apple.finalcutpro.inspector.color.ColorBoardAspect")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.timeline.colorboard.startShiftingPuck(puck, percentShift, angleShift) -> none
--- Function
--- Starts shifting the puck, repeating at the keyboard repeat rate. Runs until `stopShiftingPuck()` is called.
---
--- Parameters:
---  * puck			- The puck to shift
---  * property		- The property to shift (typically the `percent` or `angle` value for the puck)
---  * amount		- The amount to shift the property.
---
--- Returns:
---  * None
function mod.startShiftingPuck(puck, property, amount)

    if not puck:select():isShowing() then
        dialog.displayNotification(i18n("pleaseSelectSingleClipInTimeline"))
        return false
    end

	mod.puckShifting = true
	timer.doWhile(function() return mod.puckShifting end, function()
		local value = property()
		if value ~= nil then property(value + amount) end
	end, eventtap.keyRepeatInterval())
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

    if not fcp:colorBoard():isActive() then
        dialog.displayNotification(i18n("pleaseSelectSingleClipInTimeline"))
        return false
    end

	-- start the puck.
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

function mod.nextAspect()

    --------------------------------------------------------------------------------
    -- Show the Color Board if it's hidden:
    --------------------------------------------------------------------------------
    local colorBoard = fcp:colorBoard()
    if not colorBoard:show():isActive() then
        dialog.displayNotification(i18n("colorBoardCouldNotBeActivated"))
        return "Failed"
    end

	colorBoard:nextAspect()

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

	local colorBoard = fcp:colorBoard()

	local colorBoardAspects = {
		{ title = "Color", control = colorBoard:color(), hasAngle = true },
		{ title = "Saturation", control = colorBoard:saturation() },
		{ title = "Exposure", control = colorBoard:exposure() },
	}

	local pucks = {
		{ title = "Master", fn = ColorBoardAspect.master, shortcut = "m" },
		{ title = "Shadows", fn = ColorBoardAspect.shadows, shortcut = "," },
		{ title = "Midtones", fn = ColorBoardAspect.midtones, shortcut = "." },
		{ title = "Highlights", fn = ColorBoardAspect.highlights, shortcut = "/" },
	}

	for i,puck in ipairs(pucks) do
		local iWord = tools.numberToWord(i)
        deps.fcpxCmds:add("cpSelectColorBoardPuck" .. iWord)
            :titled(i18n("cpSelectColorBoardPuck_customTitle", {count = i}))
            :groupedBy("colorboard")
            :activatedBy():ctrl():option():cmd(puck.shortcut)
            :whenActivated(function() puck.fn( colorBoard:current() ):select() end)

        deps.fcpxCmds:add("cpPuck" .. iWord .. "Mouse")
            :titled(i18n("cpPuckMouse_customTitle", {count = i}))
            :groupedBy("colorboard")
            :whenActivated(function() mod.startMousePuck(puck.fn( colorBoard:current() )) end)
            :whenReleased(function() mod.stopMousePuck() end)

		for _, aspect in ipairs(colorBoardAspects) do
			-- find the puck for the current aspect (eg. "color > master")
			local puckControl = puck.fn( aspect.control )
			if not puckControl then
				log.ef("Unable to find the %s puck control for the %s aspect.", puck.title, aspect.title)
			end

            deps.fcpxCmds:add("cp" .. aspect.title .. "Puck" .. iWord)
                :titled(i18n("cpPuck_customTitle", {count = i, panel = aspect.title}))
                :groupedBy("colorboard")
                :whenActivated(function() puckControl:select() end)

            deps.fcpxCmds:add("cp" .. aspect.title .. "Puck" .. iWord .. "Up")
                :titled(i18n("cpPuckDirection_customTitle", {count = i, panel = aspect.title, direction = "Up"}))
                :groupedBy("colorboard")
                :whenActivated(function() mod.startShiftingPuck(puckControl, puckControl.percent, 1) end)
                :whenReleased(function() mod.stopShiftingPuck() end)

            deps.fcpxCmds:add("cp" .. aspect.title .. "Puck" .. iWord .. "Down")
                :titled(i18n("cpPuckDirection_customTitle", {count = i, panel = aspect.title, direction = "Down"}))
                :groupedBy("colorboard")
                :whenActivated(function() mod.startShiftingPuck(puckControl, puckControl.percent, -1) end)
                :whenReleased(function() mod.stopShiftingPuck() end)

            if aspect.hasAngle then
                deps.fcpxCmds:add("cp" .. aspect.title .. "Puck" .. iWord .. "Left")
                    :titled(i18n("cpPuckDirection_customTitle", {count = i, panel = aspect.title, direction = "Left"}))
                    :groupedBy("colorboard")
                    :whenActivated(function() mod.startShiftingPuck(puckControl, puckControl.angle, -1) end)
                    :whenReleased(function() mod.stopShiftingPuck() end)

                deps.fcpxCmds:add("cp" .. aspect.title .. "Puck" .. iWord .. "Right")
                    :titled(i18n("cpPuckDirection_customTitle", {count = i, panel = aspect.title, direction = "Right"}))
                    :groupedBy("colorboard")
                    :whenActivated(function() mod.startShiftingPuck(puckControl, puckControl.angle, 1) end)
                    :whenReleased(function() mod.stopShiftingPuck() end)
            end

            deps.fcpxCmds:add("cp" .. aspect.title .. "Puck" .. iWord .. "Mouse")
                :titled(i18n("cpPuckMousePanel_customTitle", {count = i, panel = aspect.title}))
                :groupedBy("colorboard")
                :whenActivated(function() mod.startMousePuck(puckControl) end)
                :whenReleased(function() mod.stopMousePuck() end)
        end
    end

    deps.fcpxCmds
        :add("cpToggleColorBoard")
        :groupedBy("colorboard")
        :whenActivated(mod.nextAspect)

    return mod

end

return plugin
