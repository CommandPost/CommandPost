--- === cp.apple.finalcutpro.inspector.color.HueSaturationCurves ===
---
--- Color Curves Module.
---
--- Requires Final Cut Pro 10.4 or later.

--------------------------------------------------------------------------------
-- TODO:
--  * Add API to trigger Color Picker for Individual Curves
--  * Add API for "Save Effects Preset".
--  * Add API for "Mask Inside/Output".
--  * Add API for "View Masks".
--------------------------------------------------------------------------------

local require = require

-- local log                               = require("hs.logger").new("colorCurves")

local prop                              = require("cp.prop")
local tools                             = require("cp.tools")

local axutils                           = require("cp.ui.axutils")
local Element                           = require("cp.ui.Element")
local MenuButton                        = require("cp.ui.MenuButton")
local PropertyRow						= require("cp.ui.PropertyRow")
local RadioGroup						= require("cp.ui.RadioGroup")
local Slider							= require("cp.ui.Slider")
local TextField                         = require("cp.ui.TextField")

local If                                = require("cp.rx.go.If")

local HueSaturationCurve                = require("cp.apple.finalcutpro.inspector.color.HueSaturationCurve")

local cache, childMatching              = axutils.cache, axutils.childMatching

local toRegionalNumber                  = tools.toRegionalNumber
local toRegionalNumberString            = tools.toRegionalNumberString

local CORRECTION_TYPE                   = "Hue/Saturation Curves"

local HueSaturationCurves = Element:subclass("cp.apple.finalcutpro.inspector.color.HueSaturationCurves")

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves.matches(element)
--- Function
--- Checks if the specified element is the Color Curves element.
---
--- Parameters:
--- * element	- The element to check
---
--- Returns:
--- * `true` if the element is the Color Curves.
function HueSaturationCurves.static.matches(element)
    if Element.matches(element) and element:attributeValue("AXRole") == "AXGroup"
    and #element == 1 and element[1]:attributeValue("AXRole") == "AXGroup"
    and #element[1] == 1 and element[1][1]:attributeValue("AXRole") == "AXScrollArea" then
        local scroll = element[1][1]
        return childMatching(scroll, HueSaturationCurve.matches) ~= nil
    end
    return false
end

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves(parent) -> HueSaturationCurves object
--- Constructor
--- Creates a new HueSaturationCurves object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A ColorInspector object
function HueSaturationCurves:initialize(parent)

    local UI = parent.correctorUI:mutate(function(original)
        return cache(self, "_ui", function()
            local ui = original()
            return HueSaturationCurves.matches(ui) and ui or nil
        end, HueSaturationCurves.matches)
    end)

    Element.initialize(self, parent, UI)

    PropertyRow.prepareParent(self, self.contentUI)

    -- NOTE: There is a bug in 10.4 where updating the slider alone doesn't update the temperature value.
    -- link these fields so they mirror each other.
    self.mixSlider.value:mirror(self.mixTextField.value)
end

--------------------------------------------------------------------------------
--
-- COLOR CURVES:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves:show() -> boolean
--- Method
--- Show's the Color Board within the Color Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * HueSaturationCurves object
function HueSaturationCurves:show()
    if not self:isShowing() then
        self:parent():activateCorrection(CORRECTION_TYPE)
    end
    return self
end

function HueSaturationCurves.lazy.method:doShow()
    return If(self.isShowing):Is(false):Then(
        self:parent():doActivateCorrection(CORRECTION_TYPE)
    ):Otherwise(true)
    :Label("HueSaturationCurves:doShow")
end

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves.contentUI <cp.prop: hs.axuielement; read-only>
--- Field
--- The `axuielement` representing the content element of the HueSaturationCurves corrector.
--- This contains all the individual UI elements of the corrector, and is typically an `AXScrollArea`.
function HueSaturationCurves.lazy.prop:contentUI()
    return self.UI:mutate(function(original)
        return cache(self, "_content", function()
            local ui = original()
            return ui and #ui == 1 and #ui[1] == 1 and ui[1][1] or nil
        end)
    end)
end

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves.viewModeButton <cp.ui.MenuButton>
--- Field
--- The [MenuButton](cp.ui.MenuButton.md) for the View Mode.
function HueSaturationCurves.lazy.value:viewModeButton()
    return MenuButton(self, function()
        local ui = self:contentUI()
        if ui then
            return childMatching(ui, MenuButton.matches)
        end
        return nil
    end)
