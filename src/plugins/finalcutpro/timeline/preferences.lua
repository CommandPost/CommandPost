local fcp			= require("cp.finalcutpro")

local mod = {}

--------------------------------------------------------------------------------
-- TOGGLE BACKGROUND RENDER:
--------------------------------------------------------------------------------
function mod.toggleBackgroundRender(optionalValue)

	--------------------------------------------------------------------------------
	-- Make sure it's active:
	--------------------------------------------------------------------------------
	fcp:launch()

	--------------------------------------------------------------------------------
	-- If we're setting rather than toggling...
	--------------------------------------------------------------------------------
	if optionalValue ~= nil and optionalValue == fcp:getPreference("FFAutoStartBGRender", true) then
		return
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
		return "Failed"
	end

	--------------------------------------------------------------------------------
	-- Close the Preferences window:
	--------------------------------------------------------------------------------
	prefs:hide()

end

function mod.getAutoRenderDelay()
	return tonumber(fcp:getPreference("FFAutoRenderDelay", "0.3"))
end

---------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

local PRIORITY = 2000

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