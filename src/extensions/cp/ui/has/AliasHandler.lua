--- === cp.ui.AliasHandler ===
---
--- A handler that matches a `hs.axuielement` and creates a `Field` instance as a varable on the parent.

local require                   = require

local UIHandler                 = require "cp.ui.has.UIHandler"

local AliasHandler = UIHandler:subclass("cp.ui.has.AliasHandler")

--- cp.ui.AliasHandler(alias, elementHandler) -> cp.ui.AliasHandler
--- Constructor
--- Creates a new `AliasHandler` instance. This will indicate that the value built by the provided `elementHandler` should be
--- assigned to the `alias` on the parent.
---
--- Parameters:
---  * alias - The name of the field to create on the parent.
---  * elementHandler - The [ElementHandler](cp.ui.ElementHandler.md) to use to build the `Element` instance.
---
--- Returns:
---  * The new `AliasHandler` instance.
function AliasHandler:initialize(alias, elementHandler)
    UIHandler.initialize(self)
    self.alias = alias
    self.elementHandler = elementHandler
end

--- cp.ui.AliasHandler:matches(uiList) -> true, cp.slice | false, nil
--- Method
--- Returns the result from the wrapped `elementHandler`.
---
--- Parameters:
---  * uiList - The `cp.slice` of `hs.axuielement` objects to match against.
---
--- Returns:
---  * The result from the wrapped `elementHandler`.
function AliasHandler:matches(uiList)
    return self.elementHandler:matches(uiList)
end


--- cp.ui.AliasHandler:build(parent, matchedUIFinder) -> any
--- Method
--- Builds the [Element](cp.ui.Element.md) for the `elementHandler` provided to the constructor.
---
--- Parameters:
---  * parent - The parent [Element](cp.ui.Element.md) that this handler is for.
---  * uiFinder - A callable value which returns the list of `hs.axuielement` objects to match against.
---
--- Returns:
---  * The new [Element](cp.ui.Element.md) instance.
function AliasHandler:build(parent, matchedUIFinder)
    return self.elementHandler:build(parent, matchedUIFinder)
end

return AliasHandler