--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                                H U D                                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === finalcutpro.hud ===
---
--- Final Cut Pro HUD.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("hud")

local application								= require("hs.application")
local chooser									= require("hs.chooser")
local console									= require("hs.console")
local drawing									= require("hs.drawing")
local eventtap									= require("hs.eventtap")
local fnutils 									= require("hs.fnutils")
local fs 										= require("hs.fs")
local geometry									= require("hs.geometry")
local host										= require("hs.host")
local mouse										= require("hs.mouse")
local mouse										= require("hs.mouse")
local screen									= require("hs.screen")
local settings									= require("hs.settings")
local timer										= require("hs.timer")
local urlevent									= require("hs.urlevent")
local webview									= require("hs.webview")
local window									= require("hs.window")

local ax										= require("hs._asm.axuielement")

local dialog									= require("cp.dialog")
local fcp										= require("cp.finalcutpro")
local config									= require("cp.config")
local tools										= require("cp.tools")
local commands									= require("cp.commands")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY									= 10000
local PREFERENCES_KEY							= "enableHUD"
local PREFERENCES_KEY_POSITION					= "hudPosition"

--------------------------------------------------------------------------------
-- FFPlayerQuality CONSTANTS:
--------------------------------------------------------------------------------
local ORIGINAL_QUALITY 							= 10	-- Original - Better Quality
local ORIGINAL_PERFORMANCE						= 5		-- Original - Better Performance
local PROXY										= 4		-- Proxy

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local hud = {}

--------------------------------------------------------------------------------
-- VARIABLES:
--------------------------------------------------------------------------------
hud.title										= config.appName
hud.width										= 350
hud.heightInspector								= 90
hud.heightDropTargets							= 85
hud.heightButtons								= 85

hud.fcpGreen 									= "#3f9253"
hud.fcpRed 										= "#d1393e"

hud.maxButtons									= 4
hud.maxTextLength 								= 25

--- finalcutpro.hud.getPosition() -> table
--- Function
--- Returns the last HUD frame saved in settings.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The last HUD frame or {}.
function hud.getPosition()
	return config.get(PREFERENCES_KEY_POSITION, {})
end

--- finalcutpro.hud.setPosition() -> none
--- Function
--- Saves the HUD position to settings.
---
--- Parameters:
---  * value - Position as table
---
--- Returns:
---  * None
function hud.setPosition(value)
	config.set(PREFERENCES_KEY_POSITION, value)
end

--------------------------------------------------------------------------------
-- GET HUD HEIGHT:
--------------------------------------------------------------------------------
local function getHUDHeight()

	local hudHeight = nil

	local hudShowInspector 		= hud.isInspectorShown()
	local hudShowDropTargets 	= hud.isDropTargetsShown()
	local hudShowButtons 		= hud.isButtonsShown()

	local hudHeight = 0
	if hudShowInspector then hudHeight = hudHeight + hud.heightInspector end
	if hudShowDropTargets then hudHeight = hudHeight + hud.heightDropTargets end
	if hudShowButtons then hudHeight = hudHeight + hud.heightButtons end

	if hudShowInspector and hudShowDropTargets and (not hudShowButtons) then hudHeight = hudHeight - 15 end
	if hudShowInspector and (not hudShowDropTargets) and hudShowButtons then hudHeight = hudHeight - 20 end
	if hudShowInspector and hudShowDropTargets and hudShowButtons then  hudHeight = hudHeight - 20 end

	return hudHeight

end

--------------------------------------------------------------------------------
-- GET HUD RECT:
--------------------------------------------------------------------------------
local function getHUDRect()

	local hudHeight = getHUDHeight()

	--------------------------------------------------------------------------------
	-- Get last HUD position from settings otherwise default to centre screen:
	--------------------------------------------------------------------------------
	local screenFrame = screen.mainScreen():frame()
	local defaultHUDRect = {x = (screenFrame['w']/2) - (hud.width/2), y = (screenFrame['h']/2) - (hudHeight/2), w = hud.width, h = hudHeight}
	local hudPosition = hud.getPosition()
	if next(hudPosition) ~= nil then
		defaultHUDRect = {x = hudPosition["x"], y = hudPosition["y"], w = hud.width, h = hudHeight}
	end

	return defaultHUDRect

