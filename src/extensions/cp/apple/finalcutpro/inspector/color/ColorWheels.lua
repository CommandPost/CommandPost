--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.inspector.color.ColorWheels ===
---
--- Color Wheels Module.

-----------------------------------------------------------------------------------------------------------------------------------------------------
-- TODO LIST:
-----------------------------------------------------------------------------------------------------------------------------------------------------
--
--  [ ] `cp.apple.finalcutpro.inspector.color.ColorWheels:nudgeControl` should use GUI Scripting instead of shortcuts
--  [ ] `cp.apple.finalcutpro.inspector.color.ColorWheels:color` should use GUI Scripting on AXColorWell instead of the RGB text boxes
--  [ ] Replace the map in `cp.apple.finalcutpro.inspector.color.ColorWheels:brightness` with a mathematical formula
--
--  [ ] Add API for "Add Shape Mask", "Add Color Mask" and "Invert Masks".
--  [ ] Add API for "Save Effects Preset".
--  [ ] Add API for "Mask Inside/Output".
--  [ ] Add API for "View Masks".
--
-----------------------------------------------------------------------------------------------------------------------------------------------------

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log                               = require("hs.logger").new("colorWheels")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils							= require("cp.ui.axutils")
local MenuButton						= require("cp.ui.MenuButton")
local prop                              = require("cp.prop")
local PropertyRow						= require("cp.ui.PropertyRow")
local RadioGroup						= require("cp.ui.RadioGroup")
local Slider							= require("cp.ui.Slider")
local TextField                         = require("cp.ui.TextField")

local ColorWheel						= require("cp.apple.finalcutpro.inspector.color.ColorWheel")

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
-- PUBLIC FUNCTIONS & METHODS:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorWheels.matches(element)
--- Function
--- Checks if the specified element is the Color Wheels element.
---
--- Parameters:
--- * element	- The element to check
---
--- Returns:
--- * `true` if the element is the Color Wheels.
function ColorWheels.matches(element)
	if element and element:attributeValue("AXRole") == "AXGroup"
	and #element == 1 and element[1]:attributeValue("AXRole") == "AXGroup"
	and #element[1] == 1 and element[1][1]:attributeValue("AXRole") == "AXScrollArea" then
		local scroll = element[1][1]
		return axutils.childMatching(scroll, ColorWheel.matches) ~= nil
	end
	return false
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels.new(parent) -> ColorInspector
--- Constructor
--- Creates a new ColorWheels object
---
--- Parameters:
---  * `parent`     - The parent
---
--- Returns:
---  * A new `ColorInspector` object
function ColorWheels.new(parent)
    local o = prop.extend({
        _parent = parent,
        _child = {}
	}, ColorWheels)

--- cp.apple.finalcutpro.inspector.color.ColorWheels.UI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- The `axuielement` representing the ColorWheels corrector.
	o.UI = parent.correctorUI:mutate(function(original, self)
		return axutils.cache(self, "_ui", function()
			local ui = original()
			return ColorWheels.matches(ui) and ui or nil
		end, ColorWheels.matches)
	end):bind(o)

--- cp.apple.finalcutpro.inspector.color.ColorWheels.contentUI <cp.prop: hs._asm.axuielement; read-only>
--- Field
--- The `axuielement` representing the content element of the ColorWheels corrector.
--- This contains all the individual UI elements of the corrector, and is typically an `AXScrollArea`.
	o.contentUI = o.UI:mutate(function(original)
		return axutils.cache(o, "_content", function()
			local ui = original()
			return ui and #ui == 1 and #ui[1] == 1 and ui[1][1] or nil
		end)
	end):bind(o)

--- cp.apple.finalcutpro.inspector.color.ColorWheels.isShowing <cp.prop: boolean; read-only>
--- Field
--- Is the Color Wheels Corrector currently showing?
	o.isShowing = o.UI:mutate(function(original)
		return original() ~= nil
	end):bind(o)

