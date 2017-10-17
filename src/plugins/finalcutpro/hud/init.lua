--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                                H U D                                       --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.hud ===
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
local fcp										= require("cp.apple.finalcutpro")
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
local GROUP										= "fcpx"

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
hud.title										= "" --config.appName
hud.width										= 350
hud.heightInspector								= 90
hud.heightDropTargets							= 85
hud.heightButtons								= 85

hud.fcpGreen 									= "#3f9253"
hud.fcpRed 										= "#d1393e"

hud.maxButtons									= 4
hud.maxTextLength 								= 25

--- plugins.finalcutpro.hud.position <cp.prop: table>
--- Constant
--- Returns the last HUD frame saved in settings.
hud.position = config.prop(PREFERENCES_KEY_POSITION, {})

--------------------------------------------------------------------------------
-- GET HUD HEIGHT:
--------------------------------------------------------------------------------
local function getHUDHeight()

	local hudHeight = nil

	local hudShowInspector 		= hud.inspectorShown()
	local hudShowDropTargets 	= hud.isDropTargetsAvailable()
	local hudShowButtons 		= hud.buttonsShown()

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
	local hudPosition = hud.position()
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
			hud.enabled(false)
			hud.webview = nil
		end
	elseif action == "frameChange" then
		if frame then
			hud.position(frame)
		end
	end
end

--- plugins.finalcutpro.hud.new()
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
		local options = {}
		if config.developerMode() then options.developerExtrasEnabled = true end
		hud.webview = webview.new(getHUDRect(), options, hud.webviewController)
			:windowStyle({"titled", "nonactivating", "closable"})
			:shadow(true)
			:closeOnEscape(true)
			:html(hud.generateHTML())
			:allowGestures(false)
			:allowNewWindows(false)
			:windowTitle(hud.title)
			:level(drawing.windowLevels.floating)
			:windowCallback(windowCallback)
			:deleteOnClose(true)
			:darkMode(true)
	end

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

	env.debugMode	= config.developerMode()

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

	local backgroundRender	= fcp:getPreference("FFAutoStartBGRender", true)

	if backgroundRender then
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

	env.hudInspector 		= displayDiv( hud.inspectorShown() )
	env.hr1 				= displayDiv( hud.inspectorShown() and (hud.isDropTargetsAvailable() or hud.buttonsShown()) )
	env.hudDropTargets		= displayDiv( hud.isDropTargetsAvailable() )
	env.hr2					= displayDiv( (hud.isDropTargetsAvailable() and hud.buttonsShown()) )
	env.hudButtons			= displayDiv( hud.buttonsShown() )

	return env
end

--- plugins.finalcutpro.hud.refresh() -> none
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

--- plugins.finalcutpro.hud.delete()
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

--- plugins.finalcutpro.hud.enabled <cp.prop: boolean>
--- Field
--- Is the HUD enabled in the settings?
hud.enabled = config.prop(PREFERENCES_KEY, false)

--- plugins.finalcutpro.hud.inspectorShown <cp.prop: boolean>
--- Field
--- Should the Inspector in the HUD be shown?
hud.inspectorShown = config.prop("hudShowInspector", true):watch(hud.refresh)

--- plugins.finalcutpro.hud.dropTargetsShown <cp.prop: boolean>
--- Field
--- Should Drop Targets in the HUD be enabled?
hud.dropTargetsShown = config.prop("hudShowDropTargets", true):watch(hud.refresh)

--- plugins.finalcutpro.hud.buttonsShown <cp.prop: boolean>
--- Field
--- Should Buttons in the HUD be shown?
hud.buttonsShown = config.prop("hudShowButtons", true):watch(hud.refresh)

--- plugins.finalcutpro.hud.getButton() -> table
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
	local currentLanguage = fcp:currentLanguage()
	return config.get(string.format("%s.hudButton.%d", currentLanguage, index), defaultValue)
end

--- plugins.finalcutpro.hud.getButtonCommand() -> string
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

--- plugins.finalcutpro.hud.getButtonText() -> string
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

--- plugins.finalcutpro.hud.getButtonURL() -> string
--- Function
--- Gets the button URL.
---
--- Parameters:
---  * index - Index of the Button
---
--- Returns:
---  * Button URL
function hud.getButtonURL(index)
	local button = hud.getButton(index)
	if button then
		return hud.actionmanager.getURL(button.handlerId, button.action)
	else
		return "#"
	end
end

--- plugins.finalcutpro.hud.setButton() -> string
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
	local currentLanguage = fcp:currentLanguage()
	config.set(string.format("%s.hudButton.%d", currentLanguage, index), value)
end

