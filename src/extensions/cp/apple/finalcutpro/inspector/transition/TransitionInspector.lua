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
local section, popUpButton              = IP.section, IP.popUpButton

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
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

return TransitionInspector
