--- === plugins.finalcutpro.timeline.videoeffects ===
---
--- Controls Final Cut Pro's Video Effects.

local require = require

local log				= require "hs.logger".new("VideoEffects")

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

--- plugins.finalcutpro.timeline.videoeffects(action) -> boolean
--- Function
--- Applies the specified action as a video effect.
---
--- Parameters:
---  * `action`     - A table with the name/category/theme for the video effect to apply, or a string with just the name.
---
--- Returns:
---  * `true` if a matching video effect was found and applied to the timeline.
---
--- Notes:
---  * Expects action to be a table with the following structure:
---
--- ```lua
--- { name = "XXX", category = "YYY", theme = "ZZZ" }
--- ```
---
--- ...where `"XXX"`, `"YYY"` and `"ZZZ"` are in the current FCPX language. The `category` and `theme` are optional,
--- but if they are known it's recommended to use them, or it will simply execute the first matching video effect with that name.
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
        dialog.displayMessage(i18n("noEffectShortcut"))
        return false
    end

    --------------------------------------------------------------------------------
    -- Save the Transitions Browser layout:
    --------------------------------------------------------------------------------
    local transitions = fcp.transitions
    local transitionsLayout = transitions:saveLayout()

    --------------------------------------------------------------------------------
    -- Get Effects Browser:
    --------------------------------------------------------------------------------
    local effects = fcp.effects
    local effectsShowing = effects:isShowing()
    local effectsLayout = effects:saveLayout()

    --------------------------------------------------------------------------------
    -- Make sure FCPX is at the front.
    --------------------------------------------------------------------------------
    fcp:launch()

    --------------------------------------------------------------------------------
    -- Make sure panel is open:
    --------------------------------------------------------------------------------
    effects:show()

    --------------------------------------------------------------------------------
    -- Make sure "Installed Effects" or "Effects" (in FCP v12 and later)
    -- is selected:
    --------------------------------------------------------------------------------
    local effectsText
    if fcp:isFinalCutPro12OrLater() then
        effectsText = fcp:string("FFEffectsBrowserInstalledMotionTemplatesEffects")
    else
        effectsText = fcp:string("PEMediaBrowserInstalledEffectsMenuItem")
    end
    local group = effects.group:UI()
    if group then
        local groupValue = group:attributeValue("AXValue")
        if groupValue and effectsText and groupValue ~= effectsText then
            effects:showInstalledEffects()
        end
    end

    --------------------------------------------------------------------------------
    -- Get original search value:
    --------------------------------------------------------------------------------
    local originalSearch = effects.search:value()

    --------------------------------------------------------------------------------
    -- Make sure there's nothing in the search box:
    --------------------------------------------------------------------------------
    local fcpVersion = fcp:version()
    if fcpVersion >= semver("12.3.0") then
        effects.searchClearButton:press()
    else
        effects.search:clear()
    end

    --------------------------------------------------------------------------------
    -- Click 'All':
    --------------------------------------------------------------------------------
    --log.df("category: %s", category)
    if category then
        effects:showVideoCategory(category)
    else
        effects:showAllVideoEffects()
    end

    --------------------------------------------------------------------------------
    -- Perform Search:
    --------------------------------------------------------------------------------
    if fcpVersion >= semver("12.3.0") then
        effects.search:focus()

        local originalPasteboard = pasteboard.readAllData()

        pasteboard.setContents(name)

        if not fcp:selectMenu({"Edit", "Paste"}) then
            dialog.displayErrorMessage("Failed to paste Effect name into Search field.")
            return false
        end

        if not doUntil(function()
            return effects.search.value() == name
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
        effects.search:setValue(name)
    end

    --------------------------------------------------------------------------------
    -- Get the list of matching effects:
    --------------------------------------------------------------------------------
    local matches = effects:currentItemsUI()
    if not matches or #matches == 0 then
        dialog.displayErrorMessage("Unable to find a video effect called '"..name.."'.")
        return false
    end

    local effect = matches[1]

    --------------------------------------------------------------------------------
    -- Apply the selected Effect:
    --------------------------------------------------------------------------------
    effects:applyItem(effect)

    -- TODO: HACK: This timer exists to  work around a mouse bug in Hammerspoon Sierra
    doAfter(0.1, function()
        if fcpVersion >= semver("12.3.0") then

            effects.search:focus()

            if fcpVersion >= semver("12.3.0") then
                effects.searchClearButton:press()
            else
                effects.search:clear()
            end

            local originalPasteboard = pasteboard.readAllData()
            pasteboard.setContents(originalSearch)

            if not fcp:selectMenu({"Edit", "Paste"}) then
                dialog.displayErrorMessage("Failed to paste Effect name into Search field.")
                return false
            end

            if not doUntil(function()
                return effects.search.value() == originalSearch
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
            effects.search:setValue(originalSearch)
        end
        effects:loadLayout(effectsLayout)
        if transitionsLayout then transitions:loadLayout(transitionsLayout) end
        if not effectsShowing then effects:hide() end
    end)

    -- Success!
    return true
end

local plugin = {
    id = "finalcutpro.timeline.videoeffects",
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
