--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                  S C A N    F I N A L    C U T    P R O                    --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.preferences.scanfinalcutpro ===
---
--- Scan Final Cut Pro.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("scanfinalcutpro")

local dialog			= require("cp.dialog")
local fcp				= require("cp.apple.finalcutpro")
local guiscan			= require("cp.apple.finalcutpro.plugins.guiscan")
local just				= require("cp.just")
local config			= require("cp.config")
local tools				= require("cp.tools")
local prop				= require("cp.prop")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local PRIORITY = 1

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--------------------------------------------------------------------------------
-- SCAN FINAL CUT PRO:
--------------------------------------------------------------------------------
function mod.scanFinalCutPro()

	if not fcp:isRunning() then
		--log.d("Launching Final Cut Pro.")
		fcp:launch()

		local didFinalCutProLoad = just.doUntil(function()
			--log.d("Checking if Final Cut Pro has loaded.")
			return fcp:primaryWindow():isShowing()
		end, 10, 1)

		if not didFinalCutProLoad then
			dialog.displayMessage(i18n("loadFinalCutProFailed"))
			return false
		end
		--log.d("Final Cut Pro has loaded.")
	else
		--log.d("Final Cut Pro is already running.")
	end

	--------------------------------------------------------------------------------
	-- Warning message:
	--------------------------------------------------------------------------------
	dialog.displayMessage(i18n("scanFinalCutProWarning"))

	local result = guiscan.check()

	--------------------------------------------------------------------------------
	-- Competition Message:
	--------------------------------------------------------------------------------
	if result then
		dialog.displayMessage(i18n("scanFinalCutProDone"))
	else
		dialog.displayMessage(i18n("scanFinalCutProErrors"))
	end

	return true
end

--------------------------------------------------------------------------------
-- INITIALISE MODULE:
--------------------------------------------------------------------------------
function mod.init()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.preferences.scanfinalcutpro",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.preferences.app"]						= "prefs",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

	mod.init()

	if deps.prefs.panel then
		deps.prefs.panel:addHeading(10, i18n("setupHeading"))

		:addButton(11,
			{
				label = i18n("scanFinalCutPro"),
				onclick = mod.scanFinalCutPro,
			}
		)

	end

	return mod
end

return plugin