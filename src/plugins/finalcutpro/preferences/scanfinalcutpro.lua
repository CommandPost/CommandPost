--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                  S C A N    F I N A L    C U T    P R O                    --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("scanfinalcutpro")

local application		= require("hs.application")

local dialog			= require("cp.dialog")
local fcp				= require("cp.finalcutpro")
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
			dialog.display(i18n("loadFinalCutProFailed"))
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

	result = mod.titles.updateTitlesList()
	if result == "Fail" then return false end

	result = mod.generators.updateGeneratorsList()
	if result == "Fail" then return false end

	result = mod.transitions.updateTransitionsList()
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
		["finalcutpro.timeline.effects"]			= "effects",
		["finalcutpro.timeline.generators"]			= "generators",
		["finalcutpro.timeline.titles"]				= "titles",
		["finalcutpro.timeline.transitions"]		= "transitions",
		["finalcutpro.preferences.panels.finalcutpro"]			= "finalcutpro",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

	mod.init(deps.effects, deps.generators, deps.titles, deps.transitions)

	deps.finalcutpro:addHeading(10, function()
		return { title = "Setup:" }
	end)

	:addButton(11, function()
		return { title = i18n("scanFinalCutPro"),	fn = mod.scanFinalCutPro }
	end)

	return mod
end

return plugin