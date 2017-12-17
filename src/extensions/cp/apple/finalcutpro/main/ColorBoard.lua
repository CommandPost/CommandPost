--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.ColorBoard ===
---
--- Color Board Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")
local geometry							= require("hs.geometry")

local prop								= require("cp.prop")
local just								= require("cp.just")
local axutils							= require("cp.ui.axutils")
local tools								= require("cp.tools")

local Pucker							= require("cp.apple.finalcutpro.main.ColorPucker")

local id								= require("cp.apple.finalcutpro.ids") "ColorBoard"

local semver							= require("semver")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ColorBoard = {}

--- cp.apple.finalcutpro.main.ColorBoard.aspect -> table
--- Constant
--- A table containing tables of all the aspect panel settings
ColorBoard.aspect						= {}

--- cp.apple.finalcutpro.main.ColorBoard.aspect.color -> table
--- Constant
--- A table containing the Color Board Color panel settings
ColorBoard.aspect.color					= {
	id 									= 1,
	reset 								= id "ColorReset",
	global 								= { puck = id "ColorGlobalPuck", pct = id "ColorGlobalPct", angle = id "ColorGlobalAngle"},
	shadows 							= { puck = id "ColorShadowsPuck", pct = id "ColorShadowsPct", angle = id "ColorShadowsAngle"},
	midtones 							= { puck = id "ColorMidtonesPuck", pct = id "ColorMidtonesPct", angle = id "ColorMidtonesAngle"},
	highlights 							= { puck = id "ColorHighlightsPuck", pct = id "ColorHighlightsPct", angle = id "ColorHighlightsAngle"}
}

--- cp.apple.finalcutpro.main.ColorBoard.aspect.saturation -> table
--- Constant
--- A table containing the Color Board Saturation panel settings
ColorBoard.aspect.saturation			= {
	id 									= 2,
	reset 								= id "SatReset",
	global 								= { puck = id "SatGlobalPuck", pct = id "SatGlobalPct"},
	shadows 							= { puck = id "SatShadowsPuck", pct = id "SatShadowsPct"},
	midtones 							= { puck = id "SatMidtonesPuck", pct = id "SatMidtonesPct"},
	highlights 							= { puck = id "SatHighlightsPuck", pct = id "SatHighlightsPct"}
}

--- cp.apple.finalcutpro.main.ColorBoard.aspect.exposure -> table
--- Constant
--- A table containing the Color Board Exposure panel settings
ColorBoard.aspect.exposure				= {
	id									= 3,
	reset								= id "ExpReset",
	global								= { puck = id "ExpGlobalPuck", pct = id "ExpGlobalPct"},
	shadows 							= { puck = id "ExpShadowsPuck", pct = id "ExpShadowsPct"},
	midtones							= { puck = id "ExpMidtonesPuck", pct = id "ExpMidtonesPct"},
	highlights							= { puck = id "ExpHighlightsPuck", pct = id "ExpHighlightsPct"}
}

--- cp.apple.finalcutpro.main.ColorBoard.currentAspect -> string
--- Variable
--- The current aspect as a string.
ColorBoard.currentAspect = "*"

--- cp.apple.finalcutpro.main.ColorBoard.isColorBoard(element) -> boolean
--- Function
--- Checks to see if a GUI element is the Color Board or not
---
--- Parameters:
---  * `element`	- The element you want to check
---
--- Returns:
---  * `true` if the `element` is a Color Board otherwise `false`
function ColorBoard.isColorBoard(element)
	for _, child in ipairs(element) do
		-----------------------------------------------------------------------
		-- Final Cut Pro 10.3:
		----------------------------------------------------------------------
		if axutils.childWith(child, "AXIdentifier", id "BackButton") then
			return true
		end

		-----------------------------------------------------------------------
		-- Final Cut Pro 10.4:
		-----------------------------------------------------------------------
		local splitGroup = axutils.childWith(child, "AXRole", "AXSplitGroup")
		if splitGroup then
			local colorBoardGroup = axutils.childWith(splitGroup, "AXIdentifier", id "ColorBoardGroup")
			if colorBoardGroup and colorBoardGroup[1] and colorBoardGroup[1][1] and #colorBoardGroup[1][1]:attributeValue("AXChildren") >= 19 then
				return true
			end
		end
	end
	return false