end

--------------------------------------------------------------------------------
-- WEBVIEW WINDOW CALLBACK:
--------------------------------------------------------------------------------
local function windowCallback(action, webview, frame)
	if action == "closing" then
		if not hs.shuttingDown then
			hud.setEnabled(false)
			hud.webview = nil
		end
	elseif action == "frameChange" then
		if frame then
			hud.setPosition(frame)
		end
	end
end

--- finalcutpro.hud.new()
--- Function
--- Creates a new HUD
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.new()

	--------------------------------------------------------------------------------
	-- Setup Web View Controller:
	--------------------------------------------------------------------------------
	if not hud.webviewController then
		hud.webviewController = webview.usercontent.new("hud")
			:setCallback(hud.javaScriptCallback)
	end

	--------------------------------------------------------------------------------
	-- Setup Web View:
	--------------------------------------------------------------------------------
	if not hud.webview then
		local developerExtrasEnabled = {}
		if config.get("debugMode") then developerExtrasEnabled = {developerExtrasEnabled = true} end
		hud.webview = webview.new(getHUDRect(), developerExtrasEnabled, hud.webviewController)
			:windowStyle({"HUD", "utility", "titled", "nonactivating", "closable", "resizable"})
			:shadow(true)
			:closeOnEscape(true)
			:html(hud.generateHTML())
			:allowGestures(false)
			:allowNewWindows(false)
			:windowTitle(hud.title)
			:level(drawing.windowLevels.floating)
			:windowCallback(windowCallback)
			:deleteOnClose(true)
	end

end

--- finalcutpro.hud.delete()
--- Function
--- Deletes the existing HUD if it exists
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.delete()
	if hud.webview then
		hud.webview:delete()
		hud.webview = nil
	end
end

--- finalcutpro.hud.isEnabled() -> boolean
--- Function
--- Is the HUD enabled in the settings?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if enabled otherwise false
function hud.isEnabled()
	return config.get(PREFERENCES_KEY, false)
end

--- finalcutpro.hud.setEnabled() -> none
--- Function
--- Sets whether or not the HUD is enabled.
---
--- Parameters:
---  * value - `true` if HUD should be enabled otherwise `false`
---
--- Returns:
---  * `true` if enabled otherwise false
function hud.setEnabled(value)
	config.set(PREFERENCES_KEY, value)
end

--- finalcutpro.hud.toggleEnabled() -> none
--- Function
--- Toggles the HUD
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.toggleEnabled()

	local hudEnabled = hud.isEnabled()
	hud.setEnabled(not hudEnabled)

	if hudEnabled then
		hud.delete()
	else
		hud.new()
		hud.updateVisibility()
	end

end

--
-- Check Options:
--
local function checkOptions()
	return hud.isInspectorShown() or hud.isDropTargetsShown() or hud.isButtonsShown()
end

--- finalcutpro.hud.setOption() -> none
--- Function
--- Sets a HUD option
---
--- Parameters:
---  * name - The name of the option
---  * value - The value of the option
---
--- Returns:
---  * None
function hud.setOption(name, value)
	config.set(name, value)
	if checkOptions() then
		hud.refresh()
	else
		config.set(name, not value)
	end
end

--- finalcutpro.hud.isInspectorShown() -> boolean
--- Function
--- Should the Inspector in the HUD be shown?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` or `false`
function hud.isInspectorShown()
	return config.get("hudShowInspector", true)
end

--- finalcutpro.hud.setInspectorShown() -> none
--- Function
--- Set whether or not the Inspector should be shown in the HUD.
---
--- Parameters:
---  * value - `true` or `false`
---
--- Returns:
---  * None
function hud.setInspectorShown(value)
	hud.setOption("hudShowInspector", value)
end

--- finalcutpro.hud.toggleInspectorShown() -> none
--- Function
--- Toggles whether or not the Inspector should be shown in the HUD.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.toggleInspectorShown()
	hud.setInspectorShown(not hud.isInspectorShown())
end

--- finalcutpro.hud.isDropTargetsShown() -> boolean
--- Function
--- Should Drop Targets in the HUD be shown?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` or `false`
function hud.isDropTargetsShown()
	return config.get("hudShowDropTargets", true) and hud.xmlSharing.isEnabled()
