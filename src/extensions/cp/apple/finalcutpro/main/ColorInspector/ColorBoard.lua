--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.ColorInspector.ColorBoard ===
---
--- Color Board Module.
---
--- Requires Final Cut Pro 10.4 or later.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("colorBoard")

local prop								= require("cp.prop")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

local CORRECTION_TYPE					= "Color Board"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ColorBoard = {}

--- cp.apple.finalcutpro.main.ColorInspector.ColorBoard:new(parent) -> ColorBoard object
--- Method
--- Creates a new ColorBoard object
---
--- Parameters:
---  * `parent`		- The parent
---
--- Returns:
---  * A ColorInspector object
function ColorBoard:new(parent)
	local o = {
		_parent = parent,
		_child = {}
	}

	return prop.extend(o, ColorBoard)
end

--- cp.apple.finalcutpro.main.ColorInspector.ColorBoard:parent() -> table
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

--- cp.apple.finalcutpro.main.ColorInspector.ColorBoard:app() -> table
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

--------------------------------------------------------------------------------
--
-- COLOR BOARD:
--
--------------------------------------------------------------------------------

--- cp.apple.finalcutpro.main.ColorInspector.ColorBoard:show() -> ColorBoard object
--- Method
--- Show's the Color Board within the Color Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorBoard object
function ColorBoard:show()
	self:parent():show(CORRECTION_TYPE)
	return self
end

--- cp.apple.finalcutpro.main.ColorInspector.ColorBoard:hide() -> ColorBoard object
--- Method
--- Hide's the Color Board, by hiding the entire Inspector.
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorBoard object
function ColorBoard:hide()
	self:parent():hide()
	return self
end

--- cp.apple.finalcutpro.main.ColorInspector.ColorBoard.isShowing() -> boolean
--- Method
--- Is the Color Board currently showing?
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if showing, otherwise `false`
function ColorBoard:isShowing()
	return self:parent():isShowing(CORRECTION_TYPE)
end

return ColorBoard