end

--- cp.apple.finalcutpro.main.ColorBoard:new(parent) -> ColorBoard object
--- Method
--- Creates a new ColorBoard object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A ColorBoard object
function ColorBoard:new(parent)
	local o = {
		_parent = parent,
		_child = {}
	}

	return prop.extend(o, ColorBoard)
end

--- cp.apple.finalcutpro.main.ColorBoard:parent() -> table
--- Method
--- Returns the ColorBoard's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function ColorBoard:parent()
	return self._parent
end

--- cp.apple.finalcutpro.main.ColorBoard:app() -> table
--- Method
--- Returns the `cp.apple.finalcutpro` app table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The application object as a table
function ColorBoard:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
--
-- COLORBOARD UI:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.ColorBoard:UI() -> hs._asm.axuielement object
--- Method
--- Returns the `hs._asm.axuielement` object for the Color Board
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs._asm.axuielement` object
function ColorBoard:UI()
	return axutils.cache(self, "_ui",
	function()
		local parent = self:parent()
		local ui = parent:rightGroupUI()
		local version = self:app():getVersion()
		if ui then
			-----------------------------------------------------------------------
			-- It's in the right panel (full-height):
			-----------------------------------------------------------------------
			if ColorBoard.isColorBoard(ui) then
				if version and semver(version) >= semver("10.4") then
					-----------------------------------------------------------------------
					-- Final Cut Pro 10.4:
					----------------------------------------------------------------------
					local groupChildren = ui:attributeValue("AXChildren")
					if groupChildren then
						for _, child in ipairs(groupChildren) do
							local splitGroup = axutils.childWith(child, "AXRole", "AXSplitGroup")
							if splitGroup then
								return splitGroup and splitGroup[1] and splitGroup[1][1] and splitGroup[1][1][1]
							end
						end
					end
				else
					-----------------------------------------------------------------------
					-- Final Cut Pro 10.3:
					-----------------------------------------------------------------------
					return ui
				end
			end
		else
			-----------------------------------------------------------------------
			-- It's in the top-left panel (half-height):
			-----------------------------------------------------------------------
			local top = parent:topGroupUI()
			if not top then
				return nil
			end
			for i,child in ipairs(top) do
				if ColorBoard.isColorBoard(child) then
					if version and semver(version) >= semver("10.4") then
						-----------------------------------------------------------------------
						-- Final Cut Pro 10.4:
						----------------------------------------------------------------------
						local groupChildren = child:attributeValue("AXChildren")
						if groupChildren then
							for _, grandChild in ipairs(groupChildren) do
								local splitGroup = axutils.childWith(grandChild, "AXRole", "AXSplitGroup")
								if splitGroup then
									return splitGroup and splitGroup[1] and splitGroup[1][1] and splitGroup[1][1][1]
								end
							end
						end
					else
						-----------------------------------------------------------------------
						-- Final Cut Pro 10.3:
						-----------------------------------------------------------------------
						return child
					end
				end
			end
		end
		return nil
	end,
	function(element) return ColorBoard:isColorBoard(element) end)
end

--- cp.apple.finalcutpro.main.ColorBoard:colorInspectorBarUI() -> hs._asm.axuielement object
--- Method
--- Returns the `hs._asm.axuielement` object for the Final Cut Pro 10.4 Color Board Inspector Bar (i.e. where you can add new Color Corrections from the dropdown)
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs._asm.axuielement` object
function ColorBoard:colorInspectorBarUI()

	-----------------------------------------------------------------------
	-- Check that we're running Final Cut Pro 10.4:
	-----------------------------------------------------------------------
	local version = self:app():getVersion()
	if version and semver(version) < semver("10.4") then
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
	end
	return nil

end

