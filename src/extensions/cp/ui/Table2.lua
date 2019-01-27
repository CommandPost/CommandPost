--- === cp.ui.Table2 ===
---
--- Represents an `AXTable` `axuielement`.

local log                       = require "hs.logger" .new "Table2"

local Grid	                    = require "cp.ui.Grid"

local Table2 = Grid:subclass("cp.ui.Table2")

--- cp.ui.Table2.matches(element) -> boolean
--- Function
--- Checks if the `element` is an `Table2`.
function Table2.static.matches(element)
    log.df("matches: %s", hs.inspect(element))
    return Grid.matches(element) and element:attributeValue("AXRole") == "AXTable"
end

--- cp.ui.Table2(parent, uiFinder) -> cp.ui.Table2
--- Constructor
--- Creates a new `Table2` with the specified `parent` and `uiFinder`.
---
--- Parameters:
--- * parent - The parent instance.
--- * uiFinder - A `function` or a `cp.prop` which will return the `AXTable2` `axuielement`.
---
--- Returns:
--- * The new `Table2` instance.

return Table2