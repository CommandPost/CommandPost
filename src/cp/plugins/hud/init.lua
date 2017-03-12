--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                                H U D                                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------

local hud = {}

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------

local application								= require("hs.application")
local chooser									= require("hs.chooser")
local drawing									= require("hs.drawing")
local eventtap									= require("hs.eventtap")
local fnutils 									= require("hs.fnutils")
local fs 										= require("hs.fs")
local geometry									= require("hs.geometry")
local host										= require("hs.host")
local mouse										= require("hs.mouse")
local screen									= require("hs.screen")
local settings									= require("hs.settings")
local timer										= require("hs.timer")
local urlevent									= require("hs.urlevent")
local webview									= require("hs.webview")
local window									= require("hs.window")
local windowfilter								= require("hs.window.filter")
local ax										= require("hs._asm.axuielement")

local plugins									= require("cp.plugins")
local dialog									= require("cp.dialog")
local fcp										= require("cp.finalcutpro")
local metadata									= require("cp.metadata")
local tools										= require("cp.tools")
local commands									= require("cp.commands")
local template									= require("cp.template")

local log										= require("hs.logger").new("hud")

--------------------------------------------------------------------------------
-- SETTINGS:
--------------------------------------------------------------------------------

local PRIORITY									= 10000

hud.name										= i18n("hacksHUD")
hud.width										= 350
hud.heightInspector								= 75
hud.heightDropTargets							= 75
hud.heightButtons								= 70

hud.fcpGreen 									= "#3f9253"
hud.fcpRed 										= "#d1393e"

hud.maxButtons									= 4
hud.maxTextLength 								= 25

--------------------------------------------------------------------------------
-- VARIABLES:
--------------------------------------------------------------------------------

hud.ignoreWindowChange							= true
hud.windowID									= nil

hud.hsBundleID									= hs.processInfo["bundleID"]

function hud.isEnabled()
	return metadata.get("enableHacksHUD", false)
end

function hud.setEnabled(value)
	metadata.set("enableHacksHUD", value)
	hud.update()
end

function hud.toggleEnabled()
	hud.setEnabled(not hud.isEnabled())
end

function hud.checkOptions()
	return hud.isInspectorShown() or hud.isDropTargetsShown() or hud.isButtonsShown()
end

function hud.setOption(name, value)
	metadata.set(name, value)
	if hud.checkOptions() then
		hud.reload()
	else
		metadata.set(name, not value)
	end
end

function hud.isInspectorShown()
	return metadata.get("hudShowInspector", true)
end

function hud.setInspectorShown(value)
	hud.setOption("hudShowInspector", value)
end

function hud.toggleInspectorShown()
	hud.setInspectorShown(not hud.isInspectorShown())
end

function hud.isDropTargetsShown()
	return metadata.get("hudShowDropTargets", true) and hud.xmlSharing.isEnabled()
end

function hud.setDropTargetsShown(value)
	hud.setOption("hudShowDropTargets", value)
end

function hud.toggleDropTargetsShown()
	hud.setDropTargetsShown(not hud.isDropTargetsShown())
end

function hud.isButtonsShown()
	return metadata.get("hudShowButtons", true)
end

function hud.setButtonsShown(value)
	hud.setOption("hudShowButtons", value)
end

function hud.toggleButtonsShown()
	hud.setButtonsShown(not hud.isButtonsShown())
end

function hud.getPosition()
	return metadata.get("hudPosition", {})
end

function hud.setPosition(value)
	metadata.set("hudPosition", value)
end

function hud.getButton(index, defaultValue)
	local currentLanguage = fcp:getCurrentLanguage()
	return metadata.get(string.format("%s.hudButton.%d", currentLanguage, index), defaultValue)
end

function hud.getButtonCommand(index)
	local button = hud.getButton(index)
	if button and button.action then
		if button.action.type == "command" then
			local group = commands.group(button.action.group)
			if group then
				return group:get(button.action.id)
			end
		end
	end
	return nil
end