--- cp.apple.finalcutpro.main.ColorBoard:isShowing() -> boolean
--- Method
--- Returns whether or not the Color Board is visible
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the Color Board is showing, otherwise `false`
ColorBoard.isShowing = prop.new(function(self)
	local version = self:app():getVersion()
	if version and semver(version) >= semver("10.4") then
		-----------------------------------------------------------------------
		-- Final Cut Pro 10.4:
		----------------------------------------------------------------------
		local colorInspectorBarUI = self:colorInspectorBarUI()
		if colorInspectorBarUI then
			local menuButton = axutils.childWith(colorInspectorBarUI, "AXRole", "AXMenuButton")
			local colorBoardText = self:app():string("FFCorrectorColorBoard")
			if menuButton and colorBoardText and string.find(menuButton:attributeValue("AXTitle"), colorBoardText) then
				return true
			else
				return false
			end
		else
			return false
		end
	else
		-----------------------------------------------------------------------
		-- Final Cut Pro 10.3:
		-----------------------------------------------------------------------
		local ui = self:UI()
		return ui ~= nil and ui:attributeValue("AXSize").w > 0
	end
end):bind(ColorBoard)

--- cp.apple.finalcutpro.main.ColorBoard:isActive() -> boolean
--- Method
--- Returns whether or not the Color Board is active
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the Color Board is active, otherwise `false`
ColorBoard.isActive = prop.new(function(self)
	local ui = self:colorSatExpUI()
	return ui ~= nil and axutils.childWith(ui:parent(), "AXIdentifier", id "ColorSatExp")
end):bind(ColorBoard)

--- cp.apple.finalcutpro.main.ColorBoard:show() -> ColorBoard object
--- Method
--- Shows the Color Board
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorBoard object
function ColorBoard:show()
	if not self:isShowing() then
		local version = self:app():getVersion()
		if version and semver(version) >= semver("10.4") then
			-----------------------------------------------------------------------
			-- Final Cut Pro 10.4:
			-----------------------------------------------------------------------
			log.df("Showing a 10.4 Color Board")
			self:app():menuBar():selectMenu({"Window", "Go To", id "ColorBoard"})
			local colorInspectorBarUI = self:colorInspectorBarUI()
			if colorInspectorBarUI then
				local menuButton = axutils.childWith(colorInspectorBarUI, "AXRole", "AXMenuButton")
				local colorBoardText = self:app():string("FFCorrectorColorBoard")
				if menuButton then
					if not string.find(menuButton:attributeValue("AXTitle"), colorBoardText) then
						-----------------------------------------------------------------------
						-- A Color Board is not already selected by default:
						-----------------------------------------------------------------------
						local result = menuButton:performAction("AXPress")
						if result then
							local subMenus = menuButton:attributeValue("AXChildren")
							if subMenus and subMenus[1] then
								local foundAColorBoard = false
								local newColorBoardUI = nil
								for _, child in ipairs(subMenus[1]) do
									local title = child:attributeValue("AXTitle")
									if title and foundAColorBoard == false and not (title == "+" .. colorBoardText) and string.find(title, colorBoardText) then
										-----------------------------------------------------------------------
										-- Found an existing Color Board in the list, so open the first one:
										-----------------------------------------------------------------------
										foundAColorBoard = true
										child:performAction("AXPress")
									end
									-----------------------------------------------------------------------
									-- Save the "Add Color Board" button just in case we need it...
									-----------------------------------------------------------------------
									if title and title == "+" .. colorBoardText then
										newColorBoardUI = child
									end
								end
								if not foundAColorBoard and newColorBoardUI then
									-----------------------------------------------------------------------
									-- Not existing Color Board was found so creating new one:
									-----------------------------------------------------------------------
									local result = newColorBoardUI:performAction("AXPress")
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
				log.ef("Could not find colorInspectorBarUI.")
			end
		else
			-----------------------------------------------------------------------
			-- Final Cut Pro 10.3:
			-----------------------------------------------------------------------
			self:app():menuBar():selectMenu({"Window", "Go To", id "ColorBoard"})
		end
	end
	return self
end

--- cp.apple.finalcutpro.main.ColorBoard:hide() -> ColorBoard object
--- Method
--- Hides the Color Board
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorBoard object
function ColorBoard:hide()
	local ui = self:showInspectorUI()
	if ui then ui:doPress() end
	return self
end

