--- === cp.fn.ax ===
---
--- A collection of useful functions for working with AX.
---
--- You may also find functions in [cp.fn](cp.fn.md) and [cp.fn.table](cp.fn.table.md) useful.

local require               = require

-- local log                   = require "hs.logger" .new "fnax"

local is                            = require "cp.is"
local fn                            = require "cp.fn"
local prop                          = require "cp.prop"

local isCallable                    = is.callable
local isUserdata                    = is.userdata
local isTable                       = is.table
local isTruthy                      = is.truthy
local constant                      = fn.constant
local chain, pipe                   = fn.chain, fn.pipe
local get, ifilter, map, sort       = fn.table.get, fn.table.ifilter, fn.table.map, fn.table.sort
local imap                          = fn.table.imap

local pack, unpack                  = table.pack, table.unpack

local mod = {}

--- cp.fn.ax.isUIElement(value) -> boolean
--- Function
--- Checks to see if the `value` is an `axuielement`
---
--- Parameters:
--- * value - The value to check
---
--- Returns:
--- * `true` if the value is an `axuielement`
local function isUIElement(value)
    return isUserdata(value) and isCallable(value.attributeValue)
end

--- fn.ax.uielement(uivalue) -> axuielement | nil
--- Function
--- Returns the axuielement for the given `uivalue`.
---
--- Parameters:
---  * uivalue - The value to get the `axuielement` from.
---
--- Returns:
---  * The `axuielement` for the given `value` or `nil`.
---
--- Notes:
---   * If the `value` is an `axuielement`, it is returned.
---   * If the `value` is a table with a callable `UI` field, the `UI` field is called and the result is returned.
---   * If the `value` is callable, it is called and the result is returned.
---   * Otherwise, `nil` is returned.
local function uielement(uivalue)
    -- first, check if it's an element with a UI field
    if isTable(uivalue) and isCallable(uivalue.UI) then
        uivalue = uivalue:UI()
    end
    -- then, check if it's a callable
    if isCallable(uivalue) then
        uivalue = uivalue()
    end
    -- finally, check if it's an axuielement
    return isUIElement(uivalue) and uivalue or nil
end

--- fn.ax.uielementList(value) -> table of axuielement | nil
--- Function
--- Returns the `axuielement` list for the given `value`, if available.
---
--- Parameters:
---  * value - The value to get the `axuielement` list from.
---
--- Returns:
---  * The `axuielement` list for the given `value` or `nil`.
---
--- Notes:
---   * If the `value` is a `table` with a `UI` field, the `UI` field is called and the result is returned if it is a list.
---   * If the `value` is callable (i.e. a `function`), it is called and the result is returned if it is a list.
---   * If the `value` is a `table`, it is returned.
---   * Otherwise, `nil` is returned.
local function uielementList(value)
    -- first, check if it's an element with a UI field
    if isTable(value) and isCallable(value.UI) then
        value = value:UI()
    end
    -- then, check if it's a callable
    if isCallable(value) then
        value = value()
    end
    -- finally, check if it's a list
    if isTable(value) then
        return value
    end
    return nil
end

mod.isUIElement = isUIElement
mod.uielement = uielement
mod.uielementList = uielementList

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
    return value == nil or not mod.isValid(value) or verifyFn and not verifyFn(value)
end

