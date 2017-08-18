--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                     B U G    R E P O R T    P L U G I N                    --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.feedback.bugreport ===
---
--- Sends Apple a Bug Report or Feature Request for Final Cut Pro.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("bugreport")

local geometry			= require("hs.geometry")
local host				= require("hs.host")
local osascript			= require("hs.osascript")
local screen			= require("hs.screen")
local webview			= require("hs.webview")

local config			= require("cp.config")
local dialog			= require("cp.dialog")
local fcp				= require("cp.apple.finalcutpro")
local just				= require("cp.just")
local prop				= require("cp.prop")
local tools				= require("cp.tools")

local v					= require("semver")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 			= 1
local FEEDBACK_URL		= "https://www.apple.com/feedback/finalcutpro.html"
local FEEDBACK_TYPE		= "Bug Report"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--------------------------------------------------------------------------------
-- SETTINGS:
--------------------------------------------------------------------------------
mod.defaultWindowStyle	= {"titled", "closable", "nonactivating", "resizable"}
mod.defaultWidth 		= 650
mod.defaultHeight 		= 500
mod.defaultTitle 		= i18n("reportBugToApple")
mod.position 			= config.prop("bugreportPosition", nil)

--------------------------------------------------------------------------------
-- CENTRED POSITION:
--------------------------------------------------------------------------------
local function centredPosition()
	local sf = screen.mainScreen():frame()
	return {x = sf.x + (sf.w/2) - (mod.defaultWidth/2), y = sf.y + (sf.h/2) - (mod.defaultHeight/2), w = mod.defaultWidth, h = mod.defaultHeight}
end

--------------------------------------------------------------------------------
-- WEBVIEW WINDOW CALLBACK:
--------------------------------------------------------------------------------
local function windowCallback(action, webview, frame)
	if action == "closing" then
		if not hs.shuttingDown then
			mod.webview = nil
		end
	elseif action == "focusChange" then
	elseif action == "frameChange" then
		if frame then
			mod.position(frame)
		end
	end
end

