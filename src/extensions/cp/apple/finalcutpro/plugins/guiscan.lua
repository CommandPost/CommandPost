local log					= require("hs.logger").new("guiscan")

local dialog				= require("cp.dialog")
local fcp					= require("cp.apple.finalcutpro")
local plugins				= require("cp.apple.finalcutpro.plugins")
local just					= require("cp.just")

local insert, remove		= table.insert, table.remove

local mod = {}

-- scanVideoEffects() -> table
-- Function
-- Scans the list of video effects in the FCPX GUI and returns it as a list.
--
-- Parameters:
-- * None
--
-- Returns:
-- * The table of video effect names, or `nil` if there was a problem.
local function scanVideoEffects()

	--------------------------------------------------------------------------------
	-- Make sure Final Cut Pro is active:
	--------------------------------------------------------------------------------
	fcp:launch()

	--------------------------------------------------------------------------------
	-- Make sure Effects panel is open:
	--------------------------------------------------------------------------------
	local effects = fcp:effects()
	local effectsShowing = effects:isShowing()
	if not effects:show():isShowing() then
		dialog.displayErrorMessage("Unable to activate the Effects panel.")
		return nil
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
		dialog.displayErrorMessage("Unable to activate the Effects sidebar.")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Click 'All Video':
	--------------------------------------------------------------------------------
	if not effects:showAllVideoEffects() then
		dialog.displayErrorMessage("Unable to select all video effects.")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Get list of All Video Effects:
	--------------------------------------------------------------------------------
	local effectsList = effects:getCurrentTitles()
	if not effectsList then
		dialog.displayErrorMessage("Unable to get list of all effects.")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Restore Effects:
	--------------------------------------------------------------------------------
	effects:loadLayout(effectsLayout)
	if not effectsShowing then effects:hide() end

	--------------------------------------------------------------------------------
	-- All done!
	--------------------------------------------------------------------------------
	if #effectsList == 0 then
		dialog.displayMessage(i18n("updateEffectsListFailed") .. "\n\n" .. i18n("pleaseTryAgain"))
		return nil
	else
		return effectsList
	end
end

-- scanAudioEffects() -> table
-- Function
-- Scans the list of audio effects in the FCPX GUI and returns it as a list.
--
-- Parameters:
-- * None
--
-- Returns:
-- * The table of audio effect names, or `nil` if there was a problem.
local function scanAudioEffects()

	--------------------------------------------------------------------------------
	-- Make sure Final Cut Pro is active:
	--------------------------------------------------------------------------------
	fcp:launch()

	--------------------------------------------------------------------------------
	-- Make sure Effects panel is open:
	--------------------------------------------------------------------------------
	local effects = fcp:effects()
	local effectsShowing = effects:isShowing()
	if not effects:show():isShowing() then
		dialog.displayErrorMessage("Unable to activate the Effects panel.")
		return nil
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
		dialog.displayErrorMessage("Unable to activate the Effects sidebar.")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Click 'All Audio':
	--------------------------------------------------------------------------------
	if not effects:showAllAudioEffects() then
		dialog.displayErrorMessage("Unable to select all audio effects.")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Get list of All Video Effects:
	--------------------------------------------------------------------------------
	local effectsList = effects:getCurrentTitles()
	if not effectsList then
		dialog.displayErrorMessage("Unable to get list of all effects.")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Restore Effects:
	--------------------------------------------------------------------------------
	effects:loadLayout(effectsLayout)
	if not effectsShowing then effects:hide() end

	--------------------------------------------------------------------------------
	-- All done!
	--------------------------------------------------------------------------------
	if #effectsList == 0 then
		dialog.displayMessage(i18n("updateEffectsListFailed") .. "\n\n" .. i18n("pleaseTryAgain"))
		return nil
	else
		return effectsList
	end
end

