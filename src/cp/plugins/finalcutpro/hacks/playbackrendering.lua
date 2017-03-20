--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--              P L A Y B A C K    R E N D E R I N G    P L U G I N           --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("playbackrendering")

local application		= require("hs.application")

local dialog			= require("cp.dialog")
local fcp				= require("cp.finalcutpro")
local metadata			= require("cp.metadata")
local plist				= require("cp.plist")
local tools				= require("cp.tools")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
local PRIORITY 			= 5500
local DEFAULT_VALUE		= false
local PREFERENCES_KEY 	= "FFSuspendBGOpsDuringPlay"

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	function mod.isEnabled()

		local FFSuspendBGOpsDuringPlay = DEFAULT_VALUE
		local preferences = fcp:getPreferences()
		if preferences and preferences[PREFERENCES_KEY] then
			FFSuspendBGOpsDuringPlay = preferences[PREFERENCES_KEY]
		end
		return FFSuspendBGOpsDuringPlay

	end

	function mod.togglePerformTasksDuringPlayback()

		--------------------------------------------------------------------------------
		-- Get existing value:
		--------------------------------------------------------------------------------
		local FFSuspendBGOpsDuringPlay = mod.isEnabled()

		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local restartStatus = false
		if fcp:isRunning() then
			if dialog.displayYesNoQuestion(i18n("togglingBackgroundTasksRestart") .. "\n\n" ..i18n("doYouWantToContinue")) then
				restartStatus = true
			else
				return "Done"
			end
		end

		--------------------------------------------------------------------------------
		-- Update plist:
		--------------------------------------------------------------------------------
		local result = fcp:setPreference(PREFERENCES_KEY, not FFSuspendBGOpsDuringPlay)
		if result == nil then
			dialog.displayErrorMessage(i18n("failedToWriteToPreferences"))
			return "Failed"
		end

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if restartStatus then
			if not fcp:restart() then
				--------------------------------------------------------------------------------
				-- Failed to restart Final Cut Pro:
				--------------------------------------------------------------------------------
				dialog.displayErrorMessage(i18n("failedToRestart"))
				return "Failed"
			end
		end
	end

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {}

	--------------------------------------------------------------------------------
	-- DEPENDENCIES:
	--------------------------------------------------------------------------------
	plugin.dependencies = {
		["cp.plugins.finalcutpro.menu.timeline"] = "timeline",
		["cp.plugins.finalcutpro.commands.fcpx"] = "fcpxCmds",
	}

	--------------------------------------------------------------------------------
	-- INITIALISE PLUGIN:
	--------------------------------------------------------------------------------
	function plugin.init(deps)

		deps.timeline:addItem(PRIORITY, function()
			return { title = i18n("enableRenderingDuringPlayback"),	fn = mod.togglePerformTasksDuringPlayback, checked=mod.isEnabled() }
		end)

		-- Commands
		deps.fcpxCmds:add("cpAllowTasksDuringPlayback")
			:groupedBy("hacks")
			:activatedBy():ctrl():option():cmd("p")
			:whenActivated(mod.togglePerformTasksDuringPlayback)

		return mod

	end

return plugin