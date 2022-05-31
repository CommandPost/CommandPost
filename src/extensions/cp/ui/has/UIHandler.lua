--- === cp.ui.has.UIHandler ===
---
--- A base class for element handler. A handler is responsible for matching a `hs.axuielement` to one or more specific
--- [Element](cp.ui.Element.md) subclass, which is typically passed in the constructor.

local require               = require

local class                 = require "middleclass"

local format                = string.format

local UIHandler = class("cp.ui.has.UIHandler")

--- cp.ui.has.UIHandler:isClassOf(thing) -> boolean
--- Function
--- Checks if the `thing` is a `UIHandler`. If called on subclasses, it will check
--- if the `thing` is an instance of the subclass.
---
--- Parameters:
---  * `thing`		- The thing to check
---
--- Returns:
---  * `true` if the thing is a `Element` instance.
---
--- Notes:
---  * This is a type method, not an instance method or a type function. It is called with `:` on the type itself,
---    not an instance. For example `UIHandler:isClassOf(value)`
function UIHandler.static:isClassOf(thing)
    return type(thing) == "table" and thing.isInstanceOf ~= nil and thing:isInstanceOf(self)
end

--- cp.ui.UIHandler:isSupertypeOf(thing) -> boolean
--- Function
--- Checks if the `thing` is a subclass of `UIHandler`.
---
--- Parameters:
---  * `thing`		- The thing to check
---
--- Returns:
---  * `true` if the thing is a subclass of `UIHandler`.
---
--- Notes:
---  * This is a type method, not an instance method or a type function. It is called with `:` on the type itself,
---    not an instance. For example `UIHandler:isSupertypeof(value)`
function UIHandler.static:isSupertypeOf(thing)
    return type(thing) == "table" and thing.isSubclassOf ~= nil and thing:isSubclassOf(self)
end

--- cp.ui.has.UIHandler() -> cp.ui.has.UIHandler
--- Constructor
--- Creates a new `Handler` instance.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The new `Handler` instance.
function UIHandler:initialize()
end

--- cp.ui.has.UIHandler:matches(uiList) -> true, cp.slice | false, nil
--- Method
--- Processes the list `hs.axuielement` objects and returns a `true` if the `hs.axuielement` matches, otherwise `false`.
--- If the `hs.axuielement` matches, a [slice](cp.slice.md) of the remaining `hs.axuielement` objects is returned.
---
--- Parameters:
---  * uiList - The `cp.slice` of `hs.axuielement` objects to match.
---
--- Returns:
---  * `true` if the handler matches followed by a `slice` of remaining `hs.axuielement`s, otherwise `false` followed by `nil`.
---
--- Notes:
---  * The default implementation throws an error.
function UIHandler:matches(uiList)
    error(format("%s:matches() is not implemented.", self.class.name))
end

--- cp.ui.has.UIHandler:build(parent, uiListFinder) -> any
--- Method
--- Builds the instance for this handler. Often this is a subclass of [Element](cp.ui.Element.md), but it can be any object.
--- It should consume whatever items it needs from the `uiListFinder`, and return the new value.
---
--- Parameters:
---  * parent - The parent [Element](cp.ui.Element.md) that this handler is for.
---  * uiListFinder - A `cp.prop` value which returns the list of `hs.axuielement` objects.
---
--- Returns:
---  * The new value built by the handler.
---
--- Notes:
---  * The default implementation throws an error.
function UIHandler:build(parent, uiListFinder)
    error(format("%s:build() is not implemented.", self.class.name))
end

return UIHandler