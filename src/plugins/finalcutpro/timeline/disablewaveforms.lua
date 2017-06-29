--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--              D I S A B L E    W A V E F O R M S    P L U G I N             --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.disablewaveforms ===
---
--- Disable Waveforms Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("disablewaveforms")

local application		= require("hs.application")

local dialog			= require("cp.dialog")
local fcp				= require("cp.apple.finalcutpro")
local config			= require("cp.config")
local prop				= require("cp.prop")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 			= 10001
local DEFAULT_VALUE		= false
local PREFERENCES_KEY 	= "FFAudioDisableWaveformDrawing"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod.enabled = prop.new(
	function()
		return fcp:getPreference(PREFERENCES_KEY, DEFAULT_VALUE)
	end,

	function(value)
		--------------------------------------------------------------------------------
		-- If Final Cut Pro is running...
		--------------------------------------------------------------------------------
		local running = fcp:isRunning()
		if running and not dialog.displayYesNoQuestion(i18n("togglingWaveformsRestart") .. "\n\n" .. i18n("doYouWantToContinue")) then
			return
		end

		--------------------------------------------------------------------------------
		-- Update plist:
		--------------------------------------------------------------------------------
		if fcp:setPreference(PREFERENCES_KEY, value) == nil then
			dialog.displayErrorMessage(i18n("failedToWriteToPreferences"))
			return
		end

		--------------------------------------------------------------------------------
		-- Restart Final Cut Pro:
		--------------------------------------------------------------------------------
		if running and not fcp:restart() then
			--------------------------------------------------------------------------------
			-- Failed to restart Final Cut Pro:
			--------------------------------------------------------------------------------
			dialog.displayErrorMessage(i18n("failedToRestart"))
			return
		end

	end
)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.timeline.disablewaveforms",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.menu.timeline"]	= "menu",
		["finalcutpro.commands"] 		= "fcpxCmds",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	deps.menu:addItem(PRIORITY, function()
		return { title = i18n("enableWaveformDrawing"),	fn = function() mod.enabled:toggle() end, checked=not mod.enabled() }
	end)

	--------------------------------------------------------------------------------
	-- Commands:
	--------------------------------------------------------------------------------
	deps.fcpxCmds:add("cpDisableWaveforms")
		:groupedBy("hacks")
		:whenActivated(function() mod.enabled:toggle() end)

	return mod

end

return plugin