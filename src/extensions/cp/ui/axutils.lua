--- === cp.ui.axutils ===
---
--- Utility functions to support `hs._asm.axuielement`.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log						= require("hs.logger").new("axutils")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local canvas					= require("hs.canvas")
local fnutils					= require("hs.fnutils")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local sort                      = table.sort

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local axutils = {}

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
    if element.attributeValue then
        --------------------------------------------------------------------------------
        -- It's an AXUIElement:
        --------------------------------------------------------------------------------
        children = element:attributeValue("AXChildren") or element
    elseif type(element.children) == "function" then
        children = element:children()
    end
    return children
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
        if #children > 0 then
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
    return element ~= nil and element:isValid()
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
    local value = source and source[key]
    if value == nil or not axutils.isValid(value) or verifyFn and not verifyFn(value) then
        value = finderFn()
        if axutils.isValid(value) and source then
            source[key] = value
        else
            return nil
        end
    end
    return value
end

--- cp.ui.axutils.snapshot(element, [filename]) -> hs.image
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

return axutils
