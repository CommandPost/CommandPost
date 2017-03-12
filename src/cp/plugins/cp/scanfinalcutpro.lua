local application		= require("hs.application")
local log				= require("hs.logger").new("scanfinalcutpro")

local fcp				= require("cp.finalcutpro")
local dialog			= require("cp.dialog")
local hacksconsole		= require("cp.fcpx10-3.hacksconsole")
local tools				= require("cp.tools")
local metadata			= require("cp.metadata")
local just				= require("cp.just")

--- The function

local PRIORITY = 1

local mod = {}

function mod.scanFinalCutPro()

	if not fcp:isRunning() then
		log.d("Launching Final Cut Pro.")
		fcp:launch()

		local didFinalCutProLoad = just.doUntil(function()
			log.d("Checking if Final Cut Pro has loaded.")
			return fcp:primaryWindow():isShowing()
		end, 10, 1)

		if not didFinalCutProLoad then
			dialog.display("Failed to load Final Cut Pro. Please try again.")
			return false
		end
		log.d("Final Cut Pro has loaded.")
	else
		log.d("Final Cut Pro is already running.")
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

function mod.init(effects, generators, titles, transitions)
	mod.effects = effects
	mod.generators = generators
	mod.titles = titles
	mod.transitions = transitions
end

--- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.menu.preferences"]		= "prefs",
	["cp.plugins.timeline.effects"]		= "effects",
	["cp.plugins.timeline.generators"]	= "generators",
	["cp.plugins.timeline.titles"]		= "titles",
	["cp.plugins.timeline.transitions"]	= "transitions",
}

function plugin.init(deps)
	mod.init(deps.effects, deps.generators, deps.titles, deps.transitions)
	
	deps.prefs:addItem(PRIORITY, function()
		return { title = i18n("scanFinalCutPro"),	fn = mod.scanFinalCutPro }
	end):addSeparator(2)

	return mod
end

function plugin.scanFinalCutPro()
	return mod.scanFinalCutPro()
end

return plugin