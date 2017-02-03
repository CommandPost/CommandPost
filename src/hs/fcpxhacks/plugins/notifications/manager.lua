-- Imports
local settings									= require("hs.settings")
local http										= require("hs.http")
local distributednotifications					= require("hs.distributednotifications")
local slaxdom 									= require("slaxml.slaxdom")
local messages									= require("hs.messages")
local fs										= require("hs.fs")
local plist										= require("hs.plist")
local tools										= require("hs.fcpxhacks.modules.tools")
local dialog									= require("hs.fcpxhacks.modules.dialog")
local watcher									= require("hs.watcher")

local log										= require("hs.logger").new("notifications")

-- The Module
local mod = {}

mod.eventTypes = {"success", "failure"}

--------------------------------------------------------------------------------
-- FIND NOTIFICATION INFO:
--------------------------------------------------------------------------------
local function findNotificationInfo(path)
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
-- NOTIFICATION WATCHER ACTION:
--------------------------------------------------------------------------------
local function notificationWatcherAction(name, object, userInfo)
	-- FOR DEBUGGING/DEVELOPMENT
	-- debugMessage(string.format("name: %s\nobject: %s\nuserInfo: %s\n", name, object, hs.inspect(userInfo)))

	local message = nil
	if name == "uploadSuccess" then
		local info = findNotificationInfo(object)
		message = i18n("shareSuccessful", {info = info})
		mod.watchers:notify("success", message)
	elseif name == "ProTranscoderDidFailNotification" then
		message = i18n("shareFailed")
		mod.watchers:notify("failure", message)
	else -- unexpected result
		return
	end
end

--------------------------------------------------------------------------------
-- NOTIFICATION WATCHER:
--------------------------------------------------------------------------------
local function ensureWatching()
	if mod.successWatcher == nil then
		--------------------------------------------------------------------------------
		-- SHARE SUCCESSFUL NOTIFICATION WATCHER:
		--------------------------------------------------------------------------------
		-- NOTE: ProTranscoderDidCompleteNotification doesn't seem to trigger when exporting small clips.
		mod.successWatcher = distributednotifications.new(notificationWatcherAction, "uploadSuccess")
		mod.successWatcher:start()

		--------------------------------------------------------------------------------
		-- SHARE UNSUCCESSFUL NOTIFICATION WATCHER:
		--------------------------------------------------------------------------------
		mod.failureWatcher = distributednotifications.new(notificationWatcherAction, "ProTranscoderDidFailNotification")
		mod.failureWatcher:start()
	end
end

local function checkWatching()
	if mod.watchers:getCount() == 0 and mod.successWatcher ~= nil then
		mod.successWatcher:stop()
		mod.successWatcher = nil
		mod.failureWatcher:stop()
		mod.failureWatcher = nil
	end
end

mod.watchers = watcher:new(table.unpack(mod.eventTypes))

function mod.watch(events)
	local id = mod.watchers:watch(events)
	ensureWatching()
	return id
end

function mod.unwatch(id)
	mod.watchers:unwatch(id)
	checkWatching()
end

-- The Plugin
local plugin = {}

function plugin.init(deps)
	return mod
end

return plugin