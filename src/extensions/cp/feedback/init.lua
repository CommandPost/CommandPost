--- === cp.feedback ===
---
--- Feedback Form.

local require           = require
local hs                = _G.hs

local log               = require "hs.logger".new "feedback"
local inspect           = require "hs.inspect"

local application       = require "hs.application"
local base64            = require "hs.base64"
local console           = require "hs.console"
local screen            = require "hs.screen"
local timer             = require "hs.timer"
local urlevent          = require "hs.urlevent"
local webview           = require "hs.webview"

local config            = require "cp.config"
local dialog            = require "cp.dialog"
local i18n              = require "cp.i18n"
local tools             = require "cp.tools"

local template          = require "resty.template"

local displayMessage    = dialog.displayMessage
local doAfter           = timer.doAfter

local mod = {}

--- cp.feedback.defaultWidth -> number
--- Variable
--- Default webview width.
mod.defaultWidth = 365

--- cp.feedback.defaultHeight -> number
--- Variable
--- Default webview height.
mod.defaultHeight = 500

--- cp.feedback.defaultTitle -> number
--- Variable
--- Default webview title.
mod.defaultTitle = config.appName .. " " .. i18n("feedback")

--- cp.feedback.quitOnComplete -> boolean
--- Variable
--- Quit on complete?
mod.quitOnComplete = false

--- cp.feedback.position -> prop
--- Variable
--- Webview Position.
mod.position = config.prop("feedbackPosition", nil)

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
    -- i18n:
    --------------------------------------------------------------------------------
    env.bugReport = i18n("bugReport")
    env.featureRequest = i18n("featureRequest")
    env.support = i18n("support")
    env.whatWentWrong = i18n("whatWentWrong")
    env.whatDidYouExpectToHappen = i18n("whatDidYouExpectToHappen")
    env.whatStepsToRecreate = i18n("whatStepsToRecreate")
    env.whatFeatures = i18n("whatFeatures")
    env.howCanWeHelp = i18n("howCanWeHelp")
    env.attachLog = i18n("attachLog")
    env.attachScreenshot = i18n("attachScreenshot")
    env.emailResponse = i18n("emailResponse")
    env.includeContactInfo = i18n("includeContactInfo")
    env.cancel = i18n("cancel")
    env.send = i18n("send")

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

-- centredPosition() - table
-- Function
-- Gets the centre position.
--
-- Parameters:
--  * None
--
-- Returns:
--  * Table
local function centredPosition()
    local sf = screen.mainScreen():frame()
    return {x = sf.x + (sf.w/2) - (mod.defaultWidth/2), y = sf.y + (sf.h/2) - (mod.defaultHeight/2), w = mod.defaultWidth, h = mod.defaultHeight}
end

-- windowCallback() - none
-- Function
-- Window callback.
--
-- Parameters:
--  * action - The action
--  * unused
--  * frame - The frame
--
-- Returns:
--  * None
local function windowCallback(action, _, frame)
    if action == "closing" then
        if not hs.shuttingDown then
            mod.webview = nil
        end
    -- elseif action == "focusChange" then
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
    doAfter(0.000000001, function()
        --------------------------------------------------------------------------------
        -- Feedback window already open:
        --------------------------------------------------------------------------------
        if mod.feedbackWebView and mod.feedbackWebView:hswindow() then
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
        defaultRect.w = mod.defaultWidth
        defaultRect.h = mod.defaultHeight

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
                    log.df("Message: %s", inspect(message))
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
            :darkMode(true)
            :policyCallback(function(action, _, details1, _)
                if action == "navigationResponse" then
                    local statusCode = details1.response.statusCode
                    if statusCode == 403 or statusCode == 404 then
                        mod.feedbackWebView:delete()
                        mod.feedbackWebView = nil
                        displayMessage(i18n("feedbackError"), {message="The server responded with a " .. statusCode .. " status code."})
                        return false
                    end
                end
                return true
            end)

        --------------------------------------------------------------------------------
        -- Setup URL Events:
        --------------------------------------------------------------------------------
        mod.urlEvent = urlevent.bind("feedback", function(_, params)
            --------------------------------------------------------------------------------
            -- PHP Executed Successfully:
            --------------------------------------------------------------------------------
            if params["action"] == "done" then
                mod.feedbackWebView:delete()
                mod.feedbackWebView = nil
                displayMessage(i18n("feedbackSuccess"))
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

                displayMessage(i18n("feedbackError", {message=tools.urlQueryStringDecode(errorMessage)}))
            end
        end)

        --------------------------------------------------------------------------------
        -- Show Welcome Screen:
        --------------------------------------------------------------------------------
        mod.feedbackWebView:show()
        doAfter(0.1, function() mod.feedbackWebView:hswindow():focus() end)
    end)
end

return mod
