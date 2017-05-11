--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.effects ===
---
--- Controls Final Cut Pro's Effects.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("effects")

local chooser			= require("hs.chooser")
local screen			= require("hs.screen")
local drawing			= require("hs.drawing")
local timer				= require("hs.timer")
local inspect			= require("hs.inspect")

local choices			= require("cp.choices")
local fcp				= require("cp.apple.finalcutpro")
local dialog			= require("cp.dialog")
local tools				= require("cp.tools")
local config			= require("cp.config")
local prop				= require("cp.prop")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local MAX_SHORTCUTS = 5

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local videoaction = {}
local audioaction = {}

function videoaction.init(videoactionmanager)
	videoaction._manager = videoactionmanager
	videoaction._manager.addAction(videoaction)
end

function videoaction.id()
	return "video"
end

videoaction.enabled = config.prop(videoaction.id().."ActionEnabled", true)

function videoaction.choices()
	if not videoaction._choices then
		videoaction._choices = choices.new(videoaction.id())
		--------------------------------------------------------------------------------
		-- Video Effects List:
		--------------------------------------------------------------------------------

		local effects = mod.getVideoEffects()
		if effects ~= nil and next(effects) ~= nil then
			for i,name in ipairs(effects) do
				local params = { name = name }
				videoaction._choices:add(name)
					:subText(i18n("videoEffect_group"))
					:params(params)
					:id(videoaction.getId(params))
			end
		end
	end
	return videoaction._choices
end

function videoaction.getId(params)
	return videoaction.id() .. ":" .. params.name
end

function videoaction.execute(params)
	if params and params.name then
		mod.apply(params.name)
		return true
	end
	return false
end

function videoaction.reset()
	videoaction._choices = nil
end

function audioaction.init(audioactionmanager)
	audioaction._manager = audioactionmanager
	audioaction._manager.addAction(audioaction)
end

function audioaction.id()
	return "audio"
end

audioaction.enabled = config.prop(audioaction.id().."ActionEnabled", true)

function audioaction.choices()
	if not audioaction._choices then
		audioaction._choices = choices.new(audioaction.id())
		--------------------------------------------------------------------------------
		-- Audio Effects List:
		--------------------------------------------------------------------------------
		local effects = mod.getAudioEffects()
		if effects ~= nil and next(effects) ~= nil then
			for i,name in ipairs(effects) do
				local params = { name = name }
				audioaction._choices:add(name)
					:subText(i18n("audioEffect_group"))
					:params(params)
					:id(audioaction.getId(params))
			end
		end
	end
	return audioaction._choices
end

function audioaction.getId(params)
	return audioaction.id() .. ":" .. params.name
end

function audioaction.execute(params)
	if params and params.name then
		mod.apply(params.name)
		return true
	end
	return false
end

function audioaction.reset()
	audioaction._choices = nil
end

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

function mod.getShortcuts()
	return config.get(fcp:getCurrentLanguage() .. ".effectsShortcuts", {})
end

function mod.setShortcut(number, value)
	assert(number >= 1 and number <= MAX_SHORTCUTS)
	local shortcuts = mod.getShortcuts()
	shortcuts[number] = value
	config.set(fcp:getCurrentLanguage() .. ".effectsShortcuts", shortcuts)
end

function mod.getVideoEffects()
	return config.get(fcp:getCurrentLanguage() .. ".allVideoEffects")
end

function mod.getAudioEffects()
	return config.get(fcp:getCurrentLanguage() .. ".allAudioEffects")
end

--------------------------------------------------------------------------------
-- SHORTCUT PRESSED:
-- The shortcut may be a number from 1-5, in which case the 'assigned' shortcut is applied,
-- or it may be the name of the effect to apply in the current FCPX language.
--------------------------------------------------------------------------------
function mod.apply(shortcut)

	--------------------------------------------------------------------------------
	-- Get settings:
	--------------------------------------------------------------------------------
	local currentLanguage = fcp:getCurrentLanguage()

	if type(shortcut) == "number" then
		shortcut = mod.getShortcuts()[shortcut]
	end

	if shortcut == nil then
		dialog.displayMessage(i18n("noEffectShortcut"))
		return false
	end

	--------------------------------------------------------------------------------
	-- Save the Transitions Browser layout:
	--------------------------------------------------------------------------------
	local transitions = fcp:transitions()
	local transitionsLayout = transitions:saveLayout()

	--------------------------------------------------------------------------------
	-- Get Effects Browser:
	--------------------------------------------------------------------------------
	local effects = fcp:effects()
	local effectsShowing = effects:isShowing()
	local effectsLayout = effects:saveLayout()

	fcp:launch()

	--------------------------------------------------------------------------------
	-- Make sure panel is open:
	--------------------------------------------------------------------------------
	effects:show()

	--------------------------------------------------------------------------------
	-- Make sure "Installed Effects" is selected:
	--------------------------------------------------------------------------------
	effects:showInstalledEffects()

	--------------------------------------------------------------------------------
	-- Make sure there's nothing in the search box:
	--------------------------------------------------------------------------------
	effects:search():clear()

	--------------------------------------------------------------------------------
	-- Click 'All':
	--------------------------------------------------------------------------------
	effects:showAllTransitions()

	--------------------------------------------------------------------------------
	-- Perform Search:
	--------------------------------------------------------------------------------
	effects:search():setValue(shortcut)

	--------------------------------------------------------------------------------
	-- Get the list of matching effects
	--------------------------------------------------------------------------------
	local matches = effects:currentItemsUI()
	if not matches or #matches == 0 then
		--------------------------------------------------------------------------------
		-- If Needed, Search Again Without Text Before First Dash:
		--------------------------------------------------------------------------------
		local index = string.find(shortcut, "-")
		if index ~= nil then
			local trimmedShortcut = string.sub(shortcut, index + 2)
			effects:search():setValue(trimmedShortcut)

			matches = effects:currentItemsUI()
			if not matches or #matches == 0 then
				dialog.displayErrorMessage("Unable to find a transition called '"..shortcut.."'.\n\nError occurred in effectsShortcut().")
				return false
			end
		end
	end

	local effect = matches[1]

	--------------------------------------------------------------------------------
	-- Apply the selected Transition:
	--------------------------------------------------------------------------------
	mod.touchbar.hide()

	effects:applyItem(effect)

	-- TODO: HACK: This timer exists to  work around a mouse bug in Hammerspoon Sierra
	timer.doAfter(0.1, function()
		mod.touchbar.show()

		effects:loadLayout(effectsLayout)
		if transitionsLayout then transitions:loadLayout(transitionsLayout) end
		if not effectsShowing then effects:hide() end
	end)

	-- Success!
	return true
