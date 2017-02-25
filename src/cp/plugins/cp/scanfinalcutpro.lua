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

	local result

	result = mod.updateEffectsList()
	if result == "Fail" then return false end

	result = mod.updateTitlesList()
	if result == "Fail" then return false end

	result = mod.updateGeneratorsList()
	if result == "Fail" then return false end

	result = mod.updateTransitionsList()
	if result == "Fail" then return false end

	return true

end

--------------------------------------------------------------------------------
-- GET LIST OF EFFECTS:
--------------------------------------------------------------------------------
function mod.updateEffectsList()

	--------------------------------------------------------------------------------
	-- Make sure Final Cut Pro is active:
	--------------------------------------------------------------------------------
	fcp:launch()

	--------------------------------------------------------------------------------
	-- Warning message:
	--------------------------------------------------------------------------------
	--dialog.displayMessage(i18n("updateEffectsListWarning"))

	--------------------------------------------------------------------------------
	-- Save the layout of the Transitions panel in case we switch away...
	--------------------------------------------------------------------------------
	local transitions = fcp:transitions()
	local transitionsLayout = transitions:saveLayout()

	--------------------------------------------------------------------------------
	-- Make sure Effects panel is open:
	--------------------------------------------------------------------------------
	local effects = fcp:effects()
	local effectsShowing = effects:isShowing()
	if not effects:show():isShowing() then
		dialog.displayErrorMessage("Unable to activate the Effects panel.\n\nError occurred in updateEffectsList().")
		return "Fail"
	end

	local effectsLayout = effects:saveLayout()

	--------------------------------------------------------------------------------
	-- Make sure "Installed Effects" is selected:
	--------------------------------------------------------------------------------
	effects:showInstalledEffects()

	--------------------------------------------------------------------------------
	-- Make sure there's nothing in the search box:
	--------------------------------------------------------------------------------
	effects:search():clear()

	local sidebar = effects:sidebar()

	--------------------------------------------------------------------------------
	-- Ensure the sidebar is visible
	--------------------------------------------------------------------------------
	effects:showSidebar()

	--------------------------------------------------------------------------------
	-- If it's still invisible, we have a problem.
	--------------------------------------------------------------------------------
	if not sidebar:isShowing() then
		dialog.displayErrorMessage("Unable to activate the Effects sidebar.\n\nError occurred in updateEffectsList().")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Click 'All Video':
	--------------------------------------------------------------------------------
	if not effects:showAllVideoEffects() then
		dialog.displayErrorMessage("Unable to select all video effects.\n\nError occurred in updateEffectsList().")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Get list of All Video Effects:
	--------------------------------------------------------------------------------
	local allVideoEffects = effects:getCurrentTitles()
	if not allVideoEffects then
		dialog.displayErrorMessage("Unable to get list of all effects.\n\nError occurred in updateEffectsList().")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Click 'All Audio':
	--------------------------------------------------------------------------------
	if not effects:showAllAudioEffects() then
		dialog.displayErrorMessage("Unable to select all audio effects.\n\nError occurred in updateEffectsList().")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Get list of All Audio Effects:
	--------------------------------------------------------------------------------
	local allAudioEffects = effects:getCurrentTitles()
	if not allAudioEffects then
		dialog.displayErrorMessage("Unable to get list of all effects.\n\nError occurred in updateEffectsList().")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Restore Effects and Transitions Panels:
	--------------------------------------------------------------------------------
	effects:loadLayout(effectsLayout)
	transitions:loadLayout(transitionsLayout)
	if not effectsShowing then effects:hide() end

	--------------------------------------------------------------------------------
	-- All done!
	--------------------------------------------------------------------------------
	if #allVideoEffects == 0 or #allAudioEffects == 0 then
		dialog.displayMessage(i18n("updateEffectsListFailed") .. "\n\n" .. i18n("pleaseTryAgain"))
		return "Fail"
	else
		--------------------------------------------------------------------------------
		-- Save Results to Settings:
		--------------------------------------------------------------------------------
		local currentLanguage = fcp:getCurrentLanguage()
		metadata.get(currentLanguage .. ".allVideoEffects", allVideoEffects)
		metadata.get(currentLanguage .. ".allAudioEffects", allAudioEffects)
		metadata.get(currentLanguage .. ".effectsListUpdated", true)

		--------------------------------------------------------------------------------
		-- Update Chooser:
		--------------------------------------------------------------------------------
		--hacksconsole.refresh()

		--------------------------------------------------------------------------------
		-- Let the user know everything's good:
		--------------------------------------------------------------------------------
		--dialog.displayMessage(i18n("updateEffectsListDone"))

		log.d("Effects List Updated")
	end

