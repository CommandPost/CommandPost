--- Utility functions to support 'axuielement'

local fnutils					= require("hs.fnutils")

local axutils = {}

--- hs.finalcutpro.axutil.childWith(axuielement, string, anything) -> axuielement
--- Function:
--- This searches for the first child of the specified element which has an attribute
--- with the matching name and value.
---
--- Params:
--- * element	- the axuielement
--- * name		- the name of the attribute
--- * value		- the value of the attribute
--- Returns:
--- The first matching child, or nil if none was found
function axutils.childWith(element, name, value)
	for i,child in ipairs(element) do
		if child:attributeValue(name) == value then
			return child
		end
	end
	return nil
end

return axutils