--------------------------------------------------------------------------------
-- NAVIGATION CALLBACK:
--------------------------------------------------------------------------------
local function navigationCallback(a, b, c, d)
	if a == "didFinishNavigation" and b and b:title() == "Feedback - Final Cut Pro - Apple" then

		local defaultFeedback = "WHAT WENT WRONG?\n\n\nWHAT DID YOU EXPECT TO HAPPEN?\n\n\nWHAT ARE THE STEPS TO RECREATE THE PROBLEM?\n\n"

		if FEEDBACK_TYPE == "Enhancement Request" then
			defaultFeedback = "WHAT FEATURE WOULD YOU LIKE TO SEE IMPLEMENTED OR IMPROVED?\n\n"
		end

		--------------------------------------------------------------------------------
		-- Time to inject some JavaScript!
		--------------------------------------------------------------------------------
		local theScript = [[

			/* STYLE: */
			document.documentElement.style.overflowX = "hidden";
			document.getElementById("main").style.width = "650px";
			document.getElementById("ac-globalnav").style.display = "none";
			document.getElementById("ac-globalfooter").style.display = "none";
			document.getElementById("ac-gn-placeholder").style.display = "none";
			document.getElementsByClassName("column last sidebar")[0].style.display = "none";

			/* AUTO-COMPLETE FORM: */
			document.getElementById("app_area").value = "Other";
			document.getElementById("customer_name").value = "]] .. mod.fullname .. [[";
			document.getElementById("customer_email").value = "]] .. mod.email .. [[";
			document.getElementById("feedback_type").value = "]] .. FEEDBACK_TYPE .. [[";
			document.getElementById("app_version").value = "]] .. mod.finalCutProVersion .. [[";
			document.getElementById("osversion").value = "]] .. mod.macOSVersion .. [[";
			document.getElementById("installed_ram").value = "]] .. mod.ramSize .. [[";
			document.getElementById("installed_video_ram").value = "]] .. mod.vramSize .. [[";
			document.getElementById("machine_config").value = "]] .. mod.modelName .. [[";
			document.getElementsByName("third_party")[0].value = `]] .. mod.externalDevices .. [[`;
			document.getElementById("feedback_comment").value = `]] .. defaultFeedback .. [[`;
			document.getElementById("feedback").value = "]] .. mod.feedback .. [[";
			document.getElementById("FinalCutPro_usage_purpose").value = "]] .. mod.fcpUsage .. [[";
			document.getElementById("FinalCutPro_documentation_usage_frequency").value = "]] .. mod.documentationUsage .. [[";
			document.getElementById("documentation_context").value = "]] .. mod.documentationContext .. [[";
			document.getElementById("video_output").value = "]] .. mod.videoOutput .. [[";

			/* CUSTOMER NAME: */
			var customerName = document.getElementById("customer_name");
			customerName.addEventListener('change', function()
			{
				var result = {};
				result["id"] = "customerName";
				result["value"] = customerName.value;
				try {
					webkit.messageHandlers.bugreport.postMessage(result);
				} catch(err) {
					alert('An error has occurred. Does the controller exist yet?');
				}
			});

			/* CUSTOMER EMAIL: */
			var customerEmail = document.getElementById("customer_email");
			customerEmail.addEventListener('change', function()
			{
				var result = {};
				result["id"] = "customerEmail";
				result["value"] = customerEmail.value;
				try {
					webkit.messageHandlers.bugreport.postMessage(result);
				} catch(err) {
					alert('An error has occurred. Does the controller exist yet?');
				}
			});

			/* FEEDBACK: */
			var feedback = document.getElementById("feedback");
			feedback.addEventListener('change', function()
			{
				var result = {};
				result["id"] = "feedback";
				result["value"] = feedback.value;
				try {
					webkit.messageHandlers.bugreport.postMessage(result);
				} catch(err) {
					alert('An error has occurred. Does the controller exist yet?');
				}
			});

			/* FINAL CUT PRO USAGE: */
			var fcpUsage = document.getElementById("FinalCutPro_usage_purpose");
			fcpUsage.addEventListener('change', function()
			{
				var result = {};
				result["id"] = "fcpUsage";
				result["value"] = fcpUsage.value;
				try {
					webkit.messageHandlers.bugreport.postMessage(result);
				} catch(err) {
					alert('An error has occurred. Does the controller exist yet?');
				}
			});

			/* DOCUMENTATION USAGE: */
			var documentationUsage = document.getElementById("FinalCutPro_documentation_usage_frequency");
			documentationUsage.addEventListener('change', function()
			{
				var result = {};
				result["id"] = "documentationUsage";
				result["value"] = documentationUsage.value;
				try {
					webkit.messageHandlers.bugreport.postMessage(result);
				} catch(err) {
					alert('An error has occurred. Does the controller exist yet?');
				}
			});

			/* DOCUMENTATION CONTEXT: */
			var documentationContext = document.getElementById("documentation_context");
			documentationContext.addEventListener('change', function()
			{
				var result = {};
				result["id"] = "documentationContext";
				result["value"] = documentationContext.value;
				try {
					webkit.messageHandlers.bugreport.postMessage(result);
				} catch(err) {
					alert('An error has occurred. Does the controller exist yet?');
				}
			});

			/* VIDEO OUTPUT: */
			var videoOutput = document.getElementById("video_output");
			videoOutput.addEventListener('change', function()
			{
				var result = {};
				result["id"] = "videoOutput";
				result["value"] = videoOutput.value;
				try {
					webkit.messageHandlers.bugreport.postMessage(result);
				} catch(err) {
					alert('An error has occurred. Does the controller exist yet?');
				}
			});

			/* FOCUS ON SUBJECT FIELD: */
			document.getElementById("subject").focus();

		]]
		b:evaluateJavaScript(theScript, function(theResult, theError)
			--log.df("theResult: %s", hs.inspect(theResult))
			--log.df("Javascript Error: %s", hs.inspect(theError))
		end)
	end
end

