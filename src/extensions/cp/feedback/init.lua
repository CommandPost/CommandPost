--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                      F E E D B A C K   M O D U L E                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.feedback ===
---
--- Feedback Form.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("feedback")

local application								= require("hs.application")
local base64									= require("hs.base64")
local console									= require("hs.console")
local mouse										= require("hs.mouse")
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

-- getScreenshotsAsBase64() -> table
-- Function
-- Captures all available screens and saves them as base64 encodes in a table.
--
-- Parameters:
--  * None
--
-- Returns:
--  * table containing base64 images of all available screens.
local function getScreenshotsAsBase64()
	local screenshots = {}
	local allScreens = screen.allScreens()
	for i, v in ipairs(allScreens) do
		local temporaryFileName = os.tmpname()
		v:shotAsJPG(temporaryFileName)
		hs.execute("sips -Z 1920 " .. temporaryFileName)
		local screenshotFile = io.open(temporaryFileName, "r")
		local screenshotFileContents = screenshotFile:read("*all")
		screenshotFile:close()
		os.remove(temporaryFileName)
		screenshots[#screenshots + 1] = base64.encode(screenshotFileContents)
	end
	return screenshots
end

-- generateHTML() -> string
-- Function
-- Generates the HTML for the Feedback Plugin
--
-- Parameters:
--  * None
--
-- Returns:
--  * HTML as string or "" on error
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
	env.consoleOutput = base64.encode(console.getConsole(true):convert("html"))

	--------------------------------------------------------------------------------
	-- Get screenshots of all screens:
	--------------------------------------------------------------------------------
	env.screenshots = getScreenshotsAsBase64()

	local renderTemplate = template.compile(config.scriptPath .. "/cp/feedback/html/feedback.htm")

	local result, err = renderTemplate(env)
	if err then
		log.ef("Error while rendering the 'feedback.htm' form")
		return ""
	else
		return result
	end

end

-- urlQueryStringDecode() -> string
-- Function
-- Decodes a URL Query String
--
-- Parameters:
--  * None
--
-- Returns:
--  * Decoded URL Query String as string
local function urlQueryStringDecode(s)
	s = s:gsub('+', ' ')
	s = s:gsub('%%(%x%x)', function(h) return string.char(tonumber(h, 16)) end)
	return string.sub(s, 2, -2)
end

--- cp.feedback.showFeedback(quitOnComplete) -> nil
--- Function
--- Displays the Feedback Screen.
---
--- Parameters:
---  * quitOnComplete - `true` if you want CommandPost to quit after the Feedback is complete otherwise `false`
---
--- Returns:
---  * None
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
			if message["body"] == "cancel" then
				if mod.quitOnComplete then
					application.applicationForPID(hs.processInfo["processID"]):kill()
				else
					mod.feedbackWebView:delete()
					mod.feedbackWebView = nil
				end
			elseif message["body"] == "hide" then
				mod.feedbackWebView:hide()
			elseif type(message["body"]) == "table" then
				config.set("userFullName", message["body"][1])
				config.set("userEmail", message["body"][2])
			else
				log.df("Message: %s", hs.inspect(message))
			end
		end)

	--------------------------------------------------------------------------------
	-- Setup Web View:
	--------------------------------------------------------------------------------
	local prefs = {}
	if config.developerMode() then prefs = {developerExtrasEnabled = true} end
	mod.feedbackWebView = webview.new(defaultRect, prefs, mod.feedbackWebViewController)
		:windowStyle({"titled"})
		:shadow(true)
		:allowNewWindows(false)
		:allowTextEntry(true)
		:windowTitle(mod.defaultTitle)
		:html(generateHTML())
		:policyCallback(function(action, wv, details1, details2)
			if action == "navigationResponse" then
				local statusCode = details1.response.statusCode
				if statusCode == 403 or statusCode == 404 then
					mod.feedbackWebView:delete()
					mod.feedbackWebView = nil
					dialog.displayMessage(i18n("feedbackError"))
					return false
				end
			end
			return true
		end)

	--------------------------------------------------------------------------------
	-- Setup URL Events:
	--------------------------------------------------------------------------------
	mod.urlEvent = urlevent.bind("feedback", function(eventName, params)
		--------------------------------------------------------------------------------
		-- PHP Executed Successfully:
		--------------------------------------------------------------------------------
		if params["action"] == "done" then
			mod.feedbackWebView:delete()
			mod.feedbackWebView = nil
			dialog.displayMessage(i18n("feedbackSuccess"))
			if mod.quitOnComplete then
				application.applicationForPID(hs.processInfo["processID"]):kill()
			end
		--------------------------------------------------------------------------------
		-- Server Side Error:
		--------------------------------------------------------------------------------
		elseif params["action"] == "error" then
			mod.feedbackWebView:delete()
			mod.feedbackWebView = nil

			local errorMessage = "Unknown"
			if params["message"] then errorMessage = params["message"] end

			log.df("Server Side Error Message: %s", urlQueryStringDecode(errorMessage))

			dialog.displayMessage(i18n("feedbackError"))
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