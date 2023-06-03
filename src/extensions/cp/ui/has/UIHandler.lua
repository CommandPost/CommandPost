--- === cp.ui.has.UIHandler ===
---
--- A base class for element handler. A handler is responsible for matching a `hs.axuielement` to one or more specific
--- [Element](cp.ui.Element.md) subclass, which is typically passed in the constructor.

local require               = require

local class                 = require "middleclass"

local format                = string.format

local UIHandler = class("cp.ui.has.UIHandler")

--- cp.ui.has.UIHandler() -> cp.ui.has.UIHandler
--- Constructor
--- Creates a new `Handler` instance.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The new `Handler` instance.
function UIHandler:initialize() -- luacheck:ignore
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
function UIHandler:matches(uiList) -- luacheck:ignore
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
function UIHandler:build(parent, uiListFinder) -- luacheck:ignore
    error(format("%s:build() is not implemented.", self.class.name))
end

return UIHandler