--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.preferences ===
---
--- Final Cut Pro Timeline Preferences.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local fcp			= require("cp.apple.finalcutpro")
local prop			= require("cp.prop")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 			= 2000
local BACKGROUN_RENDER	= "FFAutoStartBGRender"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod.backgroundRender = prop.new(
	function() return fcp:getPreference(BACKGROUND_RENDER, true) end,
	function(value)
		--------------------------------------------------------------------------------
		-- Make sure it's active:
		--------------------------------------------------------------------------------
		fcp:launch()

		--------------------------------------------------------------------------------
		-- Define FCPX:
		--------------------------------------------------------------------------------
		local panel = fcp:preferencesWindow():playbackPanel()

		--------------------------------------------------------------------------------
		-- Toggle the checkbox:
		--------------------------------------------------------------------------------
		if panel:show() then
			panel:backgroundRender():toggle()
		else
			dialog.displayErrorMessage("Failed to toggle 'Enable Background Render'.\n\nError occurred in backgroundRender().")
			return false
		end

		--------------------------------------------------------------------------------
		-- Close the Preferences window:
		--------------------------------------------------------------------------------
		panel:hide()
		return true
	end
)

--- plugins.finalcutpro.timeline.preferences.getAutoRenderDelay() -> number
--- Function
--- Gets the 'FFAutoRenderDelay' value from the Final Cut Pro Preferences file.
---
--- Parameters:
---  * None
---
--- Returns:
---  * 'FFAutoRenderDelay' value as number.
function mod.getAutoRenderDelay()
	return tonumber(fcp:getPreference("FFAutoRenderDelay", "0.3"))
end

---------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.timeline.preferences",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.menu.mediaimport"] 	= "menu",
		["finalcutpro.commands"]			= "fcpxCmds",
	}
}

---------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
---------------------------------------------------------------------------------
function plugin.init(deps)
	deps.menu:addItems(PRIORITY, function()
		local fcpxRunning = fcp:isRunning()

		return {
			{ title = i18n("enableBackgroundRender", {count = mod.getAutoRenderDelay()}),	fn = function() mod.backgroundRender:toggle() end,	checked = mod.backgroundRender(),	disabled = not fcpxRunning },
		}
	end)

	deps.fcpxCmds:add("cpBackgroundRenderOn")
		:groupedBy("timeline")
		:whenActivated(function() mod.backgroundRender(true) end)
	deps.fcpxCmds:add("cpBackgroundRenderOff")
		:groupedBy("timeline")
		:whenActivated(function() mod.backgroundRender(false) end)

	return mod
end

return plugin