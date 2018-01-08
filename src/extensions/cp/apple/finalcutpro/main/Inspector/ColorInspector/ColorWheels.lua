--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels ===
---
--- Color Wheels Module.
---
--- Requires Final Cut Pro 10.4 or later.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log                               = require("hs.logger").new("colorWheels")

local drawing 							= require("hs.drawing")
local inspect							= require("hs.inspect")

local axutils                           = require("cp.ui.axutils")
local prop                              = require("cp.prop")
local tools								= require("cp.tools")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

local CORRECTION_TYPE                   = "Color Wheels"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ColorWheels = {}

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels.VIEW_MODES -> table
--- Constant
--- View Modes for Color Wheels
ColorWheels.VIEW_MODES = {
    ["All Wheels"]      = "PAE4WayCorrectorViewControllerRhombus",
    ["Single Wheels"]   = "PAE4WayCorrectorViewControllerSingleControl",
}

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels.WHEELS -> table
--- Constant
--- Table containing all the different types of Color Wheels
ColorWheels.WHEELS = {
    ["Master"]          = "PAE4WayCorrectorViewControllerMaster",
    ["Shadows"]         = "PAE4WayCorrectorViewControllerShadows",
    ["Midtones"]        = "PAE4WayCorrectorViewControllerMidtones",
    ["Highlights"]      = "PAE4WayCorrectorViewControllerHighlights",
}

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels.COLOR_MODES -> table
--- Constant
--- View Modes for Color Wheels
ColorWheels.COLOR_MODES = {
    ["Red"]             = "Primatte::Red",
    ["Green"]           = "Primatte::Green",
    ["Blue"]            = "Primatte::Blue",
}

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels.NUDGE_DIRECTIONS -> table
--- Constant
--- Nudge Directions for Color Wheels
ColorWheels.NUDGE_DIRECTIONS = {
    ["Up"]				= "Cube::Up",
    ["Down"]			= "Cube::Down",
    ["Left"]			= "Cube::Left",
    ["Right"]			= "Cube::Right",
}

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS:
--------------------------------------------------------------------------------

-- colorWellValueToTable(value) -> table | nil
-- Function
-- Converts a AXColorWell Value to a table containing "Red", "Green" and "Blue" values.
--
-- Parameters:
--  * value - A AXColorWell Value String (i.e. "rgb 0.5 0 1 0")
--  * lowercase - Whether the case should be lowercase or should the first letter be uppercase, as a boolean
--
-- Returns:
--  * A table or `nil` if an error occurred.
local function colorWellValueToTable(value, lowercase)
    if type(value) ~= "string" then
        log.ef("Value to colorWellValueToTable was invalid: %s", value and inspect(value))
        return nil
    end
    local valueToTable = string.split(value, " ")
    if not valueToTable or #valueToTable ~= 5 then
        return nil
    end
    local a, b, c = "Red", "Green", "Blue"
    if lowercase then
    	a, b, c = "red", "green", "blue"
    end
    local result = {
        [a] = tonumber(valueToTable[2]),
        [b] = tonumber(valueToTable[3]),
        [c] = tonumber(valueToTable[4]),
    }
    return result
end

-- rgbTableToColorWellValue(value) -> table | nil
-- Function
-- Converts a table containing "Red", "Green" and "Blue" values to a AXColorWell value string.
--
-- Parameters:
--  * value - A table containing "Red", "Green" and "Blue" values
--
-- Returns:
--  * A string or `nil` if an error occurred.
--
-- Notes:
--  * The key values can be either all lowercase or the first letter can be uppercase (i.e. "Red" or "red").
local function rgbTableToColorWellValue(value)
	if type(value) ~= "table"
	or (type(value["Red"]) ~= "number" and type(value["red"]) ~= "number")
	or (type(value["Green"]) ~= "number" and type(value["green"]) ~= "number")
	or (type(value["Blue"]) ~= "number" and type(value["blue"]) ~= "number")
	then
		log.ef("Value to rgbTableToColorWellValue was invalid: %s", value and inspect(value))
		return nil
	else
		local red 		= value["Red"] or value["red"]
		local green 	= value["Green"] or value["green"]
		local blue 		= value["Blue"] or value["blue"]

		red = tools.round(red, 7)
		green = tools.round(green, 7)
		blue = tools.round(blue, 7)

		if red == 0 then red = "0" end
		if green == 0 then green = "0" end
		if blue == 0 then blue = "0" end

		return "rgb " .. red .. " " .. green .. " " .. blue .. " 0"
	end
end

-- invertTable(t) -> table | nil
-- Function
-- Inverts a table.
--
-- Parameters:
--  * t - the table you want to invert.
--
-- Returns:
--  * An inverted table.
function invertTable(t)
   local s={}
   for k,v in pairs(t) do
     s[v]=k
   end
   return s
end

--------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS & METHODS:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:new(parent) -> ColorInspector object
--- Method
--- Creates a new ColorWheels object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A ColorInspector object
function ColorWheels:new(parent)
    local o = {
        _parent = parent,
        _child = {}
    }

    return prop.extend(o, ColorWheels)
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:parent() -> table
--- Method
--- Returns the ColorWheels's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function ColorWheels:parent()
    return self._parent
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function ColorWheels:app()
    return self:parent():app()
end

