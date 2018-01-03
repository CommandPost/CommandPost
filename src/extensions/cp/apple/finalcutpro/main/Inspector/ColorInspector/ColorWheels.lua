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
local log								= require("hs.logger").new("colorWheels")

local axutils 							= require("cp.ui.axutils")
local prop								= require("cp.prop")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

local CORRECTION_TYPE					= "Color Wheels"

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
	["All Wheels"] 		= "PAE4WayCorrectorViewControllerRhombus",
	["Single Wheels"] 	= "PAE4WayCorrectorViewControllerSingleControl",
}

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels.WHEELS -> table
--- Constant
--- Table containing all the different types of Color Wheels
ColorWheels.WHEELS = {
	["Master"]			= "PAE4WayCorrectorViewControllerMaster",
	["Shadows"] 		=  "PAE4WayCorrectorViewControllerShadows",
	["Midtones"] 		= "PAE4WayCorrectorViewControllerMidtones",
	["Highlights"] 		= "PAE4WayCorrectorViewControllerHighlights",
}

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels.COLOR_MODES -> table
--- Constant
--- View Modes for Color Wheels
ColorWheels.COLOR_MODES = {
	["Red"] 			= "Primatte::Red",
	["Green"] 			= "Primatte::Green",
	["Blue"]			= "Primatte::Blue",
}

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels.NUDGE_DIRECTIONS -> table
--- Constant
--- Nudge Directions for Color Wheels
ColorWheels.NUDGE_DIRECTIONS = {
	"Up",
	"Down",
	"Left",
	"Right",
}

--------------------------------------------------------------------------------
-- HELPER FUNCTIONS:
--------------------------------------------------------------------------------

--- colorWellValueToTable(value) -> table | nil
--- Function
--- Converts a AXColorWell Value to a table containing "Red", "Green" and "Blue" values.
---
--- Parameters:
---  * value - A AXColorWell Value String (i.e. "rgb 0.5 0 1 0")
---
--- Returns:
---  * A table or `nil` if an error occurred.
local function colorWellValueToTable(value)
	if type(value) ~= "string" then
		return nil
	end
	local valueToTable = string.split(value, " ")
	if not valueToTable or #valueToTable ~= 5 then
		return nil
	end
	local result = {
		["Red"] 	= valueToTable[2],
		["Green"] 	= valueToTable[3],
		["Blue"]	= valueToTable[4],
	}
	return result
end

--------------------------------------------------------------------------------
-- AXColorWell Notes:
--------------------------------------------------------------------------------

	-- --------------------------------------------------------------------------
	-- Value in FCP Interface | Value in Accessibility Framework
	-- --------------------------------------------------------------------------
	-- Red		Green	Blue	AXValue		R			G			B			A
	-- --------------------------------------------------------------------------
	-- 0		0		0		rgb 		0 			0 			0 			0
	--
	-- 255		0		0		rgb 		0.183333 	1 			0 			0
	-- -255		0		0		rgb 		0.816667 	0 			1 			0
	--
	-- 0		255		0		rgb 		0 			0.183333 	1 			0
	-- 0		-255	0		rgb 		1 			0.816667 	0 			0
	--
	-- 0		0		255		rgb 		1 			0 			0.183333 	0
	-- 0		0		-255	rgb 		0 			1 			0.816667 	0
	--
	-- 255		255		0		rgb 		0 			1 			0.816667 	0
	-- 0		255		255		rgb 		0.816667 	0 			1 			0
	-- --------------------------------------------------------------------------

	-- --------------------------------------------------------------------------
	-- 					Value in FCP Interface
	-- --------------------------------------------------------------------------
	--                  Red			Green		Blue
	-- --------------------------------------------------------------------------
	-- Far Left 		208			255			0
	-- Far Right		47			0			255
	-- Far Top			255			0			81
	-- Far Bottom		0			255			174
	-- --------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- PUBLIC FUNCTIONS & METHODS:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:new(parent) -> ColorInspector object
--- Method
--- Creates a new ColorWheels object
---
--- Parameters:
---  * `parent`		- The parent
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
		log.ef("Invalid Value: %s", value)
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
		log.ef("Invalid Value: %s", value)
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
	-- Validation:
	--------------------------------------------------------------------------------
	if wheel and not self.WHEELS[wheel] then
		log.ef("Invalid Wheel: %s", wheel)
		return nil
	end
	if color and not self.COLOR_MODES[color] then
		log.ef("Invalid Color: %s", color)
		return nil
	end
	if value then
		if type(value) ~= "number" then
			log.ef("Invalid Value Type: %s", type(value))
			return nil
		end
		if value >= -255 and value <= 255 then
			log.df("valid value")
		else
			log.ef("Invalid Value: %s", value)
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
			showing["Master"] 	= checkboxes[1]:attributeValue("AXValue") == 1 or false
			showing["Shadows"] 	= checkboxes[2]:attributeValue("AXValue") == 1 or false
			showing["Midtones"] = checkboxes[3]:attributeValue("AXValue") == 1 or false
			showing["Shadows"] 	= checkboxes[4]:attributeValue("AXValue") == 1 or false

			if wheel == "Master" and not showing["Master"] == true then
				checkboxes[1]:performAction("AXPress")
			elseif wheel == "Shadows" and not showing["Shadows"] == true then
				checkboxes[2]:performAction("AXPress")
			elseif wheel == "Midtones" and not showing["Midtones"] == true then
				checkboxes[3]:performAction("AXPress")
			elseif wheel == "Highlights" and not showing["Highlights"] == true then
				checkboxes[4]:performAction("AXPress")
			end

			if ui and ui[2] then
				if color == "Red" then
					--------------------------------------------------------------------------------
					-- Adjusting Red Value:
					--------------------------------------------------------------------------------
					if wheel == "Master" then
						return ui[28]:attributeValue("AXValue")
					elseif wheel == "Shadows" then
					elseif wheel == "Midtones" then
					elseif wheel == "Highlights" then
					end
				elseif color == "Green" then
				elseif color == "Blue" then
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
		if wheel == "Master" then

		elseif wheel == "Shadows" then

		elseif wheel == "Midtones" then

		elseif wheel == "Highlights" then

		end
	else
		log.ef("Failed to detect view mode. This shouldn't happen.")
		return nil
	end
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels:mix(wheel, [value]) -> number | nil
--- Method
--- Sets or gets a color wheel mix.
---
--- Parameters:
---  * wheel - Which wheel you want to set/get ("Master, "Shadows", "Midtones" or "Highlights")
---  * direction - Which direction you want to nudge the wheel control ("Up", "Down", "Left" or "Right")
---
--- Returns:
---  * A number containing the mix value or `nil` if an error occurs.
function ColorWheels:nudgeControl(wheel, direction)

	-- TODO

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
function ColorWheels:saturation(wheel, value)

	-- TODO

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
function ColorWheels:brightness(wheel, value)

	-- TODO

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

	-- TODO

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

	-- TODO

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

	-- TODO

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

	-- TODO

end

return ColorWheels