end

--- finalcutpro.hud.setDropTargetsShown() -> none
--- Function
--- Set whether or not Drop Targets should be shown in the HUD.
---
--- Parameters:
---  * value - `true` or `false`
---
--- Returns:
---  * None
function hud.setDropTargetsShown(value)
	hud.setOption("hudShowDropTargets", value)
end

--- finalcutpro.hud.toggleInspectorShown() -> none
--- Function
--- Toggles whether or not Drop Targets should be shown in the HUD.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.toggleDropTargetsShown()
	hud.setDropTargetsShown(not hud.isDropTargetsShown())
end

--- finalcutpro.hud.isButtonsShown() -> boolean
--- Function
--- Should Buttons in the HUD be shown?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` or `false`
function hud.isButtonsShown()
	return config.get("hudShowButtons", true)
end

--- finalcutpro.hud.setButtonsShown() -> none
--- Function
--- Set whether or not Buttons should be shown in the HUD.
---
--- Parameters:
---  * value - `true` or `false`
---
--- Returns:
---  * None
function hud.setButtonsShown(value)
	hud.setOption("hudShowButtons", value)
end

--- finalcutpro.hud.toggleInspectorShown() -> none
--- Function
--- Toggles whether or not Buttons should be shown in the HUD.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.toggleButtonsShown()
	hud.setButtonsShown(not hud.isButtonsShown())
end

--- finalcutpro.hud.getButton() -> string
--- Function
--- Gets the button values from settings.
---
--- Parameters:
---  * index - Index of the Button
---  * defaultValue - Default Value of the Button
---
--- Returns:
---  * Button value
function hud.getButton(index, defaultValue)
	local currentLanguage = fcp:getCurrentLanguage()
	return config.get(string.format("%s.hudButton.%d", currentLanguage, index), defaultValue)
end

--- finalcutpro.hud.getButtonCommand() -> string
--- Function
--- Gets the button command.
---
--- Parameters:
---  * index - Index of the Button
---
--- Returns:
---  * Button Command
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

--- finalcutpro.hud.getButtonText() -> string
--- Function
--- Gets the button text.
---
--- Parameters:
---  * index - Index of the Button
---
--- Returns:
---  * Button Label or Unassigned Value
function hud.getButtonText(index)
	local button = hud.getButton(index)
	if button and button.text then
		return tools.stringMaxLength(tools.cleanupButtonText(button.text), hud.maxTextLength, "...")
	else
		return i18n("unassigned")
	end
end

--- finalcutpro.hud.getButtonURL() -> string
--- Function
--- Gets the button URL.
---
--- Parameters:
---  * index - Index of the Button
---
--- Returns:
---  * Button URL
function hud.getButtonURL(index)
	return hud.actionmanager.getURL(hud.getButton(index))
end

--- finalcutpro.hud.setButton() -> string
--- Function
--- Sets the button.
---
--- Parameters:
---  * index - Index of the Button
---  * value - Value you want to set the button to.
---
--- Returns:
---  * None
function hud.setButton(index, value)
	local currentLanguage = fcp:getCurrentLanguage()
	config.set(string.format("%s.hudButton.%d", currentLanguage, index), value)
end

--- finalcutpro.hud.updateVisibility() -> none
--- Function
--- Update the visibility of the HUD.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.updateVisibility()
	if hud.isEnabled() then

		local fcpRunning 	= fcp:isRunning()
		local fcpFrontmost 	= fcp:isFrontmost()

		local fullscreenWindowShowing = fcp:fullScreenWindow():isShowing()
		local commandEditorShowing = fcp:commandEditor():isShowing()

		if (fcpRunning and fcpFrontmost and not fullscreenWindowShowing and not commandEditorShowing) then
			hud.show()
		else
			local frontmostWindowTitle = window.frontmostWindow():application():title()
			if frontmostWindowTitle and frontmostWindowTitle ~= "Final Cut Pro" and frontmostWindowTitle ~= "CommandPost" then
				hud.hide()
			end
		end
	end
end

--- finalcutpro.hud.show() -> none
--- Function
--- Show the HUD.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.show()
	if not hud.webview then
		hud.new()
	end

	hud.webview:show()
	hud.refresh()
end

--- finalcutpro.hud.hide() -> none
--- Function
--- Hide the HUD.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.hide()
	if hud.webview then
		hud.webview:hide()
	end
end

--- finalcutpro.hud.visible() -> none
--- Function
--- Is the HUD visible?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` or `false`
function hud.visible()
	if hud.webview and hud.webview:hswindow() then return true end
	return false
