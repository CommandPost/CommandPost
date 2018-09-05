--- === cp.apple.finalcutpro.inspector.color.ColorCurves ===
---
--- Color Curves Module.
---
--- Requires Final Cut Pro 10.4 or later.

--------------------------------------------------------------------------------
-- TODO:
--  * Add API to Reset Individual Curves
--  * Add API to trigger Color Picker for Individual Curves
--  * Add API for "Add Shape Mask", "Add Color Mask" and "Invert Masks".
--  * Add API for "Save Effects Preset".
--  * Add API for "Mask Inside/Output".
--  * Add API for "View Masks".
--  * Add API for "Preserve Luma" Checkbox
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log                               = require("hs.logger").new("colorCurves")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local prop                              = require("cp.prop")
local axutils                           = require("cp.ui.axutils")
local CheckBox                          = require("cp.ui.CheckBox")
local Element                           = require("cp.ui.Element")
local MenuButton                        = require("cp.ui.MenuButton")
local PropertyRow						= require("cp.ui.PropertyRow")
local RadioGroup						= require("cp.ui.RadioGroup")
local Slider							= require("cp.ui.Slider")
local TextField                         = require("cp.ui.TextField")

local If                                = require("cp.rx.go.If")

local ColorCurve                        = require("cp.apple.finalcutpro.inspector.color.ColorCurve")

local cache, childMatching              = axutils.cache, axutils.childMatching

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

local CORRECTION_TYPE                   = "Color Curves"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ColorCurves = Element:subclass("ColorCurves")

function ColorCurves.__tostring()
    return "cp.apple.finalcutpro.inspector.color.ColorCurves"
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves.matches(element)
--- Function
--- Checks if the specified element is the Color Curves element.
---
--- Parameters:
--- * element	- The element to check
---
--- Returns:
--- * `true` if the element is the Color Curves.
function ColorCurves.static.matches(element)
    if Element.matches(element) and element:attributeValue("AXRole") == "AXGroup"
    and #element == 1 and element[1]:attributeValue("AXRole") == "AXGroup"
    and #element[1] == 1 and element[1][1]:attributeValue("AXRole") == "AXScrollArea" then
        local scroll = element[1][1]
        return childMatching(scroll, ColorCurve.matches) ~= nil
    end
    return false
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves(parent) -> ColorCurves object
--- Constructor
--- Creates a new ColorCurves object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A ColorInspector object
function ColorCurves:initialize(parent)

    local UI = parent.correctorUI:mutate(function(original)
        return cache(self, "_ui", function()
            local ui = original()
            return ColorCurves.matches(ui) and ui or nil
        end, ColorCurves.matches)
    end)

    Element.initialize(self, parent, UI)

    PropertyRow.prepareParent(self, self.contentUI)

    -- NOTE: There is a bug in 10.4 where updating the slider alone doesn't update the temperature value.
    -- link these fields so they mirror each other.
    self:mixSlider().value:mirror(self:mixTextField().value)
end

--------------------------------------------------------------------------------
--
-- COLOR CURVES:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorCurves:show() -> boolean
--- Method
--- Show's the Color Board within the Color Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorCurves object
function ColorCurves:show()
    if not self:isShowing() then
        self:parent():activateCorrection(CORRECTION_TYPE)
    end
    return self
end

