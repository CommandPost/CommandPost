--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                      F E E D B A C K   M O D U L E                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("welcome")

local application								= require("hs.application")
local console									= require("hs.console")
local base64									= require("hs.base64")
local screen									= require("hs.screen")
local timer										= require("hs.timer")
local urlevent									= require("hs.urlevent")
local webview									= require("hs.webview")

local dialog									= require("cp.dialog")
local config									= require("cp.config")

local template									= require("resty.template")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--------------------------------------------------------------------------------
-- SETTINGS:
--------------------------------------------------------------------------------
mod.defaultWidth 		= 365
mod.defaultHeight 		= 438
mod.defaultTitle 		= config.appName .. " " .. i18n("feedback")
mod.quitOnComplete		= false

--------------------------------------------------------------------------------
-- GET SCREENSHOTS:
--------------------------------------------------------------------------------
local function getScreenshotsAsBase64()

	local screenshots = {}
	local allScreens = screen.allScreens()
	for i, v in ipairs(allScreens) do
		local temporaryFileName = os.tmpname()
		v:shotAsJPG(temporaryFileName)
		local screenshotFile = io.open(temporaryFileName, "r")
		local screenshotFileContents = screenshotFile:read("*all")
		screenshotFile:close()
		os.remove(temporaryFileName)
		screenshots[#screenshots + 1] = base64.encode(screenshotFileContents)
	end

	return screenshots

end

--------------------------------------------------------------------------------
-- GENERATE HTML:
--------------------------------------------------------------------------------
local function generateHTML()

	local env = {}

	env.appVersion = config.appVersion

	env.defaultUserFullName = i18n("fullName")
	env.defaultUserEmail = i18n("emailAddress")

	env.userFullName = config.get("userFullName", env.defaultUserFullName)
	env.userEmail = config.get("userEmail", env.defaultUserEmail)

	--------------------------------------------------------------------------------
	-- Get Console output:
	--------------------------------------------------------------------------------
	env.consoleOutput = console.getConsole(true):convert("html")

	--------------------------------------------------------------------------------
	-- Get screenshots of all screens:
	--------------------------------------------------------------------------------
	env.screenshots = getScreenshotsAsBase64()

	return template.render(config.scriptPath .. "/cp/feedback/html/feedback.htm", env)

end

local function urlQueryStringDecode(s)
	s = s:gsub('+', ' ')
	s = s:gsub('%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
	return string.sub(s, 2, -2)
end

--------------------------------------------------------------------------------
-- NAVIGATION CALLBACK:
--------------------------------------------------------------------------------
local function feedbackWebViewNavigationWatcher(action, webView, navID, errorTable)
	print("Action: " .. hs.inspect(action))
	print("webView: " .. hs.inspect(webView))
	print("navID: " .. hs.inspect(navID))
	print("errorTable: " .. hs.inspect(errorTable))
end

--------------------------------------------------------------------------------
-- CREATE THE FEEDBACK SCREEN:
--------------------------------------------------------------------------------
function mod.showFeedback(quitOnComplete)

	--------------------------------------------------------------------------------
	-- Quit on Complete?
	--------------------------------------------------------------------------------
	if quitOnComplete == true then
		mod.quitOnComplete = true
	else
		mod.quitOnComplete = false
	end

	--------------------------------------------------------------------------------
	-- Centre on Screen:
	--------------------------------------------------------------------------------
	local screenFrame = screen.mainScreen():frame()
	local defaultRect = {x = (screenFrame['w']/2) - (mod.defaultWidth/2), y = (screenFrame['h']/2) - (mod.defaultHeight/2), w = mod.defaultWidth, h = mod.defaultHeight}

	--------------------------------------------------------------------------------
	-- Setup Web View Controller:
	--------------------------------------------------------------------------------
	mod.feedbackWebViewController = webview.usercontent.new("feedback")
		:setCallback(function(message)
			if type(message["body"]) == "table" then
				config.set("userFullName", message["body"][1])
				config.set("userEmail", message["body"][2])
			end
		end)

	--------------------------------------------------------------------------------
	-- Setup Web View:
	--------------------------------------------------------------------------------
	local developerExtrasEnabled = {}
	if config.get("debugMode") then developerExtrasEnabled = {developerExtrasEnabled = true} end
	mod.feedbackWebView = webview.new(defaultRect, developerExtrasEnabled, mod.feedbackWebViewController)
		--:navigationCallback(feedbackWebViewNavigationWatcher)
		:windowStyle({"titled"})
		:shadow(true)
		:allowNewWindows(false)
		:allowTextEntry(true)
		:windowTitle(mod.defaultTitle)
		:html(generateHTML())

	--------------------------------------------------------------------------------
	-- Setup URL Events:
	--------------------------------------------------------------------------------
	mod.urlEvent = urlevent.bind("feedback", function(eventName, params)

		if params["action"] == "cancel" then
			mod.feedbackWebView:delete()
			mod.feedbackWebView = nil
		elseif params["action"] == "error" then

			local errorMessage = "Unknown"
			if params["message"] then errorMessage = params["message"] end

			print("Feedback Error Message:")
			print(urlQueryStringDecode(errorMessage))

			dialog.displayMessage("The following error occurred when trying to process the form:\n\n" .. urlQueryStringDecode(errorMessage))

			mod.feedbackWebView:delete()
			mod.feedbackWebView = nil
		elseif params["action"] == "done" then
			if mod.quitOnComplete then
				application.applicationForPID(hs.processInfo["processID"]):kill()
			else
				mod.feedbackWebView:delete()
				mod.feedbackWebView = nil
			end
		end

	end)

	--------------------------------------------------------------------------------
	-- Show Welcome Screen:
	--------------------------------------------------------------------------------
	mod.feedbackWebView:show()
	timer.doAfter(0.1, function() mod.feedbackWebView:hswindow():focus() end)

end

--------------------------------------------------------------------------------
-- END OF MODULE:
--------------------------------------------------------------------------------
return mod