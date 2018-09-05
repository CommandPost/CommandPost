--- === cp.apple.finalcutpro.inspector.color.ColorCurve ===
---
--- A ColorCurve [Element](cp.ui.Element.md).

local axutils                               = require("cp.ui.axutils")
local Element                               = require("cp.ui.Element")

local If                                    = require("cp.rx.go.If")

local childWithRole                         = axutils.childWithRole
local childMatching, childrenMatching       = axutils.childMatching, axutils.childrenMatching
local cache                                 = axutils.cache

local ColorCurve = Element:subclass("ColorCurve")

ColorCurve.static.TYPE ={
    LUMA = 1,
    RED = 2,
    GREEN = 3,
    BLUE = 4,
}

--- cp.apple.finalcutpro.inspector.color.ColorCurve.matches(element) -> boolean
--- Function
--- Checks if the specified value is a `ColorCurve`.
---
--- Parameters:
--- * element       - The `axuielement` to check.
---
--- Returns:
--- * `true` if it matches a ColorCurve element.
function ColorCurve.static.matches(element)
    return Element.matches(element) and element:attributeValue("AXRole") == "AXGroup"
        and #element == 4 and childWithRole(element, "AXList") ~= nil
        and childWithRole(element, "AXColorWell") ~= nil
end

--- cp.apple.finalcutpro.inspector.color.ColorCurve(parent, type) -> ColorCurve
--- Constructor
--- Creates a new `ColorCurve` [Element](cp.ui.Element.md).
---
--- Parameters:
--- * parent    - The parent `Element`.
--- * type     - The [TYPE](#TYPE) of curve.
---
--- Returns:
--- * The new `ColorCurve`.
function ColorCurve:initialize(parent, type)
    local UI = parent.contentUI:mutate(function(original)
        return cache(self, "_ui", function()
            local ui = original()
            if ui then
                if parent:viewingAllCurves() then
                    --------------------------------------------------------------------------------
                    -- All Wheels:
                    --------------------------------------------------------------------------------
                    return axutils.childFromTop(childrenMatching(ui, ColorCurve.matches), self:type())
                elseif parent:wheelType():selectedOption() == self:type() then
                    --------------------------------------------------------------------------------
                    -- Single Wheels - with only a single wheel visible:
                    --------------------------------------------------------------------------------
                    return childMatching(ui, ColorCurve.matches)
                end
            end
            return nil
        end, ColorCurve.matches)
    end)

    Element.initialize(self, parent, UI)
    self._type = type
end

function ColorCurve:type()
    return self._type
end

function ColorCurve:show()
    local parent = self:parent()
    parent:show()
    parent:wheelType():selectedOption(self:type())
end

function ColorCurve.lazy.method:doShow()
    local parent = self:parent()
    local wheelType = parent:wheelType()
    return If(self.isShowing):Is(false):Then(
        parent:doShow()
    ):Then(
        If(wheelType.isShowing):Then(
            wheelType:doSelectOption(self:type())
        )
    ):Then(true)
    :Otherwise(true)
    :Label("ColorCurve:doShow")
end

return ColorCurve