-- scanTransitions() -> table
-- Function
-- Scans the list of transitions in the FCPX GUI and returns it as a list.
--
-- Parameters:
-- * None
--
-- Returns:
-- * The table of transition names, or `nil` if there was a problem.
local function scanTransitions()

	--------------------------------------------------------------------------------
	-- Make sure Final Cut Pro is active:
	--------------------------------------------------------------------------------
	fcp:launch()

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
		dialog.displayErrorMessage("Unable to activate the Transitions panel.")
		return nil
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
		dialog.displayErrorMessage("Unable to activate the Transitions sidebar.")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Click 'All' in the sidebar:
	--------------------------------------------------------------------------------
	transitions:showAllTransitions()

	--------------------------------------------------------------------------------
	-- Get list of All Transitions:
	--------------------------------------------------------------------------------
	local allTransitions = transitions:getCurrentTitles()

	--------------------------------------------------------------------------------
	-- Restore Effects and Transitions Panels:
	--------------------------------------------------------------------------------
	transitions:loadLayout(transitionsLayout)
	if effectsLayout then effects:loadLayout(effectsLayout) end
	if not transitionsShowing then transitions:hide() end

	--------------------------------------------------------------------------------
	-- Return results:
	--------------------------------------------------------------------------------
	return  allTransitions
end

--------------------------------------------------------------------------------
-- GET LIST OF GENERATORS:
--------------------------------------------------------------------------------
local function scanGenerators()

	--------------------------------------------------------------------------------
	-- Make sure Final Cut Pro is active:
	--------------------------------------------------------------------------------
	fcp:launch()

	local generators = fcp:generators()

	local browserLayout = fcp:browser():saveLayout()

	--------------------------------------------------------------------------------
	-- Make sure Generators and Generators panel is open:
	--------------------------------------------------------------------------------
	if not generators:show():isShowing() then
		dialog.displayErrorMessage("Unable to activate the Generators and Generators panel.")
		return nil
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
		dialog.displayErrorMessage("Unable to get list of all generators.")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Restore Effects or Transitions Panel:
	--------------------------------------------------------------------------------
	fcp:browser():loadLayout(browserLayout)

	--------------------------------------------------------------------------------
	-- Return the results:
	--------------------------------------------------------------------------------
	return allGenerators
end

local function scanTitles()

	--------------------------------------------------------------------------------
	-- Make sure Final Cut Pro is active:
	--------------------------------------------------------------------------------
	fcp:launch()

	local generators = fcp:generators()

	local browserLayout = fcp:browser():saveLayout()

	--------------------------------------------------------------------------------
	-- Make sure Titles and Generators panel is open:
	--------------------------------------------------------------------------------
	if not generators:show():isShowing() then
		dialog.displayErrorMessage("Unable to activate the Titles and Generators panel.")
		return nil
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
		dialog.displayErrorMessage("Unable to get list of all titles.")
		return nil
	end

	--------------------------------------------------------------------------------
	-- Restore Effects or Transitions Panel:
	--------------------------------------------------------------------------------
	fcp:browser():loadLayout(browserLayout)

	return allTitles
end

