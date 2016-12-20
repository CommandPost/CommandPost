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
	if element then
		for i,child in ipairs(element) do
			if child:attributeValue(name) == value then
				return child
			end
		end
	end
	return nil
end

--- hs.finalcutpro.axutil.childWith(axuielement, string, anything) -> axuielement
--- Function:
--- This searches for the first child of the specified element for which the provided
--- function returns true. The function will receive one parameter - the current child.
---
--- Params:
--- * element	- the axuielement
--- * matcherFn	- the function which checks if the child matches the requirements.
--- Returns:
--- The first matching child, or nil if none was found
function axutils.childMatching(element, matcherFn)
	if element then
		for i,child in ipairs(element) do
			if matcherFn(child) then
				return child
			end
		end
	end
	return nil
end

--- hs.finalcutpro.axutil.isValid(axuielement) -> boolean
--- Function:
--- Checks if the axuilelement is still valid
---
--- Params:
--- * element	- the axuielement
--- * matcherFn	- the function which checks if the child matches the requirements.
--- Returns:
--- The first matching child, or nil if none was found
function axutils.isValid(element)
	return element ~= nil and element.role
end

--- hs.finalcutpro.axutil.isValid(axuielement) -> boolean
--- Function:
--- Checks if the axuilelement is still valid
---
--- Params:
--- * element	- the axuielement
--- * matcherFn	- the function which checks if the child matches the requirements.
--- Returns:
--- The first matching child, or nil if none was found
function axutils.isInvalid(element)
	return element == nil or element:attributeValue("AXRole") == nil
end

function axutils.find(cachedElement, finderFn)
	return axutils.isValid(cachedElement) and cachedElement or finderFn()
end

return axutils