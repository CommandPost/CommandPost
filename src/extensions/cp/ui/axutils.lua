--- === cp.ui.axutils ===
---
--- Utility functions to support `hs._asm.axuielement`.

local require = require

local canvas					= require("hs.canvas")
local fnutils					= require("hs.fnutils")
local prop            = require("cp.prop")
local is              = require("cp.is")

local sort            = table.sort

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local axutils = {}

--- cp.ui.axutils.valueOf(element, name[, default]) -> anything
--- Function
--- Returns the named `AX` attribute value, or the `default` if it is empty.
---
--- Parameters:
--- * element - the `axuielement` to retrieve the attribute value for.
--- * attribute - The attribute name (e.g. "AXValue")
--- * default - (optional) if provided, this will be returned if the attribute is `nil`.
---
--- Returns:
--- * The attribute value, or the `default` if none is found.
function axutils.valueOf(element, attribute, default)
    if axutils.isValid(element) then
        return element:attributeValue(attribute) or default
    end
end

--- cp.ui.axutils.childrenInColumn(element, role, startIndex) -> table | nil
--- Function
--- Finds the children for an element, then checks to see if they match the supplied
--- role. It then compares the vertical position data of all matching children
--- and returns a table with only the elements that line up to the element defined
--- by the startIndex.
---
--- Parameters:
---  * element     - The element to retrieve the children from.
---  * role        - The required role as a string.
---  * startIndex  - A number which defines the index of the first element to use.
---
--- Returns:
---  * The table of `axuielement` objects, otherwise `nil`.
function axutils.childrenInColumn(element, role, startIndex, childIndex)
    local children = axutils.childrenWith(element, "AXRole", role)
    if children and #children >= 2 then
        local baseElement = children[startIndex]
        if baseElement then
            local frame = baseElement:attributeValue("AXFrame")
            if frame then
                local result = {}
                for i=startIndex, #children do
                    local child = children[i]
                    local f = child and child:attributeValue("AXFrame")
                    if child and f.x >= frame.x and f.x <= frame.x + frame.w then
                        table.insert(result, child)
                    end
                end
                if next(result) ~= nil then
                    if childIndex then
                        if result[childIndex] then
                            return result[childIndex]
                        end
                    else
                        return result
                    end
                end
            end
        end
    end
end

--- cp.ui.axutils.childInColumn(element, role, startIndex, childIndex) -> table | nil
--- Function
--- Finds the children for an element, then checks to see if they match the supplied
--- role. It then compares the vertical position data of all matching children
--- and returns an element defined by the `childIndex`, which lines up vertially
--- with the element defined by the `startIndex`.
---
--- Parameters:
---  * element     - The element to retrieve the children from.
---  * role        - The required role as a string.
---  * startIndex  - A number which defines the index of the first element to use.
---  * childIndex  - A number which defines the index of the element to return.
---
--- Returns:
---  * The `axuielement` if it matches, otherwise `nil`.
function axutils.childInColumn(element, role, startIndex, childIndex)
    return axutils.childrenInColumn(element, role, startIndex, childIndex)
end

--- cp.ui.axutils.children(element) -> table | nil
--- Function
--- Finds the children for the element. If it is an `hs._asm.axuielement`, it will
--- attempt to get the `AXChildren` attribute. If it is a table with a `children` function,
--- that will get called. Otherwise, the element is returned.
---
--- Parameters:
---  * element   - The element to retrieve the children of.
---
--- Returns:
---  * the children table, or `nil`.
function axutils.children(element)
    local children = element
    --------------------------------------------------------------------------------
    -- Try to get the children array directly, if present, to optimise the loop.
    --
    -- NOTE: There seems to be some weirdness with some elements coming from
    --       `axuielement` without the correct metatable.
    --------------------------------------------------------------------------------
    if element and element.attributeValue then
        --------------------------------------------------------------------------------
        -- It's an AXUIElement:
        --------------------------------------------------------------------------------
        children = element:attributeValue("AXChildren") or element
    elseif element and is.callable(element.children) then
        children = element:children()
    end
    return children
end

local function isBelow(a)
    return function(b)
        if b == nil then
            return false
        elseif a == nil then
            return true
        else
            local aFrame, bFrame = a:frame(), b:frame()
            return aFrame.y + aFrame.h < bFrame.y
        end
    end
end

local function isAbove(a)
    return function(b)
        if b == nil then
            return false
        elseif a == nil then
            return true
        else
            local aFrame, bFrame = a:frame(), b:frame()
            return aFrame.y < bFrame.y + bFrame.h
        end
    end
end

