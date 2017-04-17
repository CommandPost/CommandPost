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
local fcp			= require("cp.finalcutpro")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY 		= 2000

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.timeline.preferences.toggleBackgroundRender(optionalValue) -> nil
--- Function
--- Toggles Background Render in Final Cut Pro.
---
--- Parameters:
---  * optionalValue - Set the Background Render to `true` or `false`
---
--- Returns:
---  * `true` if successful otherwise `false`
function mod.toggleBackgroundRender(optionalValue)

	--------------------------------------------------------------------------------
	-- Make sure it's active:
	--------------------------------------------------------------------------------
	fcp:launch()

	--------------------------------------------------------------------------------
	-- If we're setting rather than toggling...
	--------------------------------------------------------------------------------
	if optionalValue ~= nil and optionalValue == fcp:getPreference("FFAutoStartBGRender", true) then
		return true
	end

	--------------------------------------------------------------------------------
	-- Define FCPX:
	--------------------------------------------------------------------------------
	local prefs = fcp:preferencesWindow()

	--------------------------------------------------------------------------------
	-- Toggle the checkbox:
	--------------------------------------------------------------------------------
	if not prefs:playbackPanel():toggleAutoStartBGRender() then
		dialog.displayErrorMessage("Failed to toggle 'Enable Background Render'.\n\nError occurred in toggleBackgroundRender().")
		return false
	end

	--------------------------------------------------------------------------------
	-- Close the Preferences window:
	--------------------------------------------------------------------------------
	prefs:hide()
	return true

end

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
		["finalcutpro.menu.mediaimport"] 	= "shortcuts",
		["finalcutpro.commands"]			= "fcpxCmds",
	}
}

---------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
---------------------------------------------------------------------------------
function plugin.init(deps)
	deps.shortcuts:addItems(PRIORITY, function()
		local fcpxRunning = fcp:isRunning()

		return {
			{ title = i18n("enableBackgroundRender", {count = mod.getAutoRenderDelay()}),		fn = mod.toggleBackgroundRender, 					checked = fcp:getPreference("FFAutoStartBGRender", true),						disabled = not fcpxRunning },
		}
	end)

	deps.fcpxCmds:add("cpBackgroundRenderOn")
		:groupedBy("timeline")
		:whenActivated(function() toggleBackgroundRender(true) end)
	deps.fcpxCmds:add("cpBackgroundRenderOff")
		:groupedBy("timeline")
		:whenActivated(function() toggleBackgroundRender(false) end)

	return mod
end

return plugin