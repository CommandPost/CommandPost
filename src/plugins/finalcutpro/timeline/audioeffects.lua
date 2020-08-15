--- === plugins.finalcutpro.timeline.audioeffects ===
---
--- Controls Final Cut Pro's Audio Effects.

local require = require

local log				= require "hs.logger".new "audiofx"

local timer				= require "hs.timer"

local dialog            = require "cp.dialog"
local fcp				= require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"

local doAfter           = timer.doAfter

local mod = {}

--- plugins.finalcutpro.timeline.audioeffects(action) -> boolean
--- Function
--- Applies the specified action as a audio effect. Expects action to be a table with the following structure:
---
--- ```lua
--- { name = "XXX", category = "YYY", theme = "ZZZ" }
--- ```
---
--- ...where `"XXX"`, `"YYY"` and `"ZZZ"` are in the current FCPX language. The `category` and `theme` are optional,
--- but if they are known it's recommended to use them, or it will simply execute the first matching audio effect with that name.
---
--- Alternatively, you can also supply a string with just the name.
---
--- Parameters:
---  * `action`		- A table with the name/category/theme for the audio effect to apply, or a string with just the name.
---
--- Returns:
---  * `true` if a matching audio effect was found and applied to the timeline.
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
    -- Make sure "Installed Effects" is selected:
    --------------------------------------------------------------------------------
    local group = effects:group():UI()
    if group then
        local groupValue = group:attributeValue("AXValue")
        if groupValue ~= fcp:string("PEMediaBrowserInstalledEffectsMenuItem") then
            effects:showInstalledEffects()
        end
    else
        log.ef("Failed to find Effects Group UI.")
    end

    --------------------------------------------------------------------------------
    -- Make sure there's nothing in the search box:
    --------------------------------------------------------------------------------
    effects:search():clear()

    --------------------------------------------------------------------------------
    -- Click 'All':
    --------------------------------------------------------------------------------
    if category then
        --log.df("Showing audio category '%s'", category)
        effects:showAudioCategory(category)
    else
        --log.df("Showing all audio categories")
        effects:showAllAudioEffects()
    end

    --------------------------------------------------------------------------------
    -- Perform Search:
    --------------------------------------------------------------------------------
    effects:search():setValue(name)

    --------------------------------------------------------------------------------
    -- Get the list of matching effects:
    --------------------------------------------------------------------------------
    local matches = effects:currentItemsUI()
    if not matches or #matches == 0 then
        dialog.displayErrorMessage("Unable to find an audio effect called '"..name.."'.")
        return false
    end

    local effect = matches[1]

    --------------------------------------------------------------------------------
    -- Apply the selected Transition:
    --------------------------------------------------------------------------------
    effects:applyItem(effect)

    --------------------------------------------------------------------------------
    -- TODO: HACK: This timer exists to  work around a mouse bug in
    --       Hammerspoon Sierra
    --------------------------------------------------------------------------------
    doAfter(0.1, function()
        effects:loadLayout(effectsLayout)
        if transitionsLayout then transitions:loadLayout(transitionsLayout) end
        if not effectsShowing then effects:hide() end
    end)

    --------------------------------------------------------------------------------
    -- Success:
    --------------------------------------------------------------------------------
    return true
end

local plugin = {
    id = "finalcutpro.timeline.audioeffects",
    group = "finalcutpro",
    dependencies = {
    }
}

function plugin.init()
    return mod
end

return plugin
