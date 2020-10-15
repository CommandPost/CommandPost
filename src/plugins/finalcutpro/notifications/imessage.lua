--- === plugins.finalcutpro.notifications.imessage ===
---
--- iMessage Notifications Plugin.

local require       = require

local messages      = require "hs.messages"
local dialog        = require "hs.dialog"

local config        = require "cp.config"
local fcp           = require "cp.apple.finalcutpro"
local html          = require "cp.web.html"
local i18n          = require "cp.i18n"
local ui            = require "cp.web.ui"

local mod = {}

--- plugins.finalcutpro.notifications.imessage.update() -> none
--- Function
--- Enables or disables iMessage Notifications depending on the user's preferences.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.update()
    if mod.enabled() then
        if mod.target() ~= nil and mod.watchId == nil then
            mod.watchId = mod.notifications.watch({
                success = mod.sendNotification,
                failure = mod.sendNotification,
            })
        end
    else
        if mod.watchId ~= nil then
            mod.notifications.unwatch(mod.watchId)
            mod.watchId = nil
        end
    end
end

--- plugins.finalcutpro.notifications.imessage.enabled <cp.prop: boolean>
--- Field
--- Whether or not the plugin has been enabled.
mod.enabled = config.prop("iMessageNotificationsEnabled", false):watch(function() mod.update() end)

--- plugins.finalcutpro.notifications.imessage.target <cp.prop: string>
--- Field
--- A string containing a mobile number or Apple ID
mod.target = config.prop("iMessageTarget")

--- plugins.finalcutpro.notifications.imessage.sendNotification(message) -> none
--- Function
--- Sends a notification.
---
--- Parameters:
---  * message - The message you want to send as a string.
---
--- Returns:
---  * None
function mod.sendNotification(message)
    local iMessageTarget = mod.target()
    if iMessageTarget then
        messages.iMessage(iMessageTarget, message)
    end
end

--- plugins.finalcutpro.notifications.imessage.init() -> none
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

local plugin = {
    id = "finalcutpro.notifications.imessage",
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
            :addContent(301, ui.style ([[
                .iMessageEnable {
                    margin-bottom: 10px !important;
                }
                .testiMessage {
                    float:left;
                    margin-top: 5px;
                    margin-bottom: 10px;
                    clear: both;
                }
                .openMessages {
                    float:left;
                    margin-top: 5px;
                    margin-bottom: 10px;
                    margin-left:-15px;
                }
                ]]) ..
                html.br() ..
                html.br() ..
                html.hr())
            :addHeading(302, i18n("iMessageNotifications"))
            :addCheckbox(303,
                {
                    label = i18n("enableiMessageNotifications"),
                    onchange = function(_, params)
                        if mod.target() and mod.target() ~= "" then
                            mod.enabled(params.checked)
                        else
                            dialog.webviewAlert(deps.prefsManager.getWebview(), function()
                                deps.prefsManager.injectScript([[
                                    document.getElementById("iMessageEnable").checked = false;
                                ]])
                            end, i18n("iMessageMissingDestination"), i18n("iMessageMissingMessage"), i18n("ok"))
                        end
                    end,
                    checked = mod.enabled,
                    id = "iMessageEnable",
                    class = "iMessageEnable",
                }
            )
            :addTextbox(304,
                {
                    label = i18n("iMessageDestination") .. ":",
                    value = function() return mod.target() end,
                    class = "api",
                    onchange = function(_, params)
                        mod.target(params.value)
                    end,
                }
            )
            :addButton(305,
                {
                    width = 200,
                    label = i18n("sendTestNotification"),
                    onclick = function()
                        mod.sendNotification(i18n("thisIsATest"))
                    end,
                    class = "testiMessage",
                }
            )
            :addButton(306,
                {
                    width = 200,
                    label = i18n("openMessages"),
                    onclick = function()
                        os.execute("open /Applications/Messages.app")
                    end,
                    class = "openMessages",
                }
            )
            :addButton(307,
                {
                    width = 200,
                    label = i18n("openContacts"),
                    onclick = function()
                        os.execute("open /Applications/Contacts.app")
                    end,
                    class = "openMessages",
                }
            )
    end
    return mod
end

return plugin
