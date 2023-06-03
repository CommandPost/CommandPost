--- === cp.ui.has.EndHandler ===
---
--- This expects to be the last [UIHandler](cp.ui.has.UIHandler.md), and only passes if the list of `hs.axuielement`s is empty.

local require               = require

local UIHandler             = require "cp.ui.has.UIHandler"

local EndHandler = UIHandler:subclass("cp.ui.has.EndHandler")

--- cp.ui.has.EndHandler() -> cp.ui.has.EndHandler
--- Constructor
--- Creates a new `EndHandler` instance.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The new `EndHandler` instance.
function EndHandler:initialize()
    UIHandler.initialize(self)
end

--- cp.ui.has.EndHandler:matches(uiList) -> true, cp.slice
--- Method
--- Processes the list `hs.axuielement`. It will only return `true` if the list is empty.
--- If so, the original list is returned. If not, `false` is returned.
---
--- Parameters:
---  * uiList - The `cp.slice` of `hs.axuielement` objects to match against.
---
--- Returns:
---  * `true` if the handler matches the `hs.axuielement`, otherwise `false`.
---  * The remaining `hs.axuielement` objects that were not matched as a slice, or `nil` if it was not matched.
function EndHandler:matches(uiList) -- luacheck:ignore
    if #uiList == 0 then
        return true, uiList
    end
    return false, nil
end

--- cp.ui.has.EndHandler:build(parent, uiListFinder) -> nil
--- Method
--- Returns the result of the internal handler's `build` method.
---
--- Parameters:
---  * parent - The parent [Element](cp.ui.Element.md) that this handler is for.
---  * uiListFinder - A callable value which returns the list of `hs.axuielement` objects to match against.
---
--- Returns:
---  * The result of the internal handler's `build` method.
function EndHandler:build(parent, uiListFinder) -- luacheck:ignore
    return nil
end

return EndHandler