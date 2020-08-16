--- === cp.apple.finalcutpro.inspector.color.ColorWheels ===
---
--- Color Wheels Module.
---
--- Extends [Element](cp.ui.Element.md)

local require = require

-- local log                               = require("hs.logger").new("colorWheels")

local axutils                           = require("cp.ui.axutils")
local prop                              = require("cp.prop")
local tools                             = require("cp.tools")

local Element                           = require("cp.ui.Element")
local MenuButton                        = require("cp.ui.MenuButton")
local PropertyRow                       = require("cp.ui.PropertyRow")
local RadioGroup                        = require("cp.ui.RadioGroup")
local Slider                            = require("cp.ui.Slider")
local TextField                         = require("cp.ui.TextField")

local ColorWheel                        = require("cp.apple.finalcutpro.inspector.color.ColorWheel")

local If                                = require("cp.rx.go.If")

local childMatching, cache              = axutils.childMatching, axutils.cache

local toRegionalNumber                  = tools.toRegionalNumber
local toRegionalNumberString            = tools.toRegionalNumberString

local CORRECTION_TYPE                   = "Color Wheels"

local ColorWheels = Element:subclass("cp.apple.finalcutpro.inspector.color.ColorWheels")

--- cp.apple.finalcutpro.inspector.color.ColorWheels.matches(element)
--- Function
--- Checks if the specified element is the Color Wheels element.
---
--- Parameters:
--- * element   - The element to check
---
--- Returns:
--- * `true` if the element is the Color Wheels.
function ColorWheels.static.matches(element)
    if Element.matches(element) and element:attributeValue("AXRole") == "AXGroup"
    and #element == 1 and element[1]:attributeValue("AXRole") == "AXGroup"
    and #element[1] == 1 and element[1][1]:attributeValue("AXRole") == "AXScrollArea" then
        local scroll = element[1][1]
        return childMatching(scroll, ColorWheel.matches) ~= nil
    end
    return false
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels(parent) -> ColorInspector
--- Constructor
--- Creates a new ColorWheels object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A new `ColorInspector` object
function ColorWheels:initialize(parent)

    local UI = parent.correctorUI:mutate(function(original)
        return cache(self, "_ui", function()
            local ui = original()
            return ColorWheels.matches(ui) and ui or nil
        end, ColorWheels.matches)
    end)

    Element.initialize(self, parent, UI)
    self._child = {}

    -- mark this as being able to contain `PropertyRow` values.
    PropertyRow.prepareParent(self, self.contentUI)

    -- NOTE: There is a bug in 10.4 where updating the slider alone doesn't update the temperature value.
    -- link these fields so they mirror each other.
    self.temperatureSlider.value:mirror(self.temperatureTextField.value)
    self.mixSlider.value:mirror(self.mixTextField.value)
    self.tintSlider.value:mirror(self.tintTextField.value)
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.contentUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- The `axuielement` representing the content element of the ColorWheels corrector.
--- This contains all the individual UI elements of the corrector, and is typically an `AXScrollArea`.
function ColorWheels.lazy.prop:contentUI()
    return self.UI:mutate(function(original)
        return cache(self, "_content", function()
            local ui = original()
            return ui and #ui == 1 and #ui[1] == 1 and ui[1][1] or nil
        end)
    end)
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.viewingAllWheels <cp.prop: boolean>
--- Field
--- Reports and modifies whether the ColorWheels corrector is showing "All Wheels" (`true`) or "Single Wheels" (`false`).
function ColorWheels.lazy.prop:viewingAllWheels()
    return prop(
        function()
            local ui = self:contentUI()
            if ui then
                local wheelOne = childMatching(ui, ColorWheel.matches, 1)
                local wheelTwo = childMatching(ui, ColorWheel.matches, 2)
                local posOne = wheelOne and wheelOne:attributeValue("AXPosition")
                local posTwo = wheelTwo and wheelTwo:attributeValue("AXPosition")
                return posOne ~= nil and posTwo ~= nil and posOne.y ~= posTwo.y or false
            end
            return false
        end,
        function(allWheels, _, theProp)
            local current = theProp:get()
            if allWheels and not current then
                self.viewMode:selectItem(1)
            elseif not allWheels and current then
                self.viewMode:selectItem(2)
            end
        end
    ):monitor(self.contentUI)
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.mix <cp.prop: number>
--- Field
--- The mix amount for this corrector. A number ranging from `0` to `1`.
function ColorWheels.lazy.prop:mix()
    return self.mixSlider.value
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.temperature <cp.prop: number>
--- Field
--- The color temperature for this corrector. A number from 2500 to 10000.
function ColorWheels.lazy.prop:temperature()
    return self.temperatureSlider.value
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.tint <cp.prop: number>
--- Field
--- The tint for the corrector. A number from `-50` to `50`.
function ColorWheels.lazy.prop:tint()
    return self.tintTextField.value
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.hue <cp.prop: number>
--- Field
--- The hue for the corrector. A number from `0` to `360`.
function ColorWheels.lazy.prop:hue()
    return self.hueTextField.value
end

