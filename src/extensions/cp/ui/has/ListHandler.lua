--- === cp.ui.has.ListHandler ===
---
--- A handler that receives multiple child [Handler](cp.ui.has.Handler.md) instances builds a list of
--- their build results.

local require               = require

local ElementList           = require "cp.ui.has.ElementList"
local UIHandler             = require "cp.ui.has.UIHandler"

local ListHandler = UIHandler:subclass("cp.ui.has.ListHandler")

--- cp.ui.has.ListHandler(handlerList) -> cp.ui.has.ListHandler
--- Constructor
--- Creates a new `ListHandler` instance.
---
--- Parameters:
---  * handlerList - The list of [UIHandler](cp.ui.has.UIHandler.md) instances to use to build the list.
---
--- Returns:
---  * The new `ListHandler` instance.
function ListHandler:initialize(handlerList)
    UIHandler.initialize(self)
    self.handlerList = handlerList
end

--- cp.ui.has.ListHandler:matches(uiList) -> true, cp.slice | false, nil
--- Method
--- Processes the list `hs.axuielement` and returns a `true` if the `hs.axuielement` matches, otherwise `false`.
--- If the `hs.axuielement` matches, a [slice](cp.slice.md) of the remaining `hs.axuielement` objects is returned.
---
--- Parameters:
---  * elements - The `cp.slice` of `hs.axuielement` objects to match against.
---
--- Returns:
---  * `true` if the handler matches the `hs.axuielement`, otherwise `false`.
---  * The remaining `hs.axuielement` objects that were not matched as a slice, or `nil` if it was not matched.
function ListHandler:matches(uiList)
    local handlerList = self.handlerList
    local result
    for _, handler in ipairs(handlerList) do
        result, uiList = handler:matches(uiList)
        if not result then
            return false, nil
        end
    end
    return true, uiList
end

--- cp.ui.has.ListHandler:build(parent, uiListFinder) -> cp.ui.has.ElementList
--- Method
--- Builds an [has](cp.ui.has.md) instance for the `handlerList` provided to the constructor.
---
--- Parameters:
---  * parent - The parent [Element](cp.ui.Element.md) that this handler is for.
---  * uiListFinder - A callable value which returns the list of `hs.axuielement` objects to match against.
---
--- Returns:
---  * The new [ElementList](cp.ui.has.ElementList.md) instance.
function ListHandler:build(parent, uiListFinder)
    return ElementList:ofExactly(self.handlerList)(parent, uiListFinder)
end

return ListHandler