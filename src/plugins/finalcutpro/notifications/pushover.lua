--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                 P U S H O V E R     N O T I F I C A T I O N S              --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.notifications.pushover ===
---
--- Pushover Notifications Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("pushover")

local http										= require("hs.http")
local json										= require("hs.json")
local dialog									= require("hs.dialog")

local config									= require("cp.config")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY = 10

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.notifications.pushover.userAPIKey <cp.prop: string>
--- Field
--- User API Key
mod.userAPIKey = config.prop("pushoverUserAPIKey", nil)

--- plugins.finalcutpro.notifications.pushover.appAPIKey <cp.prop: string>
--- Field
--- Application API Key
mod.appAPIKey = config.prop("pushoverAppAPIKey", nil)

--- plugins.finalcutpro.notifications.pushover.apiValidated <cp.prop: boolean>
--- Field
--- Whether or not the API keys have been validated.
mod.apiValidated = config.prop("pushoverAPIValidated", false)

--- plugins.finalcutpro.notifications.pushover.enabled <cp.prop: boolean>
--- Field
--- Whether or not the plugin has been enabled.
mod.enabled = config.prop("pushoverNotificationsEnabled", false):watch(function() mod.update() end)

--- plugins.finalcutpro.notifications.pushover.validateAPIKeys(userKey, appKey) -> success, errorMessage
--- Function
--- Validates a Pushover User & Application API Key
---
--- Parameters:
---  * userKey - The User API Key as a string
---  * appKey - The Application API Key as a string
---
--- Returns:
---  * success - `true` if successful otherwise `false`
---  * errorMessage - a string containing any error messages
function mod.validateAPIKeys(userKey, appKey)
	if not userKey or not appKey then
		log.ef("Invalid User and/or Application API Key. This shouldn't happen.")
		return false
	end	
	local url = "https://api.pushover.net/1/users/validate.json"
	local request = "token=" .. http.encodeForQuery(appKey) .. "&user=" .. http.encodeForQuery(userKey)
	local status, body, header = http.doRequest(url, "post", request)
	if status == 200 and string.match(body, [["status":1]]) then
		return true
	else
		if pcall(function() json.decode(body) end) and json.decode(body)["errors"] then
			local errors = json.decode(body)["errors"]
			local errorMessage = ""
			for i, v in ipairs(errors) do
				errorMessage = "  - " .. errorMessage .. v
				if i ~= #errors then
					errorMessage = errorMessage .. "\n"
				end
			end
			return false, errorMessage
		else	
			if status == 0 then
				return false, "  - " .. i18n("pushoverServerFailed") .. "\n  - " .. i18n("areYouConnectedToTheInternet")
			else
				return false, "  - " .. i18n("unknownError") .. " (" .. tostring(status) .. ")"
			end
		end
	end
end

--- plugins.finalcutpro.notifications.pushover.update() -> none
--- Function
--- Enables or disables Pushover Notifications depending on the user's preferences.
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
				success	= mod.sendNotification,
				failure	= mod.sendNotification,
			})
		end
	else
		if mod.watcherId ~= nil then
			mod.notifications.unwatch(mod.watcherId)
			mod.watcherId = nil
		end
	end
end

--- plugins.finalcutpro.notifications.pushover.init() -> none
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

