local chooser			= require("hs.chooser")
local drawing 			= require("hs.drawing")
local fnutils 			= require("hs.fnutils")
local menubar			= require("hs.menubar")
local mouse				= require("hs.mouse")
local screen			= require("hs.screen")
local timer				= require("hs.timer")

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
	return metadata.get("consoleLastQueryValue", nil)
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
											        	:choices(mod.actionmanager.choices)

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
	local chooserRememberLast = metadata.get("chooserRememberLast")
	if not chooserRememberLast then
		mod.hacksChooser:query("")
	else
		mod.hacksChooser:query(metadata.get("chooserRememberLastValue", ""))
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
	metadata.set("chooserRememberLastValue", mod.hacksChooser:query())

	--------------------------------------------------------------------------------
	-- Put focus back on Final Cut Pro:
	--------------------------------------------------------------------------------
	fcp:launch()

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
function mod.rightClickAction()

	--------------------------------------------------------------------------------
	-- Settings:
	--------------------------------------------------------------------------------
	local currentLanguage 				= fcp:getCurrentLanguage()
	local chooserRememberLast 			= mod.isLastQueryRemembered()
	local chooserRemoved 				= metadata.get(currentLanguage .. ".chooserRemoved", {})
	local chooserFavourited				= metadata.get(currentLanguage .. ".chooserFavourited", {})

	--------------------------------------------------------------------------------
	-- Display Options:
	--------------------------------------------------------------------------------
	local chooserShowAutomation 		= metadata.get("chooserShowAutomation")
	local chooserShowShortcuts 			= metadata.get("chooserShowShortcuts")
	local chooserShowHacks 				= metadata.get("chooserShowHacks")
	local chooserShowVideoEffects 		= metadata.get("chooserShowVideoEffects")
	local chooserShowAudioEffects 		= metadata.get("chooserShowAudioEffects")
	local chooserShowTransitions 		= metadata.get("chooserShowTransitions")
	local chooserShowTitles				= metadata.get("chooserShowTitles")
	local chooserShowGenerators 		= metadata.get("chooserShowGenerators")
	local chooserShowMenuItems 			= metadata.get("chooserShowMenuItems")

	local selectedRowContents 			= mod.hacksChooser:selectedRowContents()

	--------------------------------------------------------------------------------
	-- 'Show All' Display Option:
	--------------------------------------------------------------------------------
	local chooserShowAll = false
	if chooserShowAutomation and chooserShowShortcuts and chooserShowHacks and chooserShowVideoEffects and chooserShowAudioEffects and chooserShowTransitions and chooserShowTitles and chooserShowGenerators then
		chooserShowAll = true
	end

	--------------------------------------------------------------------------------
	-- Menubar:
	--------------------------------------------------------------------------------
	mod.rightClickMenubar = menubar.new(false)

	local selectedItemMenu = {}
	local rightClickMenu = {}

	if next(mod.hacksChooser:selectedRowContents()) ~= nil and mod.mode == "normal" then

		local isFavourite = false
		if next(chooserFavourited) ~= nil then
			for i=1, #chooserFavourited do
				if selectedRowContents["text"] == chooserFavourited[i]["text"] and selectedRowContents["subText"] == chooserFavourited[i]["subText"] then
					isFavourite = true
				end
			end
		end

		local favouriteTitle = "Unfavourite"
		if not isFavourite then favouriteTitle = "Favourite" end

		selectedItemMenu = {
			{ title = string.upper(i18n("highlightedItem")) .. ":", disabled = true },
			{ title = favouriteTitle, fn = function()

				if isFavourite then
					--------------------------------------------------------------------------------
					-- Remove from favourites:
					--------------------------------------------------------------------------------
					for x=#chooserFavourited,1,-1 do
						if chooserFavourited[x]["text"] == selectedRowContents["text"] and chooserFavourited[x]["subText"] == selectedRowContents["subText"] then
							table.remove(chooserFavourited, x)
						end
					end
					metadata.get(currentLanguage .. ".chooserFavourited", chooserRemoved)
				else
					--------------------------------------------------------------------------------
					-- Add to favourites:
					--------------------------------------------------------------------------------
					chooserFavourited[#chooserFavourited + 1] = selectedRowContents
					metadata.get(currentLanguage .. ".chooserFavourited", chooserFavourited)
				end

				mod.refresh()
				mod.hacksChooser:show()

			end },
			{ title = i18n("removeFromList"), fn = function()
				chooserRemoved[#chooserRemoved + 1] = selectedRowContents
				metadata.get(currentLanguage .. ".chooserRemoved", chooserRemoved)
				mod.refresh()
				mod.hacksChooser:show()
			end },
			{ title = "-" },
		}
	end

	rightClickMenu = {
		
	}
	local nada = {
		{ title = i18n("mode"), menu = {
			{ title = i18n("normal"), 				checked = mod.mode == "normal",				fn = function() mod.mode = "normal"; 		mod.refresh() end },
			{ title = i18n("removeFromList"),		checked = mod.mode == "remove",				fn = function() mod.mode = "remove"; 		mod.refresh() end },
			{ title = i18n("restoreToList"),		disabled = next(chooserRemoved) == nil, 	checked = mod.mode == "restore",			fn = function() mod.mode = "restore"; 		mod.refresh() end },
		}},
     	{ title = "-" },
     	{ title = i18n("displayOptions"), menu = {
			{ title = i18n("showNone"), disabled=mod.mode == "restore", fn = function()
				metadata.set("chooserShowAutomation", false)
				metadata.set("chooserShowShortcuts", false)
				metadata.set("chooserShowHacks", false)
				metadata.set("chooserShowVideoEffects", false)
				metadata.set("chooserShowAudioEffects", false)
				metadata.set("chooserShowTransitions", false)
				metadata.set("chooserShowTitles", false)
				metadata.set("chooserShowGenerators", false)
				metadata.set("chooserShowMenuItems", false)
				mod.refresh()
			end },
			{ title = i18n("showAll"), 				checked = chooserShowAll, disabled=mod.mode == "restore" or chooserShowAll, fn = function()
				metadata.set("chooserShowAutomation", true)
				metadata.set("chooserShowShortcuts", true)
				metadata.set("chooserShowHacks", true)
				metadata.set("chooserShowVideoEffects", true)
				metadata.set("chooserShowAudioEffects", true)
				metadata.set("chooserShowTransitions", true)
				metadata.set("chooserShowTitles", true)
				metadata.set("chooserShowGenerators", true)
				metadata.set("chooserShowMenuItems", true)
				mod.refresh()
			end },
			{ title = "-" },
			{ title = i18n("showAutomation"), 		checked = chooserShowAutomation,	disabled=mod.mode == "restore", 	fn = function() metadata.set("chooserShowAutomation", not chooserShowAutomation); 			mod.refresh() end },
			{ title = i18n("showHacks"), 			checked = chooserShowHacks,			disabled=mod.mode == "restore", 	fn = function() metadata.set("chooserShowHacks", not chooserShowHacks); 						mod.refresh() end },
			{ title = i18n("showShortcuts"), 		checked = chooserShowShortcuts,		disabled=mod.mode == "restore", 	fn = function() metadata.set("chooserShowShortcuts", not chooserShowShortcuts); 				mod.refresh() end },
			{ title = "-" },
			{ title = i18n("showVideoEffects"), 	checked = chooserShowVideoEffects,	disabled=mod.mode == "restore", 	fn = function() metadata.set("chooserShowVideoEffects", not chooserShowVideoEffects); 		mod.refresh() end },
			{ title = i18n("showAudioEffects"), 	checked = chooserShowAudioEffects,	disabled=mod.mode == "restore", 	fn = function() metadata.set("chooserShowAudioEffects", not chooserShowAudioEffects); 		mod.refresh() end },
			{ title = "-" },
			{ title = i18n("showTransitions"), 		checked = chooserShowTransitions,	disabled=mod.mode == "restore", 	fn = function() metadata.set("chooserShowTransitions", not chooserShowTransitions); 			mod.refresh() end },
			{ title = i18n("showTitles"), 			checked = chooserShowTitles,		disabled=mod.mode == "restore", 	fn = function() metadata.set("chooserShowTitles", not chooserShowTitles); 					mod.refresh() end },
			{ title = i18n("showGenerators"), 		checked = chooserShowGenerators,	disabled=mod.mode == "restore", 	fn = function() metadata.set("chooserShowGenerators", not chooserShowGenerators); 			mod.refresh() end },
			{ title = "-" },
			{ title = i18n("showMenuItems"), 		checked = chooserShowMenuItems,		disabled=mod.mode == "restore", 	fn = function() metadata.set("chooserShowMenuItems", not chooserShowMenuItems); 				mod.refresh() end },
			},
		},
       	{ title = "-" },
       	{ title = i18n("preferences") .. "...", menu = {
			{ title = i18n("rememberLastQuery"), 	checked = chooserRememberLast,						fn= function() metadata.set("chooserRememberLast", not chooserRememberLast) end },
			{ title = "-" },
			{ title = i18n("update"), menu = {
				{ title = i18n("effectsShortcuts"),			fn= function() mod.hide(); 		plugins("cp.plugins.timeline.effects").updateEffectsList();				end },
				{ title = i18n("transitionsShortcuts"),		fn= function() mod.hide(); 		plugins("cp.plugins.timeline.transitions").updateTransitionsList(); 		end },
				{ title = i18n("titlesShortcuts"),			fn= function() mod.hide(); 		plugins("cp.plugins.timeline.titles").updateTitlesList()	 				end },
				{ title = i18n("generatorsShortcuts"),		fn= function() mod.hide(); 		plugins("cp.plugins.timeline.generators")updateGeneratorsList() 			end },
				{ title = i18n("menuItems"),				fn= function() metadata.set("chooserMenuItems", nil); 			mod.refresh() end },
			}},
		}},
	}


	rightClickMenu = fnutils.concat(selectedItemMenu, rightClickMenu)

	mod.rightClickMenubar:setMenu(rightClickMenu)
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
		
	-- Add the menus
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

	return mod

end

return plugin