--------------------------------------------------------------------------------
--
-- COLOR WHEELS:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorWheels:show() -> boolean
--- Method
--- Show's the Color Board within the Color Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorWheels object
function ColorWheels:show()
    if not self:isShowing() then
        self:parent():activateCorrection(CORRECTION_TYPE)
    end
    return self
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels:doShow() -> cs.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement.md) that shows the Color Board within the Color Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Statement`, resolving to `true` if successfully shown.
function ColorWheels.lazy.method:doShow()
    return If(self.isShowing):Is(false):Then(
        self:parent():doActivateCorrection(CORRECTION_TYPE)
    ):Otherwise(true)
    :Label("ColorWheels:doShow")
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.viewMode <cp.ui.MenuButton>
--- Field
--- The [MenuButton](cp.ui.MenuButton.md) for the View Mode.
function ColorWheels.lazy.value:viewMode()
    return MenuButton(self, function()
        local ui = self:contentUI()
        if ui then
            return childMatching(ui, MenuButton.matches)
        end
        return nil
    end)
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.wheelType <cp.ui.RadioGroup>
--- Field
--- The `RadioGroup` that allows selection of the wheel type. Only available when
--- `viewingAllWheels` is `true`.
function ColorWheels.lazy.value:wheelType()
    return RadioGroup(self,
        function()
            if not self:viewingAllWheels() then
                local ui = self:contentUI()
                return ui and childMatching(ui, RadioGroup.matches) or nil
            end
            return nil
        end,
        false -- not cached
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.master <ColorWheel>
--- Field
--- A `ColorWheel` that allows control of the 'master' color settings.
function ColorWheels.lazy.value:master()
    return ColorWheel(self, ColorWheel.TYPE.MASTER)
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.shadows <ColorWheel>
--- Field
--- A `ColorWheel` that allows control of the 'shadows' color settings.
function ColorWheels.lazy.value:shadows()
    return ColorWheel(self, ColorWheel.TYPE.SHADOWS)
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.midtones <ColorWheel>
--- Field
--- A `ColorWheel` that allows control of the 'midtones' color settings.
function ColorWheels.lazy.value:midtones()
    return ColorWheel(self, ColorWheel.TYPE.MIDTONES)
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.highlights <ColorWheel>
--- Field
--- A `ColorWheel` that allows control of the 'highlights' color settings.
function ColorWheels.lazy.value:highlights()
    return ColorWheel(self, ColorWheel.TYPE.HIGHLIGHTS)
end

--------------------------------------------------------------------------------
-- PROPERTIES:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorWheels.mixRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the 'Mix' parameter, and `axuielement`
--- values for that row.
function ColorWheels.lazy.value:mixRow()
    return PropertyRow(self, "FFChannelMixName")
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.mixSlider <cp.ui.Slider>
--- Field
--- A `Slider` that provides access to the 'Mix' slider.
function ColorWheels.lazy.value:mixSlider()
    return Slider(self,
        function()
            local ui = self.mixRow:children()
            return ui and childMatching(ui, Slider.matches)
        end
    )
end

function ColorWheels.lazy.value:mixTextField()
    return TextField(self,
        function()
            local ui = self.mixRow:children()
            return ui and childMatching(ui, TextField.matches)
        end,
        toRegionalNumber, toRegionalNumberString
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.temperatureRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the 'Temperatures' parameter, and `axuielement`
--- values for that row.
function ColorWheels.lazy.value:temperatureRow()
    return PropertyRow(self, "PAECorrectorEffectTemperature")
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.temperatureSlider <cp.ui.Slider>
--- Field
--- A `Slider` that provides access to the 'Temperatures' slider.
function ColorWheels.lazy.value:temperatureSlider()
    return Slider(self,
        function()
            return childMatching(self.temperatureRow, Slider.matches)
        end
    )
end

function ColorWheels.lazy.value:temperatureTextField()
    return TextField(self,
        function()
            local ui = self.temperatureRow:children()
            return ui and childMatching(ui, TextField.matches)
        end,
        toRegionalNumber, toRegionalNumberString
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.tintRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the 'Tint' parameter, and `axuielement`
--- values for that row.
function ColorWheels.lazy.value:tintRow()
    return PropertyRow(self, "PAECorrectorEffectTint")
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.tintSlider <cp.ui.Slider>
--- Field
--- Returns a `Slider` that provides access to the 'Tint' slider.
function ColorWheels.lazy.value:tintSlider()
    return Slider(self,
        function()
            local ui = self.tintRow:children()
            return ui and childMatching(ui, Slider.matches)
        end
    )
end

function ColorWheels.lazy.value:tintTextField()
    return TextField(self,
        function()
            local ui = self.tintRow:children()
            return ui and childMatching(ui, TextField.matches)
        end,
        toRegionalNumber, toRegionalNumberString
    ):forceFocus()
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.hueRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the 'Hue' parameter, and `axuielement`
--- values for that row.
function ColorWheels.lazy.value:hueRow()
    return PropertyRow(self, "PAECorrectorEffectHue")
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.hueTextField <cp.ui.TextField>
--- Field
--- A `TextField` that provides access to the 'Hue' slider.
function ColorWheels.lazy.value:hueTextField()
    return TextField(self,
        function()
            local ui = self.hueRow:children()
            return ui and childMatching(ui, TextField.matches)
        end,
        toRegionalNumber, toRegionalNumberString
    )
end

return ColorWheels
