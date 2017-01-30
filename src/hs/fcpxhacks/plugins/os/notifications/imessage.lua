-- Imports
local settings									= require("hs.settings")
local messages									= require("hs.messages")

-- The Module
local mod = {}

function mod.isEnabled()
	return settings.get("fcpxHacks.iMessageNotificationsEnabled") or false
end

function mod.setEnabled(value)
	settings.set("fcpxHacks.iMessageNotificationsEnabled", value)
	mod.update()
end

function mod.toggleEnabled()
	mod.setEnabled(not mod.isEnabled())
end

function mod.getTarget()
	return settings.get("fcpxHacks.iMessageTarget") or nil
end

function mod.setTarget(value)
	settings.set("fcpxHacks.iMessageTarget", value)
end

function mod.sendNotification(message)
	local iMessageTarget = mod.getTarget()
	if iMessageTarget then
		messages.iMessage(iMessageTarget, message)
	end
end

function mod.update()
	if mod.isEnabled() then
		if mod.getTarget() == nil then
			local result = dialog.displayTextBoxMessage(i18n("iMessageTextBox"), i18n("pleaseTryAgain"), mod.getTarget())
			if result == false then
				mod.setEnabled(false)
				return
			else
				mod.setTarget(result)
			end
		end
	else
		mod.setTarget(nil)
	end
end

-- The Plugin
local plugin = {}

plugin.dependencies = {
	["hs.fcpxhacks.plugins.os.notifications"]	= "notifications",
}

function plugin.init(deps)
	mod.update()
	return mod
end

return plugin