--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--              P L A Y B A C K    R E N D E R I N G    P L U G I N           --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.hacks.playbackrendering ===
---
--- Playback Rendering Plugin.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("playbackrendering")

local application		= require("hs.application")

local dialog			= require("cp.dialog")
local fcp				= require("cp.apple.finalcutpro")
local config			= require("cp.config")
local plist				= require("cp.plist")
local tools				= require("cp.tools")
local prop				= require("cp.prop")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 			= 5500
local DEFAULT_VALUE		= false
local PREFERENCES_KEY 	= "FFSuspendBGOpsDuringPlay"

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
		if running and not dialog.displayYesNoQuestion(i18n("togglingBackgroundTasksRestart") .. "\n\n" ..i18n("doYouWantToContinue")) then
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
	id				= "finalcutpro.hacks.playbackrendering",
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
		return { title = i18n("enableRenderingDuringPlayback"),	fn = function() mod.enabled:toggle() end, checked=mod.enabled() }
	end)

	-- Commands
	deps.fcpxCmds:add("cpAllowTasksDuringPlayback")
		:groupedBy("hacks")
		:activatedBy():ctrl():option():cmd("p")
		:whenActivated(function() mod.enabled:toggle() end)

	return mod

end

return plugin