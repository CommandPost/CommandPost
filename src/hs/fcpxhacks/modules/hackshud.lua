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
--
-- TO DO:
--
--   - Work out how to detect when the close button is pressed
--   - Work out how to detect when the Hacks HUD is moved (to save position)
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------

local hackshud = {}

local settings									= require("hs.settings")
local fnutils 									= require("hs.fnutils")
local webview									= require("hs.webview")
local drawing									= require("hs.drawing")
local screen									= require("hs.screen")
local window									= require("hs.window")
local windowfilter								= require("hs.window.filter")
local urlevent									= require("hs.urlevent")
local timer										= require("hs.timer")

local fcp										= require("hs.finalcutpro")
local dialog									= require("hs.fcpxhacks.modules.dialog")

--------------------------------------------------------------------------------
-- Create the Hacks HUD:
--------------------------------------------------------------------------------
function hackshud.new()

	local screenFrame = screen.mainScreen():frame()
	local hudWidth = 350
	local hudHeight = 200
	local defaultHUDRect = {x = (screenFrame['w']/2) - (hudWidth/2), y = (screenFrame['h']/2) - (hudHeight/2), w = hudWidth, h = hudHeight}

	local hudName = "Hacks HUD"

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
		:allowGestures(true)
		:allowNewWindows(false)
		:windowTitle(hudName)
		:level(drawing.windowLevels.modalPanel)

	--------------------------------------------------------------------------------
	-- URL Events:
	--------------------------------------------------------------------------------
	hackshud.urlEvent = urlevent.bind("fcpxhacks", hackshud.hudCallback)

	--------------------------------------------------------------------------------
	-- Window Watcher:
	--------------------------------------------------------------------------------
	-- TO DO: Work out why the hell this doesn't work:
	--windowFilter = windowfilter.new{hudName}
	--windowFilter:subscribe(windowfilter.windowMoved, function() print("Moving") end)

end

--------------------------------------------------------------------------------
-- Show the Hacks HUD:
--------------------------------------------------------------------------------
function hackshud.show()
	if hackshud.hudWebView == nil then
		hackshud.new()
		hackshud.hudWebView:show()
	else
		hackshud.hudWebView:show()
	end
end

--------------------------------------------------------------------------------
-- Is Hacks HUD Active?
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
-- Hide the Hacks HUD:
--------------------------------------------------------------------------------
function hackshud.hide()
	if hackshud.active() then
		hackshud.hudWebView:hide()
	end
end

--------------------------------------------------------------------------------
-- Delete the Hacks HUD:
--------------------------------------------------------------------------------
function hackshud.delete()
	if hackshud.active() then
		hackshud.hudWebView:delete()
	end
end

--------------------------------------------------------------------------------
-- Refresh the Hacks HUD:
--------------------------------------------------------------------------------
function hackshud.refresh()
	if hackshud.active() then
		hackshud.hudWebView:html(generateHTML())
	end
end

--------------------------------------------------------------------------------
-- Generate HTML:
--------------------------------------------------------------------------------
function generateHTML()

	local preferences = fcp.getPreferencesAsTable()

	if preferences["FFPlayerQuality"] == nil then
		FFPlayerQuality = 5
	else
		FFPlayerQuality = preferences["FFPlayerQuality"]
	end
	local playerQuality = nil
	if FFPlayerQuality == 4 then
		playerQuality = '<span style="color: red;">Proxy</span>'
	else
		playerQuality = '<span style="color: green;">Original/Optimised</span>'
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
		backgroundRender = '<span style="color: green;">Enabled (' .. FFAutoRenderDelay .. 'secs)</span>'
	else
		backgroundRender = '<span style="color: red;">Disabled</span>'
	end

	local HTML = [[<!DOCTYPE html>
<html>
	<head>
		<!-- Style Sheets: -->
		<style>
		body {
			background-color:#1f1f1f;
			color: white;
			font-family: 'Verdana';
			font-size: 12px;
		}
		table {
			text-align:left;
		}
		h1 {
			font-size: 12px;
			font-weight: bold;
		}
		hr {
			height:1px;
			border-width:0;
			color:gray;
			background-color:gray;
		    display: block;
			margin-top: 15px;
			margin-bottom: 15px;
			margin-left: auto;
			margin-right: auto;
			border-style: inset;
		}
		input[type=text] {
			width: 100%;
			padding: 12px 20px;
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

				x.value = "DROP FINAL CUT PRO LIBRARIES & EVENTS HERE";
			}

		</script>
	</head>
	<body>
		<table style="width:100%">
			<tr>
				<th><strong>Media:</strong></th>
				<th>]] .. playerQuality .. [[<th>
			</tr>
			<tr>
				<th><strong>Background Render:</strong></th>
				<th>]] .. backgroundRender .. [[</th>
			</tr>
		</table>
		<hr />
		<a href="hammerspoon://fcpxhacks?function=toggleScrollingTimeline" style="color: white;">Toggle Scrolling Timeline</a>
		<hr />
		<form>
			<input type="text" id="dropbox" name="dropbox" oninput="dropboxAction()" tabindex="-1" value="DROP FINAL CUT PRO LIBRARIES & EVENTS HERE">
		</form>
		</span>
	</body>
</html>
	]]

	return HTML

end

--------------------------------------------------------------------------------
-- JavaScript Callback:
--------------------------------------------------------------------------------
function hackshud.javaScriptCallback(message)
	if message["body"] ~= nil then
		if string.find(message["body"], "<!DOCTYPE fcpxml>") ~= nil then
			dialog.displayMessage("An FCPXML has been successfully dragged onto the Hacks HUD.")
		else
			dialog.displayMessage("Ah, I'm not sure what you dragged here, but it didn't look like FCPXML?")
		end
	end
end

--------------------------------------------------------------------------------
-- URL Event Callback:
--------------------------------------------------------------------------------
function hackshud.hudCallback(eventName, params)
	if params["function"] ~= nil then
		timer.doAfter(0.0000000001, function() _G[params["function"]]() end )
	end
end

return hackshud