end

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves.viewingAllCurves <cp.prop: boolean>
--- Field
--- Reports and modifies whether the corrector is showing "All Curves" (`true`) or "Single Curves" (`false`).
function HueSaturationCurves.lazy.prop:viewingAllCurves()
    return prop(
        function()
            local ui = self:contentUI()
            if ui then
                local curveOne = childMatching(ui, HueSaturationCurve.matches, 1)
                local curveTwo = childMatching(ui, HueSaturationCurve.matches, 2)
                local posOne = curveOne and curveOne:attributeValue("AXPosition")
                local posTwo = curveTwo and curveTwo:attributeValue("AXPosition")
                return posOne ~= nil and posTwo ~= nil and posOne.y ~= posTwo.y or false
            end
            return false
        end,
        function(allCurves, _, theProp)
            local current = theProp:get()
            if allCurves and not current then
                self.viewModeButton:selectItem(1)
            elseif not allCurves and current then
                self.viewModeButton:selectItem(2)
            end
        end
    ):monitor(self.contentUI)
end

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves.wheelType <RadioGroup>
--- Field
--- The `RadioGroup` that allows selection of the curve type. Only available when
--- [viewingAllCurves](#viewingAllCurves) is `true`.
function HueSaturationCurves.lazy.value:wheelType()
    return RadioGroup(self,
        function()
            if not self:viewingAllCurves() then
                local ui = self:contentUI()
                return ui and childMatching(ui, RadioGroup.matches) or nil
            end
            return nil
        end,
        false -- not cached
    )
end

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves.hueVsHue <HueSaturationCurve>
--- Field
--- A [HueSaturationCurve](cp.apple.finalcutpro.inspector.color.HueSaturationCurve.md)
--- that allows control of the 'HUE vs HUE' color settings.
function HueSaturationCurves.lazy.value:hueVsHue()
    return HueSaturationCurve(self, HueSaturationCurve.TYPE.HUE_VS_HUE)
end

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves.hueVsSat <HueSaturationCurve>
--- Field
--- A [HueSaturationCurve](cp.apple.finalcutpro.inspector.color.HueSaturationCurve.md)
--- that allows control of the 'HUE vs SAT' color settings.
function HueSaturationCurves.lazy.value:hueVsSat()
    return HueSaturationCurve(self, HueSaturationCurve.TYPE.HUE_VS_SAT)
end

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves.hueVsLuma <HueSaturationCurve>
--- Field
--- A [HueSaturationCurve](cp.apple.finalcutpro.inspector.color.HueSaturationCurve.md)
--- that allows control of the 'HUE vs LUMA' color settings.
function HueSaturationCurves.lazy.value:hueVsLuma()
    return HueSaturationCurve(self, HueSaturationCurve.TYPE.HUE_VS_LUMA)
end

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves.lumaVsSat <HueSaturationCurve>
--- Field
--- A [HueSaturationCurve](cp.apple.finalcutpro.inspector.color.HueSaturationCurve.md)
--- that allows control of the 'LUMA vs SAT' color settings.
function HueSaturationCurves.lazy.value:lumaVsSat()
    return HueSaturationCurve(self, HueSaturationCurve.TYPE.LUMA_VS_SAT)
end

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves.satVsSat <HueSaturationCurve>
--- Field
--- A [HueSaturationCurve](cp.apple.finalcutpro.inspector.color.HueSaturationCurve.md)
--- that allows control of the 'SAT vs SAT' color settings.
function HueSaturationCurves.lazy.value:satVsSat()
    return HueSaturationCurve(self, HueSaturationCurve.TYPE.SAT_VS_SAT)
end

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves.colorVsSat <HueSaturationCurve>
--- Field
--- A [HueSaturationCurve](cp.apple.finalcutpro.inspector.color.HueSaturationCurve.md)
--- that allows control of the '<COLOR> vs SAT' color settings. The color is variable, but typically
--- starts with 'ORANGE'.
function HueSaturationCurves.lazy.value:colorVsSat()
    return HueSaturationCurve(self, HueSaturationCurve.TYPE.COLOR_VS_SAT)
end

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves.mixRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the 'Mix' parameter, and `axuielement`
--- values for that row.
function HueSaturationCurves.lazy.value:mixRow()
    return PropertyRow(self, "FFChannelMixName")
end

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves.mixSlider <cp.ui.Slider>
--- Field
--- A `Slider` that provides access to the 'Mix' slider.
function HueSaturationCurves.lazy.value:mixSlider()
    return Slider(self,
        function()
            local ui = self.mixRow:children()
            return ui and childMatching(ui, Slider.matches)
        end
    )
end

function HueSaturationCurves.lazy.value:mixTextField()
    return TextField(self,
        function()
            local ui = self.mixRow:children()
            return ui and childMatching(ui, TextField.matches)
        end,
        toRegionalNumber, toRegionalNumberString
    )
end

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves.mix <cp.prop: number>
--- Field
--- The mix amount for this corrector. A number ranging from `0` to `1`.
function HueSaturationCurves.lazy.prop:mix()
    return self.mixSlider.value
end

return HueSaturationCurves
