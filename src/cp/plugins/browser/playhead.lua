-- Imports
local settings						= require("hs.settings")
local drawing						= require("hs.drawing")
local geometry						= require("hs.geometry")
local timer							= require("hs.timer")

local fcp							= require("cp.finalcutpro")
local dialog						= require("cp.dialog")
local metadata						= require("cp.metadata")

-- Constants
local PRIORITY = 10000
local DEFAULT_TIME = 3
local DEFAULT_COLOR = "Red"

local SHAPE_RECTANGLE 	= "Rectangle"
local SHAPE_CIRCLE		= "Circle"
local SHAPE_DIAMOND		= "Diamond"

-- The Module
local mod = {}

--------------------------------------------------------------------------------
-- Get Highlight Colour Preferences:
--------------------------------------------------------------------------------
function mod.getHighlightColor()
	return settings.get(metadata.settingsPrefix .. ".displayHighlightColour") or DEFAULT_COLOR
end

function mod.setHighlightColor(value)
	settings.set(metadata.settingsPrefix .. ".displayHighlightColour", value)
end

function mod.getHighlightCustomColor()
	return settings.get(metadata.settingsPrefix .. ".displayHighlightCustomColour")
end

function mod.setHighlightCustomColor(value)
	settings.set(metadata.settingsPrefix .. ".displayHighlightCustomColour", value)
end

--------------------------------------------------------------------------------
-- CHANGE HIGHLIGHT COLOUR:
--------------------------------------------------------------------------------
function mod.changeHighlightColor(value)
	if value=="Custom" then
		local customColor = mod.getHighlightCustomColor()
		local result = dialog.displayColorPicker(customColor)
		if result == nil then return nil end
		mod.setHighlightCustomColor(result)
	end
	mod.setHighlightColor(value)
end

function mod.getHighlightShape()
	return settings.get(metadata.settingsPrefix .. ".displayHighlightShape") or SHAPE_RECTANGLE
end

--------------------------------------------------------------------------------
-- CHANGE HIGHLIGHT SHAPE:
--------------------------------------------------------------------------------
function mod.setHighlightShape(value)
	settings.set(metadata.settingsPrefix .. ".displayHighlightShape", value)
end

--------------------------------------------------------------------------------
-- Get Highlight Playhead Time in seconds:
--------------------------------------------------------------------------------
function mod.getHighlightTime()
	return settings.get(metadata.settingsPrefix .. ".highlightPlayheadTime") or DEFAULT_TIME
end

function mod.setHighlightTime(value)
	settings.set(metadata.settingsPrefix .. ".highlightPlayheadTime", value)
end

--------------------------------------------------------------------------------
-- HIGHLIGHT FINAL CUT PRO BROWSER PLAYHEAD:
--------------------------------------------------------------------------------
function mod.highlight()

	--------------------------------------------------------------------------------
	-- Delete any pre-existing highlights:
	--------------------------------------------------------------------------------
	mod.deleteHighlight()

	--------------------------------------------------------------------------------
	-- Get Browser Persistent Playhead:
	--------------------------------------------------------------------------------
	local playhead = fcp:libraries():playhead()
	if playhead:isShowing() then
		mod.highlightFrame(playhead:getFrame())
	end
end

--------------------------------------------------------------------------------
-- HIGHLIGHT MOUSE IN FCPX:
--------------------------------------------------------------------------------
function mod.highlightFrame(frame)

	--------------------------------------------------------------------------------
	-- Delete Previous Highlights:
	--------------------------------------------------------------------------------
	mod.deleteHighlight()

	--------------------------------------------------------------------------------
	-- Get Sizing Preferences:
	--------------------------------------------------------------------------------
	local displayHighlightShape = nil
	displayHighlightShape = settings.get(metadata.settingsPrefix .. ".displayHighlightShape")
	if displayHighlightShape == nil then displayHighlightShape = "Rectangle" end

	--------------------------------------------------------------------------------
	-- Get Highlight Colour Preferences:
	--------------------------------------------------------------------------------
	local displayHighlightColour = settings.get(metadata.settingsPrefix .. ".displayHighlightColour") or "Red"
	if displayHighlightColour == "Red" then 	displayHighlightColour = {["red"]=1,["blue"]=0,["green"]=0,["alpha"]=1} 	end
	if displayHighlightColour == "Blue" then 	displayHighlightColour = {["red"]=0,["blue"]=1,["green"]=0,["alpha"]=1}		end
	if displayHighlightColour == "Green" then 	displayHighlightColour = {["red"]=0,["blue"]=0,["green"]=1,["alpha"]=1}		end
	if displayHighlightColour == "Yellow" then 	displayHighlightColour = {["red"]=1,["blue"]=0,["green"]=1,["alpha"]=1}		end
	if displayHighlightColour == "Custom" then
		local displayHighlightCustomColour = settings.get(metadata.settingsPrefix .. ".displayHighlightCustomColour")
		displayHighlightColour = {red=displayHighlightCustomColour["red"],blue=displayHighlightCustomColour["blue"],green=displayHighlightCustomColour["green"],alpha=1}
	end

	--------------------------------------------------------------------------------
	-- Highlight the FCPX Browser Playhead:
	--------------------------------------------------------------------------------
	if displayHighlightShape == "Rectangle" then
		mod.browserHighlight = drawing.rectangle(geometry.rect(frame.x, frame.y, frame.w, frame.h - 12))
	end
	if displayHighlightShape == "Circle" then
		mod.browserHighlight = drawing.circle(geometry.rect((frame.x-(frame.h/2)+10), frame.y, frame.h-12,frame.h-12))
	end
	if displayHighlightShape == "Diamond" then
		mod.browserHighlight = drawing.circle(geometry.rect(frame.x, frame.y, frame.w, frame.h - 12))
	end
	mod.browserHighlight:setStrokeColor(displayHighlightColour)
					    :setFill(false)
					    :setStrokeWidth(5)
					    :bringToFront(true)
					    :show()

	--------------------------------------------------------------------------------
	-- Set a timer to delete the circle after the configured time:
	--------------------------------------------------------------------------------
	mod.browserHighlightTimer = timer.doAfter(mod.getHighlightTime(), mod.deleteHighlight)