--- plugins.finalcutpro.feedback.bugreport.open() -> none
--- Function
--- Opens Final Cut Pro Feedback Screen
---
--- Parameters:
---  * bugReport - Is it a bug report?
---
--- Returns:
---  * None
function mod.open(bugReport)

	--------------------------------------------------------------------------------
	-- Feedback Type:
	--------------------------------------------------------------------------------
	if bugReport then
		FEEDBACK_TYPE = "Bug Report"
	else
		FEEDBACK_TYPE = "Enhancement Request"
	end

	--------------------------------------------------------------------------------
	-- Gather Data:
	--------------------------------------------------------------------------------
	mod.fullname = config.get("bugReportCustomerName", "")
	if mod.fullname == "" then
		mod.fullname = tools.getFullname() or ""
	end

	mod.email = config.get("bugReportCustomerEmail", "")
	if mod.email == "" and mod.fullname ~= "" then
		mod.email = tools.getEmail(mod.fullname) or ""
	end

	mod.videoOutput = config.get("bugReportVideoOutput", "")
	mod.feedback = config.get("bugReportFeedback", "")
	mod.fcpUsage = config.get("bugReportFCPUsage", "")
	mod.documentationUsage = config.get("bugReportDocumentationUsage", "")
	mod.documentationContext = config.get("bugReportDocumentationContext", "")

	if not mod.macOSVersion then
		mod.macOSVersion = tools.getmacOSVersion()
	end
	if not mod.ramSize then
		mod.ramSize = tools.getRAMSize()
	end
	if not mod.vramSize then
		mod.vramSize = tools.getVRAMSize()
	end
	if not mod.modelName then
		mod.modelName = tools.getModelName()
	end
	if not mod.externalDevices then
		mod.externalDevices = tools.getExternalDevices()
	end

	mod.finalCutProVersion = fcp.getVersion()

	--------------------------------------------------------------------------------
	-- Use last Position or Centre on Screen:
	--------------------------------------------------------------------------------
	local defaultRect = mod.position()
	if tools.isOffScreen(defaultRect) then
		defaultRect = centredPosition()
	end

	--------------------------------------------------------------------------------
	-- Setup Web View Controller:
	--------------------------------------------------------------------------------
	mod.controller = webview.usercontent.new("bugreport")
		:setCallback(function(message)

			local body = message.body
			local id = body.id
			local value = body.value

			--log.df("Result: %s | %s", id, value)

			if id == "customerName" then
				config.set("bugReportCustomerName", value)
			elseif id == "customerEmail" then
				config.set("bugReportCustomerEmail", value)
			elseif id == "feedback" then
				config.set("bugReportFeedback", value)
			elseif id == "fcpUsage" then
				config.set("bugReportFCPUsage", value)
			elseif id == "documentationUsage" then
				config.set("bugReportDocumentationUsage", value)
			elseif id == "documentationContext" then
				config.set("bugReportDocumentationContext", value)
			elseif id == "videoOutput" then
				config.set("bugReportVideoOutput", value)
			else
				log.ef("Bug Report Controller recieved something it didn't expect.")
			end

		end)

	--------------------------------------------------------------------------------
	-- Setup Web View:
	--------------------------------------------------------------------------------
	local prefs = {}
	prefs.developerExtrasEnabled = config.developerMode()
	mod.webview = webview.new(defaultRect, prefs, mod.controller)
		:windowStyle(mod.defaultWindowStyle)
		:shadow(true)
		:allowNewWindows(false)
		:allowTextEntry(true)
		:windowTitle(mod.defaultTitle)
		:deleteOnClose(true)
		:windowCallback(windowCallback)
		:navigationCallback(navigationCallback)
		:url(FEEDBACK_URL)
		:show()

	--------------------------------------------------------------------------------
	-- Bring WebView to Front:
	--------------------------------------------------------------------------------
	just.doUntil(function()
		if mod.webview and mod.webview:hswindow() and mod.webview:hswindow():raise():focus() then
			return true
		else
			return false
		end
	end)

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.feedback.bugreport",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.menu.support"] 	= "menu",
		["core.commands.global"] 		= "global",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	--------------------------------------------------------------------------------
	-- Menubar:
	--------------------------------------------------------------------------------
	deps.menu
		:addItem(PRIORITY, function()
			return { title = i18n("suggestFeatureToApple"),	fn = function() mod.open(false) end }
		end)
		:addItem(PRIORITY + 0.1, function()
			return { title = i18n("reportBugToApple"),	fn = function() mod.open(true) end }
		end)
		:addSeparator(PRIORITY + 0.2)

	--------------------------------------------------------------------------------
	-- Commands:
	--------------------------------------------------------------------------------
	deps.global:add("cpBugReport")
		:whenActivated(function() mod.open(true) end)

	deps.global:add("cpFeatureRequest")
		:whenActivated(function() mod.open(false) end)

	return mod

end

return plugin