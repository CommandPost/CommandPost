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

--- hs.finalcutpro.axutil.cached(table, string, function) -> axuielement
--- Function:
--- Checks if the cached value at the `source[key]` is a valid axuielement. If not
--- it will call the provided function, cache the result and return it.
---
--- Params:
--- * source	- the table containing the cache
--- * key		- the key the value is cached under
--- * finderFn	- the function which will return the element if not found.
--- Returns:
--- The valid cached value.
function axutils.cache(source, key, finderFn)
	local value = source[key]
	if not axutils.isValid(value) then
		value = finderFn()
		if axutils.isValid(value) then
			source[key] = value
		else
			return nil
		end
	end
	return value
end

return axutils