--- plugins.finalcutpro.hud.updateVisibility() -> none
--- Function
--- Update the visibility of the HUD.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.updateVisibility()
	if hud.enabled() then

		local fcpRunning 	= fcp:isRunning()
		local fcpFrontmost 	= fcp:isFrontmost()
		
		if not fcpRunning and not fcpFrontmost then
			hud.hide()
			return
		end

		local fullscreenWindowShowing = fcp:fullScreenWindow():isShowing()
		local commandEditorShowing = fcp:commandEditor():isShowing()

		if fullscreenWindowShowing or commandEditorShowing then
			hud.hide()
			return
		end
		
		if fcpRunning and fcpFrontmost then
			hud.show()
		else		
			
			local focusedWindow = window.focusedWindow()		
			local mouseButtons = mouse.getButtons()
			
			if mouseButtons and mouseButtons["left"] and mouseButtons["left"] == true and focusedWindow and focusedWindow:application():pid() == config.processID then
				hud.show()
			else
				hud.hide()
			end				

		end
	end
end

--- plugins.finalcutpro.hud.show() -> none
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

--- plugins.finalcutpro.hud.hide() -> none
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

--- plugins.finalcutpro.hud.visible() -> none
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

--- plugins.finalcutpro.hud.assignButton() -> none
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
	local activator = nil

	local chooserAction = function(handler, action, text)
		--------------------------------------------------------------------------------
		-- Perform Specific Function:
		--------------------------------------------------------------------------------
		if action ~= nil then
			local button = { handlerId = handler:id(), action = action, text = text }
			hud.setButton(whichButton, button)
		end

		--------------------------------------------------------------------------------
		-- Put focus back in Final Cut Pro:
		--------------------------------------------------------------------------------
		if wasFinalCutProOpen then
			fcp:launch()
		end

		--------------------------------------------------------------------------------
		-- Refresh HUD:
		--------------------------------------------------------------------------------
		if hud.enabled() then
			hud.refresh()
		end
	end

	activator = hud.actionmanager.getActivator("finalcutpro.hud.buttons")
	:onActivate(chooserAction)

	--------------------------------------------------------------------------------
	-- Restrict Allowed Handlers for Activator to current group:
	--------------------------------------------------------------------------------
	local allowedHandlers = {}			
	local handlerIds = hud.actionmanager.handlerIds()			
	for _,id in pairs(handlerIds) do				
		local handlerTable = tools.split(id, "_")
		if handlerTable[1] == GROUP then
			table.insert(allowedHandlers, id)
		end										
	end					
	activator:allowHandlers(table.unpack(allowedHandlers))

	activator:show()
end

--- plugins.finalcutpro.hud.choices() -> none
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

--- plugins.finalcutpro.hud.generateHTML() -> none
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

--- plugins.finalcutpro.hud.javaScriptCallback() -> none
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
			hud.xmlSharing.shareXML(message["body"])
		else
			dialog.displayMessage(i18n("hudDropZoneError"))
		end
	end
end

function hud.update()
	if hud.enabled() then
		hud.new()
		hud.updateVisibility()
	else
		hud.delete()
	end
end

--- plugins.finalcutpro.hud.init() -> none
--- Function
--- Initialise HUD Module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function hud.init(xmlSharing, actionmanager, env)
	hud.xmlSharing		= xmlSharing
	hud.actionmanager	= actionmanager
	hud.renderTemplate	= env:compileTemplate("html/hud.html")

	-- Set up checking for XML Sharing
	xmlSharing.enabled:watch(hud.refresh)
	hud.isDropTargetsAvailable = hud.dropTargetsShown:AND(xmlSharing.enabled)

	hud.enabled:watch(hud.update)
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
		["core.action.manager"]		= "actionmanager",
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
		open		= hud.updateVisibility,
		close		= hud.updateVisibility,
	})

	--------------------------------------------------------------------------------
	-- Menus:
	--------------------------------------------------------------------------------
	local hudMenu = deps.menu:addMenu(PRIORITY, function() return i18n("hud") end)
	hudMenu:addItem(1000, function()
			return { title = i18n("enableHUD"),	fn = function() hud.enabled:toggle() end,		checked = hud.enabled()}
		end)
	hudMenu:addSeparator(2000)
	hudMenu:addMenu(3000, function() return i18n("hudOptions") end)
		:addItems(1000, function()
			return {
				{ title = i18n("showInspector"),	fn = function() hud.inspectorShown:toggle() end,		checked = hud.inspectorShown()},
				{ title = i18n("showDropTargets"),	fn = function() hud.dropTargetsShown:toggle() end, 	checked = hud.isDropTargetsAvailable(),	disabled = not hud.xmlSharing.enabled()},
				{ title = i18n("showButtons"),		fn = function() hud.buttonsShown:toggle() end, 		checked = hud.buttonsShown()},
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
		:whenActivated(function() hud.enabled:toggle() end)

	return hud
end

--------------------------------------------------------------------------------
-- POST INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.postInit(deps)
	hud.update()
end

return plugin