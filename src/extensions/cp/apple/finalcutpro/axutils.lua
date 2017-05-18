--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.axutils ===
---
--- Utility functions to support `hs._asm.axuielement`

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

local fnutils					= require("hs.fnutils")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------

local axutils = {}

-- TODO: Add documentation
function axutils.hasAttribute(element, name, value)
	return element and element:attributeValue(name) == value
end

--- cp.apple.finalcutpro.axutils.childWith(element, name, value) -> axuielement
--- Function
--- This searches for the first child of the specified element which has an attribute with the matching name and value.
---
--- Parameters:
---  * element	- the axuielement
---  * name		- the name of the attribute
---  * value	- the value of the attribute
---
--- Returns:
---  * The first matching child, or nil if none was found
function axutils.childWith(element, name, value)
	return axutils.childMatching(element, function(child) return axutils.hasAttribute(child, name, value) end)
end

--- cp.apple.finalcutpro.axutils.childWithID(element, value) -> axuielement
--- Function
--- This searches for the first child of the specified element which has `AXIdentifier` with the specified value.
---
--- Parameters:
---  * element	- the axuielement
---  * value	- the value
---
--- Returns:
---  * The first matching child, or `nil` if none was found
function axutils.childWithID(element, value)
	return axutils.childWith(element, "AXIdentifier", value)
end

--- cp.apple.finalcutpro.axutils.childWithRole(element, value) -> axuielement
--- Function
--- This searches for the first child of the specified element which has `AXRole` with the specified value.
---
--- Parameters:
---  * element	- the axuielement
---  * value	- the value
---
--- Returns:
---  * The first matching child, or `nil` if none was found
function axutils.childWithRole(element, value)
	return axutils.childWith(element, "AXRole", value)
end

--- cp.apple.finalcutpro.axutils.childMatching(element, matcherFn) -> axuielement
--- Function
--- This searches for the first child of the specified element for which the provided function returns `true`.
--- The function will receive one parameter - the current child.
---
--- Parameters:
---  * element		- the axuielement
---  * matcherFn	- the function which checks if the child matches the requirements.
---
--- Returns:
---  * The first matching child, or nil if none was found
function axutils.childMatching(element, matcherFn)
	if element then
		local children = element
		-- Try to get the children array directly, if present, to optimise the loop.
		-- NOTE: There seems to be some weirdness with some elements coming from `axuielement` without the correct metatable.
		if element.attributeValue then -- it's an AXUIElement
			children = element:attributeValue("AXChildren") or element
		end
		if #children > 0 then
			for i,child in ipairs(children) do
				if matcherFn(child) then
					return child
				end
			end
		end
	end
	return nil
end

--- cp.apple.finalcutpro.axutils.childrenWith(element, name, value) -> axuielement
--- Function
--- This searches for all children of the specified element which has an attribute with the matching name and value.
---
--- Parameters:
---  * element	- the axuielement
---  * name		- the name of the attribute
---  * value	- the value of the attribute
---
--- Returns:
---  * All matching children, or `nil` if none was found
function axutils.childrenWith(element, name, value)
	return axutils.childrenMatching(element, function(child) return axutils.hasAttribute(child, name, value) end)
end

--- cp.apple.finalcutpro.axutils.childrenWithRole(element, value) -> axuielement
--- Function
--- This searches for all children of the specified element which has an `AXRole` attribute with the matching value.
---
--- Parameters:
---  * element	- the axuielement
---  * value	- the value of the attribute
---
--- Returns:
---  * All matching children, or `nil` if none was found
function axutils.childrenWithRole(element, value)
	return axutils.childrenWith(element, "AXRole", value)
end

--- cp.apple.finalcutpro.axutils.childrenMatching(element, matcherFn) -> { axuielement }
--- Function
--- This searches for all children of the specified element for which the provided
--- function returns true. The function will receive one parameter - the current child.
---
--- Parameters:
---  * element	- the axuielement
---  * matcherFn	- the function which checks if the child matches the requirements.
---
--- Returns:
---  * All matching children, or `nil` if none was found
function axutils.childrenMatching(element, matcherFn)
	if element then
		return fnutils.ifilter(element, matcherFn)
	end
	return nil
end

--- cp.apple.finalcutpro.axutils.isValid(element) -> boolean
--- Function
--- Checks if the axuilelement is still valid - that is, still active in the UI.
---
--- Parameters:
---  * element	- the axuielement
---
--- Returns:
---  * `true` if the element is valid.
function axutils.isValid(element)
	return element ~= nil and element.role
end

--- cp.apple.finalcutpro.axutils.cache(source, key, finderFn, verifyFn) -> axuielement
--- Function
--- Checks if the cached value at the `source[key]` is a valid axuielement. If not
--- it will call the provided `finderFn()` function (with no arguments), cache the result and return it.
---
--- If the optional `verifyFn` is provided, it will be called to check that the cached
--- value is still valid. It is passed a single parameter (the axuielement) and is expected
--- to return `true` or `false`.
---
--- Parameters:
---  * source	- the table containing the cache
---  * key		- the key the value is cached under
---  * finderFn	- the function which will return the element if not found.
---  * verifyFn	- (optional) a function which will check the cached element to verify it is still valid.
---
--- Returns:
---  * The valid cached value.
function axutils.cache(source, key, finderFn, verifyFn)
	local value = source[key]
	if not axutils.isValid(value) or verifyFn and not verifyFn(value) then
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