--- cp.apple.finalcutpro.main.ColorBoard:childUI(id) -> hs._asm.axuielement object
--- Method
--- Gets the `hs._asm.axuielement` object for a child with the specified ID.
---
--- Parameters:
---  * id - `AXIdentifier` of the child
---
--- Returns:
---  * An `hs._asm.axuielement` object
function ColorBoard:childUI(id)
	return axutils.cache(self._child, id, function()
		local ui = self:UI()
		return ui and axutils.childWith(ui, "AXIdentifier", id)
	end)
end

--- cp.apple.finalcutpro.main.ColorBoard:topToolbarUI() -> hs._asm.axuielement object
--- Method
--- Gets the `hs._asm.axuielement` object for the top toolbar (i.e. where the Back Button is located in Final Cut Pro 10.3)
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `hs._asm.axuielement` object
---
--- Notes:
---  * This object doesn't exist in Final Cut Pro 10.4 as the Color Board is now contained within the Color Inspector
function ColorBoard:topToolbarUI()
	return axutils.cache(self, "_topToolbar", function()
		local ui = self:UI()
		if ui then
			for i,child in ipairs(ui) do
				if axutils.childWith(child, "AXIdentifier", id "BackButton") then
					return child
				end
			end
		end
		return nil
	end)
end

--- cp.apple.finalcutpro.main.ColorBoard:showInspectorUI() -> hs._asm.axuielement object
--- Method
--- Gets the `hs._asm.axuielement` object for the inspector
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `hs._asm.axuielement` object
function ColorBoard:showInspectorUI()
	return axutils.cache(self, "_showInspector", function()
		local ui = self:topToolbarUI()
		if ui then
			return axutils.childWith(ui, "AXIdentifier", id "BackButton")
		end
		return nil
	end)
end

-----------------------------------------------------------------------
--
-- COLOR CORRECTION PANELS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.ColorBoard:colorSatExpUI() -> hs._asm.axuielement object
--- Method
--- Gets the `hs._asm.axuielement` object for the `AXRadioGroup` which houses the "Color", "Saturation" and "Exposure" button
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `hs._asm.axuielement` object
function ColorBoard:colorSatExpUI()
	return axutils.cache(self, "_colorSatExp", function()
		local ui = self:UI()
		return ui and axutils.childWith(ui, "AXIdentifier", id "ColorSatExp")
	end)
end

--- cp.apple.finalcutpro.main.ColorBoard:getAspect(aspect, property) -> table
--- Method
--- Gets a table containing the ID information for a specific `aspect` and `property`
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---
--- Returns:
---  * A table or `nil` if an error occurs
function ColorBoard:getAspect(aspect, property)
	local panel = nil
	if type(aspect) == "string" then
		if aspect == ColorBoard.currentAspect then
			-----------------------------------------------------------------------
			-- Return the currently-visible aspect:
			-----------------------------------------------------------------------
			local ui = self:colorSatExpUI()
			if ui then
				for k,value in pairs(ColorBoard.aspect) do
					if ui[value.id]:value() == 1 then
						panel = value
					end
				end
			end
		else
			panel = ColorBoard.aspect[aspect]
		end
	else
		panel = name
	end
	if panel and property then
		return panel[property]
	end
	return panel
end

-----------------------------------------------------------------------
--
-- PANEL CONTROLS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.ColorBoard:togglePanel() -> ColorBoard object
--- Method
--- Toggles the Color Board Panels between "Color", "Saturation" and "Exposure"
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorBoard object
function ColorBoard:togglePanel()
	self:show()

	local colorAspect = self:getAspect("color")
	local saturationAspect = self:getAspect("saturation")
	local exposureAspect = self:getAspect("exposure")

	local ui = self:colorSatExpUI()
	if colorAspect and ui and ui[colorAspect.id]:value() == 1 then
		ui[saturationAspect.id]:doPress()
	elseif saturationAspect and ui and ui[saturationAspect.id]:value() == 1 then
		ui[exposureAspect.id]:doPress()
	elseif exposureAspect and ui and ui[exposureAspect.id]:value() == 1 then
		ui[colorAspect.id]:doPress()
	end
	return self
end

