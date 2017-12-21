--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.ColorInspector ===
---
--- Color Inspector Module.
---
--- Require Final Cut Pro 10.4 or later

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

local semver							= require("semver")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ColorInspector = {}

--- cp.apple.finalcutpro.main.ColorInspector:new(parent) -> ColorInspector object
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

	return prop.extend(o, ColorInspector)
end

--- cp.apple.finalcutpro.main.ColorInspector:parent() -> table
--- Method
--- Returns the ColorInspector's parent table
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent object as a table
function ColorInspector:parent()
	return self._parent
end

--- cp.apple.finalcutpro.main.ColorInspector:app() -> table
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

--- cp.apple.finalcutpro.main.ColorInspector:colorInspectorBarUI() -> hs._asm.axuielement object
--- Method
--- Returns the `hs._asm.axuielement` object for the Final Cut Pro 10.4 Color Board Inspector Bar (i.e. where you can add new Color Corrections from the dropdown)
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `hs._asm.axuielement` object
function ColorInspector:colorInspectorBarUI()

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

--- cp.apple.finalcutpro.main.ColorInspector:isShowing() -> boolean
--- Method
--- Returns whether or not the Color Inspector is visible
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if the Color Inspector is showing, otherwise `false`
function ColorInspector:isShowing()
	local colorInspectorBarUI = self:colorInspectorBarUI()
	return colorInspectorBarUI ~= nil or false
end

return ColorInspector