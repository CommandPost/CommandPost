--- === plugins.finalcutpro.timeline.transitions ===
---
--- Controls Final Cut Pro's Transitions.

local require           = require
--local log               = require "hs.logger".new "transitions"

local eventtap          = require "hs.eventtap"
local pasteboard        = require "hs.pasteboard"
local timer             = require "hs.timer"

local dialog            = require "cp.dialog"
local fcp               = require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"
local just              = require "cp.just"

local semver            = require "semver"

local doAfter           = timer.doAfter
local doUntil           = just.doUntil

local mod = {}

--- plugins.finalcutpro.timeline.transitions(action) -> boolean
--- Function
--- Applies the specified action as a transition.
---
--- Parameters:
---  * `action`     - A table with the name/category/theme for the transition to apply, or a string with just the name.
---
--- Returns:
---  * `true` if a matching transition was found and applied to the timeline.
---
--- Notes:
---  * Expects action to be a table with the following structure:
---
--- ```lua
--- { name = "XXX", category = "YYY", theme = "ZZZ" }
--- ```
---
--- ...where `"XXX"`, `"YYY"` and `"ZZZ"` are in the current FCPX language. The `category` and `theme` are optional,
--- but if they are known it's recommended to use them, or it will simply execute the first matching transition with that name.
---
--- Alternatively, you can also supply a string with just the name.
function mod.apply(action)

    --------------------------------------------------------------------------------
    -- Get settings:
    --------------------------------------------------------------------------------
    if type(action) == "string" then
        action = { name = action }
    end

    local name, category = action.name, action.category

    if name == nil then
        dialog.displayMessage(i18n("noPluginShortcut", {plugin = i18n("transition_group")}))
        return false
    end

    --------------------------------------------------------------------------------
    -- Save the Effects Browser layout:
    --------------------------------------------------------------------------------
    local effects = fcp.effects
    local effectsLayout = effects:saveLayout()

    --------------------------------------------------------------------------------
    -- Get Transitions Browser:
    --------------------------------------------------------------------------------
    local transitions = fcp.transitions
    local transitionsShowing = transitions:isShowing()
    local transitionsLayout = transitions:saveLayout()

    --------------------------------------------------------------------------------
    -- Make sure FCPX is at the front.
    --------------------------------------------------------------------------------
    fcp:launch()

    --------------------------------------------------------------------------------
    -- Make sure panel is open:
    --------------------------------------------------------------------------------
    transitions:show()

    --------------------------------------------------------------------------------
    -- Make sure "Installed Transitions" or "Transitions" (in FCP v12 and later)
    -- is selected:
    --------------------------------------------------------------------------------
    local transitionsText
    if fcp:isFinalCutPro12OrLater() then
        transitionsText = fcp:string("FFEffectsBrowserInstalledMotionTemplatesTransitions")
    else
        transitionsText = fcp:string("PEMediaBrowserInstalledEffectsMenuItem")
    end
    local group = effects.group:UI()
    if group then
        local groupValue = group:attributeValue("AXValue")
        if groupValue and transitionsText and groupValue ~= transitionsText then
            effects:showInstalledEffects()
        end
    end

    --------------------------------------------------------------------------------
    -- Get original search value:
    --------------------------------------------------------------------------------
    local originalSearch = transitions.search:value()

    --------------------------------------------------------------------------------
    -- Make sure there's nothing in the search box:
    --------------------------------------------------------------------------------
    local fcpVersion = fcp:version()
    if fcpVersion >= semver("12.3.0") then
        transitions.searchClearButton:press()
    else
        transitions.search:clear()
    end


    --------------------------------------------------------------------------------
    -- Click 'All':
    --------------------------------------------------------------------------------
    if category then
        transitions:showTransitionsCategory(category)
    else
        transitions:showAllTransitions()
    end

    --------------------------------------------------------------------------------
    -- Perform Search:
    --------------------------------------------------------------------------------
    if fcpVersion >= semver("12.3.0") then
        transitions.search:focus()

        local originalPasteboard = pasteboard.readAllData()

        pasteboard.setContents(name)

        if not fcp:selectMenu({"Edit", "Paste"}) then
            dialog.displayErrorMessage("Failed to paste Effect name into Search field.")
            return false
        end

        if not doUntil(function()
            return transitions.search.value() == name
        end, 3) then
            dialog.displayErrorMessage("Failed to update the Search field via the Pasteboard.")
            return false
        end

        ---------------------------------------------------------
        -- Restore the original pasteboard value:
        ---------------------------------------------------------
        if originalPasteboard then
            pasteboard.writeAllData(originalPasteboard)
        end

    else
        transitions.search:setValue(name)
    end

    --------------------------------------------------------------------------------
    -- Get the list of matching transitions:
    --------------------------------------------------------------------------------
    local matches = transitions:currentItemsUI()
    if not matches or #matches == 0 then
        dialog.displayErrorMessage(i18n("noPluginFound", {plugin=i18n("transition_group"), name=name}))
        return false
    end

    --------------------------------------------------------------------------------
    -- Take into account the Theme if needed:
    --------------------------------------------------------------------------------
    local transition = matches[1]
    if action.theme and action.theme ~= "" then
        local requestedTitle = action.theme .. " - " .. action.name
        if #matches > 1 then
            for _, ui in pairs(matches) do
                local title = ui:attributeValue("AXTitle")
                if title == requestedTitle then
                    transition = ui
                    break
                end
            end
        end
    end

    --------------------------------------------------------------------------------
    -- Apply the selected Transition:
    --------------------------------------------------------------------------------
    transitions:applyItem(transition)

    -- TODO: HACK: This timer exists to work around a mouse bug in Hammerspoon Sierra
    doAfter(0.1, function()
        if fcpVersion >= semver("12.3.0") then

            transitions.search:focus()

            if fcpVersion >= semver("12.3.0") then
                transitions.searchClearButton:press()
            else
                transitions.search:clear()
            end

            local originalPasteboard = pasteboard.readAllData()
            pasteboard.setContents(originalSearch)

            if not fcp:selectMenu({"Edit", "Paste"}) then
                dialog.displayErrorMessage("Failed to paste Effect name into Search field.")
                return false
            end

            if not doUntil(function()
                return transitions.search.value() == originalSearch
            end, 3) then
                dialog.displayErrorMessage("Failed to update the Search field via the Pasteboard.")
                return false
            end

            ---------------------------------------------------------
            -- Restore the original pasteboard value:
            ---------------------------------------------------------
            if originalPasteboard then
                pasteboard.writeAllData(originalPasteboard)
            end
        else
            transitions.search:setValue(originalSearch)
        end

        transitions:loadLayout(transitionsLayout)
        if effectsLayout then effects:loadLayout(effectsLayout) end
        if not transitionsShowing then transitions:hide() end
    end)

    -- Success!
    return true
end


local plugin = {
    id = "finalcutpro.timeline.transitions",
    group = "finalcutpro",
    dependencies = {
    }
}

function plugin.init()
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    return mod
end

return plugin