end

function mod.choices()
	if not mod._choices then
		mod._choices = choices.new("effect")
	end
	return mod._choices

end

--------------------------------------------------------------------------------
-- ASSIGN EFFECTS SHORTCUT:
--------------------------------------------------------------------------------
function mod.assignEffectsShortcut(whichShortcut)

	--------------------------------------------------------------------------------
	-- Was Final Cut Pro Open?
	--------------------------------------------------------------------------------
	local wasFinalCutProOpen = fcp:isFrontmost()

	--------------------------------------------------------------------------------
	-- Get settings:
	--------------------------------------------------------------------------------
	local currentLanguage 		= fcp:getCurrentLanguage()
	local listUpdated 	= mod.listUpdated()
	local allVideoEffects 		= mod.getVideoEffects()
	local allAudioEffects 		= mod.getAudioEffects()

	--------------------------------------------------------------------------------
	-- Error Checking:
	--------------------------------------------------------------------------------
	if not listUpdated
	   or allVideoEffects == nil or allAudioEffects == nil
	   or next(allVideoEffects) == nil or next(allAudioEffects) == nil then
		dialog.displayMessage(i18n("assignEffectsShortcutError"))
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Video Effects List:
	--------------------------------------------------------------------------------
	local choices = {}
	if allVideoEffects ~= nil and next(allVideoEffects) ~= nil then
		for i=1, #allVideoEffects do
			individualEffect = {
				["text"] = allVideoEffects[i],
				["subText"] = "Video Effect",
			}
			table.insert(choices, 1, individualEffect)
		end
	end

	--------------------------------------------------------------------------------
	-- Audio Effects List:
	--------------------------------------------------------------------------------
	if allAudioEffects ~= nil and next(allAudioEffects) ~= nil then
		for i=1, #allAudioEffects do
			individualEffect = {
				["text"] = allAudioEffects[i],
				["subText"] = "Audio Effect",
			}
			table.insert(choices, 1, individualEffect)
		end
	end

	--------------------------------------------------------------------------------
	-- Sort everything:
	--------------------------------------------------------------------------------
	table.sort(choices, function(a, b) return a.text < b.text end)

	--------------------------------------------------------------------------------
	-- Setup Chooser:
	--------------------------------------------------------------------------------
	local effectChooser = nil
	effectChooser = chooser.new(function(result)
		effectChooser:hide()
		effectChooser = nil

		--------------------------------------------------------------------------------
		-- Perform Specific Function:
		--------------------------------------------------------------------------------
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

	effectChooser:bgDark(true):choices(choices)

	--------------------------------------------------------------------------------
	-- Allow for Reduce Transparency:
	--------------------------------------------------------------------------------
	if screen.accessibilitySettings()["ReduceTransparency"] then
		effectChooser:fgColor(nil)
					 :subTextColor(nil)
	else
		effectChooser:fgColor(drawing.color.x11.snow)
	 				 :subTextColor(drawing.color.x11.snow)
	end

	--------------------------------------------------------------------------------
	-- Show Chooser:
	--------------------------------------------------------------------------------
	effectChooser:show()
end

--------------------------------------------------------------------------------
-- GET LIST OF EFFECTS:
--------------------------------------------------------------------------------
function mod.updateEffectsList()

	--------------------------------------------------------------------------------
	-- Make sure Final Cut Pro is active:
	--------------------------------------------------------------------------------
	fcp:launch()

	--------------------------------------------------------------------------------
	-- Make sure Effects panel is open:
	--------------------------------------------------------------------------------
	local effects = fcp:effects()
	local effectsShowing = effects:isShowing()
	if not effects:show():isShowing() then
		dialog.displayErrorMessage("Unable to activate the Effects panel.\n\nError occurred in updateEffectsList().")
		return false
	end

	local effectsLayout = effects:saveLayout()

	--------------------------------------------------------------------------------
	-- Make sure "Installed Effects" is selected:
	--------------------------------------------------------------------------------
	effects:showInstalledEffects()

	--------------------------------------------------------------------------------
	-- Make sure there's nothing in the search box:
	--------------------------------------------------------------------------------
	effects:search():clear()

	local sidebar = effects:sidebar()

	--------------------------------------------------------------------------------
	-- Ensure the sidebar is visible
	--------------------------------------------------------------------------------
	effects:showSidebar()

	--------------------------------------------------------------------------------
	-- If it's still invisible, we have a problem.
	--------------------------------------------------------------------------------
	if not sidebar:isShowing() then
		dialog.displayErrorMessage("Unable to activate the Effects sidebar.\n\nError occurred in updateEffectsList().")
		return false
	end

	--------------------------------------------------------------------------------
	-- Click 'All Video':
	--------------------------------------------------------------------------------
	if not effects:showAllVideoEffects() then
		dialog.displayErrorMessage("Unable to select all video effects.\n\nError occurred in updateEffectsList().")
		return false
	end

	--------------------------------------------------------------------------------
	-- Get list of All Video Effects:
	--------------------------------------------------------------------------------
	local allVideoEffects = effects:getCurrentTitles()
	if not allVideoEffects then
		dialog.displayErrorMessage("Unable to get list of all effects.\n\nError occurred in updateEffectsList().")
		return false
	end

	--------------------------------------------------------------------------------
	-- Click 'All Audio':
	--------------------------------------------------------------------------------
	if not effects:showAllAudioEffects() then
		dialog.displayErrorMessage("Unable to select all audio effects.\n\nError occurred in updateEffectsList().")
		return false
	end

	--------------------------------------------------------------------------------
	-- Get list of All Audio Effects:
	--------------------------------------------------------------------------------
	local allAudioEffects = effects:getCurrentTitles()
	if not allAudioEffects then
		dialog.displayErrorMessage("Unable to get list of all effects.\n\nError occurred in updateEffectsList().")
		return false
	end

	--------------------------------------------------------------------------------
	-- Restore Effects:
	--------------------------------------------------------------------------------
	effects:loadLayout(effectsLayout)
	if not effectsShowing then effects:hide() end

	--------------------------------------------------------------------------------
	-- All done!
	--------------------------------------------------------------------------------
	if #allVideoEffects == 0 or #allAudioEffects == 0 then
		dialog.displayMessage(i18n("updateEffectsListFailed") .. "\n\n" .. i18n("pleaseTryAgain"))
		return false
	else
		--------------------------------------------------------------------------------
		-- Save Results to Settings:
		--------------------------------------------------------------------------------
		local currentLanguage = fcp:getCurrentLanguage()
		config.set(currentLanguage .. ".allVideoEffects", allVideoEffects)
		config.set(currentLanguage .. ".allAudioEffects", allAudioEffects)
		config.set(currentLanguage .. ".effectsListUpdated", true)
		audioaction.reset()
		videoaction.reset()
		return true
	end

end

mod.listUpdated = prop.new(function()
	return config.get(fcp:getCurrentLanguage() .. ".effectsListUpdated", false)
end)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local PRIORITY = 1000

local plugin = {
	id = "finalcutpro.timeline.effects",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.menu.timeline.assignshortcuts"]	= "automation",
		["finalcutpro.commands"]						= "fcpxCmds",
		["finalcutpro.os.touchbar"]						= "touchbar",
		["core.action.manager"]							= "actionmanager",
	}
}

