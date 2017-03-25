-- Imports
local chooser			= require("hs.chooser")
local screen			= require("hs.screen")
local drawing			= require("hs.drawing")
local timer				= require("hs.timer")
local inspect			= require("hs.inspect")

local choices			= require("cp.choices")
local fcp				= require("cp.finalcutpro")
local dialog			= require("cp.dialog")
local metadata			= require("cp.config")
local tools				= require("cp.tools")

local log				= require("hs.logger").new("titles")

-- Constants
local PRIORITY = 3000

local MAX_SHORTCUTS = 5

-- Effects Action
local action = {}
local mod = {}

function action.init(actionmanager)
	action._manager = actionmanager
	action._manager.addAction(action)
end

function action.id()
	return "title"
end

function action.setEnabled(value)
	metadata.set(action.id().."ActionEnabled", value)
	action._manager.refresh()
end

function action.isEnabled()
	return metadata.get(action.id().."ActionEnabled", true)
end

function action.toggleEnabled()
	action.setEnabled(not action.isEnabled())
end

function action.choices()
	if not action._choices then
		action._choices = choices.new(action.id())
		--------------------------------------------------------------------------------
		-- Titles List:
		--------------------------------------------------------------------------------

		local list = mod.getTitles()
		if list ~= nil and next(list) ~= nil then
			for i,name in ipairs(list) do
				local params = { name = name }
				action._choices:add(name)
					:subText(i18n("title_group"))
					:params(params)
					:id(action.getId(params))
			end
		end
	end
	return action._choices
end

function action.getId(params)
	return action.id() .. ":" .. params.name
end

function action.execute(params)
	if params and params.name then
		mod.apply(params.name)
		return true
	end
	return false
end

function action.reset()
	action._choices = nil
end

-- The Module

function mod.getShortcuts()
	return metadata.get(fcp:getCurrentLanguage() .. ".titlesShortcuts", {})
end

function mod.setShortcut(number, value)
	assert(number >= 1 and number <= MAX_SHORTCUTS)
	local shortcuts = mod.getShortcuts()
	shortcuts[number] = value
	metadata.set(fcp:getCurrentLanguage() .. ".titlesShortcuts", shortcuts)
end

function mod.getTitles()
	return metadata.get(fcp:getCurrentLanguage() .. ".allTitles")
end

--------------------------------------------------------------------------------
-- TITLES SHORTCUT PRESSED:
-- The shortcut may be a number from 1-5, in which case the 'assigned' shortcut is applied,
-- or it may be the name of the title to apply in the current FCPX language.
--------------------------------------------------------------------------------
function mod.apply(shortcut)

	--------------------------------------------------------------------------------
	-- Get settings:
	--------------------------------------------------------------------------------
	if type(shortcut) == "number" then
		shortcut = mod.getShortcuts()[shortcut]
	end

	if shortcut == nil then
		dialog.displayMessage(i18n("noTitleShortcut"))
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Save the main Browser layout:
	--------------------------------------------------------------------------------
	local browser = fcp:browser()
	local browserLayout = browser:saveLayout()

	--------------------------------------------------------------------------------
	-- Get Titles Browser:
	--------------------------------------------------------------------------------
	local generators = fcp:generators()
	local generatorsShowing = generators:isShowing()
	local generatorsLayout = generators:saveLayout()


	--------------------------------------------------------------------------------
	-- Make sure FCPX is at the front.
	--------------------------------------------------------------------------------
	fcp:launch()

	--------------------------------------------------------------------------------
	-- Make sure the panel is open:
	--------------------------------------------------------------------------------
	generators:show()

	if not generators:isShowing() then
		dialog.displayErrorMessage("Unable to display the Titles panel.\n\nError occurred in titles.apply(...)")
		return false
	end

	--------------------------------------------------------------------------------
	-- Make sure there's nothing in the search box:
	--------------------------------------------------------------------------------
	generators:search():clear()

	--------------------------------------------------------------------------------
	-- Click 'All':
	--------------------------------------------------------------------------------
	generators:showAllTitles()

	--------------------------------------------------------------------------------
	-- Make sure "Installed Titles" is selected:
	--------------------------------------------------------------------------------
	generators:showInstalledTitles()

	--------------------------------------------------------------------------------
	-- Perform Search:
	--------------------------------------------------------------------------------
	generators:search():setValue(shortcut)

	--------------------------------------------------------------------------------
	-- Get the list of matching effects
	--------------------------------------------------------------------------------
	local matches = generators:currentItemsUI()
	if not matches or #matches == 0 then
		--------------------------------------------------------------------------------
		-- If Needed, Search Again Without Text Before First Dash:
		--------------------------------------------------------------------------------
		local index = string.find(shortcut, "-")
		if index ~= nil then
			local trimmedShortcut = string.sub(shortcut, index + 2)
			effects:search():setValue(trimmedShortcut)

			matches = generators:currentItemsUI()
			if not matches or #matches == 0 then
				dialog.displayErrorMessage("Unable to find a transition called '"..shortcut.."'.\n\nError occurred in titles.apply(...).")
				return "Fail"
			end
		end
	end

	local generator = matches[1]

	--------------------------------------------------------------------------------
	-- Apply the selected Transition:
	--------------------------------------------------------------------------------
	mod.touchbar.hide()

	generators:applyItem(generator)

	-- TODO: HACK: This timer exists to  work around a mouse bug in Hammerspoon Sierra
	timer.doAfter(0.1, function()
		mod.touchbar.show()

		generators:loadLayout(generatorsLayout)
		if browserLayout then browser:loadLayout(browserLayout) end
		if not generatorsShowing then generators:hide() end
	end)