function hud.getButtonText(index)
	local button = hud.getButton(index)
	if button and button.text then
		return tools.stringMaxLength(tools.cleanupButtonText(button.text), hud.maxTextLength, "...")
	else
		return i18n("unassigned")
	end
end

function hud.getButtonURL(index)
	return hud.actionmanager.getURL(hud.getButton(index))
end

function hud.setButton(index, value)
	local currentLanguage = fcp:getCurrentLanguage()
	metadata.set(string.format("%s.hudButton.%d", currentLanguage, index), value)
end

function hud.isFrontmost()
	if hud.hudWebView ~= nil then
		return window.focusedWindow() == hud.hudWebView:hswindow()
	else
		return false
	end
end

function hud.update()
	if hud.canShow() then
		hud.show()
	else
		hud.hide()
	end
end

function hud.canShow()
	-- return hud.isEnabled()
	local result = (fcp:isFrontmost() or hud.isFrontmost() or metadata.isFrontmost())
	and not fcp:fullScreenWindow():isShowing()
	and not fcp:commandEditor():isShowing()
	and hud.isEnabled()
	return result
end

--------------------------------------------------------------------------------
-- CREATE THE HUD:
--------------------------------------------------------------------------------
function hud.new()

	--------------------------------------------------------------------------------
	-- Work out HUD height based off settings:
	--------------------------------------------------------------------------------
	local hudShowInspector 		= hud.isInspectorShown()
	local hudShowDropTargets 	= hud.isDropTargetsShown()
	local hudShowButtons 		= hud.isButtonsShown()

	local hudHeight = 0
	if hudShowInspector then hudHeight = hudHeight + hud.heightInspector end
	if hudShowDropTargets then hudHeight = hudHeight + hud.heightDropTargets end
	if hudShowButtons then hudHeight = hudHeight + hud.heightButtons end

	--------------------------------------------------------------------------------
	-- Get last HUD position from settings otherwise default to centre screen:
	--------------------------------------------------------------------------------
	local screenFrame = screen.mainScreen():frame()
	local defaultHUDRect = {x = (screenFrame['w']/2) - (hud.width/2), y = (screenFrame['h']/2) - (hudHeight/2), w = hud.width, h = hudHeight}
	local hudPosition = hud.getPosition()
	if next(hudPosition) ~= nil then
		defaultHUDRect = {x = hudPosition["_x"], y = hudPosition["_y"], w = hud.width, h = hudHeight}
	end

	--------------------------------------------------------------------------------
	-- Setup Web View Controller:
	--------------------------------------------------------------------------------
	hud.hudWebViewController = webview.usercontent.new("hud")
		:setCallback(hud.javaScriptCallback)

	--------------------------------------------------------------------------------
	-- Setup Web View:
	--------------------------------------------------------------------------------
	hud.hudWebView = webview.new(defaultHUDRect, {}, hud.hudWebViewController)
		:windowStyle({"HUD", "utility", "titled", "nonactivating", "closable"})
		:shadow(true)
		:closeOnEscape(true)
		:html(hud.generateHTML())
		:allowGestures(false)
		:allowNewWindows(false)
		:windowTitle(hud.name)
		:level(drawing.windowLevels.modalPanel)

	--------------------------------------------------------------------------------
	-- Window Watcher:
	--------------------------------------------------------------------------------
	hud.hudFilter = windowfilter.new(true)
		:setAppFilter(hud.name, {activeApplication=true})

	--------------------------------------------------------------------------------
	-- HUD Moved:
	--------------------------------------------------------------------------------
	hud.hudFilter:subscribe(windowfilter.windowMoved, function(window, applicationName, event)
		if window:id() == hud.windowID then
			if hud.active() then
				local result = hud.hudWebView:hswindow():frame()
				if result ~= nil then
					hud.setPosition(result)
				end
			end
		end
	end, true)

	--------------------------------------------------------------------------------
	-- HUD Closed:
	--------------------------------------------------------------------------------
	hud.hudFilter:subscribe(windowfilter.windowDestroyed,
	function(window, applicationName, event)
		if window:id() == hud.windowID then
			if not hud.ignoreWindowChange then
				hud.setEnabled(false)
			end
		end
	end, true)

	--------------------------------------------------------------------------------
	-- Watches all apps:
	--------------------------------------------------------------------------------
	hud.windowFilter = windowfilter.new(true)

	--------------------------------------------------------------------------------
	-- HUD Unfocussed:
	--------------------------------------------------------------------------------
	hud.windowFilter:subscribe(windowfilter.windowFocused,
	function(window, applicationName, event)
		hud.update()
	end, true)

	local watcher = application.watcher
	hud.appWatcher = watcher.new(
		function(appName, eventType, appObject)
			if eventType == watcher.activated or eventType == watcher.deactivated or eventType == watcher.terminated then
				hud.update()
			end
		end
	)
	hud.appWatcher:start()
