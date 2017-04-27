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

local dialog									= require("cp.dialog")
local config									= require("cp.config")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY = 2000

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local function requestTarget()
	local result = dialog.displayTextBoxMessage(i18n("iMessageTextBox"), i18n("pleaseTryAgain"), mod.target())
	if result == false then
		mod.enabled(false)
		return
	else
		mod.target(result)
	end
end

function mod.update(changed)
	if mod.enabled() then
		if changed or mod.target() == nil then
			requestTarget()
		end

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

mod.enabled = config.prop("iMessageNotificationsEnabled", false):watch(function() mod.update(true) end)

mod.target = config.prop("iMessageTarget")

function mod.sendNotification(message)
	local iMessageTarget = mod.target()
	if iMessageTarget then
		messages.iMessage(iMessageTarget, message)
	end
end

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
		return { title = i18n("iMessage"),	fn = function() mod.enabled:toggle() end,	checked = mod.enabled() }
	end)


	return mod
end

return plugin