--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.transitions ===
---
--- Controls Final Cut Pro's Transitions.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("transitions")

local chooser			= require("hs.chooser")
local drawing			= require("hs.drawing")
local inspect			= require("hs.inspect")
local screen			= require("hs.screen")
local timer				= require("hs.timer")

local choices			= require("cp.choices")
local config			= require("cp.config")
local dialog			= require("cp.dialog")
local fcp				= require("cp.apple.finalcutpro")
local tools				= require("cp.tools")
local prop				= require("cp.prop")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 			= 2000
local MAX_SHORTCUTS 	= 5

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local action = {}

function action.init(actionmanager)
	action._manager = actionmanager
	action._manager.addAction(action)
end

function action.id()
	return "transition"
end

action.enabled = config.prop(action.id().."ActionEnabled", true)

function action.choices()
	if not action._choices then
		action._choices = choices.new(action.id())
		--------------------------------------------------------------------------------
		-- Transition List:
		--------------------------------------------------------------------------------

		local list = fcp:plugins():transitions()
		if list then
			for i,plugin in ipairs(list) do
				local params = { name = plugin.name, category = plugin.category }
				local subText = i18n("transition_group")
				if plugin.category then
					subText = subText..": "..plugin.category
				end
				if plugin.theme then
					subText = subText.." ("..plugin.theme..")"
				end
				action._choices:add(plugin.name)
					:subText(subText)
					:params(params)
					:id(action.getId(params))
			end
		end
	end
	return action._choices
end

function action.getId(params)
	return string.format("%s:%s:%s", action.id(), params.category, params.name)
end

function action.execute(params)
	if action.enabled() and params and params.name then
		mod.apply(params.name, params.category)
		return true
	end
	return false
end

function action.reset()
	action._choices = nil
end

function mod.getShortcuts()
	return config.get(fcp:currentLanguage() .. ".transitionsShortcuts", {})
end

function mod.getShortcut(number)
	local shortcuts = mod.getShortcuts()
	return shortcuts and shortcuts[number]
end

function mod.setShortcut(number, value)
	assert(number >= 1 and number <= MAX_SHORTCUTS)
	local shortcuts = mod.getShortcuts()
	shortcuts[number] = value
	config.set(fcp:currentLanguage() .. ".transitionsShortcuts", shortcuts)
end

--------------------------------------------------------------------------------
-- TRANSITIONS SHORTCUT PRESSED:
-- The shortcut may be a number from 1-5, in which case the 'assigned' shortcut is applied,
-- or it may be the name of the transition to apply in the current FCPX language.
--------------------------------------------------------------------------------
function mod.apply(shortcut, category)

	--------------------------------------------------------------------------------
	-- Get settings:
	--------------------------------------------------------------------------------
	local currentLanguage = fcp:currentLanguage()

	if type(shortcut) == "number" then
		local params = mod.getShortcut(shortcut)
		if type(params) == "table" then
			shortcut = params.name
			category = params.category
		else
			shortcut = tostring(params)
		end
	end

	if shortcut == nil then
		dialog.displayMessage(i18n("noTransitionShortcut"))
		return false
	end

	--------------------------------------------------------------------------------
	-- Save the Effects Browser layout:
	--------------------------------------------------------------------------------
	local effects = fcp:effects()
	local effectsLayout = effects:saveLayout()

	--------------------------------------------------------------------------------
	-- Get Transitions Browser:
	--------------------------------------------------------------------------------
	local transitions = fcp:transitions()
	local transitionsShowing = transitions:isShowing()
	local transitionsLayout = transitions:saveLayout()

	--------------------------------------------------------------------------------
	-- Make sure panel is open:
	--------------------------------------------------------------------------------
	transitions:show()

	--------------------------------------------------------------------------------
	-- Make sure "Installed Transitions" is selected:
	--------------------------------------------------------------------------------
	transitions:showInstalledTransitions()

	--------------------------------------------------------------------------------
	-- Make sure there's nothing in the search box:
	--------------------------------------------------------------------------------
	transitions:search():clear()

	--------------------------------------------------------------------------------
	-- Click 'All':
	--------------------------------------------------------------------------------
	if category then
		transitions:showTransitionsCategory(category)
	else
		transitions:showAllTransitions()
	end

	--------------------------------------------------------------------------------
	-- Perform Search:
	--------------------------------------------------------------------------------
	transitions:search():setValue(shortcut)

	--------------------------------------------------------------------------------
	-- Get the list of matching transitions
	--------------------------------------------------------------------------------
	local matches = transitions:currentItemsUI()
	if not matches or #matches == 0 then
		--------------------------------------------------------------------------------
		-- If Needed, Search Again Without Text Before First Dash:
		--------------------------------------------------------------------------------
		local index = string.find(shortcut, "-")
		if index ~= nil then
			local trimmedShortcut = string.sub(shortcut, index + 2)
			transitions:search():setValue(trimmedShortcut)

			matches = transitions:currentItemsUI()
			if not matches or #matches == 0 then
				dialog.displayErrorMessage("Unable to find a transition called '"..shortcut.."'.\n\nError occurred in transitionsShortcut().")
				return false
			end
		end
	end

	local transition = matches[1]

	--------------------------------------------------------------------------------
	-- Apply the selected Transition:
	--------------------------------------------------------------------------------
	mod.touchbar.hide()

	transitions:applyItem(transition)

	-- TODO: HACK: This timer exists to  work around a mouse bug in Hammerspoon Sierra
	timer.doAfter(0.1, function()
		mod.touchbar.show()

		transitions:loadLayout(transitionsLayout)
		if effectsLayout then effects:loadLayout(effectsLayout) end
		if not transitionsShowing then transitions:hide() end
	end)

	-- Success!
	return true
