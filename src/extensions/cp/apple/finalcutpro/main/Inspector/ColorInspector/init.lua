--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.Inspector.ColorInspector ===
---
--- Color Inspector Module.
---
--- Requires Final Cut Pro 10.4 or later.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("colorInspect")

local prop								= require("cp.prop")
local axutils							= require("cp.ui.axutils")
local tools								= require("cp.tools")

local id								= require("cp.apple.finalcutpro.ids") "ColorInspector"

local CorrectionsBar						= require("cp.apple.finalcutpro.main.Inspector.ColorInspector.CorrectionsBar")
local ColorBoard						= require("cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorBoard")
local ColorWheels						= require("cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorWheels")
local ColorCurves						= require("cp.apple.finalcutpro.main.Inspector.ColorInspector.ColorCurves")
local HueSaturationCurves				= require("cp.apple.finalcutpro.main.Inspector.ColorInspector.HueSaturationCurves")

local v									= require("semver")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ColorInspector = {}

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.CORRECTION_TYPES
--- Constant
--- Table of Correction Types
ColorInspector.CORRECTION_TYPES = {
	["Color Board"] 			= "FFCorrectorColorBoard",
	["Color Wheels"]			= "PAECorrectorEffectDisplayName",
	["Color Curves"] 			= "PAEColorCurvesEffectDisplayName",
	["Hue/Saturation Curves"] 	= "PAEHSCurvesEffectDisplayName",
}

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.matches(element)
--- Function
--- Checks if the specified element is the Color Inspector element.
---
--- Parameters:
--- * element	- The element to check
---
--- Returns:
--- * `true` if the element is the Color Inspector.
function ColorInspector.matches(element)
	if element and element:attributeValue("AXRole") == "AXSplitGroup" and #element == 3 then
		local top = axutils.childFromTop(element, 1)
		if top and top:attributeValue("AXRole") == "AXGroup" and #top == 1 then
			-- check it's the correction bar.
			return CorrectionsBar.matches(top[1])
		end
	end
	return false
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector:new(parent) -> ColorInspector object
--- Method
--- Creates a new ColorInspector object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A ColorInspector object
function ColorInspector:new(parent)
	local o = {
		_parent = parent,
		_child = {}
	}

	prop.extend(o, ColorInspector)

--- cp.apple.finalcutpro.main.Inspector.ColorInspector.isSupported <cp.prop: boolean; read-only>
--- Field
--- Is the Color Inspector supported in the installed version of Final Cut Pro?
	o.isSupported = parent:app().getVersion:mutate(function(version, self)
		return version and v(version) >= v("10.4")
	end):bind(o)

	return o
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector:parent() -> table
--- Method
--- Returns the ColorInspector's parent table.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function ColorInspector:parent()
	return self._parent
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function ColorInspector:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
--
-- COLOR INSPECTOR UI:
--
-----------------------------------------------------------------------