--- cp.ui.axutils.childrenBelow(element, topElement) -> table of axuielement or nil
--- Function
--- Finds the list of `axuielement` children from the `element` which are below the specified `topElement`.
--- If the `element` is `nil`, `nil` is returned. If the `topElement` is `nil` all children are returned.
---
--- Parameters:
--- * element - The `axuielement` to find the children of.
--- * topElement - The `axuielement` that the other children must be below.
---
--- Returns:
--- * The table of `axuielements` that are below, or `nil` if the element is not available.
function axutils.childrenBelow(element, topElement)
    return element and axutils.childrenMatching(element, isBelow(topElement))
end

--- cp.ui.axutils.childrenAbove(element, bottomElement) -> table of axuielement or nil
--- Function
--- Finds the list of `axuielement` children from the `element` which are above the specified `bottomElement`.
--- If the `element` is `nil`, `nil` is returned. If the `topElement` is `nil` all children are returned.
---
--- Parameters:
--- * element - The `axuielement` to find the children of.
--- * topElement - The `axuielement` that the other children must be above.
---
--- Returns:
--- * The table of `axuielements` that are above, or `nil` if the element is not available.
function axutils.childrenAbove(element, topElement)
    return element and axutils.childrenMatching(element, isAbove(topElement))
end

--- cp.ui.axutils.hasAttributeValue(element, name, value) -> boolean
--- Function
--- Checks to see if an element has a specific value.
---
--- Parameters:
---  * element	- the `axuielement`
---  * name		- the name of the attribute
---  * value	- the value of the attribute
---
--- Returns:
---  * `true` if the `element` has the supplied attribute value, otherwise `false`.
function axutils.hasAttributeValue(element, name, value)
    return element and element:attributeValue(name) == value
end

--- cp.ui.axutils.withAttributeValue(element, name, value) -> hs._asm.axuielement | nil
--- Function
--- Checks if the element has an attribute value with the specified `name` and `value`.
--- If so, the element is returned, otherwise `nil`.
---
--- Parameters:
---  * element       - The element to check
---  * name          - The name of the attribute to check
---  * value         - The value of the attribute
---
--- Returns:
---  * The `axuielement` if it matches, otherwise `nil`.
function axutils.withAttributeValue(element, name, value)
    return axutils.hasAttributeValue(element, name, value) and element or nil
end

--- cp.ui.axutils.withRole(element, role) -> hs._asm.axuielement | nil
--- Function
--- Checks if the element has an "AXRole" attribute with the specified `role`.
--- If so, the element is returned, otherwise `nil`.
---
--- Parameters:
---  * element       - The element to check
---  * role          - The required role
---
--- Returns:
---  * The `axuielement` if it matches, otherwise `nil`.
function axutils.withRole(element, role)
    return axutils.withAttributeValue(element, "AXRole", role)
end

--- cp.ui.axutils.withValue(element, value) -> hs._asm.axuielement | nil
--- Function
--- Checks if the element has an "AXValue" attribute with the specified `value`.
--- If so, the element is returned, otherwise `nil`.
---
--- Parameters:
---  * element       - The element to check
---  * value         - The required value
---
--- Returns:
---  * The `axuielement` if it matches, otherwise `nil`.
function axutils.withValue(element, value)
    return axutils.withAttributeValue(element, "AXValue", value)
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

--- cp.ui.axutils.childMatching(element, matcherFn[, index]) -> axuielement
--- Function
--- This searches for the first child of the specified element for which the provided function returns `true`.
--- The function will receive one parameter - the current child.
---
--- Parameters:
---  * element		- the axuielement
---  * matcherFn	- the function which checks if the child matches the requirements.
---  * index		- the number of matching child to return. Defaults to `1`.
---
--- Returns:
---  * The first matching child, or nil if none was found
function axutils.childMatching(element, matcherFn, index)
    index = index or 1
    if element then
        local children = axutils.children(element)
        if children and #children > 0 then
            local count = 0
            for _,child in ipairs(children) do
                if matcherFn(child) then
                    count = count + 1
                    if count == index then
                        return child
                    end
                end
            end
        end
    end
    return nil
end

--- cp.ui.axutils.childAtIndex(element, index, compareFn[, matcherFn]) -> axuielement
--- Function
--- Searches for the child element which is at number `index` when sorted using the `compareFn`.
---
--- Parameters:
---  * element		- the axuielement or array of axuielements
---  * index		- the index number of the child to find.
---  * compareFn	- a function to compare the elements.
---  * matcherFn    - an optional function which is passed each child and returns `true` if the child should be processed.
---
--- Returns:
---  * The child, or `nil` if the index is larger than the number of children.
function axutils.childAtIndex(element, index, compareFn, matcherFn)
    if element and index > 0 then
        local children = axutils.children(element)
        if children then
            if matcherFn then
                children = axutils.childrenMatching(children, matcherFn)
            end
            if #children >= index then
                sort(children, compareFn)
                return children[index]
            end
        end
    end
    return nil
end

