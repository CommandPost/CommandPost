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
local http										= require("hs.http")

local slaxdom 									= require("slaxml.slaxdom")

local dialog									= require("cp.dialog")
local fcp										= require("cp.apple.finalcutpro")
local config									= require("cp.config")
local tools										= require("cp.tools")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY = 1000

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--------------------------------------------------------------------------------
-- PROWL API KEY VALID:
--------------------------------------------------------------------------------
function prowlAPIKeyValid(input)

	local result = false
	local errorMessage = nil

	local prowlAction = "https://api.prowlapp.com/publicapi/verify?apikey=" .. input
	local httpResponse, httpBody, httpHeader = http.get(prowlAction, nil)

	if string.match(httpBody, "success") then
		result = true
	else
		local xml = slaxdom:dom(tostring(httpBody))
		errorMessage = xml['root']['el'][1]['kids'][1]['value']
	end

	return result, errorMessage
end

mod.enabled = config.prop("prowlNotificationsEnabled", false):watch(function() mod.update(true) end)

mod.apiKey = config.prop("prowlAPIKey", nil)

local function requestProwlAPIKey()
	local returnToFinalCutPro = fcp:isFrontmost()

	-- Request the API Key from the user
	local result = dialog.displayTextBoxMessage(i18n("prowlTextbox"), i18n("prowlTextboxError") .. "\n\n" .. i18n("pleaseTryAgain"), mod.apiKey())
	if result == false then
		mod.enabled(false)
		return
	end

	-- Check the key is valid
	local valid, err = prowlAPIKeyValid(result)
	if valid then
		mod.apiKey(result)
		if returnToFinalCutPro then fcp:launch() end
	else
		-- Try again
		dialog.displayMessage(i18n("prowlError") .. " " .. err .. ".\n\n" .. i18n("pleaseTryAgain"))
		requestProwlAPIKey()
	end
end

function mod.update(changed)
	if mod.enabled() then
		if changed or mod.apiKey() == nil then
			requestProwlAPIKey()
		end

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

function mod.init(notifications)
	mod.notifications = notifications
	mod.update()
end

function mod.sendNotification(message)
	local prowlAPIKey = mod.apiKey()
	if prowlAPIKey ~= nil then
		local prowlApplication = http.encodeForQuery("FINAL CUT PRO")
		local prowlEvent = http.encodeForQuery("")
		local prowlDescription = http.encodeForQuery(message)

		local prowlAction = "https://api.prowlapp.com/publicapi/add?apikey=" .. prowlAPIKey .. "&application=" .. prowlApplication .. "&event=" .. prowlEvent .. "&description=" .. prowlDescription
		httpResponse, httpBody, httpHeader = http.get(prowlAction, nil)

		if not string.match(httpBody, "success") then
			local xml = slaxdom:dom(tostring(httpBody))
			local errorMessage = xml['root']['el'][1]['kids'][1]['value'] or nil
			if errorMessage ~= nil then log.e("PROWL ERROR: " .. tools.trim(tostring(errorMessage))) end
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
		["finalcutpro.menu.tools.notifications"]		= "menu",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	mod.init(deps.manager)

	--------------------------------------------------------------------------------
	-- Menu Item:
	--------------------------------------------------------------------------------
	deps.menu:addItem(PRIORITY, function()
		return { title = i18n("prowl"),	fn = function() mod.enabled:toggle() end,	checked = mod.enabled() }
	end)

	return mod
end

return plugin