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
local metadata			= require("cp.metadata")

local log				= require("hs.logger").new("console")

-- Constants

local PRIORITY = 11000

-- The Module

local mod = {}

mod.hacksChooser		= nil 		-- the actual hs.chooser
mod.active 				= false		-- is the Hacks Console Active?
mod.chooserChoices		= nil		-- Choices Table
mod.mode 				= "normal"	-- normal, remove, restore
mod.reduceTransparency	= false

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
	mod.hacksChooser = chooser.new(mod.completionAction):bgDark(true)
											           	:rightClickCallback(mod.rightClickAction)
											        	:choices(mod.choices)

	--------------------------------------------------------------------------------
	-- Allow for Reduce Transparency:
	--------------------------------------------------------------------------------
	mod.lastReducedTransparency = mod.isReducedTransparency()
	if mod.lastReducedTransparency then
		mod.hacksChooser:fgColor(nil)
								 :subTextColor(nil)
	else
		mod.hacksChooser:fgColor(drawing.color.x11.snow)
								 :subTextColor(drawing.color.x11.snow)

	end

	--------------------------------------------------------------------------------
	-- If Final Cut Pro is running, lets preemptively refresh the choices:
	--------------------------------------------------------------------------------
	if fcp:isRunning() then timer.doAfter(3, mod.refresh) end

end

function mod.choices()
	return mod.actionmanager.choices()
end

--------------------------------------------------------------------------------
-- REFRESH CONSOLE CHOICES:
--------------------------------------------------------------------------------
function mod.refresh()
	mod.hacksChooser:refreshChoicesCallback()
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
	
	if not mod.isEnabled() then
		return false
	end
	
	mod._frontApp = application.frontmostApplication()

	--------------------------------------------------------------------------------
	-- Reload Console if Reduce Transparency
	--------------------------------------------------------------------------------
	mod.checkReducedTransparency()

	--------------------------------------------------------------------------------
	-- The Console always loads in 'normal' mode:
	--------------------------------------------------------------------------------
	mod.mode = "normal"
	mod.refresh()

	--------------------------------------------------------------------------------
	-- Remember last query?
	--------------------------------------------------------------------------------
	local chooserRememberLast = mod.isLastQueryRemembered()
	if not chooserRememberLast then
		mod.hacksChooser:query("")
	else
		mod.hacksChooser:query(mod.getLastQueryValue())
	end

	--------------------------------------------------------------------------------
	-- Console is Active:
	--------------------------------------------------------------------------------
	mod.active = true

	--------------------------------------------------------------------------------
	-- Show Console:
	--------------------------------------------------------------------------------
	mod.hacksChooser:show()
	
	return true

end

--------------------------------------------------------------------------------
-- HIDE CONSOLE:
--------------------------------------------------------------------------------
function mod.hide()

	--------------------------------------------------------------------------------
	-- No Longer Active:
	--------------------------------------------------------------------------------
	mod.active = false

	--------------------------------------------------------------------------------
	-- Hide Chooser:
	--------------------------------------------------------------------------------
	mod.hacksChooser:hide()

	--------------------------------------------------------------------------------
	-- Save Last Query to Settings:
	--------------------------------------------------------------------------------
	mod.setLastQueryValue(mod.hacksChooser:query())

	if mod._frontApp then
		log.df(string.format("Activating %s", mod._frontApp:title()))
		mod._frontApp:activate()
	end

end

--------------------------------------------------------------------------------
-- CONSOLE TRIGGER ACTION:
--------------------------------------------------------------------------------
function mod.completionAction(result)

	local currentLanguage = fcp:getCurrentLanguage()
	local chooserRemoved = metadata.get(currentLanguage .. ".chooserRemoved", {})

	--------------------------------------------------------------------------------
	-- Nothing selected:
	--------------------------------------------------------------------------------
	if result == nil then
		--------------------------------------------------------------------------------
		-- Hide Console:
		--------------------------------------------------------------------------------
		mod.hide()
		return
	end

	--------------------------------------------------------------------------------
	-- Normal Mode:
	--------------------------------------------------------------------------------
	if mod.mode == "normal" then
		--------------------------------------------------------------------------------
		-- Hide Console:
		--------------------------------------------------------------------------------
		mod.hide()

		mod.actionmanager.execute(result.type, result.params)

	--------------------------------------------------------------------------------
	-- Remove Mode:
	--------------------------------------------------------------------------------
	elseif mod.mode == "remove" then

		chooserRemoved[#chooserRemoved + 1] = result
		metadata.get(currentLanguage .. ".chooserRemoved", chooserRemoved)
		mod.refresh()
		mod.hacksChooser:show()

	--------------------------------------------------------------------------------
	-- Restore Mode:
	--------------------------------------------------------------------------------
	elseif mod.mode == "restore" then

		for x=#chooserRemoved,1,-1 do
			if chooserRemoved[x]["text"] == result["text"] and chooserRemoved[x]["subText"] == result["subText"] then
				table.remove(chooserRemoved, x)
			end
		end
		metadata.get(currentLanguage .. ".chooserRemoved", chooserRemoved)
		if next(chooserRemoved) == nil then mod.mode = "normal" end
		mod.refresh()
		mod.hacksChooser:show()

	end

end

--------------------------------------------------------------------------------
-- CHOOSER RIGHT CLICK:
--------------------------------------------------------------------------------
function mod.rightClickAction(index)

	--------------------------------------------------------------------------------
	-- Settings:
	--------------------------------------------------------------------------------
	local choice = mod.hacksChooser:selectedRowContents(index)

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
				mod.hacksChooser:show()
			end }
		else
			choiceMenu[#choiceMenu + 1] = { title = i18n("consoleChoiceFavorite"), fn = function()
				mod.actionmanager.favorite(choice.id)
				mod.refresh()
				mod.hacksChooser:show()
			end }
		end
	end

	mod.rightClickMenubar:setMenu(choiceMenu)
	mod.rightClickMenubar:popupMenu(mouse.getAbsolutePosition())
end

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.commands.fcpx"]			= "fcpxCmds",
	["cp.plugins.actions.actionmanager"]	= "actionmanager",
	["cp.plugins.menu.tools"]				= "tools",
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
		}
	end)
	
	menu:addSeparator(4000)
	
	menu:addItems(5000, function()
		local actionItems = {}
		for id,action in pairs(deps.actionmanager.getActions()) do
			actionItems[#actionItems + 1] = { title = i18n(string.format("%s_action", id)) or id,	
				fn=function()
					action.toggleEnabled()
					deps.actionmanager.refresh()
				end,
				checked = action.isEnabled(), }
		end
		
		table.sort(actionItems, function(a, b) return a.title < b.title end)
		
		return actionItems
	end)
	
	return mod

end

return plugin