--------------------------------------------------------------------------------
--
-- COLOR WHEELS:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:show() -> boolean
--- Method
--- Show's the Color Board within the Color Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorWheels object
function ColorWheels:show()
    self:parent():show(CORRECTION_TYPE)
    return self
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:isShowing() -> boolean
--- Method
--- Is the Color Wheels currently showing?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if showing, otherwise `false`
function ColorWheels:isShowing()
    return self:parent():isShowing(CORRECTION_TYPE)
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:viewMode([value]) -> string | nil
--- Method
--- Sets or gets the View Mode for the Color Wheels.
---
--- Parameters:
---  * [value] - An optional value to set the View Mode, as defined in `cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels.VIEW_MODES`.
---
--- Returns:
---  * A string containing the View Mode or `nil` if an error occurs.
---
--- Notes:
---  * Value can be:
---    * All Wheels
---    * Single Wheels
---  * Example Usage:
---    `require("cp.apple.finalcutpro"):inspector():colorInspector():colorWheels():viewMode("All Wheels")`
function ColorWheels:viewMode(value)
    --------------------------------------------------------------------------------
    -- Validation:
    --------------------------------------------------------------------------------
    if value and not self.VIEW_MODES[value] then
        log.ef("Invalid Mode: %s", value)
        return nil
    end
    if not self:isShowing() then
        log.ef("Color Wheels not active.")
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
        local selectedValue = "All Wheels"
        if ui[2]:attributeValue("AXRole") == "AXRadioGroup" then
            selectedValue = "Single Wheels"
        end
        if value and selectedValue ~= value then
            --------------------------------------------------------------------------------
            -- Setter:
            --------------------------------------------------------------------------------
            ui[1]:performAction("AXPress") -- Press the "View" button
            if ui[1][1] then
                for _, child in ipairs(ui[1][1]) do
                    local title = child:attributeValue("AXTitle")
                    local selected = child:attributeValue("AXMenuItemMarkChar") ~= nil
                    local app = self:app()
                    if title == app:string(self.VIEW_MODES["All Wheels"]) and value == "All Wheels" then
                        child:performAction("AXPress") -- Close the popup
                        return "All Wheels"
                    elseif title == app:string(self.VIEW_MODES["Single Wheels"]) and value == "Single Wheels" then
                        child:performAction("AXPress") -- Close the popup
                        return "Single Wheels"
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

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:visibleWheel([value]) -> string | nil
--- Method
--- Sets or gets the selected color wheel.
---
--- Parameters:
---  * [value] - An optional value to set the visible wheel, as defined in `cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels.WHEELS`.
---
--- Returns:
---  * A string containing the selected color wheel or `nil` if an error occurs.
---
--- Notes:
---  * Value can be:
---    * All Wheels
---    * Master
---    * Shadows
---    * Midtones
---    * Highlights
---  * Example Usage:
---    `require("cp.apple.finalcutpro"):inspector():colorInspector():colorWheels():visibleWheel("Shadows")`
function ColorWheels:visibleWheel(value)
    --------------------------------------------------------------------------------
    -- Validation:
    --------------------------------------------------------------------------------
    if value and not self.WHEELS[value] then
        log.ef("Invalid Wheel: %s", value)
        return nil
    end
    if not self:isShowing() then
        log.ef("Color Wheels not active.")
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
            self:viewMode("Single Wheels")
            local ui = self:parent():UI() -- Refresh the UI
            if ui and ui[2] and ui[2][1] then
                if value == "Master" and ui[2][1]:attributeValue("AXValue") == 0 then
                    ui[2][1]:performAction("AXPress")
                elseif value == "Shadows" and ui[2][2]:attributeValue("AXValue") == 0 then
                    ui[2][2]:performAction("AXPress")
                elseif value == "Midtones" and ui[2][3]:attributeValue("AXValue") == 0 then
                    ui[2][3]:performAction("AXPress")
                elseif value == "Highlights" and ui[2][4]:attributeValue("AXValue") == 0 then
                    ui[2][4]:performAction("AXPress")
                end
            else
                log.ef("Setting Visible Wheel failed because UI was nil. This shouldn't happen.")
            end
        end
        --------------------------------------------------------------------------------
        -- Getter:
        --------------------------------------------------------------------------------
        if ui[2]:attributeValue("AXRole") == "AXRadioGroup" then
            if ui[2][1]:attributeValue("AXValue") == 1 then
                return "Master"
            elseif ui[2][2]:attributeValue("AXValue") == 1 then
                return "Shadows"
            elseif ui[2][3]:attributeValue("AXValue") == 1 then
                return "Midtones"
            elseif ui[2][4]:attributeValue("AXValue") == 1 then
                return "Highlights"
            end
        else
            return "All Wheels"
        end
    else
        log.ef("Could not find Color Inspector UI.")
    end
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:color(wheel, color, [value]) -> number | nil
--- Method
--- Sets or gets a color wheel value.
---
--- Parameters:
---  * wheel - Which wheel you want to set/get ("Master, "Shadows", "Midtones" or "Highlights")
---  * color - Which color you want to set or get ("Red", "Green" or "Blue")
---  * [value] - An optional value you want to set the supplied wheel/color to as number (-255 to 255).
---
--- Returns:
---  * A number containing the selected color wheel value or `nil` if an error occurs.
---
--- Notes:
---  * Example Usage:
---    `require("cp.apple.finalcutpro"):inspector():colorInspector():colorWheels():color("Master", "Red", 255)`
function ColorWheels:color(wheel, color, value)

    --------------------------------------------------------------------------------
    -- TODO: Currently this code is relying on the RGB Color Text-boxes to manipulate
    --       the Color Wheel values. Whilst this works, it would be much better if
    --       we used the AXValue from the AXColorWell instead, so that we don't have
    --       to "show" the various Master/Shadow/Midtones/Highlights drop-downs.
    --------------------------------------------------------------------------------

    --------------------------------------------------------------------------------
    -- Validation:
    --------------------------------------------------------------------------------
    if type(wheel) ~= "string" or not self.WHEELS[wheel] then
        log.ef("Invalid Wheel: %s", wheel)
        return nil
    end
    if color and not self.COLOR_MODES[color] then
        log.ef("Invalid Color: %s", color)
        return nil
    end
    if value then
        if type(value) ~= "number" then
            log.ef("Invalid Color Value Type: %s", type(value))
            return nil
        end
        if value >= -255 and value <= 255 then
            --log.df("Valid Value: %s", value)
        else
            log.ef("Invalid Color Value: %s", value)
            return nil
        end
    end
    if not self:isShowing() then
        log.ef("Color Wheels not active.")
        return nil
    end
    --------------------------------------------------------------------------------
    -- If in Single Wheel mode and not correct wheel, change the wheel:
    --------------------------------------------------------------------------------
    local viewMode = self:viewMode()
    if viewMode == "Single Wheels" then
        --------------------------------------------------------------------------------
        -- Single Wheel:
        --------------------------------------------------------------------------------
        local visibleWheel = self:visibleWheel()
        if visibleWheel ~= wheel then
            self:visibleWheel(wheel)
        end
        local visibleWheel = self:visibleWheel()
        if visibleWheel == wheel then
            local ui = self:parent():UI()

            --------------------------------------------------------------------------------
            -- Open the required dropdown if closed:
            --------------------------------------------------------------------------------
            local checkboxes = {}
            for _, child in ipairs(ui) do
                if child:attributeValue("AXRole") == "AXCheckBox" then
                    table.insert(checkboxes, child)
                end
            end

            if #checkboxes ~= 4 then
                log.ef("Incorrect number of checkboxes found.")
                return nil
            end

            local showing = {}
            showing["Master"]       = checkboxes[1]:attributeValue("AXValue") == 1 or false
            showing["Shadows"]      = checkboxes[2]:attributeValue("AXValue") == 1 or false
            showing["Midtones"]     = checkboxes[3]:attributeValue("AXValue") == 1 or false
            showing["Highlights"]   = checkboxes[4]:attributeValue("AXValue") == 1 or false

            if wheel == "Master" and not showing["Master"] == true then
                checkboxes[1]:performAction("AXPress")
            elseif wheel == "Shadows" and not showing["Shadows"] == true then
                checkboxes[2]:performAction("AXPress")
            elseif wheel == "Midtones" and not showing["Midtones"] == true then
                checkboxes[3]:performAction("AXPress")
            elseif wheel == "Highlights" and not showing["Highlights"] == true then
                checkboxes[4]:performAction("AXPress")
            end

            --------------------------------------------------------------------------------
            -- Refresh the UI:
            --------------------------------------------------------------------------------
            local ui = self:parent():UI()

            if ui and ui[2] then

                local startingID = 28 -- The Master Color Red Textbox
                if color == "Green" then
                    startingID = startingID - 2 -- 26
                elseif color == "Blue" then
                    startingID = startingID - 4 -- 24
                end

                local offset = 0
                local offsetAmount = 13
                if wheel == "Master" then
                    --------------------------------------------------------------------------------
                    -- Master Red Textbox with only Master Tab showing = 28
                    --------------------------------------------------------------------------------
                    if value then
                        ui[startingID]:setAttributeValue("AXValue", tostring(value))
                    end
                    return tonumber(ui[startingID]:attributeValue("AXValue"))
                elseif wheel == "Shadows" then
                    --------------------------------------------------------------------------------
                    -- Shadows Red Textbox with only Shadows Tab showing = 31
                    --------------------------------------------------------------------------------
                    if showing["Master"] == true then offset = offset + offsetAmount end
                    if value then
                        ui[startingID + 3 + offset]:setAttributeValue("AXValue", tostring(value))
                    end
                    return tonumber(ui[startingID + 3 + offset]:attributeValue("AXValue"))
                elseif wheel == "Midtones" then
                    --------------------------------------------------------------------------------
                    -- Midtones Red Textbox with only Shadows Tab showing = 34
                    --------------------------------------------------------------------------------
                    if showing["Master"] == true then offset = offset + offsetAmount end
                    if showing["Shadows"] == true then offset = offset + offsetAmount end
                    if value then
                        ui[startingID + 6 + offset]:setAttributeValue("AXValue", tostring(value))
                    end
                    return tonumber(ui[startingID + 6 + offset]:attributeValue("AXValue"))
                elseif wheel == "Highlights" then
                    if showing["Master"] == true then offset = offset + offsetAmount end
                    if showing["Shadows"] == true then offset = offset + offsetAmount end
                    if showing["Midtones"] == true then offset = offset + offsetAmount end
                    if value then
                        ui[startingID + 9 + offset]:setAttributeValue("AXValue", tostring(value))
                    end
                    return tonumber(ui[startingID + 9 + offset]:attributeValue("AXValue"))
                end

            else
                log.ef("Failed to get Color Inspector UI")
                return nil
            end
        else
            log.ef("Failed to change to correct wheel. This shouldn't happen.")
            return nil
        end

    elseif viewMode == "All Wheels" then
        --------------------------------------------------------------------------------
        -- All Wheels:
        --------------------------------------------------------------------------------
        local ui = self:parent():UI()

        --------------------------------------------------------------------------------
        -- Open the required dropdown if closed:
        --------------------------------------------------------------------------------
        local checkboxes = {}
        for _, child in ipairs(ui) do
            if child:attributeValue("AXRole") == "AXCheckBox" then
                table.insert(checkboxes, child)
            end
        end

        if #checkboxes ~= 4 then
            log.ef("Incorrect number of checkboxes found.")
            return nil
        end

        local showing = {}
        showing["Master"]       = checkboxes[1]:attributeValue("AXValue") == 1 or false
        showing["Shadows"]      = checkboxes[2]:attributeValue("AXValue") == 1 or false
        showing["Midtones"]     = checkboxes[3]:attributeValue("AXValue") == 1 or false
        showing["Highlights"]   = checkboxes[4]:attributeValue("AXValue") == 1 or false

        if wheel == "Master" and not showing["Master"] == true then
            checkboxes[1]:performAction("AXPress")
        elseif wheel == "Shadows" and not showing["Shadows"] == true then
            checkboxes[2]:performAction("AXPress")
        elseif wheel == "Midtones" and not showing["Midtones"] == true then
            checkboxes[3]:performAction("AXPress")
        elseif wheel == "Highlights" and not showing["Highlights"] == true then
            checkboxes[4]:performAction("AXPress")
        end

        --------------------------------------------------------------------------------
        -- Refresh the UI:
        --------------------------------------------------------------------------------
        local ui = self:parent():UI()

        if ui and ui[2] then

            local startingID = 30 -- The Master Color Red Textbox
            if color == "Green" then
                startingID = startingID - 2
            elseif color == "Blue" then
                startingID = startingID - 4
            end

            local offset = 0
            local offsetAmount = 13
            if wheel == "Master" then
                if value then
                    ui[startingID]:setAttributeValue("AXValue", tostring(value))
                end
                return tonumber(ui[startingID]:attributeValue("AXValue"))
            elseif wheel == "Shadows" then
                if showing["Master"] == true then offset = offset + offsetAmount end
                if value then
                    ui[startingID + 3 + offset]:setAttributeValue("AXValue", tostring(value))
                end
                return tonumber(ui[startingID + 3 + offset]:attributeValue("AXValue"))
            elseif wheel == "Midtones" then
                if showing["Master"] == true then offset = offset + offsetAmount end
                if showing["Shadows"] == true then offset = offset + offsetAmount end
                if value then
                    ui[startingID + 6 + offset]:setAttributeValue("AXValue", tostring(value))
                end
                return tonumber(ui[startingID + 6 + offset]:attributeValue("AXValue"))
            elseif wheel == "Highlights" then
                if showing["Master"] == true then offset = offset + offsetAmount end
                if showing["Shadows"] == true then offset = offset + offsetAmount end
                if showing["Midtones"] == true then offset = offset + offsetAmount end
                if value then
                    ui[startingID + 9 + offset]:setAttributeValue("AXValue", tostring(value))
                end
                return tonumber(ui[startingID + 9 + offset]:attributeValue("AXValue"))
            end
        else
            log.ef("Failed to get Color Inspector UI")
            return nil
        end
    else
        log.ef("Failed to detect view mode. This shouldn't happen.")
        return nil
    end
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:nudgeControl(wheel, direction) -> boolean
--- Method
--- Moves a Color Wheel puck/control in a specific direction.
---
--- Parameters:
---  * wheel - Which wheel you want to set/get ("Master, "Shadows", "Midtones" or "Highlights")
---  * direction - Which direction you want to nudge the wheel control ("Up", "Down", "Left" or "Right")
---
--- Returns:
---  * `true` if successful otherwise `nil`
function ColorWheels:nudgeControl(wheel, direction)

	--------------------------------------------------------------------------------
    -- TODO: We're currently using the Color Board shortcuts, however this is less
    --       than ideal, as the shortcuts aren't assigned by default. Instead we
    --       should be using GUI Scripting on the AXColorWell.
    --------------------------------------------------------------------------------

    --------------------------------------------------------------------------------
    -- Validation:
    --------------------------------------------------------------------------------
    if type(wheel) ~= "string" or not self.WHEELS[wheel] then
        log.ef("Invalid Wheel: %s", wheel)
        return nil
    end
    if type(direction) ~= "string" or not self.NUDGE_DIRECTIONS[direction] then
        log.ef("Invalid Direction: %s", direction)
        return nil
    end

    if direction == "Up" then
    	self:app():performShortcut("ColorBoard-NudgePuckUp")
    elseif direction == "Down" then
	    self:app():performShortcut("ColorBoard-NudgePuckDown")
    elseif direction == "Left" then
    	self:app():performShortcut("ColorBoard-NudgePuckLeft")
    elseif direction == "Right" then
    	self:app():performShortcut("ColorBoard-NudgePuckRight")
	end

	return true

end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:saturation(wheel, [value]) -> number | nil
--- Method
--- Sets or gets a color wheel saturation.
---
--- Parameters:
---  * wheel - Which wheel you want to set/get ("Master, "Shadows", "Midtones" or "Highlights")
---  * [value] - An optional value you want to set the saturation to as number (0 to 2).
---
--- Returns:
---  * A number containing the saturation value or `nil` if an error occurs.
---
--- Notes:
---  * Although in Final Cut Pro you can push the saturation to 10 - this isn't possible with GUI Scripting for whatever reason.
function ColorWheels:saturation(wheel, value)

	--------------------------------------------------------------------------------
	-- 				AXValueIndicator:		Final Cut Pro:
	-- Min: 		0						0
	-- Default: 	0.5						1
	-- Max: 		1						2
	--------------------------------------------------------------------------------

    --------------------------------------------------------------------------------
    -- Validation:
    --------------------------------------------------------------------------------
    if type(wheel) ~= "string" or not self.WHEELS[wheel] then
        log.ef("Invalid Wheel: %s", wheel)
        return nil
    end
    if value then
        if type(value) ~= "number" then
            log.ef("Invalid Saturation Value Type: %s", type(value))
            return nil
        end
        if value >= 0 and value <= 2 then
            --log.df("Valid Value: %s", value)
        else
            log.ef("Invalid Saturation Value: %s", value)
            return nil
        end
    end

	local factor = 2
	local ui = self:parent():UI()
	local saturationUI = nil
	local viewMode = self:viewMode()

    if viewMode == "Single Wheels" then
    	saturationUI = ui[3][3]
    elseif viewMode == "All Wheels" then
    	if wheel == "Master" then
    		saturationUI = ui[2][3]
    	elseif wheel == "Shadows" then
    		saturationUI = ui[3][3]
    	elseif wheel == "Midtones" then
    		saturationUI = ui[4][3]
    	elseif wheel == "Highlights" then
	    	saturationUI = ui[5][3]
	    end
	else
        log.ef("Failed to detect view mode. This shouldn't happen.")
        return nil
	end
	if saturationUI then
		if value then
			saturationUI:setAttributeValue("AXValue", value / factor)
			return saturationUI:attributeValue("AXValue") * factor
		else
			return saturationUI:attributeValue("AXValue") * factor
		end
	else
		log.ef("Failed to get Saturation UI.")
		return nil
	end

end

-- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:_buildBrightnessMap() -> None
-- Method
-- Displays the code needed for the brightness map table in the Error Log. This is for developers use only.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
function ColorWheels:_buildBrightnessMap()
	local ui = self:parent():UI()
	local brightnessUI = nil
	local viewMode = self:viewMode()

	brightnessSliderUI = ui[3][4]
    brightnessTextUI = ui[33]
    local result = "local map = {"
	for i = 0, 1, 0.001 do
		brightnessSliderUI:setAttributeValue("AXValue", tostring(i))
		result = result .. string.format("[%s] = %s,", tools.round(brightnessSliderUI:attributeValue("AXValue"), 3), tonumber(brightnessTextUI:attributeValue("AXValue"))) .. "\n"
	end
	result = result .. "}"
	log.df(result)
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:brightness(wheel, [value]) -> number | nil
--- Method
--- Sets or gets a color wheel brightness.
---
--- Parameters:
---  * wheel - Which wheel you want to set/get ("Master, "Shadows", "Midtones" or "Highlights")
---  * [value] - An optional value you want to set the brightness to as number (-1 to 1).
---
--- Returns:
---  * A number containing the brightness value or `nil` if an error occurs.
---
--- Notes:
---  * Although technically brightness can go down to -12 and up to 10, we're limiting it to the sliders limits.
function ColorWheels:brightness(wheel, value)

	--------------------------------------------------------------------------------
	-- 				AXValueIndicator:		Final Cut Pro:
	--				-5.5					-12
	-- Min: 		0						-1
	-- Default: 	0.5						0
	-- Max: 		1						1
	-- 				5.5						10
	--
	-- 				0.20					-0.61
	--          	0.87					0.75
	--
	--------------------------------------------------------------------------------

	--------------------------------------------------------------------------------
	-- Hardcoded Value Map - which is far less than ideal.
	--
	-- TODO: David to replace this map with a formula if we can work it out.
	--------------------------------------------------------------------------------
	local map = {
		[0.001] = -1,
		[0.002] = -1,
		[0.003] = -0.99,
		[0.004] = -0.99,
		[0.005] = -0.99,
		[0.006] = -0.99,
		[0.007] = -0.99,
		[0.008] = -0.98,
		[0.009] = -0.98,
		[0.01] = -0.98,
		[0.011] = -0.98,
		[0.012] = -0.98,
		[0.013] = -0.98,
		[0.014] = -0.97,
		[0.015] = -0.97,
		[0.016] = -0.97,
		[0.017] = -0.97,
		[0.018] = -0.97,
		[0.019] = -0.96,
		[0.02] = -0.96,
		[0.021] = -0.96,
		[0.022] = -0.96,
		[0.023] = -0.96,
		[0.024] = -0.95,
		[0.025] = -0.95,
		[0.026] = -0.95,
		[0.027] = -0.95,
		[0.028] = -0.95,
		[0.029] = -0.94,
		[0.03] = -0.94,
		[0.031] = -0.94,
		[0.032] = -0.94,
		[0.033] = -0.93,
		[0.034] = -0.93,
		[0.035] = -0.93,
		[0.036] = -0.93,
		[0.037] = -0.93,
		[0.038] = -0.92,
		[0.039] = -0.92,
		[0.04] = -0.92,
		[0.041] = -0.92,
		[0.042] = -0.92,
		[0.043] = -0.91,
		[0.044] = -0.91,
		[0.045] = -0.91,
		[0.046] = -0.91,
		[0.047] = -0.91,
		[0.048] = -0.91,
		[0.049] = -0.91,
		[0.05] = -0.9,
		[0.051] = -0.9,
		[0.052] = -0.9,
		[0.053] = -0.89,
		[0.054] = -0.89,
		[0.055] = -0.89,
		[0.056] = -0.89,
		[0.057] = -0.89,
		[0.058] = -0.88,
		[0.059] = -0.88,
		[0.06] = -0.88,
		[0.061] = -0.88,
		[0.062] = -0.88,
		[0.063] = -0.88,
		[0.064] = -0.87,
		[0.065] = -0.87,
		[0.066] = -0.87,
		[0.067] = -0.87,
		[0.068] = -0.87,
		[0.069] = -0.87,
		[0.07] = -0.86,
		[0.071] = -0.86,
		[0.072] = -0.86,
		[0.073] = -0.86,
		[0.074] = -0.85,
		[0.075] = -0.85,
		[0.076] = -0.85,
		[0.077] = -0.85,
		[0.078] = -0.84,
		[0.079] = -0.84,
		[0.08] = -0.84,
		[0.081] = -0.84,
		[0.082] = -0.84,
		[0.083] = -0.83,
		[0.084] = -0.83,
		[0.085] = -0.83,
		[0.086] = -0.83,
		[0.087] = -0.83,
		[0.088] = -0.83,
		[0.089] = -0.82,
		[0.09] = -0.82,
		[0.091] = -0.82,
		[0.092] = -0.82,
		[0.093] = -0.82,
		[0.094] = -0.81,
		[0.095] = -0.81,
		[0.096] = -0.81,
		[0.097] = -0.81,
		[0.098] = -0.81,
		[0.099] = -0.8,
		[0.1] = -0.8,
		[0.101] = -0.8,
		[0.102] = -0.8,
		[0.103] = -0.8,
		[0.104] = -0.79,
		[0.105] = -0.79,
		[0.106] = -0.79,
		[0.107] = -0.79,
		[0.108] = -0.78,
		[0.109] = -0.78,
		[0.11] = -0.78,
		[0.111] = -0.78,
		[0.112] = -0.78,
		[0.113] = -0.77,
		[0.114] = -0.77,
		[0.115] = -0.77,
		[0.116] = -0.77,
		[0.117] = -0.77,
		[0.118] = -0.76,
		[0.119] = -0.76,
		[0.12] = -0.76,
		[0.121] = -0.76,
		[0.122] = -0.76,
		[0.123] = -0.75,
		[0.124] = -0.75,
		[0.125] = -0.75,
		[0.126] = -0.75,
		[0.127] = -0.75,
		[0.128] = -0.74,
		[0.129] = -0.74,
		[0.13] = -0.74,
		[0.131] = -0.74,
		[0.132] = -0.74,
		[0.133] = -0.73,
		[0.134] = -0.73,
		[0.135] = -0.73,
		[0.136] = -0.73,
		[0.137] = -0.73,
		[0.138] = -0.72,
		[0.139] = -0.72,
		[0.14] = -0.72,
		[0.141] = -0.72,
		[0.142] = -0.72,
		[0.143] = -0.71,
		[0.144] = -0.71,
		[0.145] = -0.71,
		[0.146] = -0.71,
		[0.147] = -0.71,
		[0.148] = -0.7,
		[0.149] = -0.7,
		[0.15] = -0.7,
		[0.151] = -0.7,
		[0.152] = -0.7,
		[0.153] = -0.7,
		[0.154] = -0.69,
		[0.155] = -0.69,
		[0.156] = -0.69,
		[0.157] = -0.69,
		[0.158] = -0.68,
		[0.159] = -0.68,
		[0.16] = -0.68,
		[0.161] = -0.68,
		[0.162] = -0.68,
		[0.163] = -0.67,
		[0.164] = -0.67,
		[0.165] = -0.67,
		[0.166] = -0.67,
		[0.167] = -0.67,
		[0.168] = -0.67,
		[0.169] = -0.66,
		[0.17] = -0.66,
		[0.171] = -0.66,
		[0.172] = -0.66,
		[0.173] = -0.65,
		[0.174] = -0.65,
		[0.175] = -0.65,
		[0.176] = -0.65,
		[0.177] = -0.65,
		[0.178] = -0.64,
		[0.179] = -0.64,
		[0.18] = -0.64,
		[0.181] = -0.64,
		[0.182] = -0.64,
		[0.183] = -0.63,
		[0.184] = -0.63,
		[0.185] = -0.63,
		[0.186] = -0.63,
		[0.187] = -0.63,
		[0.188] = -0.62,
		[0.189] = -0.62,
		[0.19] = -0.62,
		[0.191] = -0.62,
		[0.192] = -0.62,
		[0.193] = -0.61,
		[0.194] = -0.61,
		[0.195] = -0.61,
		[0.196] = -0.61,
		[0.197] = -0.61,
		[0.198] = -0.6,
		[0.199] = -0.6,
		[0.2] = -0.6,
		[0.201] = -0.6,
		[0.202] = -0.6,
		[0.203] = -0.59,
		[0.204] = -0.59,
		[0.205] = -0.59,
		[0.206] = -0.59,
		[0.207] = -0.59,
		[0.208] = -0.58,
		[0.209] = -0.58,
		[0.21] = -0.58,
		[0.211] = -0.58,
		[0.212] = -0.58,
		[0.213] = -0.57,
		[0.214] = -0.57,
		[0.215] = -0.57,
		[0.216] = -0.57,
		[0.217] = -0.57,
		[0.218] = -0.56,
		[0.219] = -0.56,
		[0.22] = -0.56,
		[0.221] = -0.56,
		[0.222] = -0.56,
		[0.223] = -0.55,
		[0.224] = -0.55,
		[0.225] = -0.55,
		[0.226] = -0.55,
		[0.227] = -0.55,
		[0.228] = -0.54,
		[0.229] = -0.54,
		[0.23] = -0.54,
		[0.231] = -0.54,
		[0.232] = -0.54,
		[0.233] = -0.53,
		[0.234] = -0.53,
		[0.235] = -0.53,
		[0.236] = -0.53,
		[0.237] = -0.53,
		[0.238] = -0.52,
		[0.239] = -0.52,
		[0.24] = -0.52,
		[0.241] = -0.52,
		[0.242] = -0.52,
		[0.243] = -0.51,
		[0.244] = -0.51,
		[0.245] = -0.51,
		[0.246] = -0.51,
		[0.247] = -0.51,
		[0.248] = -0.5,
		[0.249] = -0.5,
		[0.25] = -0.5,
		[0.251] = -0.5,
		[0.252] = -0.5,
		[0.253] = -0.49,
		[0.254] = -0.49,
		[0.255] = -0.49,
		[0.256] = -0.49,
		[0.257] = -0.49,
		[0.258] = -0.48,
		[0.259] = -0.48,
		[0.26] = -0.48,
		[0.261] = -0.48,
		[0.262] = -0.48,
		[0.263] = -0.47,
		[0.264] = -0.47,
		[0.265] = -0.47,
		[0.266] = -0.47,
		[0.267] = -0.47,
		[0.268] = -0.46,
		[0.269] = -0.46,
		[0.27] = -0.46,
		[0.271] = -0.46,
		[0.272] = -0.46,
		[0.273] = -0.45,
		[0.274] = -0.45,
		[0.275] = -0.45,
		[0.276] = -0.45,
		[0.277] = -0.45,
		[0.278] = -0.44,
		[0.279] = -0.44,
		[0.28] = -0.44,
		[0.281] = -0.44,
		[0.282] = -0.44,
		[0.283] = -0.43,
		[0.284] = -0.43,
		[0.285] = -0.43,
		[0.286] = -0.43,
		[0.287] = -0.43,
		[0.288] = -0.42,
		[0.289] = -0.42,
		[0.29] = -0.42,
		[0.291] = -0.42,
		[0.292] = -0.42,
		[0.293] = -0.41,
		[0.294] = -0.41,
		[0.295] = -0.41,
		[0.296] = -0.41,
		[0.297] = -0.41,
		[0.298] = -0.4,
		[0.299] = -0.4,
		[0.3] = -0.4,
		[0.301] = -0.4,
		[0.302] = -0.4,
		[0.303] = -0.39,
		[0.304] = -0.39,
		[0.305] = -0.39,
		[0.306] = -0.39,
		[0.307] = -0.39,
		[0.308] = -0.38,
		[0.309] = -0.38,
		[0.31] = -0.38,
		[0.311] = -0.38,
		[0.312] = -0.38,
		[0.313] = -0.37,
		[0.314] = -0.37,
		[0.315] = -0.37,
		[0.316] = -0.37,
		[0.317] = -0.37,
		[0.318] = -0.36,
		[0.319] = -0.36,
		[0.32] = -0.36,
		[0.321] = -0.36,
		[0.322] = -0.36,
		[0.323] = -0.35,
		[0.324] = -0.35,
		[0.325] = -0.35,
		[0.326] = -0.35,
		[0.327] = -0.35,
		[0.328] = -0.34,
		[0.329] = -0.34,
		[0.33] = -0.34,
		[0.331] = -0.34,
		[0.332] = -0.34,
		[0.333] = -0.33,
		[0.334] = -0.33,
		[0.335] = -0.33,
		[0.336] = -0.33,
		[0.337] = -0.33,
		[0.338] = -0.33,
		[0.339] = -0.32,
		[0.34] = -0.32,
		[0.341] = -0.32,
		[0.342] = -0.32,
		[0.343] = -0.31,
		[0.344] = -0.31,
		[0.345] = -0.31,
		[0.346] = -0.31,
		[0.347] = -0.31,
		[0.348] = -0.31,
		[0.349] = -0.3,
		[0.35] = -0.3,
		[0.351] = -0.3,
		[0.352] = -0.3,
		[0.353] = -0.3,
		[0.354] = -0.29,
		[0.355] = -0.29,
		[0.356] = -0.29,
		[0.357] = -0.29,
		[0.358] = -0.29,
		[0.359] = -0.28,
		[0.36] = -0.28,
		[0.361] = -0.28,
		[0.362] = -0.28,
		[0.363] = -0.27,
		[0.364] = -0.27,
		[0.365] = -0.27,
		[0.366] = -0.27,
		[0.367] = -0.27,
		[0.368] = -0.26,
		[0.369] = -0.26,
		[0.37] = -0.26,
		[0.371] = -0.26,
		[0.372] = -0.26,
		[0.373] = -0.25,
		[0.374] = -0.25,
		[0.375] = -0.25,
		[0.376] = -0.25,
		[0.377] = -0.25,
		[0.378] = -0.24,
		[0.379] = -0.24,
		[0.38] = -0.24,
		[0.381] = -0.24,
		[0.382] = -0.24,
		[0.383] = -0.23,
		[0.384] = -0.23,
		[0.385] = -0.23,
		[0.386] = -0.23,
		[0.387] = -0.23,
		[0.388] = -0.22,
		[0.389] = -0.22,
		[0.39] = -0.22,
		[0.391] = -0.22,
		[0.392] = -0.22,
		[0.393] = -0.21,
		[0.394] = -0.21,
		[0.395] = -0.21,
		[0.396] = -0.21,
		[0.397] = -0.21,
		[0.398] = -0.2,
		[0.399] = -0.2,
		[0.4] = -0.2,
		[0.401] = -0.2,
		[0.402] = -0.2,
		[0.403] = -0.19,
		[0.404] = -0.19,
		[0.405] = -0.19,
		[0.406] = -0.19,
		[0.407] = -0.19,
		[0.408] = -0.18,
		[0.409] = -0.18,
		[0.41] = -0.18,
		[0.411] = -0.18,
		[0.412] = -0.18,
		[0.413] = -0.17,
		[0.414] = -0.17,
		[0.415] = -0.17,
		[0.416] = -0.17,
		[0.417] = -0.17,
		[0.418] = -0.16,
		[0.419] = -0.16,
		[0.42] = -0.16,
		[0.421] = -0.16,
		[0.422] = -0.16,
		[0.423] = -0.15,
		[0.424] = -0.15,
		[0.425] = -0.15,
		[0.426] = -0.15,
		[0.427] = -0.15,
		[0.428] = -0.14,
		[0.429] = -0.14,
		[0.43] = -0.14,
		[0.431] = -0.14,
		[0.432] = -0.14,
		[0.433] = -0.13,
		[0.434] = -0.13,
		[0.435] = -0.13,
		[0.436] = -0.13,
		[0.437] = -0.13,
		[0.438] = -0.13,
		[0.439] = -0.12,
		[0.44] = -0.12,
		[0.441] = -0.12,
		[0.442] = -0.12,
		[0.443] = -0.11,
		[0.444] = -0.11,
		[0.445] = -0.11,
		[0.446] = -0.11,
		[0.447] = -0.11,
		[0.448] = -0.1,
		[0.449] = -0.1,
		[0.45] = -0.1,
		[0.451] = -0.1,
		[0.452] = -0.1,
		[0.453] = -0.09,
		[0.454] = -0.09,
		[0.455] = -0.09,
		[0.456] = -0.09,
		[0.457] = -0.09,
		[0.458] = -0.09,
		[0.459] = -0.08,
		[0.46] = -0.08,
		[0.461] = -0.08,
		[0.462] = -0.08,
		[0.463] = -0.07,
		[0.464] = -0.07,
		[0.465] = -0.07,
		[0.466] = -0.07,
		[0.467] = -0.07,
		[0.468] = -0.06,
		[0.469] = -0.06,
		[0.47] = -0.06,
		[0.471] = -0.06,
		[0.472] = -0.06,
		[0.473] = -0.05,
		[0.474] = -0.05,
		[0.475] = -0.05,
		[0.476] = -0.05,
		[0.477] = -0.05,
		[0.478] = -0.05,
		[0.479] = -0.04,
		[0.48] = -0.04,
		[0.481] = -0.04,
		[0.482] = -0.04,
		[0.483] = -0.03,
		[0.484] = -0.03,
		[0.485] = -0.03,
		[0.486] = -0.03,
		[0.487] = -0.03,
		[0.488] = -0.03,
		[0.489] = -0.02,
		[0.49] = -0.02,
		[0.491] = -0.02,
		[0.492] = -0.02,
		[0.493] = -0.01,
		[0.494] = -0.01,
		[0.495] = -0.01,
		[0.496] = -0.01,
		[0.497] = -0.01,
		[0.498] = 0,
		[0.499] = 0,
		[0.5] = 0,
		[0.501] = 0,
		[0.502] = 0,
		[0.503] = 0.01,
		[0.504] = 0.01,
		[0.505] = 0.01,
		[0.506] = 0.01,
		[0.507] = 0.01,
		[0.508] = 0.02,
		[0.509] = 0.02,
		[0.51] = 0.02,
		[0.511] = 0.02,
		[0.512] = 0.02,
		[0.513] = 0.03,
		[0.514] = 0.03,
		[0.515] = 0.03,
		[0.516] = 0.03,
		[0.517] = 0.03,
		[0.518] = 0.04,
		[0.519] = 0.04,
		[0.52] = 0.04,
		[0.521] = 0.04,
		[0.522] = 0.04,
		[0.523] = 0.05,
		[0.524] = 0.05,
		[0.525] = 0.05,
		[0.526] = 0.05,
		[0.527] = 0.05,
		[0.528] = 0.05,
		[0.529] = 0.06,
		[0.53] = 0.06,
		[0.531] = 0.06,
		[0.532] = 0.06,
		[0.533] = 0.07,
		[0.534] = 0.07,
		[0.535] = 0.07,
		[0.536] = 0.07,
		[0.537] = 0.07,
		[0.538] = 0.08,
		[0.539] = 0.08,
		[0.54] = 0.08,
		[0.541] = 0.08,
		[0.542] = 0.08,
		[0.543] = 0.09,
		[0.544] = 0.09,
		[0.545] = 0.09,
		[0.546] = 0.09,
		[0.547] = 0.09,
		[0.548] = 0.1,
		[0.549] = 0.1,
		[0.55] = 0.1,
		[0.551] = 0.1,
		[0.552] = 0.1,
		[0.553] = 0.11,
		[0.554] = 0.11,
		[0.555] = 0.11,
		[0.556] = 0.11,
		[0.557] = 0.11,
		[0.558] = 0.11,
		[0.559] = 0.12,
		[0.56] = 0.12,
		[0.561] = 0.12,
		[0.562] = 0.12,
		[0.563] = 0.12,
		[0.564] = 0.13,
		[0.565] = 0.13,
		[0.566] = 0.13,
		[0.567] = 0.13,
		[0.568] = 0.14,
		[0.569] = 0.14,
		[0.57] = 0.14,
		[0.571] = 0.14,
		[0.572] = 0.14,
		[0.573] = 0.15,
		[0.574] = 0.15,
		[0.575] = 0.15,
		[0.576] = 0.15,
		[0.577] = 0.15,
		[0.578] = 0.16,
		[0.579] = 0.16,
		[0.58] = 0.16,
		[0.581] = 0.16,
		[0.582] = 0.16,
		[0.583] = 0.17,
		[0.584] = 0.17,
		[0.585] = 0.17,
		[0.586] = 0.17,
		[0.587] = 0.17,
		[0.588] = 0.18,
		[0.589] = 0.18,
		[0.59] = 0.18,
		[0.591] = 0.18,
		[0.592] = 0.18,
		[0.593] = 0.19,
		[0.594] = 0.19,
		[0.595] = 0.19,
		[0.596] = 0.19,
		[0.597] = 0.19,
		[0.598] = 0.2,
		[0.599] = 0.2,
		[0.6] = 0.2,
		[0.601] = 0.2,
		[0.602] = 0.2,
		[0.603] = 0.21,
		[0.604] = 0.21,
		[0.605] = 0.21,
		[0.606] = 0.21,
		[0.607] = 0.21,
		[0.608] = 0.22,
		[0.609] = 0.22,
		[0.61] = 0.22,
		[0.611] = 0.22,
		[0.612] = 0.22,
		[0.613] = 0.23,
		[0.614] = 0.23,
		[0.615] = 0.23,
		[0.616] = 0.23,
		[0.617] = 0.23,
		[0.618] = 0.24,
		[0.619] = 0.24,
		[0.62] = 0.24,
		[0.621] = 0.24,
		[0.622] = 0.24,
		[0.623] = 0.25,
		[0.624] = 0.25,
		[0.625] = 0.25,
		[0.626] = 0.25,
		[0.627] = 0.25,
		[0.628] = 0.26,
		[0.629] = 0.26,
		[0.63] = 0.26,
		[0.631] = 0.26,
		[0.632] = 0.26,
		[0.633] = 0.26,
		[0.634] = 0.27,
		[0.635] = 0.27,
		[0.636] = 0.27,
		[0.637] = 0.27,
		[0.638] = 0.28,
		[0.639] = 0.28,
		[0.64] = 0.28,
		[0.641] = 0.28,
		[0.642] = 0.28,
		[0.643] = 0.29,
		[0.644] = 0.29,
		[0.645] = 0.29,
		[0.646] = 0.29,
		[0.647] = 0.29,
		[0.648] = 0.3,
		[0.649] = 0.3,
		[0.65] = 0.3,
		[0.651] = 0.3,
		[0.652] = 0.3,
		[0.653] = 0.31,
		[0.654] = 0.31,
		[0.655] = 0.31,
		[0.656] = 0.31,
		[0.657] = 0.31,
		[0.658] = 0.32,
		[0.659] = 0.32,
		[0.66] = 0.32,
		[0.661] = 0.32,
		[0.662] = 0.32,
		[0.663] = 0.33,
		[0.664] = 0.33,
		[0.665] = 0.33,
		[0.666] = 0.33,
		[0.667] = 0.33,
		[0.668] = 0.34,
		[0.669] = 0.34,
		[0.67] = 0.34,
		[0.671] = 0.34,
		[0.672] = 0.34,
		[0.673] = 0.35,
		[0.674] = 0.35,
		[0.675] = 0.35,
		[0.676] = 0.35,
		[0.677] = 0.35,
		[0.678] = 0.36,
		[0.679] = 0.36,
		[0.68] = 0.36,
		[0.681] = 0.36,
		[0.682] = 0.36,
		[0.683] = 0.36,
		[0.684] = 0.37,
		[0.685] = 0.37,
		[0.686] = 0.37,
		[0.687] = 0.37,
		[0.688] = 0.38,
		[0.689] = 0.38,
		[0.69] = 0.38,
		[0.691] = 0.38,
		[0.692] = 0.38,
		[0.693] = 0.38,
		[0.694] = 0.39,
		[0.695] = 0.39,
		[0.696] = 0.39,
		[0.697] = 0.39,
		[0.698] = 0.4,
		[0.699] = 0.4,
		[0.7] = 0.4,
		[0.701] = 0.4,
		[0.702] = 0.4,
		[0.703] = 0.41,
		[0.704] = 0.41,
		[0.705] = 0.41,
		[0.706] = 0.41,
		[0.707] = 0.41,
		[0.708] = 0.41,
		[0.709] = 0.42,
		[0.71] = 0.42,
		[0.711] = 0.42,
		[0.712] = 0.42,
		[0.713] = 0.43,
		[0.714] = 0.43,
		[0.715] = 0.43,
		[0.716] = 0.43,
		[0.717] = 0.43,
		[0.718] = 0.44,
		[0.719] = 0.44,
		[0.72] = 0.44,
		[0.721] = 0.44,
		[0.722] = 0.44,
		[0.723] = 0.45,
		[0.724] = 0.45,
		[0.725] = 0.45,
		[0.726] = 0.45,
		[0.727] = 0.45,
		[0.728] = 0.46,
		[0.729] = 0.46,
		[0.73] = 0.46,
		[0.731] = 0.46,
		[0.732] = 0.46,
		[0.733] = 0.47,
		[0.734] = 0.47,
		[0.735] = 0.47,
		[0.736] = 0.47,
		[0.737] = 0.47,
		[0.738] = 0.47,
		[0.739] = 0.48,
		[0.74] = 0.48,
		[0.741] = 0.48,
		[0.742] = 0.48,
		[0.743] = 0.48,
		[0.744] = 0.49,
		[0.745] = 0.49,
		[0.746] = 0.49,
		[0.747] = 0.49,
		[0.748] = 0.5,
		[0.749] = 0.5,
		[0.75] = 0.5,
		[0.751] = 0.5,
		[0.752] = 0.5,
		[0.753] = 0.5,
		[0.754] = 0.51,
		[0.755] = 0.51,
		[0.756] = 0.51,
		[0.757] = 0.51,
		[0.758] = 0.52,
		[0.759] = 0.52,
		[0.76] = 0.52,
		[0.761] = 0.52,
		[0.762] = 0.52,
		[0.763] = 0.53,
		[0.764] = 0.53,
		[0.765] = 0.53,
		[0.766] = 0.53,
		[0.767] = 0.53,
		[0.768] = 0.54,
		[0.769] = 0.54,
		[0.77] = 0.54,
		[0.771] = 0.54,
		[0.772] = 0.54,
		[0.773] = 0.55,
		[0.774] = 0.55,
		[0.775] = 0.55,
		[0.776] = 0.55,
		[0.777] = 0.55,
		[0.778] = 0.56,
		[0.779] = 0.56,
		[0.78] = 0.56,
		[0.781] = 0.56,
		[0.782] = 0.56,
		[0.783] = 0.57,
		[0.784] = 0.57,
		[0.785] = 0.57,
		[0.786] = 0.57,
		[0.787] = 0.57,
		[0.788] = 0.58,
		[0.789] = 0.58,
		[0.79] = 0.58,
		[0.791] = 0.58,
		[0.792] = 0.58,
		[0.793] = 0.59,
		[0.794] = 0.59,
		[0.795] = 0.59,
		[0.796] = 0.59,
		[0.797] = 0.59,
		[0.798] = 0.6,
		[0.799] = 0.6,
		[0.8] = 0.6,
		[0.801] = 0.6,
		[0.802] = 0.6,
		[0.803] = 0.61,
		[0.804] = 0.61,
		[0.805] = 0.61,
		[0.806] = 0.61,
		[0.807] = 0.61,
		[0.808] = 0.62,
		[0.809] = 0.62,
		[0.81] = 0.62,
		[0.811] = 0.62,
		[0.812] = 0.62,
		[0.813] = 0.62,
		[0.814] = 0.63,
		[0.815] = 0.63,
		[0.816] = 0.63,
		[0.817] = 0.63,
		[0.818] = 0.64,
		[0.819] = 0.64,
		[0.82] = 0.64,
		[0.821] = 0.64,
		[0.822] = 0.64,
		[0.823] = 0.64,
		[0.824] = 0.65,
		[0.825] = 0.65,
		[0.826] = 0.65,
		[0.827] = 0.65,
		[0.828] = 0.66,
		[0.829] = 0.66,
		[0.83] = 0.66,
		[0.831] = 0.66,
		[0.832] = 0.66,
		[0.833] = 0.67,
		[0.834] = 0.67,
		[0.835] = 0.67,
		[0.836] = 0.67,
		[0.837] = 0.67,
		[0.838] = 0.68,
		[0.839] = 0.68,
		[0.84] = 0.68,
		[0.841] = 0.68,
		[0.842] = 0.68,
		[0.843] = 0.69,
		[0.844] = 0.69,
		[0.845] = 0.69,
		[0.846] = 0.69,
		[0.847] = 0.69,
		[0.848] = 0.7,
		[0.849] = 0.7,
		[0.85] = 0.7,
		[0.851] = 0.7,
		[0.852] = 0.7,
		[0.853] = 0.71,
		[0.854] = 0.71,
		[0.855] = 0.71,
		[0.856] = 0.71,
		[0.857] = 0.71,
		[0.858] = 0.72,
		[0.859] = 0.72,
		[0.86] = 0.72,
		[0.861] = 0.72,
		[0.862] = 0.72,
		[0.863] = 0.73,
		[0.864] = 0.73,
		[0.865] = 0.73,
		[0.866] = 0.73,
		[0.867] = 0.73,
		[0.868] = 0.74,
		[0.869] = 0.74,
		[0.87] = 0.74,
		[0.871] = 0.74,
		[0.872] = 0.74,
		[0.873] = 0.75,
		[0.874] = 0.75,
		[0.875] = 0.75,
		[0.876] = 0.75,
		[0.877] = 0.75,
		[0.878] = 0.76,
		[0.879] = 0.76,
		[0.88] = 0.76,
		[0.881] = 0.76,
		[0.882] = 0.76,
		[0.883] = 0.76,
		[0.884] = 0.77,
		[0.885] = 0.77,
		[0.886] = 0.77,
		[0.887] = 0.77,
		[0.888] = 0.78,
		[0.889] = 0.78,
		[0.89] = 0.78,
		[0.891] = 0.78,
		[0.892] = 0.78,
		[0.893] = 0.79,
		[0.894] = 0.79,
		[0.895] = 0.79,
		[0.896] = 0.79,
		[0.897] = 0.79,
		[0.898] = 0.8,
		[0.899] = 0.8,
		[0.9] = 0.8,
		[0.901] = 0.8,
		[0.902] = 0.8,
		[0.903] = 0.81,
		[0.904] = 0.81,
		[0.905] = 0.81,
		[0.906] = 0.81,
		[0.907] = 0.81,
		[0.908] = 0.82,
		[0.909] = 0.82,
		[0.91] = 0.82,
		[0.911] = 0.82,
		[0.912] = 0.82,
		[0.913] = 0.83,
		[0.914] = 0.83,
		[0.915] = 0.83,
		[0.916] = 0.83,
		[0.917] = 0.83,
		[0.918] = 0.84,
		[0.919] = 0.84,
		[0.92] = 0.84,
		[0.921] = 0.84,
		[0.922] = 0.84,
		[0.923] = 0.85,
		[0.924] = 0.85,
		[0.925] = 0.85,
		[0.926] = 0.85,
		[0.927] = 0.85,
		[0.928] = 0.85,
		[0.929] = 0.86,
		[0.93] = 0.86,
		[0.931] = 0.86,
		[0.932] = 0.86,
		[0.933] = 0.87,
		[0.934] = 0.87,
		[0.935] = 0.87,
		[0.936] = 0.87,
		[0.937] = 0.87,
		[0.938] = 0.88,
		[0.939] = 0.88,
		[0.94] = 0.88,
		[0.941] = 0.88,
		[0.942] = 0.88,
		[0.943] = 0.89,
		[0.944] = 0.89,
		[0.945] = 0.89,
		[0.946] = 0.89,
		[0.947] = 0.89,
		[0.948] = 0.9,
		[0.949] = 0.9,
		[0.95] = 0.9,
		[0.951] = 0.9,
		[0.952] = 0.9,
		[0.953] = 0.91,
		[0.954] = 0.91,
		[0.955] = 0.91,
		[0.956] = 0.91,
		[0.957] = 0.91,
		[0.958] = 0.92,
		[0.959] = 0.92,
		[0.96] = 0.92,
		[0.961] = 0.92,
		[0.962] = 0.92,
		[0.963] = 0.92,
		[0.964] = 0.93,
		[0.965] = 0.93,
		[0.966] = 0.93,
		[0.967] = 0.93,
		[0.968] = 0.94,
		[0.969] = 0.94,
		[0.97] = 0.94,
		[0.971] = 0.94,
		[0.972] = 0.94,
		[0.973] = 0.95,
		[0.974] = 0.95,
		[0.975] = 0.95,
		[0.976] = 0.95,
		[0.977] = 0.95,
		[0.978] = 0.96,
		[0.979] = 0.96,
		[0.98] = 0.96,
		[0.981] = 0.96,
		[0.982] = 0.96,
		[0.983] = 0.96,
		[0.984] = 0.97,
		[0.985] = 0.97,
		[0.986] = 0.97,
		[0.987] = 0.97,
		[0.988] = 0.98,
		[0.989] = 0.98,
		[0.99] = 0.98,
		[0.991] = 0.98,
		[0.992] = 0.98,
		[0.993] = 0.99,
		[0.994] = 0.99,
		[0.995] = 0.99,
		[0.996] = 0.99,
		[0.997] = 0.99,
		[0.998] = 1,
		[0.999] = 1,
	}

    --------------------------------------------------------------------------------
    -- Validation:
    --------------------------------------------------------------------------------
    if type(wheel) ~= "string" or not self.WHEELS[wheel] then
        log.ef("Invalid Wheel: %s", wheel)
        return nil
    end
    if value then
        if type(value) ~= "number" then
            log.ef("Invalid Brightness Value Type: %s", type(value))
            return nil
        end
        if value >= -1 and value <= 1 then
            --log.df("Valid Value: %s", value)
        else
            log.ef("Invalid Brightness Value: %s", value)
            return nil
        end
    end

	local ui = self:parent():UI()
	local brightnessUI = nil
	local viewMode = self:viewMode()

    if viewMode == "Single Wheels" then
    	brightnessUI = ui[3][4]
    elseif viewMode == "All Wheels" then
    	if wheel == "Master" then
    		brightnessUI = ui[2][4]
    	elseif wheel == "Shadows" then
    		brightnessUI = ui[3][4]
    	elseif wheel == "Midtones" then
    		brightnessUI = ui[4][4]
    	elseif wheel == "Highlights" then
	    	brightnessUI = ui[5][4]
	    end
	else
        log.ef("Failed to detect view mode. This shouldn't happen.")
        return nil
	end
	if brightnessUI then
		if value then
			brightnessUI:setAttributeValue("AXValue", invertTable(map)[tools.round(value,3)])
		end
		return map[tools.round(brightnessUI:attributeValue("AXValue"), 3)]
	else
		log.ef("Failed to get Saturation UI.")
		return nil
	end

end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:mix(wheel, [value]) -> number | nil
--- Method
--- Sets or gets a color wheel mix.
---
--- Parameters:
---  * wheel - Which wheel you want to set/get ("Master, "Shadows", "Midtones" or "Highlights")
---  * [value] - An optional value you want to set the mix value to as number (0 to 1).
---
--- Returns:
---  * A number containing the mix value or `nil` if an error occurs.
function ColorWheels:mix(wheel, value)

	--------------------------------------------------------------------------------
    -- Validation:
    --------------------------------------------------------------------------------
    if type(wheel) ~= "string" or not self.WHEELS[wheel] then
        log.ef("Invalid Wheel: %s", wheel)
        return nil
    end
    if value then
        if type(value) ~= "number" then
            log.ef("Invalid Mix Value Type: %s", type(value))
            return nil
        end
        if value >= 0 and value <= 1 then
            --log.df("Valid Value: %s", value)
        else
            log.ef("Invalid Mix Value: %s", value)
            return nil
        end
    end

	--------------------------------------------------------------------------------
	-- Find Mix Slider:
	--------------------------------------------------------------------------------
    local ui = self:parent():UI()
    local slider = nil
    for i, v in ipairs(ui) do
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

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:temperature([value]) -> number | nil
--- Method
--- Sets or gets the temperature.
---
--- Parameters:
---  * [value] - An optional value you want to set the temperature value to as number (2500 to 10000).
---
--- Returns:
---  * A number containing the temperature value or `nil` if an error occurs.
function ColorWheels:temperature(value)

	--------------------------------------------------------------------------------
    -- Validation:
    --------------------------------------------------------------------------------
    if value then
        if type(value) ~= "number" then
            log.ef("Invalid Temperature Value Type: %s", type(value))
            return nil
        end
        if value >= 2500 and value <= 10000 then
            --log.df("Valid Value: %s", value)
        else
            log.ef("Invalid Temperature Value: %s", value)
            return nil
        end
    end

	local ui = self:parent():UI()
    local viewMode = self:viewMode()
	local temperatureUI = nil
    if viewMode == "Single Wheels" then
    	temperatureUI = ui[5]
    elseif viewMode == "All Wheels" then
    	temperatureUI = ui[7]
    else
    	log.ef("Failed to detect view mode. This shouldn't happen.")
        return nil
    end
    if temperatureUI then
    	--------------------------------------------------------------------------------
    	-- Setter:
    	--------------------------------------------------------------------------------
    	if value then
    		temperatureUI:setAttributeValue("AXValue", value)
    	end

    	--------------------------------------------------------------------------------
    	-- Getter:
    	--------------------------------------------------------------------------------
    	return temperatureUI:attributeValue("AXValue")
    else
    	log.ef("Failed to get Temperature UI.")
    	return nil
    end

end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:tint([value]) -> number | nil
--- Method
--- Sets or gets the tint.
---
--- Parameters:
---  * [value] - An optional value you want to set the tint value to as number (-50 to 50).
---
--- Returns:
---  * A number containing the tint value or `nil` if an error occurs.
function ColorWheels:tint(value)

	--------------------------------------------------------------------------------
    -- Validation:
    --------------------------------------------------------------------------------
    if value then
        if type(value) ~= "number" then
            log.ef("Invalid Tint Value Type: %s", type(value))
            return nil
        end
        if value >= -50 and value <= 50 then
            --log.df("Valid Value: %s", value)
        else
            log.ef("Invalid Tint Value: %s", value)
            return nil
        end
    end

	local ui = self:parent():UI()
    local viewMode = self:viewMode()
	local tintUI = nil
    if viewMode == "Single Wheels" then
    	tintUI = ui[10]
    elseif viewMode == "All Wheels" then
    	tintUI = ui[12]
    else
    	log.ef("Failed to detect view mode. This shouldn't happen.")
        return nil
    end
    if tintUI then
    	--------------------------------------------------------------------------------
    	-- Setter:
    	--------------------------------------------------------------------------------
    	if value then
    		tintUI:setAttributeValue("AXValue", value)
    	end

    	--------------------------------------------------------------------------------
    	-- Getter:
    	--------------------------------------------------------------------------------
    	return tintUI:attributeValue("AXValue")
    else
    	log.ef("Failed to get Tint UI.")
    	return nil
    end

end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:hue([value]) -> number | nil
--- Method
--- Sets or gets the hue.
---
--- Parameters:
---  * [value] - An optional value you want to set the hue value to as number (0 to 360).
---
--- Returns:
---  * A number containing the hue value or `nil` if an error occurs.
function ColorWheels:hue(value)

	--------------------------------------------------------------------------------
    -- Validation:
    --------------------------------------------------------------------------------
    if value then
        if type(value) ~= "number" then
            log.ef("Invalid Hue Value Type: %s", type(value))
            return nil
        end
        if value >= 0 and value <= 360 then
            --log.df("Valid Value: %s", value)
        else
            log.ef("Invalid Hue Value: %s", value)
            return nil
        end
    end

	local ui = self:parent():UI()
    local viewMode = self:viewMode()
	local hueUI = nil
    if viewMode == "Single Wheels" then
    	hueUI = ui[18]
    elseif viewMode == "All Wheels" then
    	hueUI = ui[20]
    else
    	log.ef("Failed to detect view mode. This shouldn't happen.")
        return nil
    end
    if hueUI then
    	--------------------------------------------------------------------------------
    	-- Setter:
    	--------------------------------------------------------------------------------
    	if value then
    		hueUI:setAttributeValue("AXValue", tostring(value))
    	end

    	--------------------------------------------------------------------------------
    	-- Getter:
    	--------------------------------------------------------------------------------
    	return tonumber(hueUI:attributeValue("AXValue"))
    else
    	log.ef("Failed to get Hue UI.")
    	return nil
    end

end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:selectedWheel(wheel) -> boolean | nil
--- Method
--- Sets or gets the selected color wheel.
---
--- Parameters:
---  * wheel - An optional value of which wheel you want to set/get ("Master, "Shadows", "Midtones" or "Highlights")
---
--- Returns:
---  * A currently selected wheel as a string or `nil` if an error occurs.
function ColorWheels:selectedWheel(wheel)
	--------------------------------------------------------------------------------
    -- Validation:
    --------------------------------------------------------------------------------
    if wheel then
	    if type(wheel) ~= "string" or not self.WHEELS[wheel] then
			log.ef("Invalid Wheel: %s", wheel)
			return nil
		end
    end

   local viewMode = self:viewMode()
   	if wheel then
   		--------------------------------------------------------------------------------
   		-- Setter:
   		--------------------------------------------------------------------------------
		if viewMode == "Single Wheels" then
			self:visibleWheel(wheel)
		elseif viewMode == "All Wheels" then
			local ui = self:parent():UI()
			if wheel == "Master" then
				local result = ui[2]:setAttributeValue("AXFocused", true)
				if result then
					return "Master"
				else
					log.ef("Failed to set focus.")
					return nil
				end
			elseif wheel == "Shadows" then
				local result = ui[3]:setAttributeValue("AXFocused", true)
				if result then
					return "Shadows"
				else
					log.ef("Failed to set focus.")
					return nil
				end
			elseif wheel == "Midtones" then
				local result = ui[4]:setAttributeValue("AXFocused", true)
				if result then
					return "Midtones"
				else
					log.ef("Failed to set focus.")
					return nil
				end
			elseif wheel == "Highlights" then
				local result = ui[5]:setAttributeValue("AXFocused", true)
				if result then
					return "Highlights"
				else
					log.ef("Failed to set focus.")
					return nil
				end
			end
		else
			log.ef("Failed to detect view mode. This shouldn't happen.")
			return nil
		end
    else
    	--------------------------------------------------------------------------------
    	-- Getter:
    	--------------------------------------------------------------------------------
    	if viewMode == "Single Wheels" then
			return self:visibleWheel()
		elseif viewMode == "All Wheels" then
			local ui = self:parent():UI()
			if ui[2]:attributeValue("AXFocused") == true then
				return "Master"
			elseif ui[3]:attributeValue("AXFocused") == true then
				return "Shadows"
			elseif ui[4]:attributeValue("AXFocused") == true then
				return "Midtones"
			elseif ui[5]:attributeValue("AXFocused") == true then
				return "Highlights"
			else
				return nil
			end
		end
    end
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:reset(wheel) -> boolean | nil
--- Method
--- Resets the selected color wheel.
---
--- Parameters:
---  * wheel - An optional value of which wheel you want to set/get ("Master, "Shadows", "Midtones" or "Highlights"). If no wheel is supplied then all wheels will be reset.
---
--- Returns:
---  * `true` if successful otherwise `false`
function ColorWheels:reset(wheel)

	-- TODO: Finish this function.

end

--------------------------------------------------------------------------------
--
-- EXPERIMENTS:
--
-- The below code is a bunch of experiments and work-in-progress code.
--
--------------------------------------------------------------------------------

--[[
function ColorWheels:test()

	local ui = self:parent():UI()
	local board = ui[3][2]

	local result = ""
	for i=1, 5, 1 do
		self:selectedWheel("Master")
		self:nudgeControl("Master", "Up")
		local rgb = colorWellValueToTable(board:attributeValue("AXValue"))
		result = result .. string.format("R: %s   G: %s   B: %s", rgb["Red"], rgb["Green"], rgb["Blue"]) .. "\n"
	end

	log.df(result)

	--local result = rgbTableToColorWellValue(rgb)
end
--]]

--------------------------------------------------------------------------------
-- AXColorWell Notes:
--------------------------------------------------------------------------------

    -- --------------------------------------------------------------------------
    -- Value in FCP Interface | Value in Accessibility Framework
    -- --------------------------------------------------------------------------
    -- Red      Green   Blue    AXValue     R           G           B           A
    -- --------------------------------------------------------------------------
    -- 0        0       0       rgb         0           0           0           0
    --
    -- 255      0       0       rgb         0.183333    1           0           0
    -- -255     0       0       rgb         0.816667    0           1           0
    --
    -- 0        255     0       rgb         0           0.183333    1           0
    -- 0        -255    0       rgb         1           0.816667    0           0
    --
    -- 0        0       255     rgb         1           0           0.183333    0
    -- 0        0       -255    rgb         0           1           0.816667    0
    --
    -- 255      255     0       rgb         0           1           0.816667    0
    -- 0        255     255     rgb         0.816667    0           1           0
    --
    --
    -- --------------------------------------------------------------------------

	-- --------------------------------------------------------------------------
	-- Moving Color Puck directly upwards using shortcut key:
	-- --------------------------------------------------------------------------
	-- rgb 	0 				0 				0	 			0
	-- rgb 	0.000833333 	0.00166667 		0 				0
	-- rgb 	0.00166667 		0.00333333 		0 				0
	-- --------------------------------------------------------------------------

	-- ------------------------------------------------------------------------------------------
	--                  Value in FCP Interface
	-- ------------------------------------------------------------------------------------------
	--                  Red         Green       Blue		AXColorWell Value
	-- ------------------------------------------------------------------------------------------
	-- Far Left         208         255         0			rgb 0			0.999019 		1 	0
	-- Far Right        47          0           255			rgb 1 			0.000980343 	0 	0
	-- Far Top          255         0           81			rgb 0.50098    	1 				0 	0
	-- Far Bottom       0           255         174			rgb 0.49902 	0 				1 	0
	-- ------------------------------------------------------------------------------------------

    --------------------------------------------------------------------------------
    -- Color Wheel Limits:
    --------------------------------------------------------------------------------
    -- Final Cut Pro:       255 to -255
    -- UI Scripting:        1   to -1
    --------------------------------------------------------------------------------

	--[[

	Moving upwards:

	x: 0.0, y: 0.0
	x: -1.2566345481352e-06, y: 0.99999999999921
	x: 1.5707978978147e-06, y: 0.99999999999877
	x: 6.1232339957368e-17, y: 1.0
	x: -7.8539777075812e-07, y: 0.99999999999969

	--]]

--------------------------------------------------------------------------------------------------
-- The below code is based on an example given to Chris - as discussed here:
-- https://github.com/Hammerspoon/hammerspoon/issues/1642
--
-- Code Example:
-- https://github.com/asmagill/hammerspoon-config-take2/blob/master/_scratch/hsbWheel.lua
--------------------------------------------------------------------------------------------------

local orientation = 0.25

local toXY = function(c)
    local h = 1 - c.hue - orientation -- modify hue to what I *think* is the orientation in FCP
    return c.saturation * math.cos(h * math.pi * 2), c.saturation * math.sin(h * math.pi * 2)
end

local fromXY = function(x, y)
    local hue, sat = math.atan(y, x) / ( math.pi * 2), math.sqrt(x * x + y * y)
    local h = 1 - (hue + orientation) -- modify hue from what I *think* is the orientation in FCP
    return h, sat
end

function clamp(val, min, max)
    if val <= min then
        val = min
    elseif max <= val then
        val = max
    end
    return val
end


--[[
module.setXY = function(x, y)
    x, y = clamp(x or 0, -1, 1), clamp(y or 0, -1, 1)
    local h, s = fromXY(x, y)
    _C.knob.fillColor = { hue = h, saturation = s, brightness = 1 }
    _C.knob.center = { x = tostring((x + 1) / 2), y = tostring((y + 1) / 2) }
    _C.text.text = string.format("X, Y = %.3f, %.3f", x, y)
end
--]]

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:nudgeControlPrototype(wheel, direction) -> boolean
--- Method
--- Moves a Color Wheel puck/control in a specific direction.
---
--- Parameters:
---  * wheel - Which wheel you want to set/get ("Master, "Shadows", "Midtones" or "Highlights")
---  * direction - Which direction you want to nudge the wheel control ("Up", "Down", "Left" or "Right")
---
--- Returns:
---  * `true` if successful otherwise `nil`

xcount = 0
function ColorWheels:nudgeControlPrototype(wheel, direction)

	--------------------------------------------------------------------------------
	--
	-- X is left/right
	-- Y is up/down
	--
	-- hue is the angle
	-- saturation is the distance from centre to edge
	--
	-- hue - the hue component of the color specified as a number from 0.0 to 1.0. (0-359)
	-- saturation - the saturation component of the color specified as a number from 0.0 to 1.0. (0-100)
	-- brightness - the brightness component of the color specified as a number from 0.0 to 1.0. (0-100)
	-- alpha - the color transparency from 0.0 (completely transparent) to 1.0 (completely opaque)
	--
	--------------------------------------------------------------------------------

	local console = require("hs.console")
	console.clearConsole()

	local ui = self:parent():UI()
	local board = ui[3][2]

	local currentValueAsString = board:attributeValue("AXValue")
	log.df("currentValueAsString: %s", inspect(currentValueAsString))

	local currentValueAsRGB = colorWellValueToTable(currentValueAsString, true)
	log.df("currentValueAsRGB: %s", inspect(currentValueAsRGB))

	local currentValueAsHSB = drawing.color.asHSB(currentValueAsRGB)
	log.df("currentValueAsHSB: %s", inspect(currentValueAsHSB))

	local x, y = toXY(currentValueAsHSB)
	log.df("x: %s, y: %s", x,y)

	x = x + 0.1
	log.df("x: %s, y: %s", x,y)

	local hue, sat = fromXY(x, y)
	log.df("hue: %s, sat: %s", hue ,sat)

	local modifiedHSB = currentValueAsHSB
	modifiedHSB.hue = hue
	modifiedHSB.sat = sat
	log.df("modifiedHSB: %s", inspect(modifiedHSB))

	local backToRGB = drawing.color.asRGB(modifiedHSB)
	log.df("backToRGB: %s", inspect(backToRGB))


	local backToString = rgbTableToColorWellValue(backToRGB)
	log.df("backToString: %s", inspect(backToString))

	--[[
	local r = tools.round(backToRGB.red * 256, 0)
	local g = tools.round(backToRGB.green * 256, 0)
	local b = tools.round(backToRGB.blue * 256, 0)

	log.df("Red: %s, Green: %s, Blue: %s", r, g, b)
	--]]

	local setAttributeValueResult = board:setAttributeValue("AXValue", backToString)
	log.df("setAttributeValueResult: %s", setAttributeValueResult)

	local currentValueAsString = board:attributeValue("AXValue")
	log.df("currentValueAsString: %s", currentValueAsString)

	do return end











	local x, y = xcount, 0.02
	xcount = xcount - 0.0001

	log.df("xcount: %s", xcount)

	x, y = clamp(x or 0, -1, 1), clamp(y or 0, -1, 1)
	local h, s = fromXY(x, y)

	log.df("h: %s, s: %s", h, s)
	log.df("-----------------------")

	local c = currentValueAsHSB
	c.hue = h
	c.saturation = s

	log.df("hsb: %s", inspect(c))

	local rgb = drawing.color.asRGB(c)

	log.df("rgb: %s", inspect(rgb))




	local result = rgbTableToColorWellValue(rgb)

	log.df("result: %s", result)

	local setAttributeValueResult = board:setAttributeValue("AXValue", result)

	log.df("setAttributeValueResult: %s", setAttributeValueResult)

	local currentValueAsString = board:attributeValue("AXValue")

	log.df("currentValueAsString: %s", currentValueAsString)




	do return end



	local x, y = toXY(currentValueAsHSB)

	--local x = sat * math.cos(math.rad(hue))
	--local y = sat * math.sin(math.rad(hue))

	log.df("x: %s, y: %s", x,y)

	do return end

	log.df("-----------------------")

	--if direction == "Up" then
	x = x + 1
	--end

	log.df("x: %s, y: %s", x, y)

	local sat = math.sqrt(x * x + y * y)
	local hue = math.atan(y, x)

	log.df("sat: %s, hue: %s", sat, hue)

	currentValueAsHSB["hue"] = hue
	currentValueAsHSB["saturation"] = sat

	log.df("currentValueAsHSB: %s", inspect(currentValueAsHSB))

	local currentValueAsRGB = drawing.color.asRGB(currentValueAsHSB)

	log.df("currentValueAsRGB: %s", inspect(currentValueAsRGB))

	local result = rgbTableToColorWellValue(currentValueAsRGB)

	log.df("result: %s", result)

	local setAttributeValueResult = board:setAttributeValue("AXValue", result)

	log.df("setAttributeValueResult: %s", setAttributeValueResult)

	local currentValueAsString = board:attributeValue("AXValue")

	log.df("currentValueAsString: %s", currentValueAsString)

end

return ColorWheels