-- cp.apple.finalcutpro.plugins.guiscan.check([language]) -> none
-- Function
-- Compares the list of plugins created via file scanning to that produced by GUI scanning.
-- A detailed report is output in the Error Log.
--
-- Parameters:
--  * `language`	- The language to scan in. Defaults the the current FCPX language.
--
-- Returns:
--  * `true` if all plugins match.
function mod.check(language)

	language = language or fcp:currentLanguage()

	fcp.currentLanguage:set(language)
	fcp:launch()
	just.doUntil(function() return fcp:isFrontmost() end, 20, 0.1)

	--------------------------------------------------------------------------------
	-- Debug Message:
	--------------------------------------------------------------------------------
	log.df("---------------------------------------------------------")
	log.df(" COMPARING PLUGIN FILE SCAN RESULTS TO GUI SCAN RESULTS:")
	log.df("---------------------------------------------------------\n")

	--------------------------------------------------------------------------------
	-- Plugin Types:
	--------------------------------------------------------------------------------
	local pluginScanners = {
		[plugins.types.audioEffect] = scanAudioEffects,
		[plugins.types.videoEffect] = scanVideoEffects,
		[plugins.types.transition]	= scanTransitions,
		[plugins.types.generator]	= scanGenerators,
		[plugins.types.title]		= scanTitles,
	}

	--------------------------------------------------------------------------------
	-- Begin Scan:
	--------------------------------------------------------------------------------
	--------------------------------------------------------------------------------
	-- Debug Message:
	--------------------------------------------------------------------------------
	log.df("---------------------------------------------------------")
	log.df(" CHECKING LANGUAGE: %s", language)
	log.df("---------------------------------------------------------")

	local failed = false

	for newType,scanner in pairs(pluginScanners) do
		--------------------------------------------------------------------------------
		-- Get settings from GUI Scripting Results:
		--------------------------------------------------------------------------------
		local oldPlugins = scanner(language)

		if oldPlugins then

			--------------------------------------------------------------------------------
			-- Debug Message:
			--------------------------------------------------------------------------------
			log.df("  - Checking Plugin Type: %s", newType)

			local newPlugins = fcp:plugins():ofType(newType, language)
			local newPluginNames = {}
			if newPlugins then
				for _,plugin in ipairs(newPlugins) do
					local name = plugin.name
					local plugins = newPluginNames[name]
					local unmatched = nil
					if not plugins then
						plugins = {
							matched = {},
							unmatched = {},
							partials = {},
						}
						newPluginNames[name] = plugins
					end
					insert(plugins.unmatched, plugin)
				end
			end

			--------------------------------------------------------------------------------
			-- Compare Results:
			--------------------------------------------------------------------------------
			local errorCount = 0
			for _, oldFullName in pairs(oldPlugins) do
				local oldTheme, oldName = string.match(oldFullName, "^(.-) %- (.+)$")
				oldName = oldName or oldFullName
				local newPlugins = newPluginNames[oldFullName] or newPluginNames[oldName]
				if not newPlugins then
					log.df("  - ERROR: Missing %s: %s", oldType, oldFullName)
					errorCount = errorCount + 1
				else
					local unmatched = newPlugins.unmatched
					local found = false
					for i,plugin in ipairs(unmatched) do
						-- log.df("  - INFO:  Checking plugin: %s (%s)", plugin.name, plugin.theme)
						if plugin.theme == oldTheme then
							-- log.df("  - INFO:  Exact match for plugin: %s (%s)", oldName, oldTheme)
							insert(newPlugins.matched, plugin)
							remove(unmatched, i)
							found = true
							break
						end
					end
					if not found then
						-- log.df("  - INFO:  Partial for '%s' plugin.", oldFullName)
						insert(newPlugins.partials, oldFullName)
					end
				end
			end

			for newName, plugins in pairs(newPluginNames) do
				if #plugins.partials ~= #plugins.unmatched then
					for _,oldFullName in ipairs(plugins.partials) do
						log.df("  - ERROR: GUI Scan %s plugin unmatched: %s", newType, oldFullName)
						errorCount = errorCount + 1
					end

					for _,plugin in ipairs(plugins.unmatched) do
						local newFullName = plugin.name
						if plugin.theme then
							newFullName = plugin.theme .." - "..newFullName
						end
						log.df("  - ERROR: File Scan %s plugin unmatched: %s\n\t\t%s", newType, newFullName, plugin.path)
						errorCount = errorCount + 1
					end
				end
			end

			--------------------------------------------------------------------------------
			-- If all results matched:
			--------------------------------------------------------------------------------
			if errorCount == 0 then
				log.df("  - SUCCESS: %s all matched!\n", newType)
			else
				log.df("  - ERROR: %s had %d errors!\n", newType, errorCount)
			end
			failed = failed or (errorCount ~= 0)
		else
			log.df(" - SKIPPING: Could not find settings for: %s (%s)", newType, language)
		end
	end

	return not failed
end

function mod.checkAll()
	local failed = false
	for _,language in ipairs(fcp:getSupportedLanguages()) do
		failed = failed or not mod.check(language)
	end
	return not failed
end

return mod