--- plugins.finalcutpro.notifications.pushover.sendNotification(message, [title]) -> none
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
	if not mod.apiValidated() or not mod.userAPIKey() or not mod.appAPIKey then
		return false
	end	
	local url = "https://api.pushover.net/1/messages.json"
	local title = optionalTitle or http.encodeForQuery(string.upper(i18n("finalCutPro")))
	message = http.encodeForQuery(message)
	local request = "token=" .. mod.appAPIKey() .. "&user=" .. mod.userAPIKey() .. "&title=" .. title .. "&message=" .. message 
	
	local status, body, header = http.doRequest(url, "post", request)
	if status == 200 and string.match(body, [["status":1]]) then
		return true
	else
		if pcall(function() json.decode(body) end) and json.decode(body)["errors"] then
			local errors = json.decode(body)["errors"]
			local errorMessage = ""
			for i, v in ipairs(errors) do
				errorMessage = "  - " .. errorMessage .. v
				if i ~= #errors then
					errorMessage = errorMessage .. "\n"
				end
			end
			return false, errorMessage
		else
			if status == 0 then
				return false, "  - " .. i18n("pushoverServerFailed") .. "\n  - " .. i18n("areYouConnectedToTheInternet")
			else
				return false, "  - " .. i18n("unknownError") .. " (" .. tostring(status) .. ")"
			end
		end
	end

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.notifications.pushover",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.notifications.manager"] 			= "manager",
		["core.preferences.panels.notifications"]		= "prefs",
		["core.preferences.manager"]					= "prefsManager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	mod.init(deps.manager)

	--------------------------------------------------------------------------------
	-- Setup Preferences Panel:
	--------------------------------------------------------------------------------
	if deps.prefs then
		deps.prefs
			:addContent(PRIORITY+2, [[			
				<style>
					.api label {
						width:140px;
						clear:left;
						text-align:left;
						padding-right:10px;
						padding-bottom:20px;
						float: left;
					}

					.api input[type=text] {
						float: left;
						-webkit-appearance: none;
						-webkit-box-shadow: none;
						-webkit-rtl-ordering: logical;
						-webkit-user-select: text;
						color: #959595;
						background-color:#161616;
						border-style: solid;
						border-color: #0a0a0a;
						border-width: 2px;
						border-radius: 6px;
						width: 300px;
						text-align: center;
						font-size: 13px;
						height: 20px;
					}

					.api input[type=text]:focus {
						float: left;
						-webkit-appearance: none;
						-webkit-box-shadow: none;
						-webkit-rtl-ordering: logical;
						-webkit-user-select: text;
						color: #959595;
						border-style: solid;
						border-color: #1a3868;
						border-width: 2px;
						border-radius: 6px;
						width: 300px;
						text-align: center;
						font-size: 13px;
						height: 20px;
					}
					.validatePushover {
						float:left;
					}
					.getPushover {		
						float:left;										
						margin-top: 5px;
						margin-bottom: 10px;						
					}
					.createPushover {
						float:left;
						margin-left: -15px;
						margin-top: 5px;
						margin-bottom: 10px;
					}
				</style>			
			]], true)
			:addHeading(PRIORITY, i18n("pushoverNotifications"))
			:addCheckbox(PRIORITY+1,
				{
					label = i18n("enablePushoverNotifications"),
					onchange = function(_, params) 
						if mod.apiValidated() then 
							mod.enabled(params.checked) 
						else
							dialog.webviewAlert(deps.prefsManager.getWebview(), function() 
								deps.prefsManager.injectScript([[
									document.getElementById("pushoverEnable").checked = false;
								]])
							end, i18n("invalidAPIKeysSupplied"), i18n("pushoverValidateFailed"), i18n("ok"))
						end
					end,
					checked = mod.enabled,
					id = "pushoverEnable",
				}
			)
			:addButton(PRIORITY+7,
				{
					label = i18n("pushoverSignup"),
					onclick = function(_, params)		
						os.execute('open "https://pushover.net/login"')
					end,
					class = "getPushover",
				}
			)			
			:addButton(PRIORITY+8,
				{
					label = i18n("getCommandPostPushoverAPIKey"),
					onclick = function(_, params)		
						os.execute('open "https://pushover.net/apps/clone/commandpost"')
					end,
					class = "createPushover",
				}
			)			
			:addButton(PRIORITY+9,
				{
					label = i18n("sendTestNotification"),
					onclick = function(_, params)
						if mod.apiValidated() then 
							local success, errorMessage = mod.sendNotification(i18n("thisIsATest"), i18n("testTitle"))
							errorMessage = errorMessage or "  - Unknown Error"
							if not success then
								dialog.webviewAlert(deps.prefsManager.getWebview(), function() end, i18n("notificationTestFailed"), i18n("notificationTestFailedMessage") .. "\n\n" .. errorMessage, i18n("ok"))
							end
						else
							dialog.webviewAlert(deps.prefsManager.getWebview(), function() end, i18n("invalidAPIKeysSupplied"), i18n("pushoverTestFailed"), i18n("ok"))
						end						
					end,
					class = "createPushover",
				}
			)			
			:addTextbox(PRIORITY+10,
				{
					label = i18n("userAPIKey") .. ":",
					value = mod.userAPIKey(),
					class = "api",
					id = "pushoverUserAPIKey",
					onchange = function(_, params) 
						mod.apiValidated(false)
						mod.userAPIKey(params.value)
					end,
				}
			)
			:addTextbox(PRIORITY+11,
				{
					label = i18n("applicationAPIKey") .. ":",					
					value = mod.appAPIKey(),
					class = "api",
					id = "pushoverAppAPIKey",
					onchange = function(_, params) 
						mod.apiValidated(false)
						mod.appAPIKey(params.value)
					end,
				}
			)
			:addButton(PRIORITY+12,
				{
					label = i18n("validate"),
					onclick = function(_, params)		
						if not mod.userAPIKey() or not mod.appAPIKey() then							
							dialog.webviewAlert(deps.prefsManager.getWebview(), function() end, i18n("needUserAndAppAPIKey"), i18n("pleaseTryAgain"), i18n("ok"))
						else
							local success, errorMessage = mod.validateAPIKeys(mod.userAPIKey(), mod.appAPIKey())
							if success then
							 	dialog.webviewAlert(deps.prefsManager.getWebview(), function() end, i18n("success") .. "!", i18n("apiKeysValidated"), i18n("ok"))
								mod.apiValidated(true)
							else
								mod.enabled(false)
								mod.apiValidated(false)
								dialog.webviewAlert(deps.prefsManager.getWebview(), function() end, i18n("invalidAPIKeysSupplied"), i18n("notValidKeysAndError") .. errorMessage, i18n("ok"))
								deps.prefsManager.injectScript([[
									document.getElementById("pushoverEnable").checked = false;
								]])
							end							
						end		
					end,
					class = "validatePushover"
				}
			)
	end

	return mod
end

return plugin