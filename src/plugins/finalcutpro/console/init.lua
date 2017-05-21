--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.console ===
---
--- CommandPost Console

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local chooser			= require("hs.chooser")
local drawing 			= require("hs.drawing")
local fnutils 			= require("hs.fnutils")
local menubar			= require("hs.menubar")
local mouse				= require("hs.mouse")
local screen			= require("hs.screen")
local timer				= require("hs.timer")
local application		= require("hs.application")

local ax 				= require("hs._asm.axuielement")

local fcp				= require("cp.apple.finalcutpro")
local config			= require("cp.config")
local prop				= require("cp.prop")

local log				= require("hs.logger").new("console")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY = 11000

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod.mainChooser			= nil 		-- the actual hs.chooser
mod.hiderChooser		= nil		-- the chooser for hiding/unhiding items.
mod.activeChooser		= nil		-- the currently-visible chooser.
mod.active 				= false		-- is the Hacks Console Active?

mod.enabled = config.prop("consoleEnabled", true)

mod.reducedTransparency = prop.new(function()
	return screen.accessibilitySettings()["ReduceTransparency"]
end)

mod.searchSubtext = config.prop("searchSubtext", true)

mod.lastQueryRemembered = config.prop("consoleLastQueryRemembered", true)

mod.lastQueryValue = config.prop("consoleLastQueryValue", "")

--------------------------------------------------------------------------------
-- LOAD CONSOLE:
--------------------------------------------------------------------------------
function mod.init(actionmanager)
	mod.actionmanager = mod.actionmanager or actionmanager
	mod.new()
end

function mod.new()
	--------------------------------------------------------------------------------
	-- Setup Chooser:
	--------------------------------------------------------------------------------
	mod.mainChooser = chooser.new(mod.completionAction):bgDark(true)
											           	:rightClickCallback(mod.rightClickAction)
											        	:choices(mod.choices)
											        	:searchSubText(mod.searchSubtext())

	--------------------------------------------------------------------------------
	-- Allow for Reduce Transparency:
	--------------------------------------------------------------------------------
	mod.lastReducedTransparency = mod.reducedTransparency()
	if mod.lastReducedTransparency then
		mod.mainChooser:fgColor(nil)
								 :subTextColor(nil)
	else
		mod.mainChooser:fgColor(drawing.color.x11.snow)
								 :subTextColor(drawing.color.x11.snow)

	end

	--------------------------------------------------------------------------------
	-- Setup Hidden Item Manager:
	--------------------------------------------------------------------------------
	mod.hiderChooser = chooser.new(mod.toggleHidden):bgDark(true)
											           	:rightClickCallback(mod.rightClickAction)
											        	:choices(mod.actionmanager.allChoices)

	--------------------------------------------------------------------------------
	-- Allow for Reduce Transparency:
	--------------------------------------------------------------------------------
	mod.lastReducedTransparency = mod.reducedTransparency()
	if mod.lastReducedTransparency then
		mod.hiderChooser:fgColor(nil)
								 :subTextColor(nil)
	else
		mod.hiderChooser:fgColor(drawing.color.x11.snow)
								 :subTextColor(drawing.color.x11.snow)

	end

	--------------------------------------------------------------------------------
	-- If Final Cut Pro is running, lets preemptively refresh the choices:
	--------------------------------------------------------------------------------
	if fcp:isRunning() then timer.doAfter(3, mod.refresh) end
end

function mod.toggleHidden(result)
	if result and result.id then
		mod.actionmanager.toggleHidden(result.id)
		mod.refresh()
		timer.doUntil(function() return mod.hiderChooser:isVisible() end, mod.showHider)
	end
end

function mod.choices()
	return mod.actionmanager.choices()
end

--------------------------------------------------------------------------------
-- REFRESH CONSOLE CHOICES:
--------------------------------------------------------------------------------
function mod.refresh()
	mod.mainChooser:refreshChoicesCallback()
	mod.hiderChooser:refreshChoicesCallback()
end

function mod.checkReducedTransparency()
	if mod.lastReducedTransparency ~= mod.reducedTransparency() then
		mod.new()
	end
end

--------------------------------------------------------------------------------
-- SHOW CONSOLE:
--------------------------------------------------------------------------------
function mod.show()
	mod.showChooser(mod.mainChooser)
end

function mod.showHider()
	mod.showChooser(mod.hiderChooser)
end

function mod.showChooser(chooser)
	if not mod.enabled() then
		return false
	end

	mod.hide()

	mod._frontApp = application.frontmostApplication()

	--------------------------------------------------------------------------------
	-- Reload Console if Reduce Transparency
	--------------------------------------------------------------------------------
	mod.checkReducedTransparency()

	mod.refresh()

	--------------------------------------------------------------------------------
	-- Remember last query?
	--------------------------------------------------------------------------------
	local chooserRememberLast = mod.lastQueryRemembered()
	if not chooserRememberLast then
		chooser:query("")
	else
		chooser:query(mod.lastQueryValue())
	end

	--------------------------------------------------------------------------------
	-- Console is Active:
	--------------------------------------------------------------------------------
	mod.active = true
	mod.activeChooser = chooser

	--------------------------------------------------------------------------------
	-- Show Console:
	--------------------------------------------------------------------------------
	chooser:searchSubText(mod.searchSubtext())
	chooser:show()

	return true
end

