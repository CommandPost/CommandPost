--- === cp.ui.has.OptionalHandler ===
---
--- A [UIHandler](cp.ui.has.UIHandler.md) that will optionally match its contents. If they don't match, it will
--- still return `true` and the unchanged `hs.axuielement` list when matching.

local require                       = require

local inspect                       = require "hs.inspect"
local is                            = require "cp.is"

local ListHandler                   = require "cp.ui.has.ListHandler"
local UIHandler                     = require "cp.ui.has.UIHandler"

local isTable                       = is.table
local format                        = string.format

local OptionalHandler = UIHandler:subclass("cp.ui.has.OptionalHandler")

--- cp.ui.has.OptionalHandler(handlerOrList) -> cp.ui.has.OptionalHandler
--- Constructor
--- Creates a new `OptionalHandler` instance.
---
--- Parameters:
---  * handlerOrList - The [UIHandler](cp.ui.has.UIHandler.md) or `table` of [UIHandler](cp.ui.has.UIHandler.md) instances to use to build the list.
---
--- Returns:
---  * The new `OptionalHandler` instance.
function OptionalHandler:initialize(handlerOrList)
    UIHandler.initialize(self)
    if UIHandler:isSupertypeOf(handlerOrList) then
        self.handler = handlerOrList
    elseif isTable(handlerOrList) and #handlerOrList > 0 then
        self.handler = ListHandler(handlerOrList)
    else
        error(format("expected a UIHandler or a table of UIHandlers: %s", inspect(handlerOrList)))
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