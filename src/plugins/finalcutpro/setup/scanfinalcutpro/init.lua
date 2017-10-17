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
local log				= require("hs.logger").new("scanfcpx")

local dialog			= require("cp.dialog")
local fcp				= require("cp.apple.finalcutpro")
local guiscan			= require("cp.apple.finalcutpro.plugins.guiscan")
local just				= require("cp.just")
local config			= require("cp.config")
local tools				= require("cp.tools")
local prop				= require("cp.prop")
local feedback			= require("cp.feedback")

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

	local ok, result = guiscan.check()

	print(result)

	--------------------------------------------------------------------------------
	-- Competition Message:
	--------------------------------------------------------------------------------
	if ok then
		dialog.displayMessage(i18n("scanFinalCutProDone"))
	else
		feedback.showFeedback()
	end

	return true
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
		["core.preferences.panels.advanced"]			= "advanced",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

	deps.advanced
		:addButton(61.1,
			{
				label = i18n("scanFinalCutPro"),
				width = 150,
				onclick = mod.scanFinalCutPro,
			}
		)
		:addParagraph(61.2, [[<span class="tip">]]  .. "<strong>" .. string.upper(i18n("tip")) .. ": </strong>" .. i18n("scanFinalCutProDescription") .. [[</span>]], true)

	return mod
end

return plugin