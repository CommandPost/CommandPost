-- Imports
local settings									= require("hs.settings")
local messages									= require("hs.messages")

local dialog									= require("cp.dialog")
local metadata									= require("cp.metadata")

local log										= require("hs.logger").new("iMessage")

-- Constants
local PRIORITY = 2000

-- The Module
local mod = {}

function mod.isEnabled()
	return settings.get(metadata.settingsPrefix .. ".iMessageNotificationsEnabled") or false
end

function mod.setEnabled(value)
	settings.set(metadata.settingsPrefix .. ".iMessageNotificationsEnabled", value)
	mod.update(true)
end

function mod.toggleEnabled()
	mod.setEnabled(not mod.isEnabled())
end

function mod.getTarget()
	return settings.get(metadata.settingsPrefix .. ".iMessageTarget") or nil
end

function mod.setTarget(value)
	settings.set(metadata.settingsPrefix .. ".iMessageTarget", value)
end

function mod.sendNotification(message)
	local iMessageTarget = mod.getTarget()
	if iMessageTarget then
		messages.iMessage(iMessageTarget, message)
	end
end

local function requestTarget()
	local result = dialog.displayTextBoxMessage(i18n("iMessageTextBox"), i18n("pleaseTryAgain"), mod.getTarget())
	if result == false then
		mod.setEnabled(false)
		return
	else
		mod.setTarget(result)
	end
end

function mod.update(changed)
	if mod.isEnabled() then
		if changed or mod.getTarget() == nil then
			requestTarget()
		end

		if mod.getTarget() ~= nil and mod.watchId == nil then
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

function mod.init(notifications)
	mod.notifications = notifications
	mod.update()
end

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.notifications.manager"]				= "manager",
	["cp.plugins.menu.tools.options.notifications"]	= "menu",
}

function plugin.init(deps)
	mod.init(deps.manager)

	-- Menu Item
	deps.menu:addItem(PRIORITY, function()
		return { title = i18n("iMessage"),	fn = mod.toggleEnabled,	checked = mod.isEnabled() }
	end)


	return mod
end

return plugin