--- cp.apple.finalcutpro.inspector.color.ColorWheels.viewingAllWheels <cp.prop: boolean>
--- Field
--- Reports and modifies whether the ColorWheels corrector is showing "All Wheels" (`true`) or "Single Wheels" (`false`).
	o.viewingAllWheels = prop(
		function(self)
			local ui = self:contentUI()
			if ui then
				-- 'all wheels' mode has at least 2 color wheels, 'single wheels' does not.
				return axutils.childMatching(ui, ColorWheel.matches, 2) ~= nil
			end
			return false
		end,
		function(allWheels, self, theProp)
			local current = theProp:get()
			if allWheels and not current then
				self:viewMode():selectItem(1)
			elseif not allWheels and current then
				self:viewMode():selectItem(2)
			end
		end
	):bind(o)

--- cp.apple.finalcutpro.inspector.color.ColorWheels.mix <cp.prop: number>
--- Field
--- The mix amount for this corrector. A number ranging from `0` to `1`.
	o.mix = o:mixSlider().value:wrap(o)

--- cp.apple.finalcutpro.inspector.color.ColorWheels.temperature <cp.prop: number>
--- Field
--- The color temperature for this corrector. A number from 2500 to 10000.
	o.temperature = o:temperatureSlider().value:wrap(o)

--- cp.apple.finalcutpro.inspector.color.ColorWheels.tint <cp.prop: number>
--- Field
--- The tint for the corrector. A number from `-50` to `50`.
	o.tint = o:tintSlider().value:wrap(o)

--- cp.apple.finalcutpro.inspector.color.ColorWheels.hue <cp.prop: number>
--- Field
--- The hue for the corrector. A number from `0` to `50`.
	o.hue = o:hueTextField().value:wrap(o)

    return o
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels:parent() -> table
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

--- cp.apple.finalcutpro.inspector.color.ColorWheels:app() -> table
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

--- cp.apple.finalcutpro.inspector.color.ColorWheels:viewMode() -> MenuButton
--- Method
--- Returns the `MenuButton` for the View menu button.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `MenuButton` for the View mode.
function ColorWheels:viewMode()
	if not self._viewMode then
		self._viewMode = MenuButton:new(self, function()
			local ui = self:contentUI()
			if ui then
				return axutils.childWithRole(ui, "AXMenuButton")
			end
			return nil
		end)
	end
	return self._viewMode
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels:wheelType() -> RadioGroup
--- Method
--- Returns the `RadioGroup` that allows selection of the wheel type. Only available when
--- `viewingAllWheels` is `true`.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `RadioGroup`.
function ColorWheels:wheelType()
	if not self._wheelType then
		self._wheelType = RadioGroup:new(self,
			function()
				if not self:viewingAllWheels() then
					local ui = self:contentUI()
					return ui and axutils.childWithRole(ui, "AXRadioGroup") or nil
				end
				return nil
			end,
			false -- not cached
		)
	end
	return self._wheelType
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels:master() -> ColorWheel
--- Method
--- Returns a `ColorWheel` that allows control of the 'master' color settings.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `ColorWheel`.
function ColorWheels:master()
	if not self._master then
		self._master = ColorWheel.new(self, ColorWheel.TYPE.MASTER)
	end
	return self._master
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels:shadows() -> ColorWheel
--- Method
--- Returns a `ColorWheel` that allows control of the 'shadows' color settings.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `ColorWheel`.
function ColorWheels:shadows()
	if not self._shadows then
		self._shadows = ColorWheel.new(self, ColorWheel.TYPE.SHADOWS)
	end
	return self._shadows
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels:midtones() -> ColorWheel
--- Method
--- Returns a `ColorWheel` that allows control of the 'midtones' color settings.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `ColorWheel`.
function ColorWheels:midtones()
	if not self._midtones then
		self._midtones = ColorWheel.new(self, ColorWheel.TYPE.MIDTONES)
	end
	return self._midtones
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels:highlights() -> ColorWheel
--- Method
--- Returns a `ColorWheel` that allows control of the 'highlights' color settings.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `ColorWheel`.
function ColorWheels:highlights()
	if not self._highlights then
		self._highlights = ColorWheel.new(self, ColorWheel.TYPE.HIGHLIGHTS)
	end
	return self._highlights