end

--------------------------------------------------------------------------------
-- ASSIGN TITLES SHORTCUT:
--------------------------------------------------------------------------------
function mod.assignTitlesShortcut(whichShortcut)

	--------------------------------------------------------------------------------
	-- Was Final Cut Pro Open?
	--------------------------------------------------------------------------------
	local wasFinalCutProOpen = fcp:isFrontmost()

	--------------------------------------------------------------------------------
	-- Get settings:
	--------------------------------------------------------------------------------
	local currentLanguage 			= fcp:getCurrentLanguage()
	local titlesListUpdated 	= mod.isTitlesListUpdated()
	local allTitles 			= mod.getTitles()

	--------------------------------------------------------------------------------
	-- Error Checking:
	--------------------------------------------------------------------------------
	if not titlesListUpdated
	   or allTitles == nil
	   or next(allTitles) == nil then
		dialog.displayMessage(i18n("assignTitlesShortcutError"))
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Titles List:
	--------------------------------------------------------------------------------
	local choices = {}
	if allTitles ~= nil and next(allTitles) ~= nil then
		for i=1, #allTitles do
			item = {
				["text"] = allTitles[i],
				["subText"] = "Title",
			}
			table.insert(choices, 1, item)
		end
	end

	--------------------------------------------------------------------------------
	-- Sort everything:
	--------------------------------------------------------------------------------
	table.sort(choices, function(a, b) return a.text < b.text end)

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

	theChooser:bgDark(true):choices(choices)

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
end

--------------------------------------------------------------------------------
-- GET LIST OF TITLES:
--------------------------------------------------------------------------------
function mod.updateTitlesList()

	--------------------------------------------------------------------------------
	-- Make sure Final Cut Pro is active:
	--------------------------------------------------------------------------------
	fcp:launch()

	local generators = fcp:generators()

	local browserLayout = fcp:browser():saveLayout()

	--------------------------------------------------------------------------------
	-- Make sure Titles and Generators panel is open:
	--------------------------------------------------------------------------------
	if not generators:show():isShowing() then
		dialog.displayErrorMessage("Unable to activate the Titles and Generators panel.\n\nError occurred in updateTitlesList().")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Make sure there's nothing in the search box:
	--------------------------------------------------------------------------------
	generators:search():clear()

	--------------------------------------------------------------------------------
	-- Click 'Titles':
	--------------------------------------------------------------------------------
	generators:showAllTitles()

	--------------------------------------------------------------------------------
	-- Make sure "Installed Titles" is selected:
	--------------------------------------------------------------------------------
	generators:group():selectItem(1)

	--------------------------------------------------------------------------------
	-- Get list of All Transitions:
	--------------------------------------------------------------------------------
	local effectsList = generators:contents():childrenUI()
	local allTitles = {}
	if effectsList ~= nil then
		for i=1, #effectsList do
			allTitles[i] = effectsList[i]:attributeValue("AXTitle")
		end
	else
		dialog.displayErrorMessage("Unable to get list of all titles.\n\nError occurred in updateTitlesList().")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Restore Effects or Transitions Panel:
	--------------------------------------------------------------------------------
	fcp:browser():loadLayout(browserLayout)

	--------------------------------------------------------------------------------
	-- Save Results to Settings:
	--------------------------------------------------------------------------------
	local currentLanguage = fcp:getCurrentLanguage()
	metadata.set(currentLanguage .. ".allTitles", allTitles)
	metadata.set(currentLanguage .. ".titlesListUpdated", true)
	action.reset()
end

function mod.isTitlesListUpdated()
	return metadata.get(fcp:getCurrentLanguage() .. ".titlesListUpdated", false)
end

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.finalcutpro.menu.timeline.assignshortcuts"]	= "automation",
	["cp.plugins.finalcutpro.commands.fcpx"]					= "fcpxCmds",
	["cp.plugins.finalcutpro.os.touchbar"]						= "touchbar",
	["cp.plugins.core.actions.actionmanager"]					= "actionmanager",
}

function plugin.init(deps)
	local fcpxRunning = fcp:isRunning()
	mod.touchbar = deps.touchbar

	-- Register the Action
	action.init(deps.actionmanager)

	-- The 'Assign Shortcuts' menu
	local menu = deps.automation:addMenu(PRIORITY, function() return i18n("assignTitlesShortcuts") end)

	menu:addItems(1000, function()
		--------------------------------------------------------------------------------
		-- Shortcuts:
		--------------------------------------------------------------------------------
		local listUpdated 	= mod.isTitlesListUpdated()
		local shortcuts		= mod.getShortcuts()

		local items = {}

		for i = 1, MAX_SHORTCUTS do
			local shortcutName = shortcuts[i] or i18n("unassignedTitle")
			items[i] = { title = i18n("titleShortcutTitle", { number = i, title = shortcutName}), fn = function() mod.assignTitlesShortcut(i) end,	disabled = not listUpdated }
		end

		return items
	end)

	-- Commands
	local fcpxCmds = deps.fcpxCmds
	for i = 1, MAX_SHORTCUTS do
		fcpxCmds:add("cpTitles"..tools.numberToWord(i)):whenActivated(function() mod.apply(i) end)
	end

	return mod
end

return plugin