-- Imports
local settings									= require("hs.settings")
local http										= require("hs.http")
local distributednotifications					= require("hs.distributednotifications")
local slaxdom 									= require("hs.fcpxhacks.modules.slaxml.slaxdom")
local messages									= require("hs.messages")
local fs										= require("hs.fs")
local plist										= require("hs.plist")
local tools										= require("hs.fcpxhacks.modules.tools")
local dialog									= require("hs.fcpxhacks.modules.dialog")

local log										= require("hs.logger").new("notifications")

-- The Module
local mod = {}

--------------------------------------------------------------------------------
-- NOTIFICATION WATCHER ACTION:
--------------------------------------------------------------------------------
function notificationWatcherAction(name, object, userInfo)
	-- FOR DEBUGGING/DEVELOPMENT
	-- debugMessage(string.format("name: %s\nobject: %s\nuserInfo: %s\n", name, object, hs.inspect(userInfo)))

	local message = nil
	if name == "uploadSuccess" then
		local info = findNotificationInfo(object)
		message = i18n("shareSuccessful", {info = info})
	elseif name == "ProTranscoderDidFailNotification" then
		message = i18n("shareFailed")
	else -- unexpected result
		return
	end

	local notificationPlatform = settings.get("fcpxHacks.notificationPlatform")

	if notificationPlatform["Prowl"] then
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

	if notificationPlatform["iMessage"] then
		local iMessageTarget = settings.get("fcpxHacks.iMessageTarget") or ""
		if iMessageTarget ~= "" then
			messages.iMessage(iMessageTarget, message)
		end
	end
end


--------------------------------------------------------------------------------
-- FIND NOTIFICATION INFO:
--------------------------------------------------------------------------------
function findNotificationInfo(path)
	local plistPath = path .. "/ShareStatus.plist"
	if fs.attributes(plistPath) then
		local shareStatus = plist.fileToTable(plistPath)
		if shareStatus then
			local latestType = nil
			local latestInfo = nil

			for type,results in pairs(shareStatus) do
				local info = results[#results]
				if latestInfo == nil or latestInfo.fullDate < info.fullDate then
					latestInfo = info
					latestType = type
				end
			end

			if latestInfo then
				-- put the first resultStr into a top-level value to make it easier for i18n
				if latestInfo.resultStr then
					latestInfo.result = latestInfo.resultStr[1]
				end
				local message = i18n("shareDetails_"..latestType, latestInfo)
				if not message then
					message = i18n("shareUnknown", {type = latestType})
				end
				return message
			end
		end
	end
	return i18n("shareUnknown", {type = "unknown"})
end


--------------------------------------------------------------------------------
-- TOGGLE NOTIFICATION PLATFORM:
--------------------------------------------------------------------------------
function toggleNotificationPlatform(value)

	local notificationPlatform 		= settings.get("fcpxHacks.notificationPlatform")
	local prowlAPIKey 				= settings.get("fcpxHacks.prowlAPIKey") or ""
	local iMessageTarget			= settings.get("fcpxHacks.iMessageTarget") or ""

	local returnToFinalCutPro 		= fcp:isFrontmost()

	if value == "Prowl" then
		if not notificationPlatform["Prowl"] then
			::retryProwlAPIKeyEntry::
			local result = dialog.displayTextBoxMessage(i18n("prowlTextbox"), i18n("prowlTextboxError") .. "\n\n" .. i18n("pleaseTryAgain"), prowlAPIKey)
			if result == false then return end
			local prowlAPIKeyValidResult, prowlAPIKeyValidError = prowlAPIKeyValid(result)
			if prowlAPIKeyValidResult then
				if returnToFinalCutPro then fcp:launch() end
				settings.set("fcpxHacks.prowlAPIKey", result)
			else
				dialog.displayMessage(i18n("prowlError") .. " " .. prowlAPIKeyValidError .. ".\n\n" .. i18n("pleaseTryAgain"))
				goto retryProwlAPIKeyEntry
			end
		end
	end

	if value == "iMessage" then
		if not notificationPlatform["iMessage"] then
			local result = dialog.displayTextBoxMessage(i18n("iMessageTextBox"), i18n("pleaseTryAgain"), iMessageTarget)
			if result == false then return end
			settings.set("fcpxHacks.iMessageTarget", result)
		end
	end

	notificationPlatform[value] = not notificationPlatform[value]
	settings.set("fcpxHacks.notificationPlatform", notificationPlatform)

	if next(notificationPlatform) == nil then
		if mod.shareSuccessNotificationWatcher then mod.shareSuccessNotificationWatcher:stop() end
		if mod.shareFailedNotificationWatcher then mod.shareFailedNotificationWatcher:stop() end
	else
		notificationWatcher()
	end

end

--------------------------------------------------------------------------------
-- NOTIFICATION WATCHER:
--------------------------------------------------------------------------------
function notificationWatcher()

	--------------------------------------------------------------------------------
	-- USED FOR DEVELOPMENT:
	--------------------------------------------------------------------------------
	--foo = distributednotifications.new(function(name, object, userInfo) print(string.format("name: %s\nobject: %s\nuserInfo: %s\n", name, object, inspect(userInfo))) end)
	--foo:start()

	--------------------------------------------------------------------------------
	-- SHARE SUCCESSFUL NOTIFICATION WATCHER:
	--------------------------------------------------------------------------------
	-- NOTE: ProTranscoderDidCompleteNotification doesn't seem to trigger when exporting small clips.
	mod.shareSuccessNotificationWatcher = distributednotifications.new(notificationWatcherAction, "uploadSuccess")
	mod.shareSuccessNotificationWatcher:start()

	--------------------------------------------------------------------------------
	-- SHARE UNSUCCESSFUL NOTIFICATION WATCHER:
	--------------------------------------------------------------------------------
	mod.shareFailedNotificationWatcher = distributednotifications.new(notificationWatcherAction, "ProTranscoderDidFailNotification")
	mod.shareFailedNotificationWatcher:start()

end

function mod.update()
end

-- The Plugin
local plugin = {}

function plugin.init(deps)
	return mod
end

return plugin