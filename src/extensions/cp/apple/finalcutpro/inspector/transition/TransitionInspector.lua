--- === cp.apple.finalcutpro.inspector.transition.TransitionInspector ===
---
--- Transition Inspector Module.

local require = require

--local log								= require("hs.logger").new("transInspect")

local axutils                           = require("cp.ui.axutils")

local strings                           = require("cp.apple.finalcutpro.strings")
local BasePanel                         = require("cp.apple.finalcutpro.inspector.BasePanel")
local IP                                = require("cp.apple.finalcutpro.inspector.InspectorProperty")

local withRole, childWithRole           = axutils.withRole, axutils.childWithRole
local childMatching, withValue          = axutils.childMatching, axutils.withValue
local cache                             = axutils.cache


local hasProperties                     = IP.hasProperties
local popUpButton                       = IP.popUpButton
local section                           = IP.section
local slider                            = IP.slider


local TransitionInspector = BasePanel:subclass("cp.apple.finalcutpro.inspector.transition.TransitionInspector")

local function findContentUI(element)
    local root = BasePanel.matches(element) and withRole(element, "AXGroup")
    local group = root and #root == 1 and childWithRole(root, "AXGroup")
    return group and #group == 1 and childWithRole(group, "AXScrollArea") or nil
end

local function isAudioCrossfade(element)
    return withRole(element, "AXStaticText") ~= nil and withValue(element, strings:find("FFAudioTransitionEffect")) ~= nil
end

local function findAudioCrossfade(contentUI)
    return contentUI and childMatching(contentUI, isAudioCrossfade)
end

--- cp.apple.finalcutpro.inspector.transition.TransitionInspector.matches(element)
--- Function
--- Checks if the element is the `TransitionInspector`
---
--- Parameters:
--- * element   - The element to check
---
--- Returns:
--- * `true` if the element is a match, otherwise `false`.
function TransitionInspector.static.matches(element)
    local contentUI = findContentUI(element)
    return findAudioCrossfade(contentUI) ~= nil
end

--- cp.apple.finalcutpro.inspector.transition.TransitionInspector(parent) -> TransitionInspector
--- Constructor
--- Creates a new `TransitionInspector` object.
---
--- Parameters:
---  * parent - The parent
---
--- Returns:
---  * A `TransitionInspector` object
function TransitionInspector:initialize(parent)
    BasePanel.initialize(self, parent, "Transition")
    hasProperties(self, self.contentUI) {
        crossDissolve           = section "CrossDissolve::Filter Name" {
            look                    = popUpButton "CrossDissolve::Look",
            amount                  = slider "CrossDissolve::Amount",
            ease                    = popUpButton "Transition::Ease Type",
            easeAmount              = slider "Transition::Ease Amount",
        },
        audioCrossfade          = section "FFAudioTransitionEffect" {
            fadeInType              = popUpButton "FFAudioTransitionFadeInType",
            fadeOutType             = popUpButton "FFAudioTransitionFadeOutType",
        }
    }
end

function TransitionInspector.lazy.prop:contentUI()
    return self.UI:mutate(function(original)
        return cache(self, "_content", function()
            return findContentUI(original())
        end)
    end)
end

--- cp.apple.finalcutpro.inspector.transition.TransitionInspector.LOOKS -> table
--- Constant
--- Cross Dissolve Looks
TransitionInspector.LOOKS = {
    [1]     = {flexoID = "CrossDissolve::Film", i18n = "film"},
    [2]     = {flexoID = "CrossDissolve::Bright", i18n = "bright"},
    [3]     = {flexoID = "CrossDissolve::Dark", i18n = "dark"},
    [4]     = {flexoID = "CrossDissolve::Cold", i18n = "cold"},
    [5]     = {flexoID = "CrossDissolve::Warm", i18n = "warm"},
    [6]     = {flexoID = "CrossDissolve::Sharp", i18n = "sharp"},
    [7]     = {flexoID = "CrossDissolve::Dull", i18n = "dull"},
    [8]     = {flexoID = "CrossDissolve::Additive", i18n = "additive"},
    [9]     = {flexoID = "CrossDissolve::Subtractive", i18n = "subtractive"},
    [10]    = {flexoID = "CrossDissolve::Highlights", i18n = "highlights"},
    [11]    = {flexoID = "CrossDissolve::Shadows", i18n = "shadows"},
    [12]    = {flexoID = "CrossDissolve::Video", i18n = "video"},
}

--- cp.apple.finalcutpro.inspector.transition.TransitionInspector.EASE -> table
--- Constant
--- Ease Types
TransitionInspector.EASE_TYPES = {
    [1]     = {flexoID = "Transition::Ease In", i18n = "in"},
    [2]     = {flexoID = "Transition::Ease Out", i18n = "out"},
    [3]     = {flexoID = "Transition::Ease In Out", i18n = "inAndOut"},
}

--- cp.apple.finalcutpro.inspector.transition.TransitionInspector.FADE_TYPES -> table
--- Constant
--- Fade Types
TransitionInspector.FADE_TYPES = {
    [1]     = {flexoID = "FFAudioFadeTypeLinear", i18n = "linear"},
    [2]     = {flexoID = "FFAudioFadeTypePlusThreeDecibels", i18n = "plusThreeDb"},
    [3]     = {flexoID = "FFAudioFadeTypeMinusThreeDecibels", i18n = "minusThreeDb"},
    [4]     = {flexoID = "FFAudioFadeTypeSCurve", i18n = "sCurve"},
}

return TransitionInspector