end

--------------------------------------------------------------------------------
-- GET LIST OF GENERATORS:
--------------------------------------------------------------------------------
function mod.updateGeneratorsList()

	--------------------------------------------------------------------------------
	-- Make sure Final Cut Pro is active:
	--------------------------------------------------------------------------------
	fcp:launch()

	--------------------------------------------------------------------------------
	-- Warning message:
	--------------------------------------------------------------------------------
	--dialog.displayMessage(i18n("updateGeneratorsListWarning"))

	local generators = fcp:generators()

	local browserLayout = fcp:browser():saveLayout()

	--------------------------------------------------------------------------------
	-- Make sure Generators and Generators panel is open:
	--------------------------------------------------------------------------------
	if not generators:show():isShowing() then
		dialog.displayErrorMessage("Unable to activate the Generators and Generators panel.\n\nError occurred in updateGeneratorsList().")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Make sure there's nothing in the search box:
	--------------------------------------------------------------------------------
	generators:search():clear()

	--------------------------------------------------------------------------------
	-- Click 'Generators':
	--------------------------------------------------------------------------------
	generators:showAllGenerators()

	--------------------------------------------------------------------------------
	-- Make sure "Installed Generators" is selected:
	--------------------------------------------------------------------------------
	generators:group():selectItem(1)

	--------------------------------------------------------------------------------
	-- Get list of All Transitions:
	--------------------------------------------------------------------------------
	local effectsList = generators:contents():childrenUI()
	local allGenerators = {}
	if effectsList ~= nil then
		for i=1, #effectsList do
			allGenerators[i] = effectsList[i]:attributeValue("AXTitle")
		end
	else
		dialog.displayErrorMessage("Unable to get list of all generators.\n\nError occurred in updateGeneratorsList().")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Restore Effects or Transitions Panel:
	--------------------------------------------------------------------------------
	fcp:browser():loadLayout(browserLayout)

	--------------------------------------------------------------------------------
	-- Save Results to Settings:
	--------------------------------------------------------------------------------
	local currentLanguage = fcp:getCurrentLanguage()
	metadata.get(currentLanguage .. ".allGenerators", allGenerators)
	metadata.get(currentLanguage .. ".generatorsListUpdated", true)

	--------------------------------------------------------------------------------
	-- Update Chooser:
	--------------------------------------------------------------------------------
	--hacksconsole.refresh()

	--------------------------------------------------------------------------------
	-- Let the user know everything's good:
	--------------------------------------------------------------------------------
	--dialog.displayMessage(i18n("updateGeneratorsListDone"))

	log.d("Generator List Updated")

end

--------------------------------------------------------------------------------
-- GET LIST OF TITLES:
--------------------------------------------------------------------------------
function mod.updateTitlesList()

	--------------------------------------------------------------------------------
	-- Make sure Final Cut Pro is active:
	--------------------------------------------------------------------------------
	fcp:launch()

	--------------------------------------------------------------------------------
	-- Warning message:
	--------------------------------------------------------------------------------
	--dialog.displayMessage(i18n("updateTitlesListWarning"))

	local generators = fcp:generators()

	local browserLayout = fcp:browser():saveLayout()

	--------------------------------------------------------------------------------
	-- Make sure Titles and Generators panel is open:
	--------------------------------------------------------------------------------
	if not generators:show():isShowing() then
		dialog.displayErrorMessage("Unable to activate the Titles and Generators panel.\n\nError occurred in updateTitlesList().")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Make sure there's nothing in the search box:
	--------------------------------------------------------------------------------
	generators:search():clear()

	--------------------------------------------------------------------------------
	-- Click 'Titles':
	--------------------------------------------------------------------------------
	generators:showAllTitles()

	--------------------------------------------------------------------------------
	-- Make sure "Installed Titles" is selected:
	--------------------------------------------------------------------------------
	generators:group():selectItem(1)

	--------------------------------------------------------------------------------
	-- Get list of All Transitions:
	--------------------------------------------------------------------------------
	local effectsList = generators:contents():childrenUI()
	local allTitles = {}
	if effectsList ~= nil then
		for i=1, #effectsList do
			allTitles[i] = effectsList[i]:attributeValue("AXTitle")
		end
	else
		dialog.displayErrorMessage("Unable to get list of all titles.\n\nError occurred in updateTitlesList().")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Restore Effects or Transitions Panel:
	--------------------------------------------------------------------------------
	fcp:browser():loadLayout(browserLayout)

	--------------------------------------------------------------------------------
	-- Save Results to Settings:
	--------------------------------------------------------------------------------
	local currentLanguage = fcp:getCurrentLanguage()
	metadata.get(currentLanguage .. ".allTitles", allTitles)
	metadata.get(currentLanguage .. ".titlesListUpdated", true)

	--------------------------------------------------------------------------------
	-- Update Chooser:
	--------------------------------------------------------------------------------
	--hacksconsole.refresh()

	--------------------------------------------------------------------------------
	-- Let the user know everything's good:
	--------------------------------------------------------------------------------
	--dialog.displayMessage(i18n("updateTitlesListDone"))

	log.d("Title List Updated")