--- cp.ui.axutils.compareLeftToRight(a, b) -> boolean
--- Function
--- Returns `true` if element `a` is left of element `b`. May be used with `table.sort`.
---
--- Parameters
---  * a	- The first element
---  * b	- The second element
---
--- Returns:
---  * `true` if `a` is left of `b`.
function axutils.compareLeftToRight(a, b)
    local aFrame, bFrame = a:attributeValue("AXFrame"), b:attributeValue("AXFrame")
    return aFrame and bFrame and aFrame.x < bFrame.x or false
end

--- cp.ui.axutils.compareRightToLeft(a, b) -> boolean
--- Function
--- Returns `true` if element `a` is right of element `b`. May be used with `table.sort`.
---
--- Parameters
---  * a	- The first element
---  * b	- The second element
---
--- Returns:
---  * `true` if `a` is right of `b`.
function axutils.compareRightToLeft(a, b)
    local aFrame, bFrame = a:attributeValue("AXFrame"), b:attributeValue("AXFrame")
    return aFrame and bFrame and aFrame.x + aFrame.w > bFrame.x + bFrame.w or false
end

--- cp.ui.axutils.compareTopToBottom(a, b) -> boolean
--- Function
--- Returns `true` if element `a` is above element `b`. May be used with `table.sort`.
---
--- Parameters
---  * a	- The first element
---  * b	- The second element
---
--- Returns:
---  * `true` if `a` is above `b`.
function axutils.compareTopToBottom(a, b)
    local aFrame, bFrame = a:attributeValue("AXFrame"), b:attributeValue("AXFrame")
    return aFrame and bFrame and aFrame.y < bFrame.y or false
end

--- cp.ui.axutils.compareBottomToTop(a, b) -> boolean
--- Function
--- Returns `true` if element `a` is below element `b`. May be used with `table.sort`.
---
--- Parameters
---  * a	- The first element
---  * b	- The second element
---
--- Returns:
---  * `true` if `a` is below `b`.
function axutils.compareBottomToTop(a, b)
    local aFrame, bFrame = a:attributeValue("AXFrame"), b:attributeValue("AXFrame")
    return aFrame and bFrame and aFrame.y + aFrame.h > bFrame.y + bFrame.h or false
end

--- cp.ui.axutils.childFromLeft(element, index[, matcherFn]) -> axuielement
--- Function
--- Searches for the child element which is at number `index` when sorted left-to-right.
---
--- Parameters:
---  * element		- the axuielement or array of axuielements
---  * index		- the index number of the child to find.
---  * matcherFn    - an optional function which is passed each child and returns `true` if the child should be processed.
---
--- Returns:
---  * The child, or `nil` if the index is larger than the number of children.
function axutils.childFromLeft(element, index, matcherFn)
    return axutils.childAtIndex(element, index, axutils.compareLeftToRight, matcherFn)
end

--- cp.ui.axutils.childFromRight(element, index[, matcherFn]) -> axuielement
--- Function
--- Searches for the child element which is at number `index` when sorted right-to-left.
---
--- Parameters:
---  * element		- the axuielement or array of axuielements
---  * index		- the index number of the child to find.
---  * matcherFn    - an optional function which is passed each child and returns `true` if the child should be processed.
---
--- Returns:
---  * The child, or `nil` if the index is larger than the number of children.
function axutils.childFromRight(element, index, matcherFn)
    return axutils.childAtIndex(element, index, axutils.compareRightToLeft, matcherFn)
end

--- cp.ui.axutils.childFromTop(element, index[, matcherFn]) -> axuielement
--- Function
--- Searches for the child element which is at number `index` when sorted top-to-bottom.
---
--- Parameters:
---  * element		- the axuielement or array of axuielements
---  * index		- the index number of the child to find.
---  * matcherFn    - an optional function which is passed each child and returns `true` if the child should be processed.
---
--- Returns:
---  * The child, or `nil` if the index is larger than the number of children.
function axutils.childFromTop(element, index, matcherFn)
    return axutils.childAtIndex(element, index, axutils.compareTopToBottom, matcherFn)
end

--- cp.ui.axutils.childFromBottom(element, index) -> axuielement
--- Function
--- Searches for the child element which is at number `index` when sorted bottom-to-top.
---
--- Parameters:
---  * element		- the axuielement or array of axuielements
---  * index		- the index number of the child to find.
---  * matcherFn    - an optional function which is passed each child and returns `true` if the child should be processed.
---
--- Returns:
---  * The child, or `nil` if the index is larger than the number of children.
function axutils.childFromBottom(element, index, matcherFn)
    return axutils.childAtIndex(element, index, axutils.compareBottomToTop, matcherFn)
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
--- function returns `true`. The function will receive one parameter - the current child.
---
--- Parameters:
---  * element	- the axuielement
---  * matcherFn	- the function which checks if the child matches the requirements.
---
--- Returns:
---  * All matching children, or `nil` if none was found
function axutils.childrenMatching(element, matcherFn)
    if element then
        return fnutils.ifilter(axutils.children(element), matcherFn)
    end
    return nil