end

--------------------------------------------------------------------------------
-- SHOW THE HUD:
--------------------------------------------------------------------------------
function hud.show()
	hud.ignoreWindowChange = true
	if hud.hudWebView == nil then
		hud.new()
		hud.hudWebView:show()
	else
		hud.hudWebView:show()
	end

	--------------------------------------------------------------------------------
	-- Keep checking for a window ID until we get an answer:
	--------------------------------------------------------------------------------
	local hacksHUDWindowIDTimerDone = false
	timer.doUntil(function() return hacksHUDWindowIDTimerDone end, function()
		if hud.hudWebView:hswindow() ~= nil then
			if hud.hudWebView:hswindow():id() ~= nil then
				hud.windowID = hud.hudWebView:hswindow():id()
				hacksHUDWindowIDTimerDone = true
			end
		end
	end, 0.05):fire()

	if hud.windowFilter then hud.windowFilter:resume() end
	if hud.appWatcher then hud.appWatcher:start() end

	hud.ignoreWindowChange = false
end

--------------------------------------------------------------------------------
-- IS HUD ACTIVE:
--------------------------------------------------------------------------------
function hud.active()
	if hud.hudWebView == nil then
		return false
	end
	if hud.hudWebView:hswindow() == nil then
		return false
	else
		return true
	end
end

--------------------------------------------------------------------------------
-- HIDE THE HUD:
--------------------------------------------------------------------------------
function hud.hide()
	if hud.active() then
		hud.ignoreWindowChange = true
		hud.hudWebView:hide()
		if hud.windowFilter then hud.windowFilter:pause() end
		if hud.appWatcher then hud.appWatcher:stop() end
	end
end

--------------------------------------------------------------------------------
-- DELETE THE HUD:
--------------------------------------------------------------------------------
function hud.delete()
	if hud.active() then
		hud.hudWebView:delete()
		if hud.windowFocus then hud.windowFocus:delete() end
		if hud.appWatcher then hud.appWatcher:stop() end
	end
end

--------------------------------------------------------------------------------
-- RELOAD THE HUD:
--------------------------------------------------------------------------------
function hud.reload()

	local hudActive = hud.active()

	hud.delete()
	hud.ignoreWindowChange	= true
	hud.windowID			= nil
	hud.new()

	hud.refresh()

	if hudActive and fcp:isFrontmost() then
		hud.show()
	end

end

--------------------------------------------------------------------------------
-- REFRESH THE HUD:
--------------------------------------------------------------------------------
function hud.refresh()
	if hud.active() then
		hud.hudWebView:html(hud.generateHTML())
	end
end

--------------------------------------------------------------------------------
-- ASSIGN HUD BUTTON:
--------------------------------------------------------------------------------
function hud.assignButton(button)

	--------------------------------------------------------------------------------
	-- Was Final Cut Pro Open?
	--------------------------------------------------------------------------------
	local wasFinalCutProOpen = fcp:isFrontmost()
	local whichButton = button
	local hudButtonChooser = nil

	local chooserAction = function(result)

		--------------------------------------------------------------------------------
		-- Hide Chooser:
		--------------------------------------------------------------------------------
		hudButtonChooser:hide()

		--------------------------------------------------------------------------------
		-- Perform Specific Function:
		--------------------------------------------------------------------------------
		if result ~= nil then
			hud.setButton(whichButton, result)
		end

		--------------------------------------------------------------------------------
		-- Put focus back in Final Cut Pro:
		--------------------------------------------------------------------------------
		if hud.wasFinalCutProOpen then
			fcp:launch()
		end

		--------------------------------------------------------------------------------
		-- Reload HUD:
		--------------------------------------------------------------------------------
		if hud.isEnabled() then
			hud.reload()
		end
	end

	hudButtonChooser = chooser.new(chooserAction):bgDark(true)
												  :fgColor(drawing.color.x11.snow)
												  :subTextColor(drawing.color.x11.snow)
												  :choices(hud.choices)
												  :show()
