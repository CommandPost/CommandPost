--- === plugins.motion.feedback.bugreport ===
---
--- Sends Apple a Bug Report or Feature Request for Motion.

local require = require

local log               = require("hs.logger").new("motionBug")

local inspect           = require("hs.inspect")
local screen            = require("hs.screen")
local webview           = require("hs.webview")

local config            = require("cp.config")
local motion            = require("cp.apple.motion")
local just              = require("cp.just")
local tools             = require("cp.tools")
local i18n              = require("cp.i18n")


local mod = {}

-- FEEDBACK_TYPE -> string
-- Constant
-- Feedback Type
local FEEDBACK_TYPE = "Bug Report"

--- plugins.motion.feedback.bugreport.DEFAULT_WIDTH -> number
--- Constant
--- Default Window Width
mod.DEFAULT_WIDTH = 650

--- plugins.motion.feedback.bugreport.DEFAULT_HEIGHT -> number
--- Constant
--- Default Window Height
mod.DEFAULT_HEIGHT = 500

--- plugins.motion.feedback.bugreport.DEFAULT_TITLE -> string
--- Constant
--- Default Window Title
mod.DEFAULT_TITLE = i18n("reportMotionBugToApple")

--- plugins.motion.feedback.bugreport.position <cp.prop: table>
--- Field
--- Webview Position
mod.position = config.prop("motion.bugreport.position", nil)

-- centredPosition() -> none
-- Function
-- Gets the Centred Position.
--
-- Parameters:
--  * None
--
-- Returns:
--  * Table
local function centredPosition()
    local sf = screen.mainScreen():frame()
    return {x = sf.x + (sf.w/2) - (mod.DEFAULT_WIDTH/2), y = sf.y + (sf.h/2) - (mod.DEFAULT_HEIGHT/2), w = mod.DEFAULT_WIDTH, h = mod.DEFAULT_HEIGHT}
end

-- windowCallback(action, webview, frame) -> none
-- Function
-- Window Callback.
--
-- Parameters:
-- * action - accepts `closing`, `focusChange` or `frameChange`
-- * webview - the `hs.webview`
-- * frame - the frame of the `hs.webview`
--
-- Returns:
-- * None
local function windowCallback(action, _, frame)
    if action == "closing" then
        if not hs.shuttingDown then
            mod.webview = nil
        end
    --elseif action == "focusChange" then
    elseif action == "frameChange" then
        if frame then
            mod.position(frame)
        end
    end
end

-- navigationCallback(a, b, c, d) -> none
-- Function
-- Navigation Callback
--
-- Parameters:
--  * `action`  - a string indicating the webview's current status.  It will be one of the following:
--    * `didStartProvisionalNavigation`                    - a request or action to change the contents of the main frame has occurred
--    * `didReceiveServerRedirectForProvisionalNavigation` - a server redirect was received for the main frame
--    * `didCommitNavigation`                              - content has started arriving for the main frame
--    * `didFinishNavigation`                              - the webview's main frame has completed loading.
--    * `didFailNavigation`                                - an error has occurred after content started arriving
--    * `didFailProvisionalNavigation`                     - an error has occurred as or before content has started arriving
--  * `webView` - the webview object the navigation is occurring for.
--  * `navID`   - a navigation identifier which can be used to link this event back to a specific request made by a `hs.webview:url`, `hs.webview:html`, or `hs.webview:reload` method.
--  * `error`   - a table which will only be provided when `action` is equal to `didFailNavigation` or `didFailProvisionalNavigation`.  If provided, it will contain at leas some of the following keys, possibly others as well:
--    * `code`        - a numerical value indicating the type of error code.  This will mostly be of use to developers or in debugging and may be removed in the future.
--    * `domain`      - a string indcating the error domain of the error.  This will mostly be of use to developers or in debugging and may be removed in the future.
--    * `description` - a string describing the condition or problem that has occurred.
--    * `reason`      - if available, more information about what may have caused the problem to occur.
--
-- Returns:
--  * None
local function navigationCallback(action, webView)
    if action == "didFinishNavigation" and webView and webView:title() == "Feedback - Motion - Apple" then

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
            document.getElementById("anonymous_element_2").value = "Other";
            document.getElementById("customer_name").value = "]] .. mod.fullname .. [[";
            document.getElementById("customer_email").value = "]] .. mod.email .. [[";
            document.getElementById("anonymous_element_1").value = "]] .. FEEDBACK_TYPE .. [[";
            document.getElementById("app_version").value = "]] .. mod.motionVersion .. [[";
            document.getElementById("os_version").value = "]] .. mod.macOSVersion .. [[";
            document.getElementById("installed_ram").value = "]] .. mod.ramSize .. [[";
            document.getElementById("installed_video_ram").value = "]] .. mod.vramSize .. [[";
            document.getElementById("machine_config").value = "]] .. mod.modelName .. [[";
            document.getElementsByName("third_party")[0].value = `]] .. mod.externalDevices .. [[`;
            document.getElementById("anonymous_element_3").value = `]] .. defaultFeedback .. [[`;
            //document.getElementById("subject").value = "]] .. mod.feedback .. [[";
            document.getElementById("motion_usage_purpose").value = "]] .. mod.motionUsage .. [[";
            document.getElementById("motion_documentation_usage_frequency").value = "]] .. mod.documentationUsage .. [[";
            document.getElementById("documentation_context").value = "]] .. mod.documentationContext .. [[";

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
            var feedback = document.getElementById("anonymous_element_3");
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

            /* MOTION USAGE: */
            var motionUsage = document.getElementById("motion_usage_purpose");
            motionUsage.addEventListener('change', function()
            {
                var result = {};
                result["id"] = "motionUsage";
                result["value"] = motionUsage.value;
                try {
                    webkit.messageHandlers.bugreport.postMessage(result);
                } catch(err) {
                    alert('An error has occurred. Does the controller exist yet?');
                }
            });

            /* DOCUMENTATION USAGE: */
            var documentationUsage = document.getElementById("motion_documentation_usage_frequency");
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

            /* FOCUS ON SUBJECT FIELD: */
            document.getElementById("subject").focus();

        ]]
        webView:evaluateJavaScript(theScript, function(result, errorMessage)
            if not result then
                if errorMessage and type(errorMessage) == "table" and errorMessage.code then
                    if errorMessage.code ~= 0 then
                        log.ef("Javascript Error: %s", inspect(errorMessage))
                    end
                end
            end
        end)
    end
