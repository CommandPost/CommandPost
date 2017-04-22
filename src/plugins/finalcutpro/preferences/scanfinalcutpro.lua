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

local application		= require("hs.application")

local dialog			= require("cp.dialog")
local fcp				= require("cp.apple.finalcutpro")
local just				= require("cp.just")
local config			= require("cp.config")
local tools				= require("cp.tools")

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
-- HAS FINAL CUT PRO BEEN SCANNED?
--------------------------------------------------------------------------------
function mod.isScanned()

	if mod.effects.isEffectsListUpdated() and mod.generators.isGeneratorsListUpdated() and mod.titles.isTitlesListUpdated() and mod.transitions.isTransitionsListUpdated() then
		return true
	end
	return false

end

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

	local result

	result = mod.effects.updateEffectsList()
	if result == "Fail" then return false end

	result = mod.transitions.updateTransitionsList()
	if result == "Fail" then return false end

	result = mod.titles.updateTitlesList()
	if result == "Fail" then return false end

	result = mod.generators.updateGeneratorsList()
	if result == "Fail" then return false end

	dialog.displayMessage(i18n("scanFinalCutProDone"))

	return true

end

--------------------------------------------------------------------------------
-- INITIALISE MODULE:
--------------------------------------------------------------------------------
function mod.init(effects, generators, titles, transitions)
	mod.effects = effects
	mod.generators = generators
	mod.titles = titles
	mod.transitions = transitions
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
		["finalcutpro.timeline.effects"]					= "effects",
		["finalcutpro.timeline.generators"]					= "generators",
		["finalcutpro.timeline.titles"]						= "titles",
		["finalcutpro.timeline.transitions"]				= "transitions",
		["finalcutpro.preferences.panels.finalcutpro"]		= "prefs",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	mod.init(deps.effects, deps.generators, deps.titles, deps.transitions)

	if deps.prefs.panel then
		deps.prefs.panel:addHeading(10, i18n("setupHeading") .. ":" )

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