function plugin.init(deps)
	videoaction.init(deps.actionmanager)
	audioaction.init(deps.actionmanager)

	local fcpxRunning = fcp:isRunning()
	mod.touchbar = deps.touchbar

	-- The 'Assign Shortcuts' menu
	local menu = deps.automation:addMenu(PRIORITY, function() return i18n("assignEffectsShortcuts") end)

	menu:addItems(1000, function()
		--------------------------------------------------------------------------------
		-- Effects Shortcuts:
		--------------------------------------------------------------------------------
		local listUpdated 	= mod.listUpdated()
		local effectsShortcuts		= mod.getShortcuts()

		local items = {}

		for i = 1,MAX_SHORTCUTS do
			local shortcutName = effectsShortcuts[i] or i18n("unassignedTitle")
			items[i] = { title = i18n("effectShortcutTitle", { number = i, title = shortcutName}), fn = function() mod.assignEffectsShortcut(i) end,	disabled = not listUpdated }
		end

		return items
	end)

	-- Commands with default shortcuts
	local fcpxCmds = deps.fcpxCmds
	for i = 1, MAX_SHORTCUTS do
		fcpxCmds:add("cpEffects"..tools.numberToWord(i))
			:activatedBy():ctrl():shift(tostring(i))
			:whenPressed(function() mod.apply(i) end)
	end

	return mod
end

return plugin