end

--------------------------------------------------------------------------------
-- HUD CHOICES:
--------------------------------------------------------------------------------
function hud.choices()
	if hud.actionmanager then
		return hud.actionmanager.choices()
	else
		return {}
	end
end

--------------------------------------------------------------------------------
-- GENERATE HTML:
--------------------------------------------------------------------------------
local ORIGINAL_QUALITY 		= 10
local ORIGINAL_PERFORMANCE	= 5
local PROXY					= 4

function hud.generateHTML()

	--------------------------------------------------------------------------------
	-- Set up the template environment
	--------------------------------------------------------------------------------
	local env 		= template.defaultEnv()
	env.i18n		= i18n
	env.hud			= hud

	--------------------------------------------------------------------------------
	-- FFPlayerQuality
	--------------------------------------------------------------------------------
	-- 10 	= Original - Better Quality
	-- 5 	= Original - Better Performance
	-- 4 	= Proxy
	--------------------------------------------------------------------------------
	local playerQuality = fcp:getPreference("FFPlayerQuality", ORIGINAL_PERFORMANCE)

	if playerQuality == PROXY then
		env.media 	= {
			text	= i18n("proxy"),
			class	= "bad",
		}
	else
		env.media	= {
			text	= i18n("originalOptimised"),
			class	= "good",
		}
	end

	if playerQuality == ORIGINAL_QUALITY then
		env.quality	= {
			text	= i18n("betterQuality"),
			class	= "good",
		}
	else
		env.quality	= {
			text	= playerQuality == ORIGINAL_PERFORMANCE and i18n("betterPerformance") or i18n("proxy"),
			class	= "bad",
		}
	end

	local autoStartGBRender	= fcp:getPreference("FFAutoStartBGRender", true)

	if autoStartBGRender then
		local autoRenderDelay 	= tonumber(fcp:getPreference("FFAutoRenderDelay", "0.3"))
		env.backgroundRender	= {
			text	= string.format("%s (%d %s)", i18n("enabled"), autoRenderDelay, i18n("secs", {count=autoRenderDelay})),
			class	= "good",
		}
	else
		env.backgroundRender	= {
			text	= i18n("disabled"),
			class	= "bad",
		}
	end

	return template.compileFile(metadata.scriptPath .. "/cp/plugins/hud/main.lua.html", env)
end

--------------------------------------------------------------------------------
-- JAVASCRIPT CALLBACK:
--------------------------------------------------------------------------------
function hud.javaScriptCallback(message)
	if message["body"] ~= nil then
		if string.find(message["body"], "<!DOCTYPE fcpxml>") ~= nil then
			hud.shareXML(message["body"])
		else
			dialog.displayMessage(i18n("hudDropZoneError"))
		end
	end
end

