-- Imports
local settings									= require("hs.settings")
local slaxdom 									= require("hs.fcpxhacks.modules.slaxml.slaxdom")
local http										= require("hs.http")
local tools										= require("hs.fcpxhacks.modules.tools")
local fcp										= require("hs.finalcutpro")

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

-- The Module
local mod = {}

function mod.isEnabled()
	return settings.get("fcpxHacks.prowlNotificationsEnabled") or false
end

function mod.setEnabled(value)
	settings.set("fcpxHacks.prowlNotificationsEnabled", value)
	mod.update()
end

function mod.toggleEnabled()
	mod.setEnabled(not mod.isEnabled())
end

function mod.getAPIKey()
	return settings.get("fcpxHacks.prowlAPIKey") or nil
end

function mod.setAPIKey(value)
	settings.set("fcpxHacks.prowlAPIKey", value)
end

local function requestProwlAPIKey()
	local returnToFinalCutPro = fcp:isFrontmost()
	
	-- Request the API Key from the user
	local result = dialog.displayTextBoxMessage(i18n("prowlTextbox"), i18n("prowlTextboxError") .. "\n\n" .. i18n("pleaseTryAgain"), prowlAPIKey)
	if result == false then
		mod.setEnabled(false)
		return
	end
	
	-- Check the key is valid
	local result, err = prowlAPIKeyValid(result)
	if result then
		mod.setAPIKey(result)
		if returnToFinalCutPro then fcp:launch() end
	else
		-- Try again
		dialog.displayMessage(i18n("prowlError") .. " " .. err .. ".\n\n" .. i18n("pleaseTryAgain"))
		requestProwlAPIKey()
	end
end

function mod.update()
	if mod.isEnabled() then
		if mod.getAPIKey() == nil then
			requestProwlAPIKey()
		end
	else
		-- clear the API Key.
		mod.setAPIKey(nil)
	end	
end

function mod.sendNotification(message)
	local prowlAPIKey = settings.get("fcpxHacks.prowlAPIKey") or nil
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

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["hs.fcpxhacks.plugins.os.notifications"] = "notifications",
}

function plugin.init(deps)
	return mod
end

return plugin