end

--------------------------------------------------------------------------------
-- DISPLAY DIV VALUE:
--------------------------------------------------------------------------------
local function displayDiv(value)
	if value then
		return "block"
	else
		return "none"
	end
end

--------------------------------------------------------------------------------
-- SET UP TEMPLATE ENVIRONMENT:
--------------------------------------------------------------------------------
local function getEnv()
	--------------------------------------------------------------------------------
	-- Set up the template environment
	--------------------------------------------------------------------------------
	local env 		= {}

	env.i18n		= i18n
	env.hud			= hud
	env.displayDiv	= displayDiv

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

	local autoStartBGRender	= fcp:getPreference("FFAutoStartBGRender", true)

	if autoStartBGRender then
		local autoRenderDelay 	= tonumber(fcp:getPreference("FFAutoRenderDelay", "0.3"))
		env.backgroundRender	= {
			text	= string.format("%s (%s %s)", i18n("enabled"), tostring(autoRenderDelay), i18n("secs", {count=autoRenderDelay})),
			class	= "good",
		}
	else
		env.backgroundRender	= {
			text	= i18n("disabled"),
			class	= "bad",
		}
	end

	env.hudInspector 		= displayDiv( hud.isInspectorShown() )
	env.hr1 				= displayDiv( hud.isInspectorShown() and (hud.isDropTargetsShown() or hud.isButtonsShown()) )
	env.hudDropTargets		= displayDiv( hud.isDropTargetsShown() )
	env.hr2					= displayDiv( (hud.isDropTargetsShown() and hud.isButtonsShown()) )
	env.hudButtons			= displayDiv( hud.isButtonsShown() )

	return env
end

--- finalcutpro.hud.refresh() -> none
--- Function
--- Refresh the HUD's content.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.refresh()

	--------------------------------------------------------------------------------
	-- Update HUD Content:
	--------------------------------------------------------------------------------
	if hud.webview then
		local env = getEnv()
		local javascriptToInject = [[
			document.getElementById('media').innerHTML = "]] .. env.media.text .. [[";
			document.getElementById('media').className = "]] .. env.media.class .. [[";

			document.getElementById('quality').innerHTML = "]] .. env.quality.text .. [[";
			document.getElementById('quality').className = "]] .. env.quality.class .. [[";

			document.getElementById('backgroundRender').innerHTML = "]] .. env.backgroundRender.text .. [[";
			document.getElementById('backgroundRender').className = "]] .. env.backgroundRender.class .. [[";

			document.getElementById('button1').innerHTML = "]] .. hud.getButtonText(1) .. [[";
			document.getElementById('button2').innerHTML = "]] .. hud.getButtonText(2) .. [[";
			document.getElementById('button3').innerHTML = "]] .. hud.getButtonText(3) .. [[";
			document.getElementById('button4').innerHTML = "]] .. hud.getButtonText(4) .. [[";

			document.getElementById('button1').setAttribute('href', ']] .. hud.getButtonURL(1) .. [[');
			document.getElementById('button2').setAttribute('href', ']] .. hud.getButtonURL(2) .. [[');
			document.getElementById('button3').setAttribute('href', ']] .. hud.getButtonURL(3) .. [[');
			document.getElementById('button4').setAttribute('href', ']] .. hud.getButtonURL(4) .. [[');

			document.getElementById('hudInspector').style.display = ']] .. env.hudInspector .. [[';
			document.getElementById('hr1').style.display = ']] .. env.hr1 .. [[';
			document.getElementById('hudDropTargets').style.display = ']] .. env.hudDropTargets .. [[';
			document.getElementById('hr2').style.display = ']] .. env.hr2 .. [[';
			document.getElementById('hudButtons').style.display = ']] .. env.hudButtons .. [[';
		]]
		hud.webview:evaluateJavaScript(javascriptToInject)
	end

	--------------------------------------------------------------------------------
	-- Resize the HUD:
	--------------------------------------------------------------------------------
	if hud.visible() then
		hud.webview:hswindow():setSize(geometry.size(hud.width, getHUDHeight()))
	end

