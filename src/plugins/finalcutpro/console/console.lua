local chooser			= require("hs.chooser")
local drawing 			= require("hs.drawing")
local fnutils 			= require("hs.fnutils")
local menubar			= require("hs.menubar")
local mouse				= require("hs.mouse")
local screen			= require("hs.screen")
local timer				= require("hs.timer")
local application		= require("hs.application")

local ax 				= require("hs._asm.axuielement")

local plugins			= require("cp.plugins")
local fcp				= require("cp.finalcutpro")
local metadata			= require("cp.config")

local log				= require("hs.logger").new("console")

-- Constants

local PRIORITY = 11000

-- The Module

local mod = {}

mod.mainChooser			= nil 		-- the actual hs.chooser
mod.hiderChooser		= nil		-- the chooser for hiding/unhiding items.
mod.activeChooser		= nil		-- the currently-visible chooser.
mod.active 				= false		-- is the Hacks Console Active?

function mod.isEnabled()
	return metadata.get("consoleEnabled", true)
end

function mod.setEnabled(value)
	metadata.set("consoleEnabled", value)
end

function mod.toggleEnabled()
	mod.setEnabled(not mod.isEnabled())
end

function mod.isReducedTransparency()
	return screen.accessibilitySettings()["ReduceTransparency"]
end

function mod.isLastQueryRemembered()
	return metadata.get("consoleLastQueryRemembered", true)
end

function mod.setLastQueryRemembered(value)
	metadata.set("consoleLastQueryRemembered", value)
end

function mod.toggleLastQueryRemembered()
	mod.setLastQueryRemembered(not mod.isLastQueryRemembered())
end

function mod.getLastQueryValue()
	return metadata.get("consoleLastQueryValue", "")
end

function mod.setLastQueryValue(value)
	metadata.set("consoleLastQueryValue", value)
end

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

	--------------------------------------------------------------------------------
	-- Allow for Reduce Transparency:
	--------------------------------------------------------------------------------
	mod.lastReducedTransparency = mod.isReducedTransparency()
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
	mod.lastReducedTransparency = mod.isReducedTransparency()
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
	if mod.lastReducedTransparency ~= mod.isReducedTransparency() then
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
	if not mod.isEnabled() then
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
	local chooserRememberLast = mod.isLastQueryRemembered()
	if not chooserRememberLast then
		chooser:query("")
	else
		chooser:query(mod.getLastQueryValue())
	end

	--------------------------------------------------------------------------------
	-- Console is Active:
	--------------------------------------------------------------------------------
	mod.active = true
	mod.activeChooser = chooser

	--------------------------------------------------------------------------------
	-- Show Console:
	--------------------------------------------------------------------------------
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
		mod.setLastQueryValue(chooser:query())

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

-- The Plugin
local plugin = {
	id				= "finalcutpro.console",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.commands"]		= "fcpxCmds",
		["core.action.manager"]			= "actionmanager",
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
		return { title = i18n("enableConsole"),	fn = mod.toggleEnabled, checked = mod.isEnabled() }
	end)
	
	menu:addSeparator(2000)
	
	menu:addItems(3000, function()
		return {
			{ title = i18n("rememberLastQuery"),	fn=mod.toggleLastQueryRemembered, checked = mod.isLastQueryRemembered(),  },
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
			local enabled = action.isEnabled()
			allEnabled = allEnabled and enabled
			allDisabled = allDisabled and not enabled
			actionItems[#actionItems + 1] = { title = i18n(string.format("%s_action", id)) or id,	
				fn=function()
					action.toggleEnabled()
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