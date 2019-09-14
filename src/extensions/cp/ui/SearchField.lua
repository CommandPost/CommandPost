--- === cp.ui.SearchField ===
---
--- A [TextField](cp.ui.TextField.md) with a subrole of `AXSearchField`.

local TextField         = require "cp.ui.TextField"


local SearchField = TextField:subclass("cp.ui.SearchField")

--- cp.ui.SearchField.matchesSearch(element) -> boolean
--- Function
--- Checks to see if an element is a `AXTextField` with a subrole of `AXSearchField`.
---
--- Parameters:
--- * element - An `axuielementObject` to check.
---
--- Returns:
--- * `true` if matches, otherwise `false`.
function SearchField.static.matches(element)
    return TextField.matches(element) and element:attributeValue("AXSubrole") == "AXSearchField"
end

--- cp.ui.SearchField(parent, uiFinder[, convertFn]) -> cp.ui.SearchField
--- Method
--- Creates a new SearchField. They have a parent and a finder function.
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
--- local numberField = SearchField(parent, function() return ... end, tonumber)
--- ```
---
--- Parameters:
---  * parent	- The parent object.
---  * uiFinder	- The function will return the `axuielement` for the SearchField.
---  * convertFn	- (optional) If provided, will be passed the `string` value when returning.
---
--- Returns:
---  * The new `SearchField`.
function SearchField:initialize(parent, uiFinder, converterFn)
    TextField.initialize(self, parent, uiFinder, converterFn)
end

return SearchField
