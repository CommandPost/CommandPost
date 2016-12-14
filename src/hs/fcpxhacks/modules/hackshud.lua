--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                       F C P X    H A C K S    H U D                        --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--
-- Module created by Chris Hocking (https://github.com/latenitefilms).
--
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------

local hackshud = {}

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------

local settings									= require("hs.settings")
local fnutils 									= require("hs.fnutils")
local webview									= require("hs.webview")
local drawing									= require("hs.drawing")
local screen									= require("hs.screen")
local window									= require("hs.window")
local windowfilter								= require("hs.window.filter")
local urlevent									= require("hs.urlevent")
local timer										= require("hs.timer")
local host										= require("hs.host")

local fcp										= require("hs.finalcutpro")
local dialog									= require("hs.fcpxhacks.modules.dialog")

--------------------------------------------------------------------------------
-- SETTINGS:
--------------------------------------------------------------------------------

hackshud.name									= "Hacks HUD"
hackshud.width									= 350
hackshud.height									= 200

hackshud.fcpGreen 								= "#3f9253"
hackshud.fcpRed 								= "#d1393e"

--------------------------------------------------------------------------------
-- VARIABLES:
--------------------------------------------------------------------------------

hackshud.ignoreWindowChange						= true
hackshud.windowID								= nil

--------------------------------------------------------------------------------
-- CREATE THE HACKS HUD:
--------------------------------------------------------------------------------
function hackshud.new()

	--------------------------------------------------------------------------------
	-- Get last HUD position from settings otherwise default to centre screen:
	--------------------------------------------------------------------------------
	local screenFrame = screen.mainScreen():frame()
	local defaultHUDRect = {x = (screenFrame['w']/2) - (hackshud.width/2), y = (screenFrame['h']/2) - (hackshud.height/2), w = hackshud.width, h = hackshud.height}
	local hudPosition = settings.get("fcpxHacks.hudPosition") or {}
	if next(hudPosition) ~= nil then
		defaultHUDRect = {x = hudPosition["_x"], y = hudPosition["_y"], w = hackshud.width, h = hackshud.height}
	end

	--------------------------------------------------------------------------------
	-- Setup Web View Controller:
	--------------------------------------------------------------------------------
	hackshud.hudWebViewController = webview.usercontent.new("hackshud")
		:setCallback(hackshud.javaScriptCallback)

	--------------------------------------------------------------------------------
	-- Setup Web View:
	--------------------------------------------------------------------------------
	hackshud.hudWebView = webview.new(defaultHUDRect, {}, hackshud.hudWebViewController)
		:windowStyle({"HUD", "utility", "titled", "nonactivating", "closable"})
		:shadow(true)
		:closeOnEscape(true)
		:html(generateHTML())
		:allowGestures(false)
		:allowNewWindows(false)
		:windowTitle(hackshud.name)
		:level(drawing.windowLevels.modalPanel)

	--------------------------------------------------------------------------------
	-- URL Events:
	--------------------------------------------------------------------------------
	hackshud.urlEvent = urlevent.bind("fcpxhacks", hackshud.hudCallback)

	--------------------------------------------------------------------------------
	-- Window Watcher:
	--------------------------------------------------------------------------------
	hackshud.hudFilter = windowfilter.new(true)
		:setAppFilter(hackshud.name, {activeApplication=true})

	--------------------------------------------------------------------------------
	-- HUD Moved:
	--------------------------------------------------------------------------------
	hackshud.hudFilter:subscribe(windowfilter.windowMoved, function(window, applicationName, event)
		if window:id() == hackshud.windowID then
			if hackshud.active() then
				local result = hackshud.hudWebView:hswindow():frame()
				if result ~= nil then
					settings.set("fcpxHacks.hudPosition", result)
				end
			end
		end
	end, true)

	--------------------------------------------------------------------------------
	-- HUD Closed:
	--------------------------------------------------------------------------------
	hackshud.hudFilter:subscribe(windowfilter.windowDestroyed, function(window, applicationName, event)
		if window:id() == hackshud.windowID then
			if not hackshud.ignoreWindowChange then
				settings.set("fcpxHacks.enableHacksHUD", false)
				refreshMenuBar()
			end
		end
	end, true)

	--------------------------------------------------------------------------------
	-- HUD Unfocussed:
	--------------------------------------------------------------------------------
	hackshud.hudFilter:subscribe(windowfilter.windowUnfocused, function(window, applicationName, event)
		if window:id() == hackshud.windowID then
			if not fcp.frontmost() then
				if not hackshud.ignoreWindowChange then
					hackshud.hide()
				end
			end
		end
	end, true)

end

--------------------------------------------------------------------------------
-- SHOW THE HACKS HUD:
--------------------------------------------------------------------------------
function hackshud.show()
	hackshud.ignoreWindowChange = true
	if hackshud.hudWebView == nil then
		hackshud.new()
		hackshud.hudWebView:show()
	else
		hackshud.hudWebView:show()
	end

	timer.doAfter(0.01, function()
		hackshud.windowID = hackshud.hudWebView:hswindow():id()
	end)

	hackshud.ignoreWindowChange = false
end

--------------------------------------------------------------------------------
-- IS HACKS HUD ACTIVE:
--------------------------------------------------------------------------------
function hackshud.active()
	if hackshud.hudWebView == nil then
		return false
	end
	if hackshud.hudWebView:hswindow() == nil then
		return false
	else
		return true
	end
end

--------------------------------------------------------------------------------
-- HIDE THE HACKS HUD:
--------------------------------------------------------------------------------
function hackshud.hide()
	if hackshud.active() then
		hackshud.ignoreWindowChange = true
		hackshud.hudWebView:hide()
	end
end

--------------------------------------------------------------------------------
-- DELETE THE HACKS HUD:
--------------------------------------------------------------------------------
function hackshud.delete()
	if hackshud.active() then
		hackshud.hudWebView:delete()
	end
end

--------------------------------------------------------------------------------
-- REFRESH THE HACKS HUD:
--------------------------------------------------------------------------------
function hackshud.refresh()
	if hackshud.active() then
		hackshud.hudWebView:html(generateHTML())
	end
end

--------------------------------------------------------------------------------
-- GENERATE HTML:
--------------------------------------------------------------------------------
function generateHTML()

	local preferences = fcp.getPreferences()

	--------------------------------------------------------------------------------
	-- FFPlayerQuality
	--------------------------------------------------------------------------------
	-- 10 	= Original - Better Quality
	-- 5 	= Original - Better Performance
	-- 4 	= Proxy
	--------------------------------------------------------------------------------

	if preferences["FFPlayerQuality"] == nil then
		FFPlayerQuality = 5
	else
		FFPlayerQuality = preferences["FFPlayerQuality"]
	end
	local playerQuality = nil
	if FFPlayerQuality == 10 then
		playerMedia = '<span style="color: ' .. hackshud.fcpGreen .. ';">Original/Optimised</span>'
		playerQuality = '<span style="color: ' .. hackshud.fcpGreen .. ';">Better Quality</span>'
	elseif FFPlayerQuality == 5 then
		playerMedia = '<span style="color: ' .. hackshud.fcpGreen .. ';">Original/Optimised</span>'
		playerQuality = '<span style="color: ' .. hackshud.fcpRed .. ';">Better Performance</span>'
	elseif FFPlayerQuality == 4 then
		playerMedia = '<span style="color: ' .. hackshud.fcpRed .. ';">Proxy</span>'
		playerQuality = '<span style="color: ' .. hackshud.fcpRed .. ';">Proxy</span>'
	end
	if preferences["FFAutoRenderDelay"] == nil then
		FFAutoRenderDelay = "0.3"
	else
		FFAutoRenderDelay = preferences["FFAutoRenderDelay"]
	end
	if preferences["FFAutoStartBGRender"] == nil then
		FFAutoStartBGRender = true
	else
		FFAutoStartBGRender = preferences["FFAutoStartBGRender"]
	end

	local backgroundRender = nil
	if FFAutoStartBGRender then
		backgroundRender = '<span style="color: ' .. hackshud.fcpGreen .. ';">Enabled (' .. FFAutoRenderDelay .. 'secs)</span>'
	else
		backgroundRender = '<span style="color: ' .. hackshud.fcpRed .. ';">Disabled</span>'
	end

	local HTML = [[<!DOCTYPE html>
<html>
	<head>
		<!-- Style Sheets: -->
		<style>
		.button {
			font-family: -apple-system;
			font-size: 10px;
			text-decoration: none;
			background-color: #333333;
			color: #bfbebb;
			padding: 2px 6px 2px 6px;
			border-top: 1px solid #161616;
			border-right: 1px solid #161616;
			border-bottom: 1px solid #161616;
			border-left: 1px solid #161616;
		}
		body {
			background-color:#1f1f1f;
			color: #bfbebb;
			font-family: -apple-system;
			font-size: 11px;
			font-weight: lighter;
		}
		table {
			width:100%;
			text-align:left;
		}
		th {
			width:50%;
		}
		h1 {
			font-size: 12px;
			font-weight: bold;
			text-align: center;
			margin: 0px;
			padding: 0px;
		}
		hr {
			height:1px;
			border-width:0;
			color:gray;
			background-color:#797979;
		    display: block;
			margin-top: 10px;
			margin-bottom: 10px;
			margin-left: auto;
			margin-right: auto;
			border-style: inset;
		}
		input[type=text] {
			width: 100%;
			padding: 5px 5px;
			margin: 8px 0;
			box-sizing: border-box;
			border: 4px solid #22426f;
			border-radius: 4px;
			background-color: black;
			color: white;
			text-align:center;
		}
		</style>

		<!-- Javascript: -->
		<script>

			// Disable Right Clicking:
			document.addEventListener("contextmenu", function(e){
			    e.preventDefault();
			}, false);

			// Something has been dropped onto our Dropbox:
			function dropboxAction() {
				var x = document.getElementById("dropbox");
				var dropboxValue = x.value;

				try {
				webkit.messageHandlers.hackshud.postMessage(dropboxValue);
				} catch(err) {
				console.log('The controller does not exist yet');
				}

				x.value = "DROP FROM FINAL CUT PRO BROWSER TO HERE";
			}

		</script>
	</head>
	<body>
		<table>
			<tr>
				<th>Media:</th>
				<th>]] .. playerMedia .. [[<th>
			</tr>
			<tr>
				<th>Quality:</th>
				<th>]] .. playerQuality .. [[<th>
			</tr>

			<tr>
				<th>Background Render:</th>
				<th>]] .. backgroundRender .. [[</th>
			</tr>
		</table>
		<hr />
		<h1>XML Sharing</h1>
		<form><input type="text" id="dropbox" name="dropbox" oninput="dropboxAction()" tabindex="-1" value="DROP FROM FINAL CUT PRO BROWSER TO HERE"></form>
		<hr />
		<table>
			<tr>
				<th style="text-align:center;"><a href="hammerspoon://fcpxhacks?function=toggleScrollingTimeline" class="button">Toggle Scrolling Timeline</a> <a href="hammerspoon://fcpxhacks?function=toggleTouchBar" class="button">Toggle Touch Bar</a></th>
			<tr>
		</table>
	</body>
</html>
	]]

	return HTML

end

--------------------------------------------------------------------------------
-- JAVASCRIPT CALLBACK:
--------------------------------------------------------------------------------
function hackshud.javaScriptCallback(message)
	if message["body"] ~= nil then
		if string.find(message["body"], "<!DOCTYPE fcpxml>") ~= nil then
			hackshud.shareXML(message["body"])
		else
			dialog.displayMessage("Ah, I'm not sure what you dragged here, but it didn't look like FCPXML?")
		end
	end
end

--------------------------------------------------------------------------------
-- URL EVENT CALLBACK:
--------------------------------------------------------------------------------
function hackshud.hudCallback(eventName, params)
	if params["function"] ~= nil then
		timer.doAfter(0.0000000001, function()
			_G[params["function"]]()
		end)
	end
end

--------------------------------------------------------------------------------
-- SHARED XML:
--------------------------------------------------------------------------------
function hackshud.shareXML(incomingXML)

	local enableXMLSharing = settings.get("fcpxHacks.enableXMLSharing") or false

	if enableXMLSharing then

		--------------------------------------------------------------------------------
		-- Get Settings:
		--------------------------------------------------------------------------------
		local xmlSharingPath = settings.get("fcpxHacks.xmlSharingPath")

		--------------------------------------------------------------------------------
		-- Get only the needed XML content:
		--------------------------------------------------------------------------------
		local startOfXML = string.find(incomingXML, "<?xml version=")
		local endOfXML = string.find(incomingXML, "</fcpxml>")

		--------------------------------------------------------------------------------
		-- Error Detection:
		--------------------------------------------------------------------------------
		if startOfXML == nil or endOfXML == nil then
			dialog.displayErrorMessage("Something went wrong when attempting to translate the XML data you dropped. Please try again.\n\nError occurred in hackshud.shareXML().")
			if incomingXML ~= nil then
				debugMessage("Start of incomingXML.")
				debugMessage(incomingXML)
				debugMessage("End of incomingXML.")
			else
				debugMessage("ERROR: incomingXML is nil.")
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
		local textboxResult = dialog.displayTextBoxMessage("How would you like to label this XML file?", "The label you entered has special characters that cannot be used.\n\nPlease try again.", "")

		--------------------------------------------------------------------------------
		-- Save the XML content to the Shared XML Folder:
		--------------------------------------------------------------------------------
		local file = io.open(xmlSharingPath .. textboxResult .. " (" .. host.localizedName() .. ").fcpxml", "w")
		currentClipboardData = file:write(newXML)
		file:close()
	else
		dialog.displayMessage("XML Sharing is currently disabled.\n\nPlease enable it via the FCPX Hacks menu and try again.")
	end

end

--------------------------------------------------------------------------------
-- END OF MODULE:
--------------------------------------------------------------------------------
return hackshud