end

--------------------------------------------------------------------------------
-- PROPERTIES:
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.inspector.color.ColorWheels:mixRow() -> cp.ui.PropertyRow
--- Method
--- Returns a `PropertyRow` that provides access to the 'Mix' parameter, and `axuielement`
--- values for that row.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `PropertyRow`.
function ColorWheels:mixRow()
	if not self._mixRow then
		self._mixRow = PropertyRow:new(self, "FFChannelMixName", "contentUI")
	end
	return self._mixRow
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels:mixSlider() -> cp.ui.Slider
--- Method
--- Returns a `Slider` that provides access to the 'Mix' slider.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Mix `Slider`.
function ColorWheels:mixSlider()
	if not self._mixSlider then
		self._mixSlider = Slider:new(self,
			function()
				local ui = self:mixRow():children()
				return ui and axutils.childWithRole(ui, "AXSlider")
			end
		)
	end
	return self._mixSlider
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels:temperatureRow() -> cp.ui.PropertyRow
--- Method
--- Returns a `PropertyRow` that provides access to the 'Temperatures' parameter, and `axuielement`
--- values for that row.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `PropertyRow`.
function ColorWheels:temperatureRow()
	if not self._temperatureRow then
		self._temperatureRow = PropertyRow:new(self, "PAECorrectorEffectTemperature", "contentUI")
	end
	return self._temperatureRow
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels:temperatureSlider() -> cp.ui.Slider
--- Method
--- Returns a `Slider` that provides access to the 'Temperatures' slider.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Temperatures `Slider`.
function ColorWheels:temperatureSlider()
	if not self._temperatureSlider then
		self._temperatureSlider = Slider:new(self,
			function()
				local ui = self:temperatureRow():children()
				return ui and axutils.childWithRole(ui, "AXSlider")
			end
		)
	end
	return self._temperatureSlider
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels:tintRow() -> cp.ui.PropertyRow
--- Method
--- Returns a `PropertyRow` that provides access to the 'Tint' parameter, and `axuielement`
--- values for that row.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `PropertyRow`.
function ColorWheels:tintRow()
	if not self._tintRow then
		self._tintRow = PropertyRow:new(self, "PAECorrectorEffectTint", "contentUI")
	end
	return self._tintRow
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels:tintSlider() -> cp.ui.Slider
--- Method
--- Returns a `Slider` that provides access to the 'Tint' slider.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Tint `Slider`.
function ColorWheels:tintSlider()
	if not self._tintSlider then
		self._tintSlider = Slider:new(self,
			function()
				local ui = self:tintRow():children()
				return ui and axutils.childWithRole(ui, "AXSlider")
			end
		)
	end
	return self._tintSlider
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels:hueRow() -> cp.ui.PropertyRow
--- Method
--- Returns a `PropertyRow` that provides access to the 'Hue' parameter, and `axuielement`
--- values for that row.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `PropertyRow`.
function ColorWheels:hueRow()
	if not self._hueRow then
		self._hueRow = PropertyRow:new(self, "PAECorrectorEffectHue", "contentUI")
	end
	return self._hueRow
end

--- cp.apple.finalcutpro.inspector.color.ColorWheels:hueTextField() -> cp.ui.Slider
--- Method
--- Returns a `Slider` that provides access to the 'Hue' slider.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Hue `Slider`.
function ColorWheels:hueTextField()
	if not self._hueTextField then
		self._hueTextField = TextField:new(self,
			function()
				local ui = self:hueRow():children()
				return ui and axutils.childWithRole(ui, "AXTextField")
			end
		)
	end
	return self._hueTextField
end

return ColorWheels