end

--- finalcutpro.hud.assignButton() -> none
--- Function
--- Assigns a HUD button.
---
--- Parameters:
---  * button - which button you want to assign.
---
--- Returns:
---  * None
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
		-- Refresh HUD:
		--------------------------------------------------------------------------------
		if hud.isEnabled() then
			hud.refresh()
		end
	end

	hudButtonChooser = chooser.new(chooserAction):bgDark(true)
												  :fgColor(drawing.color.x11.snow)
												  :subTextColor(drawing.color.x11.snow)
												  :choices(hud.choices)
												  :show()
end

--- finalcutpro.hud.choices() -> none
--- Function
--- Choices for the Assign HUD Button chooser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Table
function hud.choices()
	if hud.actionmanager then
		return hud.actionmanager.choices()
	else
		return {}
	end
end

--- finalcutpro.hud.generateHTML() -> none
--- Function
--- Generate the HTML for the HUD.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.generateHTML()
	local result, err = hud.renderTemplate(getEnv())
	if err then
		log.ef("Error while rendering HUD template: %s", err)
		return err
	else
		return result
	end

end

--- finalcutpro.hud.javaScriptCallback() -> none
--- Function
--- Javascript Callback
---
--- Parameters:
---  * message - the message for the callback
---
--- Returns:
---  * None
function hud.javaScriptCallback(message)
	if message["body"] ~= nil then
		if string.find(message["body"], "<!DOCTYPE fcpxml>") ~= nil then
			hud.shareXML(message["body"])
		else
			dialog.displayMessage(i18n("hudDropZoneError"))
		end
	end
end

--- finalcutpro.hud.shareXML() -> none
--- Function
--- Share XML
---
--- Parameters:
---  * incomingXML - XML data as string
---
--- Returns:
---  * None
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

--- finalcutpro.hud.init() -> none
--- Function
--- Initialise HUD Module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.init(xmlSharing, actionmanager, htmlPath)
	hud.xmlSharing		= xmlSharing
	hud.actionmanager	= actionmanager
	hud.renderTemplate	= env:compileTemplate("html/hud.html")
	return hud
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.hud",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.sharing.xml"]			= "xmlSharing",
		["finalcutpro.menu.tools"]			= "menu",
		["finalcutpro.commands"]			= "fcpxCmds",
		["core.action.manager"]				= "actionmanager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

	--------------------------------------------------------------------------------
	-- Initialise Module:
	--------------------------------------------------------------------------------
	hud.init(deps.xmlSharing, deps.actionmanager, env)

	--------------------------------------------------------------------------------
	-- Setup Watchers:
	--------------------------------------------------------------------------------
	fcp:watch({
		active		= hud.updateVisibility,
		inactive	= hud.updateVisibility,
		preferences = hud.refresh,
	})

	fcp:fullScreenWindow():watch({
		show		= hud.updateVisibility,
		hide		= hud.updateVisibility,
	})

	fcp:commandEditor():watch({
		show		= hud.updateVisibility,
		hide		= hud.updateVisibility,
	})

	hud.xmlSharing:watch({
		enable		= hud.updateVisibility,
		disable		= hud.updateVisibility,
	})

	--------------------------------------------------------------------------------
	-- Menus:
	--------------------------------------------------------------------------------
	local hudMenu = deps.menu:addMenu(PRIORITY, function() return i18n("hud") end)
	hudMenu:addItem(1000, function()
			return { title = i18n("enableHUD"),	fn = hud.toggleEnabled,		checked = hud.isEnabled()}
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

	--------------------------------------------------------------------------------
	-- Commands:
	--------------------------------------------------------------------------------
	deps.fcpxCmds:add("cpHUD")
		:activatedBy():ctrl():option():cmd("a")
		:whenActivated(hud.toggleEnabled)

	return hud
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit(deps)

	if hud.isEnabled() then
		hud.new()
		hud.updateVisibility()
	end

end

return plugin