--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                 i M E S S A G E     N O T I F I C A T I O N S              --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.notifications.imessage ===
---
--- iMessage Notifications Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("iMessage")

local messages									= require("hs.messages")
local dialog									= require("hs.dialog")

local config									= require("cp.config")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY = 300

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
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
				success	= mod.sendNotification,
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

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.notifications.imessage",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.notifications.manager"]			= "manager",
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
				</style>	
				<br />
				<br />
				<hr />		
			]], true)
			:addHeading(PRIORITY+2, i18n("iMessageNotifications"))
			:addCheckbox(PRIORITY+3,
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
			:addTextbox(PRIORITY+4,
				{
					label = i18n("iMessageDestination") .. ":",
					value = mod.target(),
					class = "api",
					onchange = function(_, params)
						mod.target(params.value)
					end,
				}
			)
			:addButton(PRIORITY+5,
				{
					label = i18n("sendTestNotification"),
					onclick = function(_, params)
						mod.sendNotification(i18n("thisIsATest"))
					end,
					class = "testiMessage",
				}
			)			
			:addButton(PRIORITY+6,
				{
					label = i18n("openMessages"),
					onclick = function(_, params)
						os.execute("open /Applications/Messages.app")
					end,
					class = "openMessages",
				}
			)			
			:addButton(PRIORITY+7,
				{
					label = i18n("openContacts"),
					onclick = function(_, params)
						os.execute("open /Applications/Contacts.app")
					end,
					class = "openMessages",
				}
			)			
	end
	return mod
end

return plugin