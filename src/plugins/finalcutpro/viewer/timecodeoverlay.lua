--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--              T I M E C O D E    O V E R L A Y    P L U G I N               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.viewer.timecodeoverlay ===
---
--- Advanced Timecode Overlay.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("timecodeoverlay")

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
local PRIORITY 			= 10
local DEFAULT_VALUE		= false
local PREFERENCES_KEY 	= "FFEnableGuards"

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
		if running and not dialog.displayYesNoQuestion(i18n("togglingTimecodeOverlayRestart") .. "\n\n" .. i18n("doYouWantToContinue")) then
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
	id				= "finalcutpro.viewer.timecodeoverlay",
	group			= "finalcutpro",
	dependencies	= {
		["finalcutpro.menu.viewer"]	= "menu",
		["finalcutpro.commands"] 		= "fcpxCmds",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	deps.menu:addItem(PRIORITY, function()
		return { title = i18n("enableTimecodeOverlay"),	fn = function() mod.enabled:toggle() end, checked=mod.enabled() }
	end)

	--------------------------------------------------------------------------------
	-- Commands:
	--------------------------------------------------------------------------------
	deps.fcpxCmds:add("cpToggleTimecodeOverlays")
		:groupedBy("hacks")
		:activatedBy():ctrl():option():cmd("t")
		:whenActivated(function() mod.enabled:toggle() end)

	return mod

end

return plugin