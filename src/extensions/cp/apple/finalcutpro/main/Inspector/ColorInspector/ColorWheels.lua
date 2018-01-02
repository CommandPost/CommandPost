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

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels.VIEW_MODES -> table
--- Constant
--- View Modes for Color Wheels
ColorWheels.VIEW_MODES = {
	["All Wheels"] 		= "PAE4WayCorrectorViewControllerRhombus",
	["Single Wheels"] 	= "PAE4WayCorrectorViewControllerSingleControl",
}

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
function ColorWheels:viewMode(value)
	if value and not self.VIEW_MODES[value] then
		log.ef("Invalid Value: %s", value)
		return nil
	end
	if self:isShowing() then
		local app = self:app()
		local ui = self:parent():UI()
		if ui then
			ui[1]:performAction("AXPress") -- Press the "View" button
			if ui[1][1] then
				for _, child in ipairs(ui[1][1]) do
					local title = child:attributeValue("AXTitle")
					local selected = child:attributeValue("AXMenuItemMarkChar") ~= nil

					if value then
						--------------------------------------------------------------------------------
						-- Setter:
						--------------------------------------------------------------------------------
						if title == app:string(self.VIEW_MODES["All Wheels"]) and value == "All Wheels" then
							child:performAction("AXPress") -- Close the popup
							return "All Wheels"
						elseif title == app:string(self.VIEW_MODES["Single Wheels"]) and value == "Single Wheels" then
							child:performAction("AXPress") -- Close the popup
							return "Single Wheels"
						end
					else
						--------------------------------------------------------------------------------
						-- Getter:
						--------------------------------------------------------------------------------
						if title == app:string(self.VIEW_MODES["All Wheels"]) and selected then
							child:performAction("AXPress") -- Close the popup
							return "All Wheels"
						elseif title == app:string(self.VIEW_MODES["Single Wheels"]) and selected then
							child:performAction("AXPress") -- Close the popup
							return "Single Wheels"
						end
					end
				end
				log.df("Failed to determine which View Mode was selected")
				return nil
			end
		else
			log.ef("Could not find Color Inspector UI.")
		end
	else
		log.ef("Color Wheels not active.")
	end
end

return ColorWheels