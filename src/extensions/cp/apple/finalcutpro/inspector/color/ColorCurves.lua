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

local require = require

-- local log                               = require "hs.logger".new("colorCurves")

local prop                              = require "cp.prop"
local tools                             = require "cp.tools"

local axutils                           = require "cp.ui.axutils"
local CheckBox                          = require "cp.ui.CheckBox"
local Group                             = require "cp.ui.Group"
local MenuButton                        = require "cp.ui.MenuButton"
local PropertyRow						= require "cp.ui.PropertyRow"
local RadioGroup						= require "cp.ui.RadioGroup"
local ScrollArea                        = require "cp.ui.ScrollArea"
local Slider							= require "cp.ui.Slider"
local TextField                         = require "cp.ui.TextField"

local If                                = require "cp.rx.go.If"

local ColorCurve                        = require "cp.apple.finalcutpro.inspector.color.ColorCurve"

local cache, childMatching              = axutils.cache, axutils.childMatching

local toRegionalNumber                  = tools.toRegionalNumber
local toRegionalNumberString            = tools.toRegionalNumberString

local CORRECTION_TYPE                   = "Color Curves"

local ColorCurves = Group:subclass("cp.apple.finalcutpro.inspector.color.ColorCurves")

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
    if Group.matches(element) and #element == 1 and Group.matches(element[1])
    and #element[1] == 1 and ScrollArea.matches(element[1][1]) then
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

    Group.initialize(self, parent, UI)

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

--- cp.apple.finalcutpro.inspector.color.ColorCurves.contentUI <cp.prop: hs.axuielement; read-only>
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

--- cp.apple.finalcutpro.inspector.color.ColorCurves.viewModeButton <cp.ui.MenuButton>
--- Field
--- Returns the [MenuButton](cp.ui.MenuButton.md) for the View Mode.
function ColorCurves.lazy.value:viewModeButton()
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
                self.viewModeButton:selectItem(1)
            elseif not allCurves and current then
                self.viewModeButton:selectItem(2)
            end
        end
    ):monitor(self.contentUI)
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves.wheelType <RadioGroup>
--- Field
--- The `RadioGroup` that allows selection of the curve type. Only available when
--- [viewingAllCurves](#viewingAllCurves) is `true`.
function ColorCurves.lazy.value:wheelType()
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

--- cp.apple.finalcutpro.inspector.color.ColorCurves.luma <ColorCurve>
--- Field
--- A [ColorCurve](cp.apple.finalcutpro.inspector.color.ColorCurve.md)
--- that allows control of the 'luma' color settings.
function ColorCurves.lazy.value:luma()
    return ColorCurve(self, ColorCurve.TYPE.LUMA)
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves.red <ColorCurve>
--- Field
--- A [ColorCurve](cp.apple.finalcutpro.inspector.color.ColorCurve.md)
--- that allows control of the 'red' color settings. The actual
--- color can be adjusted within the ColorCurve, but it starts as red.
function ColorCurves.lazy.value:red()
    return ColorCurve(self, ColorCurve.TYPE.RED)
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves.green <ColorCurve>
--- Field
--- A [ColorCurve](cp.apple.finalcutpro.inspector.color.ColorCurve.md)
--- that allows control of the 'green' color settings. The actual
--- color can be adjusted within the ColorCurve, but it starts as green.
function ColorCurves.lazy.value:green()
    return ColorCurve(self, ColorCurve.TYPE.GREEN)
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves.blue <ColorCurve>
--- Field
--- A [ColorCurve](cp.apple.finalcutpro.inspector.color.ColorCurve.md)
--- that allows control of the 'blue' color settings. The actual
--- color can be adjusted within the ColorCurve, but it starts as blue.
function ColorCurves.lazy.value:blue()
    return ColorCurve(self, ColorCurve.TYPE.BLUE)
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves.mixRow <cp.ui.PropertyRow>
--- Field
--- The `PropertyRow` that provides access to the 'Mix' parameter, and `axuielement`
function ColorCurves.lazy.value:mixRow()
    return PropertyRow(self, "FFChannelMixName")
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves.mixSlider <cp.ui.Slider>
--- Field
--- A `Slider` that provides access to the 'Mix' slider.
function ColorCurves.lazy.value:mixSlider()
    return Slider(self,
        function()
            local ui = self.mixRow:children()
            return ui and childMatching(ui, Slider.matches)
        end
    )
end

function ColorCurves.lazy.value:mixTextField()
    return TextField(self,
        function()
            local ui = self.mixRow:children()
            return ui and childMatching(ui, TextField.matches)
        end,
        toRegionalNumber, toRegionalNumberString
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves.mix <cp.prop: number>
--- Field
--- The mix amount for this corrector. A number ranging from `0` to `1`.
function ColorCurves.lazy.prop:mix()
    return self.mixSlider.value
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves.preserveLumaRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the 'Preserve Luma' parameter, and `axuielement`
--- values for that row.
function ColorCurves.lazy.value:preserveLumaRow()
    return PropertyRow(self, "PAEColorCurvesEffectPreserveLuma")
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves.preserveLuma <cp.ui.CheckBox>
--- Field
--- Returns a [CheckBox](cp.ui.CheckBox.md) that provides access to the 'Preserve Luma' slider.
function ColorCurves.lazy.value:preserveLuma()
    return CheckBox(self,
        function()
            return childMatching(self.preserveLumaRow:children(), CheckBox.matches)
        end
    )
end

return ColorCurves
