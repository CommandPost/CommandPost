--- === plugins.finalcutpro.timeline.audioeffects ===
---
--- Controls Final Cut Pro's Audio Effects.

local require = require

-- local log				= require "hs.logger".new "audiofx"

local dialog            = require "cp.dialog"
local fcp				= require "cp.apple.finalcutpro"
local i18n              = require "cp.i18n"

local go                = require "cp.rx.go"
local Do                = go.Do

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

    --------------------------------------------------------------------------------
    -- Make sure FCPX is at the front.
    --------------------------------------------------------------------------------
    fcp:launch()

    --------------------------------------------------------------------------------
    -- Make sure panel is open:
    --------------------------------------------------------------------------------
    effects:show()

    local effectsLayout = effects:saveLayout()

    --------------------------------------------------------------------------------
    -- Make sure "Installed Effects" is selected:
    --------------------------------------------------------------------------------
    effects.group:doSelectValue(fcp:string("PEMediaBrowserInstalledEffectsMenuItem")):Now()

    --------------------------------------------------------------------------------
    -- Get original search value:
    --------------------------------------------------------------------------------
    local originalSearch = effects.search:value()

    --------------------------------------------------------------------------------
    -- Make sure there's nothing in the search box:
    --------------------------------------------------------------------------------
    effects.search:clear()

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
    effects.search.value:set(name)

    --------------------------------------------------------------------------------
    -- Get the list of matching effects:
    --------------------------------------------------------------------------------
    local effect = effects.childrenInNavigationOrder[1]
    if not effect then
        dialog.displayErrorMessage("Unable to find an audio effect called '"..name.."'.")
        return false
    end

    --------------------------------------------------------------------------------
    -- Apply the selected Transition:
    --------------------------------------------------------------------------------
    Do(effect:doApply())
    :Then(function()
        effects.search.value:set(originalSearch)
        effects:loadLayout(effectsLayout)
        if transitionsLayout then transitions:loadLayout(transitionsLayout) end
        if not effectsShowing then effects:hide() end
    end)
    :Now()


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
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    return mod
end

return plugin
