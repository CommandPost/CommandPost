--- === cp.apple.finalcutpro.inspector.color.HueSaturationCurve ===
---
--- A HueSaturationCurve [Element](cp.ui.Element.md).

local axutils                               = require("cp.ui.axutils")
local Element                               = require("cp.ui.Element")
local Button                                = require("cp.ui.Button")

local If                                    = require("cp.rx.go.If")

local childWithRole                         = axutils.childWithRole
local childMatching, childrenMatching       = axutils.childMatching, axutils.childrenMatching
local cache, childFromRight                 = axutils.cache, axutils.childFromRight

local ColorWell                             = require("cp.apple.finalcutpro.inspector.color.ColorWell")

local HueSaturationCurve = Element:subclass("cp.apple.finalcutpro.inspector.color.HueSaturationCurve")

HueSaturationCurve.static.TYPE = {
    HUE_VS_HUE = 1,
    HUE_VS_SAT = 2,
    HUE_VS_LUMA = 3,
    LUMA_VS_SAT = 4,
    SAT_VS_SAT = 5,
    COLOR_VS_SAT = 6,
}

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurve.matches(element) -> boolean
--- Function
--- Checks if the specified value is a `HueSaturationCurve`.
---
--- Parameters:
--- * element       - The `axuielement` to check.
---
--- Returns:
--- * `true` if it matches a HueSaturationCurve element.
function HueSaturationCurve.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXGroup"
        and #element == 5 and childWithRole(element, "AXList") ~= nil
        and childWithRole(element, "AXColorWell") ~= nil
end

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurve(parent, type) -> HueSaturationCurve
--- Constructor
--- Creates a new `HueSaturationCurve` [Element](cp.ui.Element.md).
---
--- Parameters:
--- * parent    - The parent `Element`.
--- * type     - The [TYPE](#TYPE) of curve.
---
--- Returns:
--- * The new `HueSaturationCurve`.
function HueSaturationCurve:initialize(parent, type)
    local UI = parent.contentUI:mutate(function(original)
        return cache(self, "_ui", function()
            local ui = original()
            if ui then
                if parent:viewingAllCurves() then
                    --------------------------------------------------------------------------------
                    -- All Wheels:
                    --------------------------------------------------------------------------------
                    return axutils.childFromTop(childrenMatching(ui, HueSaturationCurve.matches), self:type())
                elseif parent.wheelType:selectedOption() == self:type() then
                    --------------------------------------------------------------------------------
                    -- Single Wheels - with only a single wheel visible:
                    --------------------------------------------------------------------------------
                    return childMatching(ui, HueSaturationCurve.matches)
                end
            end
            return nil
        end, HueSaturationCurve.matches)
    end)

    Element.initialize(self, parent, UI)
    self._type = type
end

function HueSaturationCurve:type()
    return self._type
end

function HueSaturationCurve:show()
    local parent = self:parent()
    parent:show()
    parent.wheelType:selectedOption(self:type())
end

function HueSaturationCurve.lazy.method:doShow()
    local parent = self:parent()
    local wheelType = parent.wheelType
    return If(self.isShowing):Is(false):Then(
        parent:doShow()
    ):Then(
        If(wheelType.isShowing):Then(
            wheelType:doSelectOption(self:type())
        )
    ):Then(true)
    :Otherwise(true)
    :Label("HueSaturationCurve:doShow")
end

function HueSaturationCurve.lazy.value:reset()
    return Button(self, self.UI:mutate(function(original)
        return childFromRight(childrenMatching(original(), Button.matches), 1)
    end))
end

function HueSaturationCurve.lazy.value:color()
    return ColorWell(self, self.UI:mutate(function(original)
        return childMatching(original(), ColorWell.matches)
    end))
end

return HueSaturationCurve