--------------------------------------------------------------------------------
-- HIDE CONSOLE:
--------------------------------------------------------------------------------
function mod.hide()
	if mod.activeChooser then
		local chooser = mod.activeChooser

		--------------------------------------------------------------------------------
		-- No Longer Active:
		--------------------------------------------------------------------------------
		mod.active = false
		mod.activeChooser = nil

		--------------------------------------------------------------------------------
		-- Hide Chooser:
		--------------------------------------------------------------------------------
		chooser:hide()

		--------------------------------------------------------------------------------
		-- Save Last Query to Settings:
		--------------------------------------------------------------------------------
		mod.lastQueryValue:set(chooser:query())

		if mod._frontApp then
			mod._frontApp:activate()
		end
	end
end

--------------------------------------------------------------------------------
-- CONSOLE TRIGGER ACTION:
--------------------------------------------------------------------------------
function mod.completionAction(result)

	mod.hide()

	--------------------------------------------------------------------------------
	-- Nothing selected:
	--------------------------------------------------------------------------------
	if result then
		mod.actionmanager.execute(result.type, result.params)
	end
end

--------------------------------------------------------------------------------
-- CHOOSER RIGHT CLICK:
--------------------------------------------------------------------------------
function mod.rightClickAction(index)

	local chooser = mod.activeChooser

	--------------------------------------------------------------------------------
	-- Settings:
	--------------------------------------------------------------------------------
	local choice = chooser:selectedRowContents(index)

	--------------------------------------------------------------------------------
	-- Menubar:
	--------------------------------------------------------------------------------
	mod.rightClickMenubar = menubar.new(false)

	local choiceMenu = {}

	if choice then
		local isFavorite = mod.actionmanager.isFavorite(choice.id)

		choiceMenu[#choiceMenu + 1] = { title = string.upper(i18n("highlightedItem")) .. ":", disabled = true }
		if isFavorite then
			choiceMenu[#choiceMenu + 1] = { title = i18n("consoleChoiceUnfavorite"), fn = function()
				mod.actionmanager.unfavorite(choice.id)
				mod.refresh()
				chooser:show()
			end }
		else
			choiceMenu[#choiceMenu + 1] = { title = i18n("consoleChoiceFavorite"), fn = function()
				mod.actionmanager.favorite(choice.id)
				mod.refresh()
				chooser:show()
			end }
		end

		local isHidden = mod.actionmanager.isHidden(choice.id)
		if isHidden then
			choiceMenu[#choiceMenu + 1] = { title = i18n("consoleChoiceUnhide"), fn = function()
				mod.actionmanager.unhide(choice.id)
				mod.refresh()
				chooser:show()
			end}
		else
			choiceMenu[#choiceMenu + 1] = { title = i18n("consoleChoiceHide"), fn = function()
				mod.actionmanager.hide(choice.id)
				mod.refresh()
				chooser:show()
			end}
		end
	end

	mod.rightClickMenubar:setMenu(choiceMenu)
	mod.rightClickMenubar:popupMenu(mouse.getAbsolutePosition())
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.console",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.commands"]		= "fcpxCmds",
		["finalcutpro.action.manager"]			= "actionmanager",
		["finalcutpro.menu.tools"]		= "tools",
	}
}

function plugin.init(deps)

	mod.init(deps.actionmanager)

	-- Add the command trigger
	deps.fcpxCmds:add("cpConsole")
		:groupedBy("commandPost")
		:whenActivated(function() mod.show() end)
		:activatedBy():ctrl("space")

	-- Add the 'Console' menu items
	local menu = deps.tools:addMenu(PRIORITY, function() return i18n("console") end)

	menu:addItem(1000, function()
		return { title = i18n("enableConsole"),	fn = function() mod.enabled:toggle() end, checked = mod.enabled() }
	end)

	menu:addSeparator(2000)

	menu:addItems(3000, function()
		return {
			{ title = i18n("rememberLastQuery"),	fn=function() mod.lastQueryRemembered:toggle() end, checked = mod.lastQueryRemembered(),  },
			{ title = i18n("searchSubtext"),		fn=function() mod.searchSubtext:toggle() end, checked = mod.searchSubtext(),  },
			{ title = "-" },
			{ title = i18n("consoleHideUnhide"),	fn=mod.showHider, },
		}
	end)

	-- The 'Sections' menu
	local sections = menu:addMenu(5000, function() return i18n("consoleSections") end)

	sections:addItems(2000, function()
		local actionItems = {}
		local allEnabled = true
		local allDisabled = true

		for id,action in pairs(deps.actionmanager.getActions()) do
			local enabled = action.enabled()
			allEnabled = allEnabled and enabled
			allDisabled = allDisabled and not enabled
			actionItems[#actionItems + 1] = { title = i18n(string.format("%s_action", id)) or id,
				fn=function()
					action.enabled:toggle()
					deps.actionmanager.refresh()
				end,
				checked = enabled, }
		end

		table.sort(actionItems, function(a, b) return a.title < b.title end)

		local allItems = {
			{ title = i18n("consoleSectionsShowAll"), fn = mod.actionmanager.enableAllActions, disabled = allEnabled },
			{ title = i18n("consoleSectionsHideAll"), fn = mod.actionmanager.disableAllActions, disabled = allDisabled },
			{ title = "-" }
		}
		fnutils.concat(allItems, actionItems)

		return allItems
	end)

	return mod

end

return plugin