end

--------------------------------------------------------------------------------
-- ASSIGN TRANSITIONS SHORTCUT:
--------------------------------------------------------------------------------
function mod.assignTransitionsShortcut(whichShortcut)

	--------------------------------------------------------------------------------
	-- Was Final Cut Pro Open?
	--------------------------------------------------------------------------------
	local wasFinalCutProOpen = fcp:isFrontmost()

	--------------------------------------------------------------------------------
	-- Get settings:
	--------------------------------------------------------------------------------
	local currentLanguage 			= fcp:currentLanguage()
	local choices 					= action.choices():getChoices()

	--------------------------------------------------------------------------------
	-- Error Checking:
	--------------------------------------------------------------------------------
	if choices == nil or #choices == 0 then
		dialog.displayMessage(i18n("assignTransitionsShortcutError"))
		return false
	end

	--------------------------------------------------------------------------------
	-- Sort everything:
	--------------------------------------------------------------------------------
	table.sort(choices, function(a, b)
		return a.text < b.text or a.text == b.text and a.subText < b.subText
	end)

	--------------------------------------------------------------------------------
	-- Setup Chooser:
	--------------------------------------------------------------------------------
	local theChooser = nil
	theChooser = chooser.new(function(result)
		theChooser:hide()
		if result ~= nil then
			--------------------------------------------------------------------------------
			-- Save the selection:
			--------------------------------------------------------------------------------
			mod.setShortcut(whichShortcut, result.text)
		end

		--------------------------------------------------------------------------------
		-- Put focus back in Final Cut Pro:
		--------------------------------------------------------------------------------
		if wasFinalCutProOpen then fcp:launch() end
	end)

	theChooser:bgDark(true):choices(choices):searchSubText(true)

	--------------------------------------------------------------------------------
	-- Allow for Reduce Transparency:
	--------------------------------------------------------------------------------
	if screen.accessibilitySettings()["ReduceTransparency"] then
		theChooser:fgColor(nil)
		          :subTextColor(nil)
	else
		theChooser:fgColor(drawing.color.x11.snow)
 		          :subTextColor(drawing.color.x11.snow)
	end

	--------------------------------------------------------------------------------
	-- Show Chooser:
	--------------------------------------------------------------------------------
	theChooser:show()

	return true
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.timeline.transitions",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.menu.timeline.assignshortcuts"]	= "automation",
		["finalcutpro.commands"]						= "fcpxCmds",
		["finalcutpro.os.touchbar"]						= "touchbar",
		["finalcutpro.action.manager"]							= "actionmanager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	local fcpxRunning = fcp:isRunning()
	mod.touchbar = deps.touchbar

	-- Register the Action
	action.init(deps.actionmanager)

	-- The 'Assign Shortcuts' menu
	local menu = deps.automation:addMenu(PRIORITY, function() return i18n("assignTransitionsShortcuts") end)

	menu:addItems(1000, function()
		--------------------------------------------------------------------------------
		-- Shortcuts:
		--------------------------------------------------------------------------------
		local shortcuts		= mod.getShortcuts()

		local items = {}

		for i = 1, MAX_SHORTCUTS do
			local shortcutName = shortcuts[i] or i18n("unassignedTitle")
			items[i] = { title = i18n("transitionShortcutTitle", { number = i, title = shortcutName}), fn = function() mod.assignTransitionsShortcut(i) end }
		end

		return items
	end)

	-- Commands
	local fcpxCmds = deps.fcpxCmds
	for i = 1, MAX_SHORTCUTS do
		fcpxCmds:add("cpTransitions"..tools.numberToWord(i)):whenActivated(function() mod.apply(i) end)
	end

	return mod
end

return plugin