--------------------------------------------------------------------------------
-- SHARED XML:
--------------------------------------------------------------------------------
function hud.shareXML(incomingXML)

	local enableXMLSharing = hud.isEnabled()

	if enableXMLSharing then

		--------------------------------------------------------------------------------
		-- Get Settings:
		--------------------------------------------------------------------------------
		local xmlSharingPath = hud.xmlSharing.getSharingPath()

		--------------------------------------------------------------------------------
		-- Get only the needed XML content:
		--------------------------------------------------------------------------------
		local startOfXML = string.find(incomingXML, "<?xml version=")
		local endOfXML = string.find(incomingXML, "</fcpxml>")

		--------------------------------------------------------------------------------
		-- Error Detection:
		--------------------------------------------------------------------------------
		if startOfXML == nil or endOfXML == nil then
			dialog.displayErrorMessage("Something went wrong when attempting to translate the XML data you dropped. Please try again.\n\nError occurred in hud.shareXML().")
			if incomingXML ~= nil then
				log.d("Start of incomingXML.")
				log.d(incomingXML)
				log.d("End of incomingXML.")
			else
				log.e("incomingXML is nil.")
			end
			return "fail"
		end

		--------------------------------------------------------------------------------
		-- New XML:
		--------------------------------------------------------------------------------
		local newXML = string.sub(incomingXML, startOfXML - 2, endOfXML + 8)

		--------------------------------------------------------------------------------
		-- Display Text Box:
		--------------------------------------------------------------------------------
		local textboxResult = dialog.displayTextBoxMessage(i18n("hudXMLNameDialog"), i18n("hudXMLNameError"), "")

		if textboxResult then
			--------------------------------------------------------------------------------
			-- Save the XML content to the Shared XML Folder:
			--------------------------------------------------------------------------------
			local newXMLPath = xmlSharingPath .. host.localizedName() .. "/"

			if not tools.doesDirectoryExist(newXMLPath) then
				fs.mkdir(newXMLPath)
			end

			local file = io.open(newXMLPath .. textboxResult .. ".fcpxml", "w")
			currentClipboardData = file:write(newXML)
			file:close()
		end

	else
		dialog.displayMessage(i18n("hudXMLSharingDisabled"))
	end

end

function hud.init(xmlSharing, actionmanager)
	hud.xmlSharing = xmlSharing
	hud.actionmanager = actionmanager
	return hud
end

--------------------------------------------------------------------------------
-- END OF MODULE:
--------------------------------------------------------------------------------

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.sharing.xml"]				= "xmlSharing",
	["cp.plugins.menu.tools"]				= "tools",
	["cp.plugins.commands.fcpx"]			= "fcpxCmds",
	["cp.plugins.actions.actionmanager"]	= "actionmanager",
}

function plugin.init(deps)
	hud.init(deps.xmlSharing, deps.actionmanager)

	fcp:watch({
		active		= hud.update,
		inactive	= hud.update,
	})

	fcp:fullScreenWindow():watch({
		show		= hud.update,
		hide		= hud.update,
	})

	fcp:commandEditor():watch({
		show		= hud.update,
		hide		= hud.update,
	})

	-- Menus
	local hudMenu = deps.tools:addMenu(PRIORITY, function() return i18n("hud") end)
	hudMenu:addItem(1000, function()
			return { title = i18n("enableHacksHUD"),	fn = hud.toggleEnabled,		checked = hud.isEnabled()}
		end)
	hudMenu:addSeparator(2000)
	hudMenu:addMenu(3000, function() return i18n("hudOptions") end)
		:addItems(1000, function()
			return {
				{ title = i18n("showInspector"),	fn = hud.toggleInspectorShown,		checked = hud.isInspectorShown()},
				{ title = i18n("showDropTargets"),	fn = hud.toggleDropTargetsShown, 	checked = hud.isDropTargetsShown(),	disabled = not hud.xmlSharing.isEnabled()},
				{ title = i18n("showButtons"),		fn = hud.toggleButtonsShown, 		checked = hud.isButtonsShown()},
			}
		end)

	hudMenu:addMenu(4000, function() return i18n("assignHUDButtons") end)
		:addItems(1000, function()
			local items = {}
			for i = 1, hud.maxButtons do
				local title = hud.getButtonText(i)
				title = tools.stringMaxLength(tools.cleanupButtonText(title), hud.maxTextLength, "...")
				items[#items + 1] = { title = i18n("hudButtonItem", {count = i, title = title}),	fn = function() hud.assignButton(i) end }
			end
			return items
		end)

	-- Commands
	deps.fcpxCmds:add("cpHUD")
		:activatedBy():ctrl():option():cmd("a")
		:whenActivated(hud.toggleEnabled)

	return hud
end

function plugin.postInit(deps)
	hud.update()
end

return plugin