--- cp.apple.finalcutpro.main.ColorBoard:selectedPanel() -> string | nil
--- Method
--- Returns the currently selected Color Board panel
---
--- Parameters:
---  * None
---
--- Returns:
---  * "Color", "Saturation", "Exposure" or `nil` if an error occurs
function ColorBoard:selectedPanel()

	local colorAspect = self:getAspect("color")
	local saturationAspect = self:getAspect("saturation")
	local exposureAspect = self:getAspect("exposure")

	local ui = self:colorSatExpUI()
	if colorAspect and ui and ui[colorAspect.id] and ui[colorAspect.id]:value() == 1 then
		return "color"
	elseif saturationAspect and ui and ui[saturationAspect.id] and ui[saturationAspect.id]:value() == 1 then
		return "saturation"
	elseif exposureAspect and ui and ui[exposureAspect.id] and ui[exposureAspect.id]:value() == 1 then
		return "exposure"
	end
	return nil

end

--- cp.apple.finalcutpro.main.ColorBoard:showPanel(aspect) -> ColorBoard object
--- Method
--- Shows a specific panel based on the specified `aspect`
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---
--- Returns:
---  * ColorBoard object
function ColorBoard:showPanel(aspect)
	self:show()
	aspect = self:getAspect(aspect)
	local ui = self:colorSatExpUI()
	if aspect and ui and ui[aspect.id]:value() == 0 then
		ui[aspect.id]:doPress()
	end
	return self
end

--- cp.apple.finalcutpro.main.ColorBoard:reset(aspect) -> ColorBoard object
--- Method
--- Resets a specified `aspect`
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---
--- Returns:
---  * ColorBoard object
function ColorBoard:reset(aspect)
	aspect = self:getAspect(aspect)
	self:showPanel(aspect)
	local ui = self:UI()
	if ui then
		local reset = axutils.childWith(ui, "AXIdentifier", aspect.reset)
		if reset then
			reset:doPress()
		end
	end
	return self
end

--- cp.apple.finalcutpro.main.ColorBoard:puckUI(aspect, property) -> hs._asm.axuielement object
--- Method
--- Gets the `hs._asm.axuielement` object of a specific Color Board puck
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---
--- Returns:
---  * An `hs._asm.axuielement` object
function ColorBoard:puckUI(aspect, property)
	local details = self:getAspect(aspect, property)
	return self:childUI(details.puck)
end

--- cp.apple.finalcutpro.main.ColorBoard:selectPuck(aspect, property) -> ColorBoard object
--- Method
--- Selects a specific Color Board puck
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---
--- Returns:
---  * ColorBoard object
function ColorBoard:selectPuck(aspect, property)
	self:showPanel(aspect)
	local puckUI = self:puckUI(aspect, property)
	if puckUI then
		local f = puckUI:frame()
		local centre = geometry(f.x + f.w/2, f.y + f.h/2)
		tools.ninjaMouseClick(centre)
	end
	return self
end

--- cp.apple.finalcutpro.main.ColorBoard:aspectPropertyPanelUI(aspect, property, type) -> hs._asm.axuielement object
--- Method
--- Ensures that the specified aspect/property panel is visible and returns the specified value type `hs._asm.axuielement` object
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---  * type			- "pct" or "angle"
---
--- Returns:
---  * An `hs._asm.axuielement` object or `nil` if an error occurs
function ColorBoard:aspectPropertyPanelUI(aspect, property, type)
	if not self:isShowing() then
		return nil
	end
	self:showPanel(aspect)
	local details = self:getAspect(aspect, property)
	if not details or not details[type] then
		return nil
	end
	local ui = self:childUI(details[type])
	if not ui then
		-----------------------------------------------------------------------
		-- Short inspector panels can hide some details panels:
		-----------------------------------------------------------------------
		self:selectPuck(aspect, property)
		-----------------------------------------------------------------------
		-- Try again:
		-----------------------------------------------------------------------
		ui = self:childUI(details[type])
	end
	return ui
end

