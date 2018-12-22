--- === cp.apple.finalcutpro.plugins.guiscan ===
---
--- Final Cut Pro GUI Plugin Scanner.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log					= require("hs.logger").new("guiscan")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog				= require("cp.dialog")
local fcp					  = require("cp.apple.finalcutpro")
local plugins				= require("cp.apple.finalcutpro.plugins")
local just					= require("cp.just")
local i18n          = require("cp.i18n")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local insert, remove		= table.insert, table.remove
local format				    = string.format

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
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

-- cp.apple.finalcutpro.plugins.guiscan.check([locale]) -> boolean, string
-- Function
-- Compares the list of plugins created via file scanning to that produced by GUI scanning.
-- A detailed report is output in the Error Log.
--
-- Parameters:
--  * `language`	- The language to scan in. Defaults the the current FCPX language.
--
-- Returns:
--  * `true` if all plugins match.
--  * The text value of the report.
function mod.check(locale)

    locale = locale or fcp.app:currentLocale()

    local value = ""
    local function ln(str, ...) value = value .. format(str, ...) .. "\n" end

    fcp.app.currentLocale:set(locale)
    fcp:launch()
    just.doUntil(function() return fcp:isFrontmost() end, 20, 0.1)

    --------------------------------------------------------------------------------
    -- Debug Message:
    --------------------------------------------------------------------------------
    ln("\n---------------------------------------------------------")
    ln(" COMPARING PLUGIN FILE SCAN RESULTS TO GUI SCAN RESULTS:")
    ln("---------------------------------------------------------\n")

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
    ln("---------------------------------------------------------")
    ln(" CHECKING LANGUAGE: %s", locale.code)
    ln("---------------------------------------------------------")

    local failed = false

    for newType,scanner in pairs(pluginScanners) do
        --------------------------------------------------------------------------------
        -- Get settings from GUI Scripting Results:
        --------------------------------------------------------------------------------
        local oldPlugins = scanner()

        if oldPlugins then

            --------------------------------------------------------------------------------
            -- Debug Message:
            --------------------------------------------------------------------------------
            ln("  - Checking Plugin Type: %s", newType)

            local newPlugins = fcp:plugins():ofType(newType, locale)
            local newPluginNames = {}
            if newPlugins then
                for _,plugin in ipairs(newPlugins) do
                    local name = plugin.name
                    local pluginNames = newPluginNames[name]
                    if not pluginNames then
                        pluginNames = {
                            matched = {},
                            unmatched = {},
                            partials = {},
                        }
                        newPluginNames[name] = pluginNames
                    end
                    --------------------------------------------------------------------------------
                    -- TODO: David - I'm not exactly sure what this line of code was designed to do?
                    --------------------------------------------------------------------------------
                    --insert(plugins.unmatched, plugin)
                end
            end

            --------------------------------------------------------------------------------
            -- Compare Results:
            --------------------------------------------------------------------------------
            local errorCount = 0
            for _, oldFullName in pairs(oldPlugins) do
                local oldTheme, oldName = string.match(oldFullName, "^(.-) %- (.+)$")
                oldName = oldName or oldFullName
                local np = newPluginNames[oldFullName] or newPluginNames[oldName]
                if not np then
                    ln("  - ERROR: Missing %s: %s", newType, oldFullName)
                    errorCount = errorCount + 1
                else
                    local unmatched = np.unmatched
                    local found = false
                    for i,plugin in ipairs(unmatched) do
                        -- ln("  - INFO:  Checking plugin: %s (%s)", plugin.name, plugin.theme)
                        if plugin.theme == oldTheme then
                            -- ln("  - INFO:  Exact match for plugin: %s (%s)", oldName, oldTheme)
                            insert(np.matched, plugin)
                            remove(unmatched, i)
                            found = true
                            break
                        end
                    end
                    if not found then
                        -- ln("  - INFO:  Partial for '%s' plugin.", oldFullName)
                        insert(np.partials, oldFullName)
                    end
                end
            end

            for _, np in pairs(newPluginNames) do
                if #np.partials ~= #np.unmatched then
                    for _,oldFullName in ipairs(np.partials) do
                        ln("  - ERROR: GUI Scan %s plugin unmatched: %s", newType, oldFullName)
                        errorCount = errorCount + 1
                    end

                    for _,plugin in ipairs(np.unmatched) do
                        local newFullName = plugin.name
                        if plugin.theme then
                            newFullName = plugin.theme .." - "..newFullName
                        end
                        ln("  - ERROR: File Scan %s plugin unmatched: %s\n\t\t%s", newType, newFullName, plugin.path)
                        errorCount = errorCount + 1
                    end
                end
            end

            --------------------------------------------------------------------------------
            -- If all results matched:
            --------------------------------------------------------------------------------
            if errorCount == 0 then
                ln("  - SUCCESS: %s all matched!\n", newType)
            else
                ln("  - ERROR: %s had %d errors!\n", newType, errorCount)
            end
            failed = failed or (errorCount ~= 0)
        else
            ln(" - SKIPPING: Could not find settings for: %s (%s)", newType, locale.code)
        end
    end

    return not failed, value
end

function mod.checkAll()
    local failed, value = false, ""
    for _,locale in ipairs(fcp.app:getSupportedLocales()) do
        local ok, result = mod.check(locale)
        failed = failed or not ok
        value = value .. result .. "\n"
    end
    return not failed, value
end

return mod
