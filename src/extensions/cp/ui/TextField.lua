--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.TextField ===
---
--- Text Field Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log							= require("hs.logger").new("textField")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils						= require("cp.ui.axutils")
local prop							= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local TextField = {}

-- TODO: Add documentation
function TextField.matches(element)
	return element:attributeValue("AXRole") == "AXTextField"
end

--- cp.ui.TextField:new(parent, finderFn[, convertFn]) -> TextField
--- Method
--- Creates a new TextField. They have a parent and a finder function.
--- Additionally, an optional `convert` function can be provided, with the following signature:
---
--- `function(textValue) -> anything`
---
--- The `value` will be passed to the function before being returned, if present. All values
--- passed into `value(x)` will be converted to a `string` first via `tostring`.
---
--- For example, to have the value be converted into a `number`, simply use `tonumber` like this:
---
--- ```lua
--- local numberField = TextField:new(parent, function() return ... end, tonumber)
--- ```
---
--- Parameters:
--- * parent	- The parent object.
--- * finderFn	- The function will return the `axuielement` for the TextField.
--- * convertFn	- (optional) If provided, will be passed the `string` value when returning.
---
--- Returns:
--- * The new `TextField`.
-- TODO: Use a function instead of a method.
function TextField:new(parent, finderFn, convertFn) -- luacheck: ignore
	return prop.extend({
		_parent = parent,
		_finder = finderFn,
		_convert = convertFn,
	}, TextField)
end

-- TODO: Add documentation
function TextField:parent()
	return self._parent
end

-- TODO: Add documentation
function TextField:UI()
	return axutils.cache(self, "_ui", function()
		return self._finder()
	end,
	TextField.matches)
end

-- TODO: Add documentation
function TextField:isShowing()
	return self:UI() ~= nil and self:parent():isShowing()
end

--- cp.ui.TextField.value <cp.prop: anything>
--- Field
--- The current value of the text field.
TextField.value = prop(
	function(self)
		local ui = self:UI()
		local value = ui and ui:attributeValue("AXValue") or nil
		if value and self._convert then
			value = self._convert(value)
		end
		return value
	end,
	function(value, self)
		local ui = self:UI()
		if ui then
			value = tostring(value)
			local focused = ui:attributeValue("AXFocused")
			ui:setAttributeValue("AXFocused", true)
			ui:setAttributeValue("AXValue", value)
			ui:setAttributeValue("AXFocused", focused)
			ui:performAction("AXConfirm")
		end

	end
):bind(TextField)

-- TODO: Add documentation
function TextField:getValue()
	return self:value()
end

-- TODO: Add documentation
function TextField:setValue(value)
	self.value:set(value)
end

-- TODO: Add documentation
function TextField:clear()
	self.value:set("")
end

-- TODO: Add documentation
function TextField:isEnabled()
	local ui = self:UI()
	return ui and ui:enabled()
end

-- TODO: Add documentation
function TextField:saveLayout()
	local layout = {}
	layout.value = self:getValue()
	return layout
end

-- TODO: Add documentation
function TextField:loadLayout(layout)
	if layout then
		self:setValue(layout.value)
	end
end

-- TODO: Add documentation
function TextField.__call(self, parent, value)
	if parent and parent ~= self:parent() then
		value = parent
	end
	return self:value(value)
end

--- cp.ui.TextField:snapshot([path]) -> hs.image | nil
--- Method
--- Takes a snapshot of the UI in its current state as a PNG and returns it.
--- If the `path` is provided, the image will be saved at the specified location.
---
--- Parameters:
--- * path		- (optional) The path to save the file. Should include the extension (should be `.png`).
---
--- Return:
--- * The `hs.image` that was created, or `nil` if the UI is not available.
function TextField:snapshot(path)
	local ui = self:UI()
	if ui then
		return axutils.snapshot(ui, path)
	end
	return nil
end

return TextField
