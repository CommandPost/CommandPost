-- Imports
local settings									= require("hs.settings")
local http										= require("hs.http")

local slaxdom 									= require("slaxml.slaxdom")

local tools										= require("cp.tools")
local fcp										= require("cp.finalcutpro")
local dialog									= require("cp.dialog")
local metadata									= require("cp.metadata")

-- Constants
local PRIORITY = 1000

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
	return settings.get(metadata.settingsPrefix .. ".prowlNotificationsEnabled") or false
end

function mod.setEnabled(value)
	settings.set(metadata.settingsPrefix .. ".prowlNotificationsEnabled", value)
	mod.update(true)
end

function mod.toggleEnabled()
	mod.setEnabled(not mod.isEnabled())
end

function mod.getAPIKey()
	return settings.get(metadata.settingsPrefix .. ".prowlAPIKey") or nil
end

function mod.setAPIKey(value)
	settings.set(metadata.settingsPrefix .. ".prowlAPIKey", value)
end

local function requestProwlAPIKey()
	local returnToFinalCutPro = fcp:isFrontmost()

	-- Request the API Key from the user
	local result = dialog.displayTextBoxMessage(i18n("prowlTextbox"), i18n("prowlTextboxError") .. "\n\n" .. i18n("pleaseTryAgain"), mod.getAPIKey())
	if result == false then
		mod.setEnabled(false)
		return
	end

	-- Check the key is valid
	local valid, err = prowlAPIKeyValid(result)
	if valid then
		mod.setAPIKey(result)
		if returnToFinalCutPro then fcp:launch() end
	else
		-- Try again
		dialog.displayMessage(i18n("prowlError") .. " " .. err .. ".\n\n" .. i18n("pleaseTryAgain"))
		requestProwlAPIKey()
	end
end

function mod.update(changed)
	if mod.isEnabled() then
		if changed or mod.getAPIKey() == nil then
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
	local prowlAPIKey = settings.get(metadata.settingsPrefix .. ".prowlAPIKey") or nil
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
	["cp.plugins.notifications.manager"] 				= "manager",
	["cp.plugins.menu.tools.options.notifications"]	= "menu",
}

function plugin.init(deps)
	mod.init(deps.manager)

	-- Menu Item
	deps.menu:addItem(PRIORITY, function()
		return { title = i18n("prowl"),	fn = mod.toggleEnabled,	checked = mod.isEnabled() }
	end)

	return mod
end

return plugin