--- cp.fn.ax.attribute(name) -> function(uivalue) -> any | nil
--- Function
--- Returns a function which will return the `AX` value of the given `name` from the given `value`.
---
--- Parameters:
---  * name - The name of the attribute to get. Eg. `"AXValue"`.
---
--- Returns:
---  * A function which will return the `AX` value of the given `name` from the given `uivalue`.
---  * This is safe to use as a [cp.prop:mutate](cp.prop.md#mutate) getter, since it will resolve the `original` value before getting the named attribute.
function mod.attribute(name)
    return function(uivalue)
        local element = uielement(uivalue)
        if element then
            return element:attributeValue(name)
        end
    end
end

--- cp.fn.ax.setAttribute(name) -> function(newValue, uivalue) -> nil
--- Function
--- Returns a function which will set the `AX` value of `uivalue` (if present) the given `name` from the given `value`.
--- If the `uivalue` is not present, it will not attempt to set the new value.
---
--- Parameters:
---  * name - The name of the attribute to set. Eg. `"AXValue"`.
---
--- Returns:
---  * A function which will set the `AX` value of the given `name` from the given `uivalue`.
---  * The `newValue` will be passed to the `setAttributeValue` method of the `uivalue`.
---  * The `uivalue` will attempt to be resolved via [uielement](#uielement).
---  * This is safe to use as a [cp.prop:mutate](cp.prop.md#mutate) setter, since it will take the `newValue` and `uivalue` in the correct order and resolve the `uivalue`.
function mod.setAttribute(name)
    return function(newValue, uivalue)
        local ui = uielement(uivalue)
        if ui then
            ui:setAttributeValue(name, newValue)
        end
    end
end

--- cp.fn.ax.cache(source, key[, verifyFn]) -> function(finderFn) -> function(...) -> axuielement
--- Function
--- A combinator which checks if the cached value at the `source[key]` is a valid axuielement. If not
--- it will call the provided `finderFn()` function (with no arguments), cache the result and return it.
---
--- If the optional `verifyFn` is provided, it will be called to check that the cached
--- value is still valid. It is passed a single parameter (the axuielement) and is expected
--- to return `true` or `false`.
---
--- Parameters:
---  * source       - the table containing the cache
---  * key          - the key the value is cached under
---  * finderFn     - the function which will return the element if not found.
---  * [verifyFn]   - an optional function which will check the cached element to verify it is still valid.
---
--- Returns:
---  * The valid cached value.
---
--- Notes:
---  * If the `verifyFn` is provided, it will be called to check that the cached
---    value is still valid. It is passed a single parameter (the axuielement) and is expected
---    to return `true` or `false`.
---  * Example:
---    ```lua
---    ax.cache(self, "_ui", MyElement.matches)(
---        fn.table.get(1) -- return the first child of the element.
---    )
function mod.cache(source, key, verifyFn)
    return function(finderFn)
        return function(...)
            local value
            if source then
                value = source[key]
            end

            if value == nil or isInvalid(value, verifyFn) then
                value = finderFn(...)
                if isInvalid(value, verifyFn) then
                    value = nil
                end
            end

            if source then
                source[key] = value
            end

            return value
        end
    end
end

--- cp.fn.ax.areAligned(a, b) -> boolean
--- Function
--- Returns `true` if element `a` is aligned with element `b`.
---
--- Parameters:
---  * a - The first element
---  * b - The second element
---
--- Returns:
---  * `true` if `a` is aligned with `b`.
---
--- Notes:
---  * Two elements are considered to be aligned if the interesection if their heights are at least 50% of the height of both elements.
function mod.areAligned(a, b)
    local aFrame, bFrame = a:attributeValue("AXFrame"), b:attributeValue("AXFrame")
    if aFrame ~= nil and bFrame ~= nil then
        local aY, bY = aFrame.y, bFrame.y
        local aHeight, bHeight = aFrame.h, bFrame.h
        local aBottom, bBottom = aY + aHeight, bY + bHeight
        local abIntersection = math.max(0, math.min(aBottom, bBottom) - math.max(aY, bY))
        local aPercentage = abIntersection / aHeight
        local bPercentage = abIntersection / bHeight
        return aPercentage >= 0.5 and bPercentage >= 0.5
    end
    return false
end

--- cp.fn.ax.children(value) -> table | nil
--- Function
--- Returns the children of the given `value`.
---
--- Parameters:
---  * value - The value to get the children from.
---
--- Returns:
---  * The children of the given `value` or `nil`.
---
--- Notes:
---   * If it is a `table` with a `AXChildren` field, the `AXChildren` field is returned.
---   * If it is a `table` with a `UI` field, the `UI` field is called and the result is returned.
---   * If it is a `table` with a `children` function, it is called and the result is returned.
---   * If it is a `table` with a `children` field, the `children` field is returned.
---   * Otherwise, if it's any `table`, that table is returned.
mod.children = fn.any(
    -- if it is a uielement that has `AXChildren` then use that
    chain // uielement >> get "AXChildren",
    -- if it's a resolvable uielementList, then use that
    uielementList,
    -- if it has a `children` method then call that
    fn.table.call "children",
    -- if it has a `children` field that is a table then return that
    chain // get "children" >> fn.value.filter(is.table)
)

--- cp.fn.ax.childrenMatching(predicate[, comparator]) -> table of axuielement | nil
--- Function
--- Returns the children of the given `uivalue` that match the given `predicate`.
---
--- Parameters:
---  * predicate - The predicate to match.
---  * comparator - An optional comparator to use. Defaults to [topDown](#topDown).
---
--- Returns:
---  * A table of `axuielement`s that match the given `predicate`.
function mod.childrenMatching(predicate, comparator)
    comparator = comparator or mod.topDown
    return chain // mod.children >> ifilter(predicate) >> sort(comparator)
end

--- cp.fn.ax.childMatching(predicate[, index][, comparator]) -> function(uivalue) -> axuielement | nil
--- Function
--- Returns a function that will return the first child of the given `uivalue` that matches the given `predicate`.
---
--- Parameters:
---  * predicate - A function that will be called with the child `axuielement` and should return `true` if the child matches.
---  * index - An optional number that will be used to determine the child to return. Defaults to `1`.
---  * comparator - An optional function that will be called with the child `axuielement` and should return `true` if the child matches. Defaults to [`cp.fn.ax.topDown`](cp.fn.ax.md#topDown).
---
--- Returns:
---  * A function that will return the first child of the given `uivalue` that matches the given `predicate`.
function mod.childMatching(predicate, index, comparator)
    -- shift the comparator over if necessary
    if is.callable(index) then
        comparator, index = index, nil
    end
    index = index or 1
    comparator = comparator or mod.topDown

    return chain // mod.children >> ifilter(predicate) >> sort(comparator) >> get(index)
end

--- cp.fn.ax.childWith(attribute, value) -> function(uivalue) -> axuielement | nil
--- Function
--- Returns a function that will return the first child of the given `uivalue` that has the given `attribute` set to `value`.
---
--- Parameters:
---  * attribute - The attribute to check.
---  * value - The value to check.
---
--- Returns:
---  * A function that will return the first child of the given `uivalue` that has the given `attribute` set to `value`.
mod.childWith = pipe(mod.hasAttributeValue, mod.childMatching)

--- cp.fn.ax.performAction(action) -> function(uivalue) -> axuielement | false | nil, errString
--- Function
--- Performs the given `action` on the given `uivalue`.
---
--- Parameters:
---  * action - The action to perform (e.g. "AXPress")
---
--- Returns:
---  * A function that accepts an `axuielement` [uivalue](#uielement) which in turn returns the result of performing the action.
function mod.performAction(action)
    return function(uivalue)
        local element = uielement(uivalue)
        if element then
            return element:performAction(action)
        end
        return nil, "No axuielement to perform action on"
    end
end

--- cp.fn.ax.hasAttributeValue(attribute, value) -> function(uivalue) -> boolean
--- Function
--- Returns a function that returns `true` if the given `uivalue` has the given `attribute` set to the `value`.
---
--- Parameters:
---  * attribute - The attribute to check for.
---  * value - The value to check for.
---
--- Returns:
---  * A function that accepts an `axuielement` [uivalue](#uielement) which in turn returns `true` if the `uivalue` has the given `attribute` set to the `value`.
function mod.hasAttributeValue(attribute, value)
    return function(uivalue)
        local element = uielement(uivalue)
        if element then
            return element:attributeValue(attribute) == value
        end
        return false
    end
end

--- cp.fn.ax.hasRole(role) -> function(uivalue) -> boolean
--- Function
--- Returns a function that returns `true` if the given `uivalue` has the given `AXRole`.
---
--- Parameters:
---  * role - The role to check for.
---
--- Returns:
---  * A function that accepts an `axuielement` [uivalue](#uielement) which in turn returns `true` if the `uivalue` has the given `AXRole`.
mod.hasRole = fn.with("AXRole", mod.hasAttributeValue)

--- cp.fn.ax.isValid(element) -> boolean
--- Function
--- Checks if the axuilelement is still valid - that is, still active in the UI.
---
--- Parameters:
---  * element  - the axuielement
---
--- Returns:
---  * `true` if the element is valid.
function mod.isValid(element)
    if element ~= nil and type(element) ~= "userdata" then
        error(string.format("The element must be \"userdata\" but was %q.", type(element)))
    end
    return element ~= nil and element:isValid()
end

-- ========================================================
-- Comparators
-- ========================================================

--- cp.fn.ax.leftToRight(a, b) -> boolean
--- Function
--- Returns `true` if element `a` is left of element `b`. May be used with `table.sort`.
---
--- Parameters:
---  * a - The first element
---  * b - The second element
---
--- Returns:
---  * `true` if `a` is left of `b`.
function mod.leftToRight(a, b)
    local aFrame, bFrame = a:attributeValue("AXFrame"), b:attributeValue("AXFrame")
    return (aFrame ~= nil and bFrame ~= nil and aFrame.x < bFrame.x) or false
end

--- cp.fn.ax.rightToLeft(a, b) -> boolean
--- Function
--- Returns `true` if element `a` is right of element `b`. May be used with `table.sort`.
---
--- Parameters:
---  * a - The first element
---  * b - The second element
---
--- Returns:
---  * `true` if `a` is right of `b`.
function mod.rightToLeft(a, b)
    local aFrame, bFrame = a:attributeValue("AXFrame"), b:attributeValue("AXFrame")
    return (aFrame ~= nil and bFrame ~= nil and aFrame.x + aFrame.w > bFrame.x + bFrame.w) or false
end

--- cp.fn.ax.topToBottom(a, b) -> boolean
--- Function
--- Returns `true` if element `a` is above element `b`. May be used with `table.sort`.
---
--- Parameters:
---  * a - The first element
---  * b - The second element
---
--- Returns:
---  * `true` if `a` is above `b`.
function mod.topToBottom(a, b)
    local aFrame, bFrame = a:attributeValue("AXFrame"), b:attributeValue("AXFrame")
    return (aFrame ~= nil and bFrame ~= nil and aFrame.y < bFrame.y) or false
end

--- cp.fn.ax.bottomToTop(a, b) -> boolean
--- Function
--- Returns `true` if element `a` is below element `b`. May be used with `table.sort`.
---
--- Parameters:
---  * a - The first element
---  * b - The second element
---
--- Returns:
---  * `true` if `a` is below `b`.
function mod.bottomToTop(a, b)
    local aFrame, bFrame = a:attributeValue("AXFrame"), b:attributeValue("AXFrame")
    return (aFrame ~= nil and bFrame ~= nil and aFrame.y + aFrame.h > bFrame.y + bFrame.h) or false
end

--- cp.fn.ax.topToBottomBaseAligned(a, b) -> boolean
--- Function
--- Returns `true` if the base of element `a` is above the base of element `b`, based on linear vertical alignment.
--- May be used with `table.sort`.
---
--- Parameters:
---  * a - The first element
---  * b - The second element
---
--- Returns:
---  * `true` if `a` is above `b`.
---
--- Notes:
---  * Two elements are considered to be aligned if the intersection of the height is at least 50% of the height of both elements.
function mod.topToBottomBaseAligned(a, b)
    if mod.areAligned(a, b) then
        return false
    end

    local aFrame, bFrame = a:attributeValue("AXFrame"), b:attributeValue("AXFrame")
    local aBottom, bBottom = aFrame.y+ aFrame.h, bFrame.y + bFrame.h
    return aBottom < bBottom
end

--- cp.fn.ax.narrowToWide(a, b) -> boolean
--- Function
--- Returns `true` if element `a` is narrower than element `b`. May be used with `table.sort`.
---
--- Parameters:
---  * a - The first element
---  * b - The second element
---
--- Returns:
---  * `true` if `a` is narrower than `b`.
function mod.narrowToWide(a, b)
    local aFrame, bFrame = a:attributeValue("AXFrame"), b:attributeValue("AXFrame")
    return (aFrame ~= nil and bFrame ~= nil and aFrame.w < bFrame.w) or false
end

--- cp.fn.ax.shortToTall(a, b) -> boolean
--- Function
--- Returns `true` if element `a` is shorter than element `b`. May be used with `table.sort`.
---
--- Parameters:
---  * a - The first element
---  * b - The second element
---
--- Returns:
---  * `true` if `a` is shorter than `b`.
function mod.shortToTall(a, b)
    local aFrame, bFrame = a:attributeValue("AXFrame"), b:attributeValue("AXFrame")
    return (aFrame ~= nil and bFrame ~= nil and aFrame.h < bFrame.h) or false
end

--- cp.fn.ax.topDown(a, b) -> boolean
--- Function
--- Compares two `axuielement` values, ordering them linearly, from top-to-bottom, left-to-right.
--- See the Notes section for more information.
---
--- Parameters:
---  * a - The first `axuielement` to compare.
---  * b - The second `axuielement` to compare.
---
--- Returns:
---  * `true` if `a` is above or to the left of `b` in the UI, `false` otherwise.
---
--- Notes:
---  * 1. If both elements intersect vertically by more than 50% their heights, they are considered to be on the same line.
---  * 2. If not on the same line, the element whose bottom edge is highest is before the other.
---  * 3. If they are both still equal, the left-most element is before the other.
---  * 4. If they are both still equal, the shortest element is before the other.
---  * 5. If they are both still equal, the narrowest element is before the other.
mod.topDown = fn.compare(mod.topToBottomBaseAligned, mod.leftToRight, mod.shortToTall, mod.narrowToWide)

--- cp.fn.ax.bottomUp(a, b) -> boolean
--- Function
--- The reverse of `topDown`, ordering from linearly from bottom-to-top, right-to-left
---
--- Parameters:
---  * a - The first `axuielement` to compare.
---  * b - The second `axuielement` to compare.
---
--- Returns:
---  * `true` if `a` is below or to the right of `b` in the UI, `false` otherwise.
function mod.bottomUp(a, b)
    return not mod.topDown(a, b)
end

--- cp.fn.ax.init(elementType, ...) -> function(parent, uiFinder) -> cp.ui.Element
--- Function
--- Creates a function that will create a new `cp.ui.Element` of the given `elementType` with the given `parent` and `uiFinder`.
--- Any additional arguments will be passed to the `elementType` constructor after the `parent` and `uiFinder`.
--- If any of the additional arguments are a `function`, they will be called with the `parent` and `uiFinder` as the first two arguments
--- when being passed into the constructor.
---
--- Parameters:
---  * elementType - The type of `cp.ui.Element` to create.
---  * ... - Any additional arguments to pass to the `elementType` constructor.
---
--- Returns:
---  * A function that will create a new `cp.ui.Element` of the given `elementType` with the given `parent` and `uiFinder`.
function mod.init(elementType, ...)
    -- map the arguments and convert any which are not functions to constant functions
    local args = map(pack(...), function(arg)
        if isCallable(arg) then
            return arg
        else
            return constant(arg)
        end
    end)

    -- return the function that will create the element
    return function(parent, uiFinder)
        -- map calls for the argument functions, passing in the parent and uiFinder
        local mappedArgs = map(args, function(arg)
            return arg(parent, uiFinder)
        end)
        -- construct the Element
        return elementType(parent, uiFinder, unpack(mappedArgs))
    end
end

--- cp.fn.ax.initElements(parent, elementsUiFinder, elementInits) -> table of cp.ui.Element
--- Function
--- Creates a table of `cp.ui.Element`s of the given `elementInits` with the given `parent` and `uiFinder`.
--- Any additional elements provided by `elementsUiFinder` which don't have a matching `elementInits` will be ignored.
---
--- Parameters:
---  * parent - The parent `cp.ui.Element` to use for the created `cp.ui.Element`s.
---  * elementsUiFinder - A `function` or `cp.prop` that will return a table of `axuielement`s to use as the elements for the created `cp.ui.Element`s.
---  * elementInits - A table of `function`s that will create `cp.ui.Element`s.
---
--- Returns:
---  * A table of `cp.ui.Element`s.
function mod.initElements(parent, elementsUiFinder, elementInits)
    elementsUiFinder = prop.FROM(elementsUiFinder)
    if not elementInits or #elementInits == 0 then return nil end
    return imap(function(init, index)
        return init(parent, elementsUiFinder:mutate(chain // fn.call >> get(index)))
    end, elementInits)
end

--- cp.fn.ax.prop(uiFinder, attributeName[, settable]) -> cp.prop
--- Function
--- Creates a new `cp.prop` which will find the `hs.axuielement` via the `uiFinder` and
--- get/set the value (if settable is `true`).
---
--- Parameters:
---  * uiFinder      - the `cp.prop` or `function` which will retrieve the current `hs.axuielement`.
---  * attributeName - the `AX` atrribute name the property links to.
---  * settable      - Defaults to `false`. If `true`, the property will also be settable.
---
--- Returns:
---  * The `cp.prop` for the attribute.
---
--- Notes:
---  * If the `uiFinder` is a `cp.prop`, it will be monitored for changes, making the resulting `prop` "live".
function mod.prop(uiFinder, attributeName, settable)
    if prop.is(uiFinder) then
        return uiFinder:mutate(
            mod.attribute(attributeName),
            settable and mod.setAttribute(attributeName)
        )
    end
end

--- cp.fn.ax.matchesIf(...) -> function(value) -> boolean
--- Function
--- Creates a `function` which will return `true` if the `value` is either an `axuielement`,
--- an [Element](cp.ui.Element.md), or a `callable` (function) that returns an `axuielement` that matches the predicate.
---
--- Parameters:
---  * ... - Any number of predicates, all of which must return a `truthy` value for the `value` to match.
---
--- Returns:
---  * A `function` which will return `true` if the `value` is a match.
function mod.matchesIf(...)
    return pipe(
        chain // uielement >> fn.all(...),
        isTruthy
    )
end

-- ========================================================
-- Combinator Functions - depend on other functions being defined first.
-- ========================================================

--- cp.fn.ax.childrenTopDown(value) -> table | nil
--- Function
--- Returns the children of the given `value` sorted in [topDown](#topDown) order.
---
--- Parameters:
---  * value - The value to get the children from.
---
--- Returns:
---  * The children of the given `value`, sorted [topDown](#topDown), or `nil`.
mod.childrenTopDown = chain // mod.children >> sort(mod.topDown)

return mod