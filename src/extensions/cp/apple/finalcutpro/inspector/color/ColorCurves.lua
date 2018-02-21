--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                               = require("hs.logger").new("colorCurves")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local prop                              = require("cp.prop")

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
local ColorCurves = {}

--- cp.apple.finalcutpro.inspector.color.ColorCurves.VIEW_MODES -> table
--- Constant
--- View Modes for Color Curves
ColorCurves.VIEW_MODES = {
    ["All Curves"]      = "PAECurvesViewControllerVertical",
    ["Single Curves"]   = "PAECurvesViewControllerSingleControl",
}

--- cp.apple.finalcutpro.inspector.color.ColorCurves.CURVES -> table
--- Constant
--- Table containing all the different types of Color Curves
ColorCurves.CURVES = {
    ["Luma"]            = "PAECurvesViewControllerLuma",
    ["Red"]             = "Primatte::Red",
    ["Green"]           = "Primatte::Green",
    ["Blue"]            = "Primatte::Blue",
}

--- cp.apple.finalcutpro.inspector.color.ColorCurves:new(parent) -> ColorCurves object
--- Method
--- Creates a new ColorCurves object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A ColorInspector object
-- TODO: Use a Function instead of a Method.
function ColorCurves:new(parent) -- luacheck: ignore

    local o = {
        _parent = parent,
        _child = {}
    }

    return prop.extend(o, ColorCurves)
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves:parent() -> table
--- Method
--- Returns the ColorCurves's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function ColorCurves:parent()
    return self._parent
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function ColorCurves:app()
    return self:parent():app()
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

--- cp.apple.finalcutpro.inspector.color.ColorCurves:isShowing() -> boolean
--- Method
--- Is the Color Curves panel currently showing?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if showing, otherwise `false`
function ColorCurves:isShowing()
    return self:parent():isShowing(CORRECTION_TYPE)
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves:viewMode([value]) -> string | nil
--- Method
--- Sets or gets the View Mode for the Color Curves.
---
--- Parameters:
---  * [value] - An optional value to set the View Mode, as defined in `cp.apple.finalcutpro.inspector.color.ColorCurves.VIEW_MODES`.
---
--- Returns:
---  * A string containing the View Mode or `nil` if an error occurs.
---
--- Notes:
---  * Value can be:
---    * All Curves
---    * Single Curves
function ColorCurves:viewMode(value)
    --------------------------------------------------------------------------------
    -- Validation:
    --------------------------------------------------------------------------------
    if value and not self.VIEW_MODES[value] then
        log.ef("Invalid Mode: %s", value)
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
        -- Determine wheel mode based on whether or not the Radio Group exists:
        --------------------------------------------------------------------------------
        local selectedValue = "All Curves"
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
                    if title == app:string(self.VIEW_MODES["All Curves"]) and value == "All Curves" then
                        child:performAction("AXPress") -- Close the popup
                        return "All Curves"
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

--- cp.apple.finalcutpro.inspector.color.ColorCurves:visibleCurve([value]) -> string | nil
--- Method
--- Sets or gets the selected color curve.
---
--- Parameters:
---  * [value] - An optional value to set the visible curve, as defined in `cp.apple.finalcutpro.inspector.color.ColorCurves.CURVES`.
---
--- Returns:
---  * A string containing the selected color curve or `nil` if an error occurs.
---
--- Notes:
---  * Value can be:
---    * All Curves
---    * Luma
---    * Red
---    * Green
---    * Blue
---  * Example Usage:
---    `require("cp.apple.finalcutpro"):inspector():color():colorCurves():visibleCurve("Luma")`
function ColorCurves:visibleCurve(value)
    --------------------------------------------------------------------------------
    -- Validation:
    --------------------------------------------------------------------------------
    if value and not self.CURVES[value] then
        log.ef("Invalid Wheel: %s", value)
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
                if value == "Luma" and ui[2][1]:attributeValue("AXValue") == 0 then
                    ui[2][1]:performAction("AXPress")
                elseif value == "Red" and ui[2][2]:attributeValue("AXValue") == 0 then
                    ui[2][2]:performAction("AXPress")
                elseif value == "Green" and ui[2][3]:attributeValue("AXValue") == 0 then
                    ui[2][3]:performAction("AXPress")
                elseif value == "Blue" and ui[2][4]:attributeValue("AXValue") == 0 then
                    ui[2][4]:performAction("AXPress")
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
                return "Luma"
            elseif ui[2][2]:attributeValue("AXValue") == 1 then
                return "Red"
            elseif ui[2][3]:attributeValue("AXValue") == 1 then
                return "Green"
            elseif ui[2][4]:attributeValue("AXValue") == 1 then
                return "Blue"
            end
        else
            return "All Curves"
        end
    else
        log.ef("Could not find Color Inspector UI.")
    end
end

--- cp.apple.finalcutpro.inspector.color.ColorCurves:mix([value]) -> number | nil
--- Method
--- Sets or gets the color curves mix value.
---
--- Parameters:
---  * [value] - An optional value you want to set the mix value to as number (0 to 1).
---
--- Returns:
---  * A number containing the mix value or `nil` if an error occurs.
function ColorCurves:mix(value)

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
        log.ef("Color Curves not active.")
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

--- cp.apple.finalcutpro.inspector.color.ColorCurves:preserveLuma([value]) -> boolean
--- Method
--- Sets or gets whether or not Preserve Luma is active.
---
--- Parameters:
---  * [value] - An optional boolean value to set the Preserve Luma option.
---
--- Returns:
---  * `true` if Preserve Luma is selected, otherwise `false`.
function ColorCurves:preserveLuma(value)

    --------------------------------------------------------------------------------
    -- TODO: This currently only gets, not sets, because the checkbox is read only.
    --------------------------------------------------------------------------------

    --------------------------------------------------------------------------------
    -- Validation:
    --------------------------------------------------------------------------------
    if type(value) ~= "nil" then
        if type(value) ~= "boolean" then
            log.ef("Invalid Mix Value Type: %s", type(value))
            return nil
        end
    end
    if not self:isShowing() then
        log.ef("Color Curves not active.")
        return nil
    end

    --------------------------------------------------------------------------------
    -- Find Preserve Luma Chebox:
    --------------------------------------------------------------------------------
    local ui = self:parent():UI()
    local checkbox = nil
    for _, v in ipairs(ui) do
        if v:attributeValue("AXRole") == "AXCheckBox" then
            checkbox = v
        end
    end
    if not checkbox then
        log.ef("Could not find checkbox.")
        return nil
    end

    --------------------------------------------------------------------------------
    -- Setter:
    --------------------------------------------------------------------------------
    if type(value) == "boolean" then
        log.df("SETTER!")
        if value == true then
            log.df("SETTING TO TRUE")
            checkbox:setAttributeValue("AXValue", 1)
        else
            log.df("SETTING TO FALSE")
            checkbox:setAttributeValue("AXValue", 0)
        end
    end

    --------------------------------------------------------------------------------
    -- Getter:
    --------------------------------------------------------------------------------
    return checkbox:attributeValue("AXValue") == 1

end

return ColorCurves