end

--- plugins.motion.feedback.bugreport.open(bugReport) -> none
--- Function
--- Opens Final Cut Pro Feedback Screen
---
--- Parameters:
---  * bugReport - Is it a bug report or an enhancement request?
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
    mod.fullname = config.get("motion.bugReportCustomerName", "")
    if mod.fullname == "" then
        mod.fullname = tools.getFullname() or ""
    end

    mod.email = config.get("motion.bugReportCustomerEmail", "")
    if mod.email == "" and mod.fullname ~= "" then
        mod.email = tools.getEmail(mod.fullname) or ""
    end

    mod.videoOutput = config.get("motion.bugReportVideoOutput", "")
    mod.feedback = config.get("motion.bugReportFeedback", "")
    mod.motionUsage = config.get("motion.bugReportMotionUsage", "")
    mod.documentationUsage = config.get("motion.bugReportDocumentationUsage", "")
    mod.documentationContext = config.get("motion.bugReportDocumentationContext", "")

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

    mod.motionVersion = "Motion " .. motion:versionString()

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
                config.set("motion.bugReportCustomerName", value)
            elseif id == "customerEmail" then
                config.set("motion.bugReportCustomerEmail", value)
            elseif id == "feedback" then
                config.set("motion.bugReportFeedback", value)
            elseif id == "motionUsage" then
                config.set("motion.bugReportMotionUsage", value)
            elseif id == "documentationUsage" then
                config.set("motion.bugReportDocumentationUsage", value)
            elseif id == "documentationContext" then
                config.set("motion.bugReportDocumentationContext", value)
            elseif id == "videoOutput" then
                config.set("motion.bugReportVideoOutput", value)
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
        :windowStyle({"titled", "closable", "nonactivating", "resizable"})
        :shadow(true)
        :allowNewWindows(false)
        :allowTextEntry(true)
        :windowTitle(mod.DEFAULT_TITLE)
        :deleteOnClose(true)
        :windowCallback(windowCallback)
        :navigationCallback(navigationCallback)
        :url("https://www.apple.com/feedback/motion.html")
        :darkMode(true)
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


local plugin = {
    id              = "motion.feedback.bugreport",
    group           = "motion",
    dependencies    = {
        ["core.menu.manager"]           = "menu",
        ["core.commands.global"]        = "global",
    }
}

function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Menubar:
    --------------------------------------------------------------------------------
    deps.menu.appleHelpAndSupport
        :addItem(2000, function()
            return { title = i18n("suggestMotionFeatureToApple"), fn = function() mod.open(false) end }
        end)
        :addItem(2000.1, function()
            return { title = i18n("reportMotionBugToApple"),  fn = function() mod.open(true) end }
        end)
        :addSeparator(2000.2)

    --------------------------------------------------------------------------------
    -- Commands:
    --------------------------------------------------------------------------------
    local global = deps.global
    global
        :add("cpMotionBugReport")
        :whenActivated(function() mod.open(true) end)
        :groupedBy("helpandsupport")
        :titled(i18n("reportMotionBugToApple"))

    global
        :add("cpMotionFeatureRequest")
        :whenActivated(function() mod.open(false) end)
        :groupedBy("helpandsupport")
        :titled(i18n("suggestMotionFeatureToApple"))

    return mod

end

return plugin
