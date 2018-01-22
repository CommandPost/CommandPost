--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.ui.axutils ===
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
function axutils.hasAttributeValue(element, name, value)
	return element and element:attributeValue(name) == value
end

--- cp.ui.axutils.childWith(element, name, value) -> axuielement
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
	return axutils.childMatching(element, function(child) return axutils.hasAttributeValue(child, name, value) end)
end

--- cp.ui.axutils.childWithID(element, value) -> axuielement
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

--- cp.ui.axutils.childWithRole(element, value) -> axuielement
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

--- cp.ui.axutils.childWithDescription(element, value) -> axuielement
--- Function
--- This searches for the first child of the specified element which has `AXDescription` with the specified value.
---
--- Parameters:
---  * element	- the axuielement
---  * value	- the value
---
--- Returns:
---  * The first matching child, or `nil` if none was found
function axutils.childWithDescription(element, value)
	return axutils.childWith(element, "AXDescription", value)
end

--- cp.ui.axutils.childMatching(element, matcherFn) -> axuielement
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

--- cp.ui.axutils.childAtIndex(element, index, compareFn) -> axuielement
--- Function
--- Searches for the child element which is at number `index` when sorted using the `compareFn`.
---
--- Parameters:
---  * element		- the axuielement or array of axuielements
---  * index		- the index number of the child to find.
---  * compareFn	- a function to compare the elements.
---
--- Returns:
---  * The child, or `nil` if the index is larger than the number of children.
function axutils.childAtIndex(element, index, compareFn)
	if element and index > 0 then
		local children = element
		-- Try to get the children array directly, if present, to optimise the loop.
		-- NOTE: There seems to be some weirdness with some elements coming from `axuielement` without the correct metatable.
		if element.attributeValue then -- it's an AXUIElement
			children = element:attributeValue("AXChildren") or element
		end
		if #children >= index then
			table.sort(children, compareFn)
			return children[index]
		end
	end
	return nil
end

--- cp.ui.axutils.compareLeftToRight(a, b) -> boolean
--- Function
--- Returns `true` if element `a` is left of element `b`. May be used with `table.sort`.
---
--- Parameters
--- * a	- The first element
--- * b	- The second element
---
--- Returns:
--- * `true` if `a` is left of `b`.
function axutils.compareLeftToRight(a, b)
	return a:frame().x < b:frame().x
end

--- cp.ui.axutils.compareRightToLeft(a, b) -> boolean
--- Function
--- Returns `true` if element `a` is right of element `b`. May be used with `table.sort`.
---
--- Parameters
--- * a	- The first element
--- * b	- The second element
---
--- Returns:
--- * `true` if `a` is right of `b`.
function axutils.compareRightToLeft(a, b)
	return a:frame().x > b:frame().x
end

--- cp.ui.axutils.compareTopToBottom(a, b) -> boolean
--- Function
--- Returns `true` if element `a` is above element `b`. May be used with `table.sort`.
---
--- Parameters
--- * a	- The first element
--- * b	- The second element
---
--- Returns:
--- * `true` if `a` is above `b`.
function axutils.compareTopToBottom(a, b)
	return a:frame().y < b:frame().y
end


--- cp.ui.axutils.compareBottomToTop(a, b) -> boolean
--- Function
--- Returns `true` if element `a` is below element `b`. May be used with `table.sort`.
---
--- Parameters
--- * a	- The first element
--- * b	- The second element
---
--- Returns:
--- * `true` if `a` is below `b`.
function axutils.compareBottomToTop(a, b)
	return a:frame().y > b:frame().y
end

--- cp.ui.axutils.childFromLeft(element, index) -> axuielement
--- Function
--- Searches for the child element which is at number `index` when sorted left-to-right.
---
--- Parameters:
---  * element		- the axuielement or array of axuielements
---  * index		- the index number of the child to find.
---
--- Returns:
---  * The child, or `nil` if the index is larger than the number of children.
function axutils.childFromLeft(element, index)
	return axutils.childAtIndex(element, index, axutils.compareLeftToRight)
end

--- cp.ui.axutils.childFromRight(element, index) -> axuielement
--- Function
--- Searches for the child element which is at number `index` when sorted right-to-left.
---
--- Parameters:
---  * element		- the axuielement or array of axuielements
---  * index		- the index number of the child to find.
---
--- Returns:
---  * The child, or `nil` if the index is larger than the number of children.
function axutils.childFromRight(element, index)
	return axutils.childAtIndex(element, index, axutils.compareRightToLeft)
end

--- cp.ui.axutils.childFromTop(element, index) -> axuielement
--- Function
--- Searches for the child element which is at number `index` when sorted top-to-bottom.
---
--- Parameters:
---  * element		- the axuielement or array of axuielements
---  * index		- the index number of the child to find.
---
--- Returns:
---  * The child, or `nil` if the index is larger than the number of children.
function axutils.childFromTop(element, index)
	return axutils.childAtIndex(element, index, axutils.compareTopToBottom)
end

--- cp.ui.axutils.childFromBottom(element, index) -> axuielement
--- Function
--- Searches for the child element which is at number `index` when sorted bottom-to-top.
---
--- Parameters:
---  * element		- the axuielement or array of axuielements
---  * index		- the index number of the child to find.
---
--- Returns:
---  * The child, or `nil` if the index is larger than the number of children.
function axutils.childFromBottom(element, index)
	return axutils.childAtIndex(element, index, axutils.compareBottomToTop)
end

--- cp.ui.axutils.childrenWith(element, name, value) -> axuielement
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
	return axutils.childrenMatching(element, function(child) return axutils.hasAttributeValue(child, name, value) end)
end

--- cp.ui.axutils.childrenWithRole(element, value) -> axuielement
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

--- cp.ui.axutils.childrenMatching(element, matcherFn) -> { axuielement }
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

--- cp.ui.axutils.isValid(element) -> boolean
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

--- cp.ui.axutils.cache(source, key, finderFn, [verifyFn]) -> axuielement
--- Function
--- Checks if the cached value at the `source[key]` is a valid axuielement. If not
--- it will call the provided `finderFn()` function (with no arguments), cache the result and return it.
---
--- If the optional `verifyFn` is provided, it will be called to check that the cached
--- value is still valid. It is passed a single parameter (the axuielement) and is expected
--- to return `true` or `false`.
---
--- Parameters:
---  * source		- the table containing the cache
---  * key			- the key the value is cached under
---  * finderFn		- the function which will return the element if not found.
---  * [verifyFn]	- an optional function which will check the cached element to verify it is still valid.
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