--- === cp.apple.finalcutpro.inspector.color.HueSaturationCurves ===
---
--- Hue/Saturation Curves Module.
---
--- Requires Final Cut Pro 10.4 or later.

--------------------------------------------------------------------------------
-- TODO:
--  * Add API to Reset Individual Curves
--  * Add API to trigger Color Picker for Individual Curves
--  * Add API to adjust entire curve for each curve
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

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("hueSaturationCurves")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local prop								= require("cp.prop")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local CORRECTION_TYPE					= "Hue/Saturation Curves"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local HueSaturationCurves = {}

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves.VIEW_MODES -> table
--- Constant
--- View Modes for Color Curves
HueSaturationCurves.VIEW_MODES = {
    ["6 Curves"]        = "PAEHSCurvesViewControllerVertical",
    ["Single Curves"]   = "PAECurvesViewControllerSingleControl",
}

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves.CURVES -> table
--- Constant
--- Table containing all the different types of Color Curves
HueSaturationCurves.CURVES = {
    ["HvH"]             = "PAEHSCurvesViewControllerHueVsHue",
    ["HvS"]             = "PAEHSCurvesViewControllerHueVsSat",
    ["HvL"]             = "PAEHSCurvesViewControllerHueVsLuma",
    ["LvS"]             = "PAEHSCurvesViewControllerLumaVsSat",
    ["SvS"]             = "PAEHSCurvesViewControllerSatVsSat",
    ["Orange"]          = "FFConsumerSolidOrange",
}

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves.new(parent) -> HueSaturationCurves object
--- Constructor
--- Creates a new HueSaturationCurves object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A HueSaturationCurves object
function HueSaturationCurves.new(parent)
    local o = {
        _parent = parent,
        _child = {}
    }

    return prop.extend(o, HueSaturationCurves)
end

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves:parent() -> table
--- Method
--- Returns the HueSaturationCurves's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function HueSaturationCurves:parent()
    return self._parent
end

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function HueSaturationCurves:app()
    return self:parent():app()
end

--------------------------------------------------------------------------------
--
-- HUE/SATURATION CURVES:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves:isShowing() -> boolean
--- Method
--- Is the Hue/Saturation Curves panel currently showing?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if showing, otherwise `false`
function HueSaturationCurves:isShowing()
    return self:parent():isShowing(CORRECTION_TYPE)
end

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

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves:viewMode([value]) -> string | nil
--- Method
--- Sets or gets the View Mode for the Hue/Saturation Curves.
---
--- Parameters:
---  * [value] - An optional value to set the View Mode, as defined in `cp.apple.finalcutpro.inspector.color.HueSaturationCurves.VIEW_MODES`.
---
--- Returns:
---  * A string containing the View Mode or `nil` if an error occurs.
---
--- Notes:
---  * Value can be:
---    * 6 Curves
---    * Single Curves
function HueSaturationCurves:viewMode(value)
    --------------------------------------------------------------------------------
    -- Validation:
    --------------------------------------------------------------------------------
    if value and not self.VIEW_MODES[value] then
        log.ef("Invalid Mode: %s", value)
        return nil
    end
    if not self:isShowing() then
        log.ef("Hue/Saturation Curves not active.")
        return nil
    end
    --------------------------------------------------------------------------------
    -- Check that the Color Inspector UI is available:
    --------------------------------------------------------------------------------
    local ui = self:parent():UI()
    if ui and ui[2] then
        --------------------------------------------------------------------------------
        -- Determine wheel mode based on whether or not the Radio Group exists:
        --------------------------------------------------------------------------------
        local selectedValue = "6 Curves"
        if ui[2]:attributeValue("AXRole") == "AXRadioGroup" then
            selectedValue = "Single Curves"
        end
        if value and selectedValue ~= value then
            --------------------------------------------------------------------------------
            -- Setter:
            --------------------------------------------------------------------------------
            ui[1]:performAction("AXPress") -- Press the "View" button
            if ui[1][1] then
                for _, child in ipairs(ui[1][1]) do
                    local title = child:attributeValue("AXTitle")
                    --local selected = child:attributeValue("AXMenuItemMarkChar") ~= nil
                    local app = self:app()
                    if title == app:string(self.VIEW_MODES["6 Curves"]) and value == "6 Curves" then
                        child:performAction("AXPress") -- Close the popup
                        return "6 Curves"
                    elseif title == app:string(self.VIEW_MODES["Single Curves"]) and value == "Single Curves" then
                        child:performAction("AXPress") -- Close the popup
                        return "Single Curves"
                    end
                end
                log.df("Failed to determine which View Mode was selected")
                return nil
            end
        else
            --------------------------------------------------------------------------------
            -- Getter:
            --------------------------------------------------------------------------------
            return selectedValue
        end
    else
        log.ef("Could not find Color Inspector UI.")
    end
    return nil