--- cp.apple.finalcutpro.main.ColorBoard:applyPercentage(aspect, property, value) -> ColorBoard object
--- Method
--- Applies a Color Board Percentage value to the specified aspect/property
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---  * value		- value as string
---
--- Returns:
---  * ColorBoard object
function ColorBoard:applyPercentage(aspect, property, value)
	local pctUI = self:aspectPropertyPanelUI(aspect, property, 'pct')
	if pctUI then
		pctUI:setAttributeValue("AXValue", tostring(value))
		pctUI:doConfirm()
	end
	return self
end

--- cp.apple.finalcutpro.main.ColorBoard:shiftPercentage(aspect, property, shift) -> ColorBoard object
--- Method
--- Shifts a Color Board Percentage value of the specified aspect/property
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---  * shift		- number you want to increase/decrease the percentage by
---
--- Returns:
---  * ColorBoard object
function ColorBoard:shiftPercentage(aspect, property, shift)
	local ui = self:aspectPropertyPanelUI(aspect, property, 'pct')
	if ui then
		local value = tonumber(ui:attributeValue("AXValue") or "0")
		ui:setAttributeValue("AXValue", tostring(value + tonumber(shift)))
		ui:doConfirm()
	end
	return self
end

--- cp.apple.finalcutpro.main.ColorBoard:getPercentage(aspect, property) -> number | nil
--- Method
--- Gets a percentage value of the specified `aspect` and `property`
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---
--- Returns:
---  * Number or `nil` if an error occurred
function ColorBoard:getPercentage(aspect, property)
	local pctUI = self:aspectPropertyPanelUI(aspect, property, 'pct')
	if pctUI then
		return tonumber(pctUI:attributeValue("AXValue"))
	end
	return nil
end

--- cp.apple.finalcutpro.main.ColorBoard:applyAngle(aspect, property, value) -> ColorBoard object
--- Method
--- Applies a Color Board Angle value to the specified aspect/property
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---  * value		- value as string
---
--- Returns:
---  * ColorBoard object
function ColorBoard:applyAngle(aspect, property, value)
	local angleUI = self:aspectPropertyPanelUI(aspect, property, 'angle')
	if angleUI then
		angleUI:setAttributeValue("AXValue", tostring(value))
		angleUI:doConfirm()
	end
	return self
end

--- cp.apple.finalcutpro.main.ColorBoard:shiftAngle(aspect, property, shift) -> ColorBoard object
--- Method
--- Shifts a Color Board Angle value of the specified aspect/property
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---  * shift		- number you want to increase/decrease the angle by
---
--- Returns:
---  * ColorBoard object
function ColorBoard:shiftAngle(aspect, property, shift)
	local ui = self:aspectPropertyPanelUI(aspect, property, 'angle')
	if ui then
		local value = tonumber(ui:attributeValue("AXValue") or "0")
		-----------------------------------------------------------------------
		-- Loop around between 0 and 360 degrees:
		-----------------------------------------------------------------------
		value = (value + shift + 360) % 360
		ui:setAttributeValue("AXValue", tostring(value))
		ui:doConfirm()
	end
	return self
end

--- cp.apple.finalcutpro.main.ColorBoard:getAngle(aspect, property) -> number | nil
--- Method
--- Gets an angle value of the specified `aspect` and `property`
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---
--- Returns:
---  * Number or `nil` if an error occurred
function ColorBoard:getAngle(aspect, property, value)
	local angleUI = self:aspectPropertyPanelUI(aspect, property, 'angle')
	if angleUI then
		local value = angleUI:attributeValue("AXValue")
		if value ~= nil then return tonumber(value) end
	end
	return nil
end

--- cp.apple.finalcutpro.main.ColorBoard:startPucker(aspect, property) -> Pucker object
--- Method
--- Creates a Pucker object for the specified `aspect` and `property`
---
--- Parameters:
---  * aspect 		- "color", "saturation" or "exposure"
---  * property 	- "global", "shadows", "midtones" or "highlights"
---
--- Returns:
---  * Pucker object
function ColorBoard:startPucker(aspect, property)
	if self.pucker then
		self.pucker:cleanup()
		self.pucker = nil
	end
	self.pucker = Pucker:new(self, aspect, property):start()
	return self.pucker
end

return ColorBoard