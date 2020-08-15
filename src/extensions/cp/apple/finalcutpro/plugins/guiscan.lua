--- === cp.apple.finalcutpro.plugins.guiscan ===
---
--- Final Cut Pro GUI Plugin Scanner.
---
--- **Usage:**
--- ```lua
--- require("cp.apple.finalcutpro.plugins.guiscan").checkAllPlugins()
--- require("cp.apple.finalcutpro.plugins.guiscan").checkAllPluginsInAllLanguages()
--- ```

local require = require

local log                   = require("hs.logger").new("guiscan")

local dialog                = require("cp.dialog")
local fcp                   = require("cp.apple.finalcutpro")
local i18n                  = require("cp.i18n")
local plugins               = require("cp.apple.finalcutpro.plugins")


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
    fcp:launch(10)

    --------------------------------------------------------------------------------
    -- Make sure Effects panel is open:
    --------------------------------------------------------------------------------
    local effects = fcp.effects
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

    local sidebar = effects.sidebar

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
    fcp:launch(10)

    --------------------------------------------------------------------------------
    -- Make sure Effects panel is open:
    --------------------------------------------------------------------------------
    local effects = fcp.effects
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

    local sidebar = effects.sidebar

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
    fcp:launch(10)

    --------------------------------------------------------------------------------
    -- Save the layout of the Effects panel, in case we switch away...
    --------------------------------------------------------------------------------
    local effects = fcp.effects
    local effectsLayout = nil
    if effects:isShowing() then
        effectsLayout = effects:saveLayout()
    end

    --------------------------------------------------------------------------------
    -- Make sure Transitions panel is open:
    --------------------------------------------------------------------------------
    local transitions = fcp.transitions
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
    local sidebar = transitions.sidebar

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
    return allTransitions
end

-- scanGenerators() -> table
-- Function
-- Scans the list of generators in the FCPX GUI and returns it as a list.
--
-- Parameters:
-- * None
--
-- Returns:
-- * The table of generator names, or `nil` if there was a problem.
local function scanGenerators()

    --------------------------------------------------------------------------------
    -- Make sure Final Cut Pro is active:
    --------------------------------------------------------------------------------
    fcp:launch(10)

    local generators = fcp.generators

    local browserLayout = fcp.browser:saveLayout()

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
    local effectsList = generators.contents:childrenUI()
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
    fcp.browser:loadLayout(browserLayout)

    --------------------------------------------------------------------------------
    -- Return the results:
    --------------------------------------------------------------------------------
    return allGenerators
end

-- scanTitles() -> table
-- Function
-- Scans the list of titles in the FCPX GUI and returns it as a list.
--
-- Parameters:
-- * None
--
-- Returns:
-- * The table of titles names, or `nil` if there was a problem.
local function scanTitles()

    --------------------------------------------------------------------------------
    -- Make sure Final Cut Pro is active:
    --------------------------------------------------------------------------------
    fcp:launch(10)

    local generators = fcp.generators

    local browserLayout = fcp.browser:saveLayout()

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
    local effectsList = generators.contents:childrenUI()
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
    fcp.browser:loadLayout(browserLayout)

    return allTitles
end

-- cp.apple.finalcutpro.plugins.guiscan.checkAllPlugins([locale]) -> none
-- Function
-- Compares the list of plugins created via file scanning to that produced by GUI scanning.
-- A detailed report is output in the Error Log.
--
-- Parameters:
--  * language - The language to scan. Defaults to the current Final Cut Pro language.
--
-- Returns:
--  * None
function mod.checkAllPlugins(locale)
    locale = locale or fcp.app:currentLocale()

    fcp.app.currentLocale:set(locale)
    fcp:launch(10)

    local pluginScanners = {
        [plugins.types.audioEffect] = scanAudioEffects,
        [plugins.types.videoEffect] = scanVideoEffects,
        [plugins.types.transition]  = scanTransitions,
        [plugins.types.generator]   = scanGenerators,
        [plugins.types.title]       = scanTitles,
    }

    log.df("Comparing the GUI values to what we have in the Plugin Cache.")

    for newType, scanner in pairs(pluginScanners) do
        log.df(" - Scanning for '%s' in '%s'.", newType, locale.code)
        local oldPlugins = scanner()
        if oldPlugins then
            local newPlugins = fcp:plugins():ofType(newType, locale)
            for _, oldFullName in pairs(oldPlugins) do
                local found = false
                for _,plugin in ipairs(newPlugins) do
                    if plugin.name == oldFullName or
                    plugin.theme and (plugin.theme .. " - " .. plugin.name == oldFullName) or
                    --------------------------------------------------------------------------------
                    -- This is a workaround for some strange MotionVFX Plugins
                    -- (i.e. mFlare 2/SCI-FI/UFO Glimmer)
                    -- The theme is "SCI-FI", but it's labelled as "Sci-Fi" in Final Cut Pro's UI.
                    --------------------------------------------------------------------------------
                    plugin.theme and (plugin.theme:lower() .. " - " .. plugin.name:lower() == oldFullName:lower()) then
                        found = true
                    end
                end
                if not found then
                    log.df("   - Missing %s plugin: %s", newType, oldFullName)
                end
            end
        end
    end
    log.df("Scan complete!")
    hs.openConsole()
end

-- cp.apple.finalcutpro.plugins.guiscan.checkAllPluginsInAllLanguages() -> none
-- Function
-- Compares the list of plugins created via file scanning to that produced by GUI scanning.
-- A detailed report is output in the Error Log.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function mod.checkAllPluginsInAllLanguages()
    for _,locale in ipairs(fcp.app:supportedLocales()) do
        mod.checkAllPlugins(locale)
    end
end

return mod