end

--------------------------------------------------------------------------------
-- DELETE ALL HIGHLIGHTS:
--------------------------------------------------------------------------------
function mod.deleteHighlight()
	if mod.browserHighlight ~= nil then
		mod.browserHighlight:delete()
		mod.browserHighlight = nil
		if mod.browserHighlightTimer then
			mod.browserHighlightTimer:stop()
			mod.browserHighlightTimer = nil
		end
	end
end

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.commands.fcpx"] 		= "fcpxCmds",
	["cp.plugins.menu.timeline.highlightplayhead"]	= "prefs",
}

function plugin.init(deps)
	-- Menus
	local section = deps.prefs:addSection(PRIORITY)

	section:addSeparator(1000)
		:addSeparator(9000)

	local highlightColor = section:addMenu(2000, function() return i18n("highlightPlayheadColour") end)
	:addItems(1000, function()
		local displayHighlightColour = mod.getHighlightColor()
		return {
			{ title = i18n("red"), 		fn = function() mod.changeHighlightColor("Red") end, 		checked = displayHighlightColour == "Red" },
			{ title = i18n("blue"), 	fn = function() mod.changeHighlightColor("Blue") end,		checked = displayHighlightColour == "Blue" },
			{ title = i18n("green"), 	fn = function() mod.changeHighlightColor("Green") end, 		checked = displayHighlightColour == "Green"	},
			{ title = i18n("yellow"), 	fn = function() mod.changeHighlightColor("Yellow") end, 	checked = displayHighlightColour == "Yellow" },
			{ title = "-" },
			{ title = i18n("custom"), 	fn = function() mod.changeHighlightColor("Custom") end, 	checked = displayHighlightColour == "Custom" },
		}
	end)

	local highlightShape = section:addMenu(3000, function() return i18n("highlightPlayheadShape") end)
	:addItems(1000, function()
		local shape = mod.getHighlightShape()
		return {
			{ title = i18n("rectangle"),	fn = function() mod.setHighlightShape(SHAPE_RECTANGLE) end,	checked = shape == SHAPE_RECTANGLE	},
			{ title = i18n("circle"), 		fn = function() mod.setHighlightShape(SHAPE_CIRCLE) end, 	checked = shape == SHAPE_CIRCLE		},
			{ title = i18n("diamond"),		fn = function() mod.setHighlightShape(SHAPE_DIAMOND) end, 	checked = shape == SHAPE_DIAMOND	},
		}
	end)

	local highlightTime = section:addMenu(4000, function() return i18n("highlightPlayheadTime") end)
	:addItems(1000, function()
		local highlightPlayheadTime = mod.getHighlightTime()
		return {
			{ title = i18n("one") .. " " .. i18n("secs", {count=1}),	fn = function() mod.setHighlightTime(1) end, 	checked = highlightPlayheadTime == 1 },
			{ title = i18n("two") .. " " .. i18n("secs", {count=2}), 	fn = function() mod.setHighlightTime(2) end, 	checked = highlightPlayheadTime == 2 },
			{ title = i18n("three") .. " " .. i18n("secs", {count=2}), 	fn = function() mod.setHighlightTime(3) end, 	checked = highlightPlayheadTime == 3 },
			{ title = i18n("four") .. " " .. i18n("secs", {count=2}), 	fn = function() mod.setHighlightTime(4) end, 	checked = highlightPlayheadTime == 4 },
			{ title = i18n("five") .. " " .. i18n("secs", {count=2}), 	fn = function() mod.setHighlightTime(5) end, 	checked = highlightPlayheadTime == 5 },
			{ title = i18n("six") .. " " .. i18n("secs", {count=2}), 	fn = function() mod.setHighlightTime(6) end, 	checked = highlightPlayheadTime == 6 },
			{ title = i18n("seven") .. " " .. i18n("secs", {count=2}), 	fn = function() mod.setHighlightTime(7) end, 	checked = highlightPlayheadTime == 7 },
			{ title = i18n("eight") .. " " .. i18n("secs", {count=2}), 	fn = function() mod.setHighlightTime(8) end, 	checked = highlightPlayheadTime == 8 },
			{ title = i18n("nine") .. " " .. i18n("secs", {count=2}), 	fn = function() mod.setHighlightTime(9) end, 	checked = highlightPlayheadTime == 9 },
			{ title = i18n("ten") .. " " .. i18n("secs", {count=2}), 	fn = function() mod.setHighlightTime(10) end,	checked = highlightPlayheadTime == 10 },
		}
	end)

	-- Commands
	deps.fcpxCmds:add("FCPXHackHighlightBrowserPlayhead")
		:activatedBy():cmd():option():ctrl("h")
		:whenActivated(mod.highlight)

	return mod
end

return plugin