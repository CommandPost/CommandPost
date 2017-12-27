--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                  P R O W L     N O T I F I C A T I O N S                   --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.notifications.prowl ===
---
--- Prowl Notifications Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prowl")

local dialog									= require("hs.dialog")
local http										= require("hs.http")

local slaxdom 									= require("slaxml.slaxdom")

local fcp										= require("cp.apple.finalcutpro")
local config									= require("cp.config")
local tools										= require("cp.tools")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY = 200

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.notifications.prowl.apiValidated <cp.prop: boolean>
--- Field
--- Whether or not the API key has been validated.
mod.apiValidated = config.prop("prowlAPIValidated", false)

--- plugins.finalcutpro.notifications.prowl.validateAPIKey(key) -> success, errorMessage
--- Function
--- Validates a Growl API Key
---
--- Parameters:
---  * key - The API key as string
---
--- Returns:
---  * success - `true` if successful otherwise `false`
---  * errorMessage - a string containing any error messages
function mod.validateAPIKey(input)
	local result = false
	local errorMessage = "  - " .. i18n("unknownError")

	local prowlAction = "https://api.prowlapp.com/publicapi/verify?apikey=" .. http.encodeForQuery(input)
	local httpResponse, httpBody, httpHeader = http.get(prowlAction, nil)

	if httpBody and string.match(httpBody, "success") then
		result = true
	else
		local xml = slaxdom:dom(tostring(httpBody))
		if xml and xml['root'] and xml['root']['el'] and xml['root']['el'][1] and xml['root']['el'][1]['kids'] and xml['root']['el'][1]['kids'][1] and xml['root']['el'][1]['kids'][1]['value'] then 
			errorMessage = "  - " .. xml['root']['el'][1]['kids'][1]['value']
		end
	end

	return result, errorMessage
end

--- plugins.finalcutpro.notifications.prowl.enabled <cp.prop: boolean>
--- Field
--- Whether or not the plugin has been enabled.
mod.enabled = config.prop("prowlNotificationsEnabled", false):watch(function() mod.update() end)

--- plugins.finalcutpro.notifications.prowl.apiKey <cp.prop: string>
--- Field
--- Prowl API Key
mod.apiKey = config.prop("prowlAPIKey", nil)

--- plugins.finalcutpro.notifications.prowl.update() -> none
--- Function
--- Enables or disables Prowl Notifications depending on the user's preferences.
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

--- plugins.finalcutpro.notifications.prowl.init() -> none
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

--- plugins.finalcutpro.notifications.prowl.sendNotification(message, [title]) -> none
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
	local prowlAPIKey = mod.apiKey()
	if prowlAPIKey ~= nil then
		local prowlApplication = optionalTitle or string.upper(i18n("finalCutPro"))
		local prowlEvent = ""
		local prowlDescription = message

		local prowlAction = "https://api.prowlapp.com/publicapi/add?apikey=" .. http.encodeForQuery(prowlAPIKey) .. "&application=" .. http.encodeForQuery(prowlApplication) .. "&event=" .. http.encodeForQuery(prowlEvent) .. "&description=" .. http.encodeForQuery(prowlDescription)
		httpResponse, httpBody, httpHeader = http.get(prowlAction, nil)

		if string.match(httpBody, "success") then
			return true
		else
			local xml = slaxdom:dom(tostring(httpBody))
			local errorMessage = xml['root']['el'][1]['kids'][1]['value'] or "  - " .. i18n("unknownError")
			return false, errorMessage
		end
	end
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.notifications.prowl",
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
			:addContent(PRIORITY+1, [[				
				<style>
					.prowlEnable {
						margin-bottom: 10px !important;
					}
					.testProwl {		
						float:left;										
						margin-top: 5px;
						margin-bottom: 10px;	
						clear: both;					
					}
					.getProwlAccount {		
						float:left;										
						margin-top: 5px;
						margin-bottom: 10px;
						margin-left:-15px;	
					}
				</style>	
				<br />
				<br />
				<hr />		
			]], true)
			:addHeading(PRIORITY+2, i18n("prowlNotifications"))
			:addCheckbox(PRIORITY+3,
				{
					label = i18n("enableProwlNotifications"),
					onchange = function(_, params) 
						if mod.apiValidated() then 
							mod.enabled(params.checked)
						else
							dialog.webviewAlert(deps.prefsManager.getWebview(), function() 
								deps.prefsManager.injectScript([[
									document.getElementById("prowlEnable").checked = false;
								]])
							end, i18n("prowlMissingAPIKey"), i18n("prowlMissingAPIKeyMessage"), i18n("ok"))
						end
					end,
					checked = mod.enabled,
					id = "prowlEnable",
					class = "prowlEnable",
				}
			)
			:addTextbox(PRIORITY+4,
				{
					label = i18n("prowlAPIKey") .. ":",
					value = mod.apiKey(),
					class = "api",
					onchange = function(_, params)
						mod.apiKey(params.value)
						local result, errorMessage = mod.validateAPIKey(params.value)						
						if result then
							mod.apiValidated(true)														
						else
							deps.prefsManager.injectScript([[
									document.getElementById("prowlEnable").checked = false;
								]])
							mod.apiValidated(false)
							mod.enabled(false)
							dialog.webviewAlert(deps.prefsManager.getWebview(), function() end, i18n("invalidProwlAPIKey"), i18n("notValidProwlAPIKeyError") .. "\n\n" .. errorMessage, i18n("ok"))
						end
					end,
				}
			)
			:addButton(PRIORITY+5,
				{
					label = i18n("sendTestNotification"),
					onclick = function(_, params)
						local success, errorMessage = mod.sendNotification(i18n("thisIsATest"), i18n("testTitle"))
						if not success then
							dialog.webviewAlert(deps.prefsManager.getWebview(), function() end, i18n("notificationTestFailed"), i18n("notificationTestFailedMessage") .. "\n\n" .. errorMessage, i18n("ok"))
						end
					end,
					class = "testProwl",
				}
			)			
			:addButton(PRIORITY+6,
				{
					label = i18n("getProwlAccount"),
					onclick = function(_, params)
						os.execute("open https://www.prowlapp.com/register.php")
					end,
					class = "getProwlAccount",
				}
			)						

	end	

	return mod
end

return plugin