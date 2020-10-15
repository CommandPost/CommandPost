--- === plugins.finalcutpro.notifications.ifttt ===
---
--- IFTTT Notifications Plugin.
---
--- Author: [JFtechOfficial](https://github.com/JFtechOfficial)

local require           = require

--local log               = require "hs.logger".new "ifttt"

local dialog            = require "hs.dialog"
local http              = require "hs.http"
local json              = require "hs.json"

local config            = require "cp.config"
local html              = require "cp.web.html"
local i18n              = require "cp.i18n"
local ui                = require "cp.web.ui"

local mod = {}

--- plugins.finalcutpro.notifications.ifttt.userAPIKey <cp.prop: string>
--- Field
--- User API Key
mod.userAPIKey = config.prop("iftttUserAPIKey", nil)

--- plugins.finalcutpro.notifications.ifttt.appAPIKey <cp.prop: string>
--- Field
--- Application API Key
mod.appAPIKey = config.prop("iftttAppAPIKey", nil)

--- plugins.finalcutpro.notifications.ifttt.enabled <cp.prop: boolean>
--- Field
--- Whether or not the plugin has been enabled.
mod.enabled = config.prop("iftttNotificationsEnabled", false):watch(function() mod.update() end)

--- plugins.finalcutpro.notifications.ifttt.update() -> none
--- Function
--- Enables or disables ifttt Notifications depending on the user's preferences.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    if mod.enabled() then
        if mod.watcherId == nil then
            mod.watcherId = mod.notifications.watch({
                success = mod.sendNotification,
                failure = mod.sendNotification,
            })
        end
    else
        if mod.watcherId ~= nil then
            mod.notifications.unwatch(mod.watcherId)
            mod.watcherId = nil
        end
    end
end

--- plugins.finalcutpro.notifications.ifttt.init() -> none
--- Function
--- Initialises the plugin.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(notifications)
    mod.notifications = notifications
    mod.update()
end

--- plugins.finalcutpro.notifications.ifttt.sendNotification(message, [title]) -> none
--- Function
--- Sends a notification.
---
--- Parameters:
---  * message - The message you want to send as a string.
---  * [title] - An optional Title for the message as a string.
---
--- Returns:
---  * success - `true` if successful otherwise `false`
---  * errorMessage - a string containing any error messages
function mod.sendNotification(message, optionalTitle)
    if not mod.userAPIKey() or not mod.appAPIKey() then
        return false
    end
    local maker = "https://maker.ifttt.com/trigger/"
    local title = optionalTitle or string.upper(i18n("finalCutPro"))
    title = http.encodeForQuery(title)
    message = http.encodeForQuery(message)
    local url = maker .. mod.userAPIKey() .. "/with/key/" .. mod.appAPIKey() .. "?value1=" .. title .. "&value2=" .. message .. "&value3=Unused"
    local status, body = http.doRequest(url, "post")
    if status == 200 and string.match(body, [[Congratulations!]]) then
        return true
    else
        if pcall(function() json.decode(body) end) and json.decode(body)["errors"] then
            local errors = json.decode(body)["errors"]
            local errorMessage = errors[1]["message"]
            print(errorMessage)
            return false, errorMessage
        else
            if status == 0 then
                return false, "  - " .. i18n("iftttServerFailed") .. "\n  - " .. i18n("areYouConnectedToTheInternet")
            else
                return false, "  - " .. i18n("unknownError") .. " (" .. tostring(status) .. ")"
            end
        end
    end
end

local plugin = {
    id = "finalcutpro.notifications.ifttt",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.notifications.manager"]           = "manager",
        ["core.preferences.panels.notifications"]       = "prefs",
        ["core.preferences.manager"]                    = "prefsManager",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    mod.init(deps.manager)

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    if deps.prefs then
        deps.prefs
            :addContent(1000, ui.style ([[
                .sendIFTTTTestNotification {
                    clear: both;
                    float:left;
                    margin-top: 5px;
                    margin-bottom: 10px;
                }
                .iftttButtons {
                    float:left;
                    margin-left: -15px;
                    margin-top: 5px;
                    margin-bottom: 10px;
                }
                ]]) ..
                html.br() ..
                html.br() ..
                html.hr()
            )
            :addHeading(1001, i18n("iftttNotifications"))
            :addCheckbox(1002,
                {
                    label = i18n("iftttEnableNotifications"),
                    onchange = function(_, params)
                        mod.enabled(params.checked)
                    end,
                    checked = mod.enabled,
                    id = "iftttEnable",
                }
            )
            :addButton(1003,
                {
                    width = 200,
                    label = i18n("sendTestNotification"),
                    onclick = function()
                            local success, errorMessage = mod.sendNotification(i18n("thisIsATest"), i18n("testTitle"))
                            errorMessage = errorMessage or "  - Unknown Error"
                            if not success then
                                dialog.webviewAlert(deps.prefsManager.getWebview(), function() end, i18n("notificationTestFailed"), i18n("notificationTestFailedMessage") .. "\n\n" .. errorMessage, i18n("ok"))
                            end
                    end,
                    class = "sendIFTTTTestNotification",
                }
            )
            :addButton(1004,
                {
                    width = 200,
                    label = i18n("iftttSignup"),
                    onclick = function()
                        os.execute('open "https://ifttt.com/login"')
                    end,
                    class = "iftttButtons",
                }
            )
            :addButton(1005,
                {
                    width = 200,
                    label = i18n("iftttGetAPIKey"),
                    onclick = function()
                        os.execute('open "https://ifttt.com/maker_webhooks/settings"')
                    end,
                    class = "iftttButtons",
                }
            )
            :addTextbox(1006,
                {
                    label = i18n("iftttEventName") .. ":",
                    value = function() return mod.userAPIKey() end,
                    class = "api",
                    id = "iftttUserAPIKey",
                    onchange = function(_, params)
                        mod.userAPIKey(params.value)
                    end,
                }
            )
            :addTextbox(1007,
                {
                    label = i18n("iftttAPIKey") .. ":",
                    value = function() return mod.appAPIKey() end,
                    class = "api",
                    id = "iftttAppAPIKey",
                    onchange = function(_, params)
                        local key = params.value
                        --------------------------------------------------------------------------------
                        -- Extract API key if user inputs the url:
                        --------------------------------------------------------------------------------
                        if string.match(params.value, "https://maker.ifttt.com/use/") then
                          key = string.gsub(params.value, "https://maker.ifttt.com/use/", "")
                        end
                        mod.appAPIKey(key)
                    end,
                }
            )
    end

    return mod
end

return plugin
