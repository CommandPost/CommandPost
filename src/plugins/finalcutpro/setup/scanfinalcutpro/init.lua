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
-- NEW SCAN FINAL CUT PRO:
--------------------------------------------------------------------------------
function mod.newScanFinalCutPro()
	dialog.displayMessage("We will now scan Final Cut Pro for Effects, Transitions, Generators and Titles. This can take several minutes.")
	local result = fcp:scanPlugins()

	log.df("Result: %s", hs.inspect(result))

	if result then
		local effectTypes = { "Effects", "Transitions", "AudioEffects", "Generators", "Titles" }
		for _, currentLanguage in pairs(fcp.SUPPORTED_LANGUAGES) do
			for _, effectType in pairs(effectTypes) do

				local effects = {}
				for _, videoEffects in ipairs(result[currentLanguage][effectType]) do
					for category, videoEffect in ipairs(videoEffects) do
						if type(videoEffect) == "table" then
							for _, plugin in ipairs(videoEffect) do
								--log.df("Match: %s", category .. " - " .. plugin)
								effects[#effects + 1] = category .. " - " .. plugin
							end
						else
							effects[#effects + 1] = videoEffect
						end
					end
				end

				config.set(currentLanguage .. ".all" .. effectType)

			end
		end
	else
		dialog.displayErrorMessage("Something went wrong when scanning Final Cut Pro.")
	end
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

	--------------------------------------------------------------------------------
	-- Show Effects Panel:
	--------------------------------------------------------------------------------
	fcp:effects():show()

	--------------------------------------------------------------------------------
	-- Show Generators Panel:
	--------------------------------------------------------------------------------
	fcp:generators():show()

	--------------------------------------------------------------------------------
	-- Update Effects, Transitions, Titles & Generator Lists:
	--------------------------------------------------------------------------------
	if not mod.effects.updateEffectsList() then return false end
	if not mod.transitions.updateTransitionsList() then return false end
	if not mod.titles.updateTitlesList() then return false end
	if not mod.generators.updateGeneratorsList() then return false end

	--------------------------------------------------------------------------------
	-- Competition Message:
	--------------------------------------------------------------------------------
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

	--------------------------------------------------------------------------------
	-- HAS FINAL CUT PRO BEEN SCANNED?
	--------------------------------------------------------------------------------
	mod.scanned = prop.AND(
		mod.effects.listUpdated,
		mod.generators.listUpdated,
		mod.titles.listUpdated,
		mod.transitions.listUpdated
	)



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
		["finalcutpro.preferences.app"]		= "prefs",
		["core.setup"]										= "setup",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

	mod.init(deps.effects, deps.generators, deps.titles, deps.transitions)

	if deps.prefs.panel then
		deps.prefs.panel:addHeading(10, i18n("setupHeading"))

		:addButton(11,
			{
				label = i18n("scanFinalCutPro") .. " (GUI Scripting)",
				onclick = mod.scanFinalCutPro,
			}
		)

		:addButton(12,
			{
				label = i18n("scanFinalCutPro") .. " (File System)",
				onclick = mod.newScanFinalCutPro,
			}
		)

	end

	-- Add a setup panel if the initial onboarding is not complete and a scan is required.
	deps.setup.onboardingRequired:AND(mod.scanned:NOT()):watch(function(setupRequired)
		if setupRequired then
			local setup = deps.setup
			setup.addPanel(
				setup.panel.new("scanfinalcutpro", 60)
					:addIcon(fcp:getPath() .. "/Contents/Resources/Final Cut.icns")
					:addParagraph(i18n("scanFinalCutProText"), true)
					:addButton({
						label		= i18n("scanFinalCutPro"),
						onclick		= function()
							if mod.scanFinalCutPro() then
								setup.nextPanel()
							else
								setup.focus()
							end
						end
					})
					:addButton({
						label		= i18n("skip"),
						onclick		= setup.nextPanel
					})
			).show()
		end
	end, true)

	return mod
end

return plugin