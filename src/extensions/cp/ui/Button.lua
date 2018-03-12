--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.Button ===
---
--- Button Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
-- local log							= require("hs.logger").new("button")

local axutils						= require("cp.ui.axutils")
local prop							= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Button = {}

--- cp.ui.Button.matches(element) -> boolean
--- Function
--- Checks if the `element` is a `Button`, returning `true` if so.
---
--- Parameters:
--- * element		- The `hs._asm.axuielement` to check.
---
--- Returns:
--- * `true` if the `element` is a `Button`, or `false` if not.
function Button.matches(element)
	return element and element:attributeValue("AXRole") == "AXButton"
end

--- cp.ui.Button.new(parent, finderFn) -> cp.ui.Button
--- Constructor
--- Creates a new `Button` instance.
---
--- Parameters:
--- * parent		- The parent object. Should have a `UI` and `isShowing` field.
--- * finderFn		- A function which will return the `hs._asm.axuielement` the button belongs to, or `nil` if not available.
---
--- Returns:
--- The new `Button` instance.
function Button.new(parent, finderFn)
	local o = prop.extend({_parent = parent, _finder = finderFn}, Button)

	-- TODO: Add documentation
	local UI = prop(function(self)
		return axutils.cache(self, "_ui", finderFn, Button.matches)
	end)

	if prop.is(parent.UI) then
		UI:monitor(parent.UI)
	end

	local isShowing = UI:mutate(function(original, self)
		return original() ~= nil and self:parent():isShowing()
	end)

	if prop.is(parent.isShowing) then
		isShowing.monitor(parent.isShowing)
	end

	local frame = UI:mutate(function(original)
		local ui = original()
		return ui and ui:frame() or nil
	end)

	prop.bind(o) {
		--- cp.ui.Button.UI <cp.prop: hs._asm.axuielement; read-only>
		--- Field
		--- Retrieves the `axuielement` for the `Button`, or `nil` if not available..
		UI = UI,

		--- cp.ui.Button.isShowing <cp.prop: boolean; read-only>
		--- Field
		--- If `true`, the `Button` is showing on screen.
		isShowing = isShowing,

		--- cp.ui.Button.frame <cp.prop: table; read-only>
		--- Field
		--- Returns the table containing the `x`, `y`, `w`, and `h` values for the button frame, or `nil` if not available.
		frame = frame,
	}

	return o
end

-- TODO: Add documentation
function Button:parent()
	return self._parent
end

--- cp.ui.Button:isEnabled() -> boolean
--- Method
--- Returns `true` if the button is visible and enabled.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if the button is visible and enabled.
function Button:isEnabled()
	local ui = self:UI()
	return ui ~= nil and ui:enabled()
end

--- cp.ui.Button:press() -> self
--- Method
--- Performs a button press action, if the button is available.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `Button` instance.
function Button:press()
	local ui = self:UI()
	if ui then ui:doPress() end
	return self
end

--- cp.ui.Button:snapshot([path]) -> hs.image | nil
--- Method
--- Takes a snapshot of the button in its current state as a PNG and returns it.
--- If the `path` is provided, the image will be saved at the specified location.
---
--- Parameters:
--- * path		- (optional) The path to save the file. Should include the extension (should be `.png`).
---
--- Return:
--- * The `hs.image` that was created.
function Button:snapshot(path)
	local ui = self:UI()
	if ui then
		return axutils.snapshot(ui, path)
	end
	return nil
end

return Button