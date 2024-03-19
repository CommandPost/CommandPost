--- === cp.apple.finalcutpro.inspector.color.ColorAdjustments ===
---
--- Color Adjustments Module.
---
--- Requires Final Cut Pro v10.6.6 or later.

local require = require

local log                               = require "hs.logger".new("colorAdjustments")

local tools                             = require "cp.tools"

local axutils                           = require "cp.ui.axutils"
local Group                             = require "cp.ui.Group"
local PopUpButton                       = require "cp.ui.PopUpButton"
local PropertyRow						= require "cp.ui.PropertyRow"
local ScrollArea                        = require "cp.ui.ScrollArea"
local Slider							= require "cp.ui.Slider"
local TextField                         = require "cp.ui.TextField"

local If                                = require "cp.rx.go.If"

local cache                             = axutils.cache
local childMatching                     = axutils.childMatching

local toRegionalNumber                  = tools.toRegionalNumber
local toRegionalNumberString            = tools.toRegionalNumberString

local CORRECTION_TYPE                   = "Color Adjustments"

local ColorAdjustments = Group:subclass("cp.apple.finalcutpro.inspector.color.ColorAdjustments")

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.matches(element)
--- Function
--- Checks if the specified element is the Color Curves element.
---
--- Parameters:
---  * element	- The element to check
---
--- Returns:
---  * `true` if the element is the Color Curves.
function ColorAdjustments.static.matches(element)
    if Group.matches(element) and #element == 1 and Group.matches(element[1]) and #element[1] == 1 and ScrollArea.matches(element[1][1]) then
        local scroll = element[1][1]
        local scrollChildren = scroll and scroll:attributeValue("AXChildren")
        if scrollChildren and #scrollChildren >= 74 then
            return true
        end
    end
    return false
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments(parent) -> ColorAdjustments object
--- Constructor
--- Creates a new ColorAdjustments object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A ColorInspector object
function ColorAdjustments:initialize(parent)
    local UI = parent.correctorUI:mutate(function(original)
        return cache(self, "_ui", function()
            local ui = original()
            return ColorAdjustments.matches(ui) and ui or nil
        end, ColorAdjustments.matches)
    end)

    Group.initialize(self, parent, UI)

    PropertyRow.prepareParent(self, self.contentUI)

    --------------------------------------------------------------------------------
    -- Link Text Fields to Sliders:
    --------------------------------------------------------------------------------
    self.exposureSlider.value:mirror(self.exposureTextField.value)
    self.contrastSlider.value:mirror(self.contrastTextField.value)
    self.brightnessSlider.value:mirror(self.brightnessTextField.value)
    self.saturationSlider.value:mirror(self.saturationTextField.value)
    self.highlightsSlider.value:mirror(self.highlightsTextField.value)
    self.blackPointSlider.value:mirror(self.blackPointTextField.value)
    self.shadowsSlider.value:mirror(self.shadowsTextField.value)
    self.highlightsWarmthSlider.value:mirror(self.highlightsWarmthTextField.value)
    self.highlightsTintSlider.value:mirror(self.highlightsTintTextField.value)
    self.midtonesWarmthSlider.value:mirror(self.midtonesWarmthTextField.value)
    self.midtonesTintSlider.value:mirror(self.midtonesTintTextField.value)
    self.shadowsWarmthSlider.value:mirror(self.shadowsWarmthTextField.value)
    self.shadowsTintSlider.value:mirror(self.shadowsTintTextField.value)
    self.mixSlider.value:mirror(self.mixTextField.value)
end

--------------------------------------------------------------------------------
--
-- COLOR ADJUSTMENTS:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments:show() -> boolean
--- Method
--- Show's the Color Board within the Color Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorAdjustments object
function ColorAdjustments:show()
    if not self:isShowing() then
        self:parent():activateCorrection(CORRECTION_TYPE)
    end
    return self
end

