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

local config									= require("cp.config")
local dialog									= require("cp.dialog")
local tools										= require("cp.tools")

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
mod.position 			= config.prop("feedbackPosition", nil)
mod.isOpen				= false

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

	--------------------------------------------------------------------------------
	-- Default Values:
	--------------------------------------------------------------------------------
	env.defaultUserFullName = i18n("fullName")
	env.defaultUserEmail = i18n("emailAddress")

	--------------------------------------------------------------------------------
	-- Attempt to get Full Name & Email from the Contacts App:
	--------------------------------------------------------------------------------
	local fullname = tools.getFullname()
	local email = ""
	if fullname then email = tools.getEmail(fullname) end		
		
	if fullname == "" then fullname = i18n("fullName") end
	if email == "" then email = i18n("emailAddress") end	
	
	env.userFullName = config.get("userFullName", fullname)
	env.userEmail = config.get("userEmail", email)

	--------------------------------------------------------------------------------
	-- Get Console output:
	--------------------------------------------------------------------------------
	env.consoleOutput = base64.encode(console.getConsole(true):convert("html"))

	--------------------------------------------------------------------------------
	-- Get screenshots of all screens:
	--------------------------------------------------------------------------------
	env.screenshots = tools.getScreenshotsAsBase64()

	local renderTemplate = template.compile(config.scriptPath .. "/cp/feedback/html/feedback.htm")

	local result, err = renderTemplate(env)
	if err then
		log.ef("Error while rendering the 'feedback.htm' form")
		return ""
	else
		return result
	end

end

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
			mod.isOpen = false
		end
	elseif action == "focusChange" then
	elseif action == "frameChange" then
		if frame then
			mod.position(frame)
		end
	end
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
	-- Feedback window already open:
	--------------------------------------------------------------------------------
	if mod.isOpen then
		mod.feedbackWebView:show()
		return
	end

	--------------------------------------------------------------------------------
	-- Quit on Complete?
	--------------------------------------------------------------------------------
	if quitOnComplete == true then
		mod.quitOnComplete = true
	else
		mod.quitOnComplete = false
	end

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
		:windowCallback(windowCallback)
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

			log.df("Server Side Error Message: %s", tools.urlQueryStringDecode(errorMessage))

			dialog.displayMessage(i18n("feedbackError"))
		end
	end)

	--------------------------------------------------------------------------------
	-- Show Welcome Screen:
	--------------------------------------------------------------------------------
	mod.feedbackWebView:show()
	mod.isOpen = true
	timer.doAfter(0.1, function() mod.feedbackWebView:hswindow():focus() end)

end

--------------------------------------------------------------------------------
-- END OF MODULE:
--------------------------------------------------------------------------------
return mod