end

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves:visibleCurve([value]) -> string | nil
--- Method
--- Sets or gets the selected hue/saturation curve.
---
--- Parameters:
---  * [value] - An optional value to set the visible curve, as defined in `cp.apple.finalcutpro.inspector.color.HueSaturationCurves.CURVES`.
---
--- Returns:
---  * A string containing the selected color curve or `nil` if an error occurs.
---
--- Notes:
---  * Value can be:
---    * 6 Curves
---    * HvH
---    * HvS
---    * HvL
---    * LvS
---    * SvS
---    * Orange
---  * Example Usage:
---    `require("cp.apple.finalcutpro"):inspector():color():hueSaturationCurves():visibleCurve("HvH")`
function HueSaturationCurves:visibleCurve(value)
    --------------------------------------------------------------------------------
    -- Validation:
    --------------------------------------------------------------------------------
    if value and not self.CURVES[value] then
        log.ef("Invalid Curve: %s", value)
        return nil
    end
    if not self:isShowing() then
        log.ef("Color Curves not active.")
        return nil
    end
    --------------------------------------------------------------------------------
    -- Check that the Color Inspector UI is available:
    --------------------------------------------------------------------------------
    local ui = self:parent():UI()
    if ui and ui[2] then
        --------------------------------------------------------------------------------
        -- Setter:
        --------------------------------------------------------------------------------
        if value then
            self:viewMode("Single Curves")
            ui = self:parent():UI() -- Refresh the UI
            if ui and ui[2] and ui[2][1] then
                if value == "HvH" and ui[2][1]:attributeValue("AXValue") == 0 then
                    ui[2][1]:performAction("AXPress")
                elseif value == "HvS" and ui[2][2]:attributeValue("AXValue") == 0 then
                    ui[2][2]:performAction("AXPress")
                elseif value == "HvL" and ui[2][3]:attributeValue("AXValue") == 0 then
                    ui[2][3]:performAction("AXPress")
                elseif value == "LvS" and ui[2][4]:attributeValue("AXValue") == 0 then
                    ui[2][4]:performAction("AXPress")
                elseif value == "SvS" and ui[2][5]:attributeValue("AXValue") == 0 then
                    ui[2][5]:performAction("AXPress")
                elseif value == "Orange" and ui[2][6]:attributeValue("AXValue") == 0 then
                    ui[2][6]:performAction("AXPress")
                end
            else
                log.ef("Setting Visible Curve failed because UI was nil. This shouldn't happen.")
            end
        end
        --------------------------------------------------------------------------------
        -- Getter:
        --------------------------------------------------------------------------------
        if ui[2]:attributeValue("AXRole") == "AXRadioGroup" then
            if ui[2][1]:attributeValue("AXValue") == 1 then
                return "HvH"
            elseif ui[2][2]:attributeValue("AXValue") == 1 then
                return "HvS"
            elseif ui[2][3]:attributeValue("AXValue") == 1 then
                return "HvL"
            elseif ui[2][4]:attributeValue("AXValue") == 1 then
                return "LvS"
            elseif ui[2][5]:attributeValue("AXValue") == 1 then
                return "SvS"
            elseif ui[2][6]:attributeValue("AXValue") == 1 then
                return "Orange"
            end
        else
            return "6 Curves"
        end
    else
        log.ef("Could not find Color Inspector UI.")
    end
end

--- cp.apple.finalcutpro.inspector.color.HueSaturationCurves:mix([value]) -> number | nil
--- Method
--- Sets or gets the Hue/Saturation Curves mix value.
---
--- Parameters:
---  * [value] - An optional value you want to set the mix value to as number (0 to 1).
---
--- Returns:
---  * A number containing the mix value or `nil` if an error occurs.
function HueSaturationCurves:mix(value)

    --------------------------------------------------------------------------------
    -- Validation:
    --------------------------------------------------------------------------------
    if value then
        if type(value) ~= "number" then
            log.ef("Invalid Mix Value Type: %s", type(value))
            return nil
        end
        if value >= 0 and value <= 1 then
            log.df("Valid Value: %s", value)
        else
            log.ef("Invalid Mix Value: %s", value)
            return nil
        end
    end
    if not self:isShowing() then
        log.ef("Hue/Saturation Curves not active.")
        return nil
    end

    --------------------------------------------------------------------------------
    -- Find Mix Slider:
    --------------------------------------------------------------------------------
    local ui = self:parent():UI()
    local slider = nil
    for _, v in ipairs(ui) do
      if v:attributeValue("AXRole") == "AXSlider" then
        slider = v
      end
    end
    if not slider then
        log.ef("Could not find slider.")
        return nil
    end

    --------------------------------------------------------------------------------
    -- Setter:
    --------------------------------------------------------------------------------
    if value then
        slider:setAttributeValue("AXValue", value)
    end

    --------------------------------------------------------------------------------
    -- Getter:
    --------------------------------------------------------------------------------
    return slider:attributeValue("AXValue")

end

return HueSaturationCurves
