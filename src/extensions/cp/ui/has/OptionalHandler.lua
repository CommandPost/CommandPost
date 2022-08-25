--- === cp.ui.has.OptionalHandler ===
---
--- A [UIHandler](cp.ui.has.UIHandler.md) that will optionally match its contents. If they don't match, it will
--- still return `true` and the unchanged `hs.axuielement` list when matching.

local require                       = require

local inspect                       = require "hs.inspect"

local UIHandler                     = require "cp.ui.has.UIHandler"

local format                        = string.format

local OptionalHandler = UIHandler:subclass("cp.ui.has.OptionalHandler")

--- cp.ui.has.OptionalHandler(handler) -> cp.ui.has.OptionalHandler
--- Constructor
--- Creates a new `OptionalHandler` instance.
---
--- Parameters:
---  * handler - The [UIHandler](cp.ui.has.UIHandler.md) which may or may not be present in the list.
---
--- Returns:
---  * The new `OptionalHandler` instance.
function OptionalHandler:initialize(handler)
    UIHandler.initialize(self)
    if UIHandler:isSuperclassFor(handler) then
        self.handler = handler
    else
        error(format("expected a UIHandler or a table of UIHandlers: %s", inspect(handler)))
    end
end

--- cp.ui.has.OptionalHandler:matches(uiList) -> true, cp.slice
--- Method
--- Processes the list `hs.axuielement`. It will always return `true`. If the the internal handler matches, the returned
--- `hs.axuielement` list will be the remaining list, otherwise it will be the original `uiList`, unmodified.
---
--- Parameters:
---  * uiList - The `cp.slice` of `hs.axuielement` objects to match against.
---
--- Returns:
---  * `true` if the handler matches the `hs.axuielement`, otherwise `false`.
---  * The remaining `hs.axuielement` objects that were not matched as a slice, or `nil` if it was not matched.
function OptionalHandler:matches(uiList)
    local result, remainder = self.handler:matches(uiList)
    if result then
        return true, remainder
    end
    return true, uiList
end

--- cp.ui.has.OptionalHandler:build(parent, uiListFinder) -> any
--- Method
--- Returns the result of the internal handler's `build` method.
---
--- Parameters:
---  * parent - The parent [Element](cp.ui.Element.md) that this handler is for.
---  * uiListFinder - A callable value which returns the list of `hs.axuielement` objects to match against.
---
--- Returns:
---  * The result of the internal handler's `build` method.
function OptionalHandler:build(parent, uiListFinder)
    return self.handler:build(parent, uiListFinder)
end

return OptionalHandler