function ColorAdjustments.lazy.method:doShow()
    return If(self.isShowing):Is(false):Then(
        self:parent():doActivateCorrection(CORRECTION_TYPE)
    ):Otherwise(true)
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.contentUI <cp.prop: hs.axuielement; read-only>
--- Field
--- The `axuielement` representing the content element of the ColorAdjustments corrector.
--- This contains all the individual UI elements of the corrector, and is typically an `AXScrollArea`.
function ColorAdjustments.lazy.prop:contentUI()
    return self.UI:mutate(function(original)
        return cache(self, "_content", function()
            local ui = original()
            return ui and #ui == 1 and #ui[1] == 1 and ui[1][1] or nil
        end)
    end)
end

--------------------------------------------------------------------------------
--
-- PROPERTIES:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CONTROL RANGE:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.exposureRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the parameter, and `axuielement` values for that row.
function ColorAdjustments.lazy.value:controlRangeRow()
    return PropertyRow(self, "HDRColorCorrect::Control Range")
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.exposureTextField <cp.ui.TextField>
--- Field
--- A `TextField` that provides access to the slider.
function ColorAdjustments.lazy.value:controlRangePopUpButton()
    return PopUpButton(self,
        function()
            local ui = self.controlRangeRow:children()
            return ui and childMatching(ui, PopUpButton.matches)
        end
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.CONTROL_RANGES
--- Constant
--- Table of Control Ranges.
---
--- Notes:
---  * Possible values are:
---   ** SDR
---   ** HLG
---   ** PQ 1000 nits
---   ** PQ 2000 nites
---   ** PQ 4000 nits
---   ** PQ 10000 nits
ColorAdjustments.CONTROL_RANGES = {
    "SDR",
    "HLG",
    "PQ 1000 nits",
    "PQ 2000 nits",
    "PQ 4000 nits",
    "PQ 10000 nits",
}

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.controlRange(id) -> boolean
--- Method
--- Sets the Control Range Menu Item.
---
--- Parameters:
---  * id - A string containing the control range value (in English)
---
--- Returns:
---  * `true` if successful, otherwise `false`
function ColorAdjustments:controlRange(id)

    local controlRangeEntries = self:parent():app().strings:find("HDRColorCorrect::Control Range Entries")
    local individualControlRangeEntries = controlRangeEntries:split("|")

    local pid
    if id == "SDR" then
        pid = individualControlRangeEntries[1]
    elseif id == "HLG" then
        pid = individualControlRangeEntries[2]
    elseif id == "PQ 1000 nits" then
        pid = individualControlRangeEntries[3]
    elseif id == "PQ 2000 nits" then
        pid = individualControlRangeEntries[4]
    elseif id == "PQ 4000 nits" then
        pid = individualControlRangeEntries[5]
    elseif id == "PQ 10000 nits" then
        pid = individualControlRangeEntries[6]
    else
        log.ef("Invalid Control Range ID: %s", id)
        return false
    end

    self.controlRangePopUpButton:show():value(pid)
    return true
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.controlRangeLabel(id) -> boolean
--- Method
--- Gets the Control Range i18n Value.
---
--- Parameters:
---  * id - A string containing the control range value (in English)
---
--- Returns:
---  * A string
function ColorAdjustments:controlRangeLabel(id)
    local controlRangeEntries = self:parent():app().strings:find("HDRColorCorrect::Control Range Entries")
    local individualControlRangeEntries = controlRangeEntries:split("|")

    local pid = id
    if id == "SDR" then
        pid = individualControlRangeEntries[1]
    elseif id == "HLG" then
        pid = individualControlRangeEntries[2]
    elseif id == "PQ 1000 nits" then
        pid = individualControlRangeEntries[3]
    elseif id == "PQ 2000 nits" then
        pid = individualControlRangeEntries[4]
    elseif id == "PQ 4000 nits" then
        pid = individualControlRangeEntries[5]
    elseif id == "PQ 10000 nits" then
        pid = individualControlRangeEntries[6]
    else
        log.ef("Invalid Control Range ID: %s", id)
    end

    return pid
end

--------------------------------------------------------------------------------
-- EXPOSURE:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.exposureRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the parameter, and `axuielement` values for that row.
function ColorAdjustments.lazy.value:exposureRow()
    return PropertyRow(self, "HDRColorCorrect::Exposure")
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.exposureSlider <cp.ui.Slider>
--- Field
--- A `Slider` that provides access to the slider.
function ColorAdjustments.lazy.value:exposureSlider()
    return Slider(self,
        function()
            local ui = self.exposureRow:children()
            return ui and childMatching(ui, Slider.matches)
        end
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.exposureTextField <cp.ui.TextField>
--- Field
--- A `TextField` that provides access to the slider.
function ColorAdjustments.lazy.value:exposureTextField()
    return TextField(self,
        function()
            local ui = self.exposureRow:children()
            return ui and childMatching(ui, TextField.matches)
        end,
        toRegionalNumber, toRegionalNumberString
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.exposure <cp.prop: number>
--- Field
--- The amount for this corrector.
function ColorAdjustments.lazy.prop:exposure()
    return self.exposureSlider.value
end

--------------------------------------------------------------------------------
-- CONTRAST:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.contrastRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the parameter, and `axuielement` values for that row.
function ColorAdjustments.lazy.value:contrastRow()
    return PropertyRow(self, "HDRColorCorrect::Contrast")
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.contrastSlider <cp.ui.Slider>
--- Field
--- A `Slider` that provides access to the slider.
function ColorAdjustments.lazy.value:contrastSlider()
    return Slider(self,
        function()
            local ui = self.contrastRow:children()
            return ui and childMatching(ui, Slider.matches)
        end
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.contrastTextField <cp.ui.TextField>
--- Field
--- A `TextField` that provides access to the slider.
function ColorAdjustments.lazy.value:contrastTextField()
    return TextField(self,
        function()
            local ui = self.contrastRow:children()
            return ui and childMatching(ui, TextField.matches)
        end,
        toRegionalNumber, toRegionalNumberString
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.contrast <cp.prop: number>
--- Field
--- The amount for this corrector.
function ColorAdjustments.lazy.prop:contrast()
    return self.contrastSlider.value
end

--------------------------------------------------------------------------------
-- BRIGHTNESS:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.brightnessRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the parameter, and `axuielement` values for that row.
function ColorAdjustments.lazy.value:brightnessRow()
    return PropertyRow(self, "HDRColorCorrect::Brightness")
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.brightnessSlider <cp.ui.Slider>
--- Field
--- A `Slider` that provides access to the slider.
function ColorAdjustments.lazy.value:brightnessSlider()
    return Slider(self,
        function()
            local ui = self.brightnessRow:children()
            return ui and childMatching(ui, Slider.matches)
        end
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.brightnessTextField <cp.ui.TextField>
--- Field
--- A `TextField` that provides access to the slider.
function ColorAdjustments.lazy.value:brightnessTextField()
    return TextField(self,
        function()
            local ui = self.brightnessRow:children()
            return ui and childMatching(ui, TextField.matches)
        end,
        toRegionalNumber, toRegionalNumberString
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.brightness <cp.prop: number>
--- Field
--- The amount for this corrector.
function ColorAdjustments.lazy.prop:brightness()
    return self.brightnessSlider.value
end

--------------------------------------------------------------------------------
-- SATURATION:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.saturationRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the parameter, and `axuielement` values for that row.
function ColorAdjustments.lazy.value:saturationRow()
    return PropertyRow(self, "HDRColorCorrect::Saturation")
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.saturationSlider <cp.ui.Slider>
--- Field
--- A `Slider` that provides access to the slider.
function ColorAdjustments.lazy.value:saturationSlider()
    return Slider(self,
        function()
            local ui = self.saturationRow:children()
            return ui and childMatching(ui, Slider.matches)
        end
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.saturationTextField <cp.ui.TextField>
--- Field
--- A `TextField` that provides access to the slider.
function ColorAdjustments.lazy.value:saturationTextField()
    return TextField(self,
        function()
            local ui = self.saturationRow:children()
            return ui and childMatching(ui, TextField.matches)
        end,
        toRegionalNumber, toRegionalNumberString
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.saturation <cp.prop: number>
--- Field
--- The amount for this corrector.
function ColorAdjustments.lazy.prop:saturation()
    return self.saturationSlider.value
end

--------------------------------------------------------------------------------
-- HIGHLIGHTS:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.highlightsRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the parameter, and `axuielement` values for that row.
function ColorAdjustments.lazy.value:highlightsRow()
    return PropertyRow(self, "HDRColorCorrect::Highlights")
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.highlightsSlider <cp.ui.Slider>
--- Field
--- A `Slider` that provides access to the slider.
function ColorAdjustments.lazy.value:highlightsSlider()
    return Slider(self,
        function()
            local ui = self.highlightsRow:children()
            return ui and childMatching(ui, Slider.matches)
        end
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.highlightsTextField <cp.ui.TextField>
--- Field
--- A `TextField` that provides access to the slider.
function ColorAdjustments.lazy.value:highlightsTextField()
    return TextField(self,
        function()
            local ui = self.highlightsRow:children()
            return ui and childMatching(ui, TextField.matches)
        end,
        toRegionalNumber, toRegionalNumberString
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.highlights <cp.prop: number>
--- Field
--- The amount for this corrector.
function ColorAdjustments.lazy.prop:highlights()
    return self.highlightsSlider.value
end

--------------------------------------------------------------------------------
-- BLACK POINT:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.blackPointRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the parameter, and `axuielement` values for that row.
function ColorAdjustments.lazy.value:blackPointRow()
    return PropertyRow(self, "HDRColorCorrect::BlackPoint")
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.blackPointSlider <cp.ui.Slider>
--- Field
--- A `Slider` that provides access to the slider.
function ColorAdjustments.lazy.value:blackPointSlider()
    return Slider(self,
        function()
            local ui = self.blackPointRow:children()
            return ui and childMatching(ui, Slider.matches)
        end
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.blackPointTextField <cp.ui.TextField>
--- Field
--- A `TextField` that provides access to the slider.
function ColorAdjustments.lazy.value:blackPointTextField()
    return TextField(self,
        function()
            local ui = self.blackPointRow:children()
            return ui and childMatching(ui, TextField.matches)
        end,
        toRegionalNumber, toRegionalNumberString
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.blackPoint <cp.prop: number>
--- Field
--- The amount for this corrector.
function ColorAdjustments.lazy.prop:blackPoint()
    return self.blackPointSlider.value
end

--------------------------------------------------------------------------------
-- SHADOWS:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.shadowsRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the parameter, and `axuielement` values for that row.
function ColorAdjustments.lazy.value:shadowsRow()
    return PropertyRow(self, "HDRColorCorrect::Shadows")
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.shadowsSlider <cp.ui.Slider>
--- Field
--- A `Slider` that provides access to the slider.
function ColorAdjustments.lazy.value:shadowsSlider()
    return Slider(self,
        function()
            local ui = self.shadowsRow:children()
            return ui and childMatching(ui, Slider.matches)
        end
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.shadowsTextField <cp.ui.TextField>
--- Field
--- A `TextField` that provides access to the slider.
function ColorAdjustments.lazy.value:shadowsTextField()
    return TextField(self,
        function()
            local ui = self.shadowsRow:children()
            return ui and childMatching(ui, TextField.matches)
        end,
        toRegionalNumber, toRegionalNumberString
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.shadows <cp.prop: number>
--- Field
--- The amount for this corrector.
function ColorAdjustments.lazy.prop:shadows()
    return self.shadowsSlider.value
end

--------------------------------------------------------------------------------
-- HIGHLIGHTS WARMTH:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.highlightsWarmthRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the parameter, and `axuielement` values for that row.
function ColorAdjustments.lazy.value:highlightsWarmthRow()
    return PropertyRow(self, "HDRColorCorrect::HighlightsWarmth")
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.highlightsWarmthSlider <cp.ui.Slider>
--- Field
--- A `Slider` that provides access to the slider.
function ColorAdjustments.lazy.value:highlightsWarmthSlider()
    return Slider(self,
        function()
            local ui = self.highlightsWarmthRow:children()
            return ui and childMatching(ui, Slider.matches)
        end
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.highlightsWarmthTextField <cp.ui.TextField>
--- Field
--- A `TextField` that provides access to the slider.
function ColorAdjustments.lazy.value:highlightsWarmthTextField()
    return TextField(self,
        function()
            local ui = self.highlightsWarmthRow:children()
            return ui and childMatching(ui, TextField.matches)
        end,
        toRegionalNumber, toRegionalNumberString
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.highlightsWarmth <cp.prop: number>
--- Field
--- The amount for this corrector.
function ColorAdjustments.lazy.prop:highlightsWarmth()
    return self.highlightsWarmthSlider.value
end

--------------------------------------------------------------------------------
-- HIGHLIGHTS TINT:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.highlightsTintRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the parameter, and `axuielement` values for that row.
function ColorAdjustments.lazy.value:highlightsTintRow()
    return PropertyRow(self, "HDRColorCorrect::HighlightsTint")
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.highlightsTintSlider <cp.ui.Slider>
--- Field
--- A `Slider` that provides access to the slider.
function ColorAdjustments.lazy.value:highlightsTintSlider()
    return Slider(self,
        function()
            local ui = self.highlightsTintRow:children()
            return ui and childMatching(ui, Slider.matches)
        end
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.highlightsTintTextField <cp.ui.TextField>
--- Field
--- A `TextField` that provides access to the slider.
function ColorAdjustments.lazy.value:highlightsTintTextField()
    return TextField(self,
        function()
            local ui = self.highlightsTintRow:children()
            return ui and childMatching(ui, TextField.matches)
        end,
        toRegionalNumber, toRegionalNumberString
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.highlightsTint <cp.prop: number>
--- Field
--- The amount for this corrector.
function ColorAdjustments.lazy.prop:highlightsTint()
    return self.highlightsTintSlider.value
end

--------------------------------------------------------------------------------
-- MIDTONES WARMTH:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.midtonesWarmthRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the parameter, and `axuielement` values for that row.
function ColorAdjustments.lazy.value:midtonesWarmthRow()
    return PropertyRow(self, "HDRColorCorrect::MidtonesWarmth")
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.midtonesWarmthSlider <cp.ui.Slider>
--- Field
--- A `Slider` that provides access to the slider.
function ColorAdjustments.lazy.value:midtonesWarmthSlider()
    return Slider(self,
        function()
            local ui = self.midtonesWarmthRow:children()
            return ui and childMatching(ui, Slider.matches)
        end
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.midtonesWarmthTextField <cp.ui.TextField>
--- Field
--- A `TextField` that provides access to the slider.
function ColorAdjustments.lazy.value:midtonesWarmthTextField()
    return TextField(self,
        function()
            local ui = self.midtonesWarmthRow:children()
            return ui and childMatching(ui, TextField.matches)
        end,
        toRegionalNumber, toRegionalNumberString
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.midtonesWarmth <cp.prop: number>
--- Field
--- The amount for this corrector.
function ColorAdjustments.lazy.prop:midtonesWarmth()
    return self.midtonesWarmthSlider.value
end

--------------------------------------------------------------------------------
-- MIDTONES TINT:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.midtonesTintRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the parameter, and `axuielement` values for that row.
function ColorAdjustments.lazy.value:midtonesTintRow()
    return PropertyRow(self, "HDRColorCorrect::MidtonesTint")
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.midtonesTintSlider <cp.ui.Slider>
--- Field
--- A `Slider` that provides access to the slider.
function ColorAdjustments.lazy.value:midtonesTintSlider()
    return Slider(self,
        function()
            local ui = self.midtonesTintRow:children()
            return ui and childMatching(ui, Slider.matches)
        end
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.midtonesTintTextField <cp.ui.TextField>
--- Field
--- A `TextField` that provides access to the slider.
function ColorAdjustments.lazy.value:midtonesTintTextField()
    return TextField(self,
        function()
            local ui = self.midtonesTintRow:children()
            return ui and childMatching(ui, TextField.matches)
        end,
        toRegionalNumber, toRegionalNumberString
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.midtonesTint <cp.prop: number>
--- Field
--- The amount for this corrector.
function ColorAdjustments.lazy.prop:midtonesTint()
    return self.midtonesTintSlider.value
end

--------------------------------------------------------------------------------
-- SHADOWS WARMTH:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.shadowsWarmthRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the parameter, and `axuielement` values for that row.
function ColorAdjustments.lazy.value:shadowsWarmthRow()
    return PropertyRow(self, "HDRColorCorrect::ShadowsWarmth")
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.shadowsWarmthSlider <cp.ui.Slider>
--- Field
--- A `Slider` that provides access to the slider.
function ColorAdjustments.lazy.value:shadowsWarmthSlider()
    return Slider(self,
        function()
            local ui = self.shadowsWarmthRow:children()
            return ui and childMatching(ui, Slider.matches)
        end
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.shadowsWarmthTextField <cp.ui.TextField>
--- Field
--- A `TextField` that provides access to the slider.
function ColorAdjustments.lazy.value:shadowsWarmthTextField()
    return TextField(self,
        function()
            local ui = self.shadowsWarmthRow:children()
            return ui and childMatching(ui, TextField.matches)
        end,
        toRegionalNumber, toRegionalNumberString
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.shadowsWarmth <cp.prop: number>
--- Field
--- The amount for this corrector.
function ColorAdjustments.lazy.prop:shadowsWarmth()
    return self.shadowsWarmthSlider.value
end

--------------------------------------------------------------------------------
-- SHADOWS TINT:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.shadowsTintRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the parameter, and `axuielement` values for that row.
function ColorAdjustments.lazy.value:shadowsTintRow()
    return PropertyRow(self, "HDRColorCorrect::ShadowsTint")
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.shadowsTintSlider <cp.ui.Slider>
--- Field
--- A `Slider` that provides access to the slider.
function ColorAdjustments.lazy.value:shadowsTintSlider()
    return Slider(self,
        function()
            local ui = self.shadowsTintRow:children()
            return ui and childMatching(ui, Slider.matches)
        end
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.shadowsTintTextField <cp.ui.TextField>
--- Field
--- A `TextField` that provides access to the slider.
function ColorAdjustments.lazy.value:shadowsTintTextField()
    return TextField(self,
        function()
            local ui = self.shadowsTintRow:children()
            return ui and childMatching(ui, TextField.matches)
        end,
        toRegionalNumber, toRegionalNumberString
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.shadowsTint <cp.prop: number>
--- Field
--- The amount for this corrector.
function ColorAdjustments.lazy.prop:shadowsTint()
    return self.shadowsTintSlider.value
end

--------------------------------------------------------------------------------
-- MIX:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.mixRow <cp.ui.PropertyRow>
--- Field
--- A `PropertyRow` that provides access to the parameter, and `axuielement` values for that row.
function ColorAdjustments.lazy.value:mixRow()
    return PropertyRow(self, "FFChannelMixName")
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.mixSlider <cp.ui.Slider>
--- Field
--- A `Slider` that provides access to the slider.
function ColorAdjustments.lazy.value:mixSlider()
    return Slider(self,
        function()
            local ui = self.mixRow:children()
            return ui and childMatching(ui, Slider.matches)
        end
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorAdjustments.mixTextField <cp.ui.TextField>
--- Field
--- A `TextField` that provides access to the slider.
function ColorAdjustments.lazy.value:mixTextField()
    return TextField(self,
        function()
            local ui = self.mixRow:children()
            return ui and childMatching(ui, TextField.matches)
        end,
        toRegionalNumber, toRegionalNumberString
    )
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.mix <cp.prop: number>
--- Field
--- The amount for this corrector.
function ColorAdjustments.lazy.prop:mix()
    return self.mixSlider.value
end

return ColorAdjustments