function ColorCurves.lazy.method:doShow()
    return If(self.isShowing):Is(false):Then(
        self:parent():doActivateCorrection(CORRECTION_TYPE)
    ):Otherwise(true)
    :Label("ColorCurves:doShow")
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves.contentUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- The `axuielement` representing the content element of the ColorCurves corrector.
--- This contains all the individual UI elements of the corrector, and is typically an `AXScrollArea`.
function ColorCurves.lazy.prop:contentUI()
    return self.UI:mutate(function(original)
        return cache(self, "_content", function()
            local ui = original()
            return ui and #ui == 1 and #ui[1] == 1 and ui[1][1] or nil
        end)
    end)
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves:viewModeButton() -> MenuButton
--- Method
--- Returns the [MenuButton](cp.ui.MenuButton.md) for the View Mode.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `MenuButton` for the View Mode.
function ColorCurves.lazy.method:viewModeButton()
    return MenuButton(self, function()
        local ui = self:contentUI()
        if ui then
            return childMatching(ui, MenuButton.matches)
        end
        return nil
    end)
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves.viewingAllCurves <cp.prop: boolean>
--- Field
--- Reports and modifies whether the corrector is showing "All Curves" (`true`) or "Single Curves" (`false`).
function ColorCurves.lazy.prop:viewingAllCurves()
    return prop(
        function()
            local ui = self:contentUI()
            if ui then
                local curveOne = childMatching(ui, ColorCurve.matches, 1)
                local curveTwo = childMatching(ui, ColorCurve.matches, 2)
                local posOne = curveOne and curveOne:attributeValue("AXPosition")
                local posTwo = curveTwo and curveTwo:attributeValue("AXPosition")
                return posOne ~= nil and posTwo ~= nil and posOne.y ~= posTwo.y or false
            end
            return false
        end,
        function(allCurves, _, theProp)
            local current = theProp:get()
            if allCurves and not current then
                self:viewModeButton():selectItem(1)
            elseif not allCurves and current then
                self:viewModeButton():selectItem(2)
            end
        end
    ):monitor(self.contentUI)
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves:curveType() -> RadioGroup
--- Method
--- Returns the `RadioGroup` that allows selection of the curve type. Only available when
--- [viewingAllCurves](#viewingAllCurves) is `true`.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `RadioGroup`.
function ColorCurves.lazy.method:wheelType()
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

--- cp.apple.finalcutpro.inspector.color.ColorCurves:luma() -> ColorCurve
--- Method
--- Returns a [ColorCurve](cp.apple.finalcutpro.inspector.color.ColorCurve.md)
--- that allows control of the 'luma' color settings.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `ColorCurve`.
function ColorCurves.lazy.method:luma()
    return ColorCurve(self, ColorCurve.TYPE.LUMA)
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves:red() -> ColorCurve
--- Method
--- Returns a [ColorCurve](cp.apple.finalcutpro.inspector.color.ColorCurve.md)
--- that allows control of the 'red' color settings. The actual
--- color can be adjusted within the ColorCurve, but it starts as red.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `ColorCurve`.
function ColorCurves.lazy.method:red()
    return ColorCurve(self, ColorCurve.TYPE.RED)
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves:green() -> ColorCurve
--- Method
--- Returns a [ColorCurve](cp.apple.finalcutpro.inspector.color.ColorCurve.md)
--- that allows control of the 'green' color settings. The actual
--- color can be adjusted within the ColorCurve, but it starts as green.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `ColorCurve`.
function ColorCurves.lazy.method:green()
    return ColorCurve(self, ColorCurve.TYPE.GREEN)
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves:blue() -> ColorCurve
--- Method
--- Returns a [ColorCurve](cp.apple.finalcutpro.inspector.color.ColorCurve.md)
--- that allows control of the 'blue' color settings. The actual
--- color can be adjusted within the ColorCurve, but it starts as blue.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `ColorCurve`.
function ColorCurves.lazy.method:blue()
    return ColorCurve(self, ColorCurve.TYPE.BLUE)
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves:mixRow() -> cp.ui.PropertyRow
--- Method
--- Returns a `PropertyRow` that provides access to the 'Mix' parameter, and `axuielement`
--- values for that row.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `PropertyRow`.
function ColorCurves.lazy.method:mixRow()
    return PropertyRow(self, "FFChannelMixName")
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves:mixSlider() -> cp.ui.Slider
--- Method
--- Returns a `Slider` that provides access to the 'Mix' slider.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Mix `Slider`.
function ColorCurves.lazy.method:mixSlider()
    return Slider(self,
        function()
            local ui = self:mixRow():children()
            return ui and childMatching(ui, Slider.matches)
        end
    )
end

function ColorCurves.lazy.method:mixTextField()
    return TextField(self,
        function()
            local ui = self:mixRow():children()
            return ui and childMatching(ui, TextField.matches)
        end,
        tonumber
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves.mix <cp.prop: number>
--- Field
--- The mix amount for this corrector. A number ranging from `0` to `1`.
function ColorCurves.lazy.prop:mix()
    return self:mixSlider().values
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves:preserveLumaRow() -> cp.ui.PropertyRow
--- Method
--- Returns a `PropertyRow` that provides access to the 'Preserve Luma' parameter, and `axuielement`
--- values for that row.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `PropertyRow`.
function ColorCurves.lazy.method:preserveLumaRow()
    return PropertyRow(self, "PAEColorCurvesEffectPreserveLuma")
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves.preserveLuma <cp.ui.CheckBox>
--- Field
--- Returns a [CheckBox](cp.ui.CheckBox.md) that provides access to the 'Preserve Luma' slider.
function ColorCurves.lazy.value:preserveLuma()
    return CheckBox(self,
        function()
            return childMatching(self:preserveLumaRow():children(), CheckBox.matches)
        end
    )
end

return ColorCurves