--- cp.apple.finalcutpro.main.Inspector.ColorInspector:UI() -> hs._asm.axuielement object
--- Method
--- Returns the `hs._asm.axuielement` object for the Final Cut Pro 10.4 Color Board Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs._asm.axuielement` object or `nil` if not running Final Cut Pro 10.4 (or later), or if an error occurs.
function ColorInspector:UI()
	return axutils.cache(self, "_ui",
		function()
			local properties = self:parent():propertiesUI()
			return ColorInspector.matches(properties) and properties or nil
		end,
		ColorInspector.matches
	)
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector:correctorUI() -> hs._asm.axuielement object
--- Method
--- Returns the `hs._asm.axuielement` object representing the currently-selected corrector panel.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs._asm.axuielement` object or `nil` if not running Final Cut Pro 10.4 (or later), or if an error occurs.
function ColorInspector:correctorUI()
	return axutils.cache(self, "_corrector",
		function()
			local ui = self:UI()
			if ui then
				local bottomPanel = axutils.childAtIndex(ui, 1,
					function(a, b)
						local aFrame, bFrame = a:frame(), b:frame()
						local aBottom, bBottom = aFrame.y + aFrame.h, bFrame.y + bFrame.h
						return aBottom > bBottom
					end)
				return bottomPanel and bottomPanel[1] or nil
			end
			return nil
		end
	)
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector:corrections() -> CorrectionsBar
--- Method
--- Returns the `CorrectionsBar` instance representing the available corrections,
--- and currently selected correction type.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `CorrectionsBar` instance.
function ColorInspector:corrections()
	if not self._corrections then
		self._corrections = CorrectionsBar:new(self)
	end
	return self._corrections
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector:colorInspectorBarUI() -> hs._asm.axuielement object
--- Method
--- Returns the `hs._asm.axuielement` object for the Final Cut Pro 10.4 Color Board Inspector Bar (i.e. where you can add new Color Corrections from the dropdown)
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs._asm.axuielement` object or `nil` if not running Final Cut Pro 10.4 (or later), or if an error occurs.
function ColorInspector:colorInspectorBarUI()

	-----------------------------------------------------------------------
	-- Check that we're running Final Cut Pro 10.4:
	-----------------------------------------------------------------------
	if not self:isSupported() then
		log.ef("colorInspectorBarUI is only supported in Final Cut Pro 10.4 or later.")
		return nil
	end

	-----------------------------------------------------------------------
	-- Find the Color Inspector Bar:
	-----------------------------------------------------------------------
	local inspectorUI = self:app():inspector():UI()
	if inspectorUI then
		for _, child in ipairs(inspectorUI:attributeValue("AXChildren")) do
			local splitGroup = axutils.childWith(child, "AXRole", "AXSplitGroup")
			if splitGroup then
				for _, subchild in ipairs(splitGroup:attributeValue("AXChildren")) do
					local group = axutils.childWith(subchild, "AXIdentifier", id "ChooseColorCorrectorsBar")
					if group then
						return group
					end
				end
			end
		end
	else
		--log.df("inspectorUI is nil")
	end
	return nil

end

--------------------------------------------------------------------------------
--
-- COLOR INSPECTOR:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector.ColorInspector:isShowing([correctionType]) -> boolean
--- Method
--- Returns whether or not the Color Inspector is visible
---
--- Parameters:
---  * [correctionType] - A string containing the name of the Correction Type (see cp.apple.finalcutpro.main.Inspector.ColorInspector.CORRECTION_TYPES).
---
--- Returns:
---  * `true` if the Color Inspector is showing, otherwise `false`
function ColorInspector:isShowing(correctionType)
	local colorInspectorBarUI = self:colorInspectorBarUI()
	if correctionType then
		if colorInspectorBarUI then
			local menuButton = axutils.childWith(colorInspectorBarUI, "AXRole", "AXMenuButton")
			local colorBoardText = self:app():string(self.CORRECTION_TYPES[correctionType])
			if menuButton and colorBoardText and string.find(menuButton:attributeValue("AXTitle"), colorBoardText) then
				return true
			else
				return false
			end
		else
			return false
		end
	else
		return colorInspectorBarUI ~= nil or false
	end
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector:show([correctionType]) -> ColorInspector
--- Method
--- Show's the Color Inspector
---
--- Parameters:
---  * [correctionType] - A string containing the name of the Correction Type (see cp.apple.finalcutpro.main.Inspector.ColorInspector.CORRECTION_TYPES).
---
--- Returns:
---  * ColorInspector object
function ColorInspector:show(correctionType)
	if not self:isShowing() then
		self:app():menuBar():selectMenu({"Window", "Go To", "Color Inspector"})
	end
	if correctionType then
		if self.CORRECTION_TYPES[correctionType] then
			local colorInspectorBarUI = self:colorInspectorBarUI()
			if colorInspectorBarUI then
				local menuButton = axutils.childWith(colorInspectorBarUI, "AXRole", "AXMenuButton")
				local colorInspectorText = self:app():string(self.CORRECTION_TYPES[correctionType])
				if menuButton then
					if not string.find(menuButton:attributeValue("AXTitle"), colorInspectorText) then
						-----------------------------------------------------------------------
						-- A Color Board is not already selected by default:
						-----------------------------------------------------------------------
						local result = menuButton:performAction("AXPress")
						if result then
							local subMenus = menuButton:attributeValue("AXChildren")
							if subMenus and subMenus[1] then
								local foundAColorInspector = false
								local newColorInspectorUI = nil
								for _, child in ipairs(subMenus[1]) do
									local title = child:attributeValue("AXTitle")
									if title and foundAColorInspector == false and not (title == "+" .. colorInspectorText) and string.find(title, colorInspectorText) then
										-----------------------------------------------------------------------
										-- Found an existing Color Correction in the list, so open the first one:
										-----------------------------------------------------------------------
										foundAColorInspector = true
										child:performAction("AXPress")
									end
									-----------------------------------------------------------------------
									-- Save the "Add" button just in case we need it...
									-----------------------------------------------------------------------
									if title and title == "+" .. colorInspectorText then
										newColorInspectorUI = child
									end
								end
								if not foundAColorInspector and newColorInspectorUI then
									-----------------------------------------------------------------------
									-- Not existing Color Correction was found so creating new one:
									-----------------------------------------------------------------------
									local result = newColorInspectorUI:performAction("AXPress")
									if not result then
										log.ef("Failed to trigger new Color Board button.")
									end
								end
							end
						else
							log.ef("Failed to activate Color Controls drop down.")
						end
					end
				end
			else
				--log.ef("Could not find colorInspectorBarUI.")
			end
		else
			log.ef("Invalid Correction Type: %s", correctionType)
		end
	end

	return self
end

--- cp.apple.finalcutpro.main.Inspector.ColorInspector:hide() -> ColorInspector
--- Method
--- Hides's the Color Inspector
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorInspector object
function ColorInspector:hide()
	if self:isShowing() then
		self:app():menuBar():selectMenu({"Window", "Show in Workspace", "Inspector"})
	end
	return self
end

--------------------------------------------------------------------------------
--
-- COLOR BOARD:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector.ColorInspector:colorBoard() -> ColorBoard
--- Method
--- Gets the ColorBoard object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A new ColorBoard object
function ColorInspector:colorBoard()
	if not self._colorBoard then
		self._colorBoard = ColorBoard:new(self)
	end
	return self._colorBoard
end

--------------------------------------------------------------------------------
--
-- COLOR WHEELS:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector.ColorInspector:colorWheels() -> ColorWheels
--- Method
--- Gets the ColorWheels object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A new ColorWheels object
function ColorInspector:colorWheels()
	if not self._colorWheels then
		self._colorWheels = ColorWheels:new(self)
	end
	return self._colorWheels
end

--------------------------------------------------------------------------------
--
-- COLOR CURVES:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector.ColorInspector:colorCurves() -> ColorCurves
--- Method
--- Gets the ColorCurves object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A new ColorCurves object
function ColorInspector:colorCurves()
	if not self._colorCurves then
		self._colorCurves = ColorCurves:new(self)
	end
	return self._colorCurves
end

--------------------------------------------------------------------------------
--
-- HUE/SATURATION CURVES:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.Inspector.ColorInspector:hueSaturationCurves() -> HueSaturationCurves
--- Method
--- Gets the HueSaturationCurves object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A new HueSaturationCurves object
function ColorInspector:hueSaturationCurves()
	if not self._hueSaturationCurves then
		self._hueSaturationCurves = HueSaturationCurves:new(self)
	end
	return self._hueSaturationCurves
end

return ColorInspector