end

--- cp.ui.axutils.hasChild(element, matcherFn) -> boolean
--- Function
--- Checks if the axuielement has a child that passes the `matcherFn`.
---
--- Parameters:
--- * element - the `axuielement` to check.
--- * matcherFn - the `function` that accepts an `axuielement` and returns a `boolean`
---
--- Returns:
--- * `true` if any child matches, otherwise `false`.
function axutils.hasChild(element, matcherFn)
    return axutils.childMatching(element, matcherFn) ~= nil
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
    if element ~= nil and type(element) ~= "userdata" then
        error(string.format("The element must be \"userdata\" but was %q.", type(element)))
    end
    return element ~= nil and element:isValid()
end

-- isInvalid(value[, verifyFn]) -> boolean
-- Function
-- Checks to see if an `axuielement` is invalid.
--
-- Parameters:
--  * value     - an `axuielement` object.
--  * verifyFn  - an optional function which will check the cached element to verify it is still valid.
--
-- Returns:
--  * `true` if the `value` is invalid or not verified, otherwise `false`.
local function isInvalid(value, verifyFn)
    return value == nil or not axutils.isValid(value) or verifyFn and not verifyFn(value)
end

--- cp.ui.axutils.cache(source, key, finderFn[, verifyFn]) -> axuielement
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
    local value
    if source then
        value = source[key]
    end

    if value == nil or isInvalid(value, verifyFn) then
        value = finderFn()
        if isInvalid(value, verifyFn) then
            value = nil
        end
    end

    if source then
        source[key] = value
    end

    return value
end

--- cp.ui.axutils.snapshot(element[, filename]) -> hs.image
--- Function
--- Takes a snapshot of the specified `axuielement` and returns it.
--- If the `filename` is provided it also saves the file to the specified location.
---
--- Parameters:
---  * element		- The `axuielement` to snap.
---  * filename		- (optional) The path to save the image as a PNG file.
---
--- Returns:
---  * An `hs.image` file, or `nil` if the element could not be snapped.
function axutils.snapshot(element, filename)
    if axutils.isValid(element) then
        local window = element:attributeValue("AXWindow")
        if window then
            local hsWindow = window:asHSWindow()
            local windowSnap = hsWindow:snapshot()
            local windowFrame = window:frame()
            local shotSize = windowSnap:size()

            local ratio = shotSize.h/windowFrame.h
            local elementFrame = element:frame()

            local imageFrame = {
                x = (windowFrame.x-elementFrame.x)*ratio,
                y = (windowFrame.y-elementFrame.y)*ratio,
                w = shotSize.w,
                h = shotSize.h,
            }

            local c = canvas.new({w=elementFrame.w*ratio, h=elementFrame.h*ratio})
            c[1] = {
                type = "image",
                image = windowSnap,
                imageScaling = "none",
                imageAlignment = "topLeft",
                frame = imageFrame,
            }

            local elementSnap = c:imageFromCanvas()

            if filename then
                elementSnap:saveToFile(filename)
            end

            return elementSnap
        end
    end
    return nil
end

--- cp.ui.axutils.prop(uiFinder, attributeName[, settable]) -> cp.prop
--- Function
--- Creates a new `cp.prop` which will find the `hs._asm.axuielement` via the `uiFinder` and
--- get/set the value (if settable is `true`).
---
--- Parameters:
---  * uiFinder      - the `cp.prop` or `function` which will retrieve the current `hs._asm.axuielement`.
---  * attributeName - the `AX` atrribute name the property links to.
---  * settable      - Defaults to `false`. If `true`, the property will also be settable.
---
--- Returns:
---  * The `cp.prop` for the attribute.
---
--- Notes:
---  * If the `uiFinder` is a `cp.prop`, it will be monitored for changes, making the resulting `prop` "live".
function axutils.prop(uiFinder, attributeName, settable)
    if prop.is(uiFinder) then
        return uiFinder:mutate(function(original)
            local ui = original()
            return ui and ui:attributeValue(attributeName)
        end,
        settable and function(newValue, original)
            local ui = original()
            return ui and ui:setAttributeValue(attributeName, newValue)
        end
    )
    end
end

axutils.match = {}

--- cp.ui.axutils.match.role(roleName) -> function
--- Function
--- Returns a `match` function that will return true if the `axuielement` has the specified `AXRole`.
---
--- Parameters:
---  * roleName  - The role to check for.
---
--- Returns:
---  * `function(element) -> boolean` that checks the `AXRole` is `roleName`
function axutils.match.role(roleName)
    return function(element)
        return axutils.hasAttributeValue(element, "AXRole", roleName)
    end
end

return axutils
