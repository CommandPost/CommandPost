--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                 i M E S S A G E     N O T I F I C A T I O N S              --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("iMessage")

local messages									= require("hs.messages")

local dialog									= require("cp.dialog")
local metadata									= require("cp.metadata")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
local PRIORITY = 2000

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	function mod.isEnabled()
		return metadata.get("iMessageNotificationsEnabled", false)
	end

	function mod.setEnabled(value)
		metadata.set("iMessageNotificationsEnabled", value)
		mod.update(true)
	end

	function mod.toggleEnabled()
		mod.setEnabled(not mod.isEnabled())
	end

	function mod.getTarget()
		return metadata.get("iMessageTarget", nil)
	end

	function mod.setTarget(value)
		metadata.set("iMessageTarget", value)
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

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {}

	--------------------------------------------------------------------------------
	-- DEPENDENCIES:
	--------------------------------------------------------------------------------
	plugin.dependencies = {
		["cp.plugins.finalcutpro.notifications.manager"]		= "manager",
		["cp.plugins.finalcutpro.menu.tools.notifications"]		= "menu",
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
			return { title = i18n("iMessage"),	fn = mod.toggleEnabled,	checked = mod.isEnabled() }
		end)


		return mod
	end

return plugin