end

--------------------------------------------------------------------------------
-- GET LIST OF TRANSITIONS:
--------------------------------------------------------------------------------
function mod.updateTransitionsList()

	--------------------------------------------------------------------------------
	-- Make sure Final Cut Pro is active:
	--------------------------------------------------------------------------------
	fcp:launch()

	--------------------------------------------------------------------------------
	-- Warning message:
	--------------------------------------------------------------------------------
	--dialog.displayMessage(i18n("updateTransitionsListWarning"))

	--------------------------------------------------------------------------------
	-- Save the layout of the Effects panel, in case we switch away...
	--------------------------------------------------------------------------------
	local effects = fcp:effects()
	local effectsLayout = nil
	if effects:isShowing() then
		effectsLayout = effects:saveLayout()
	end

	--------------------------------------------------------------------------------
	-- Make sure Transitions panel is open:
	--------------------------------------------------------------------------------
	local transitions = fcp:transitions()
	local transitionsShowing = transitions:isShowing()
	if not transitions:show():isShowing() then
		dialog.displayErrorMessage("Unable to activate the Transitions panel.\n\nError occurred in updateTransitionsList().")
		return "Fail"
	end

	local transitionsLayout = transitions:saveLayout()

	--------------------------------------------------------------------------------
	-- Make sure "Installed Transitions" is selected:
	--------------------------------------------------------------------------------
	transitions:showInstalledTransitions()

	--------------------------------------------------------------------------------
	-- Make sure there's nothing in the search box:
	--------------------------------------------------------------------------------
	transitions:search():clear()

	--------------------------------------------------------------------------------
	-- Make sure the sidebar is visible:
	--------------------------------------------------------------------------------
	local sidebar = transitions:sidebar()

	transitions:showSidebar()

	if not sidebar:isShowing() then
		dialog.displayErrorMessage("Unable to activate the Transitions sidebar.\n\nError occurred in updateTransitionsList().")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Click 'All' in the sidebar:
	--------------------------------------------------------------------------------
	transitions:showAllTransitions()

	--------------------------------------------------------------------------------
	-- Get list of All Transitions:
	--------------------------------------------------------------------------------
	local allTransitions = transitions:getCurrentTitles()
	if allTransitions == nil then
		dialog.displayErrorMessage("Unable to get list of all transitions.\n\nError occurred in updateTransitionsList().")
		return "Fail"
	end

	--------------------------------------------------------------------------------
	-- Restore Effects and Transitions Panels:
	--------------------------------------------------------------------------------
	transitions:loadLayout(transitionsLayout)
	if effectsLayout then effects:loadLayout(effectsLayout) end
	if not transitionsShowing then transitions:hide() end

	--------------------------------------------------------------------------------
	-- Save Results to Settings:
	--------------------------------------------------------------------------------
	local currentLanguage = fcp:getCurrentLanguage()
	metadata.get(currentLanguage .. ".allTransitions", allTransitions)
	metadata.get(currentLanguage .. ".transitionsListUpdated", true)

	--------------------------------------------------------------------------------
	-- Update Chooser:
	--------------------------------------------------------------------------------
	--hacksconsole.refresh()

	--------------------------------------------------------------------------------
	-- Let the user know everything's good:
	--------------------------------------------------------------------------------
	--dialog.displayMessage(i18n("updateTransitionsListDone"))

	log.d("Transition List Updated")

end

--- The Plugin
local plugin = {}

plugin.dependencies = {
	["cp.plugins.menu.preferences"]	= "prefs",
}

function plugin.init(deps)
	deps.prefs:addItem(PRIORITY, function()
		return { title = i18n("scanFinalCutPro"),	fn = mod.scanFinalCutPro }
	end):addSeparator(2)

	return mod
end

function plugin.scanFinalCutPro()
	return mod.scanFinalCutPro()
end

return plugin