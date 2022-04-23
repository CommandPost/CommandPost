--- === cp.ui.Row ===
---
--- Represents an `AXRow` `axuielement`.

local ax                        = require "cp.fn.ax"
local Element                   = require "cp.ui.Element"

local pack                      = table.pack

local Row = Element:subclass("cp.ui.Row")
    :defineBuilder("containing")

--- === cp.ui.Row.Builder ===
---
--- Defines a `Row` builder.

--- cp.ui.Row:containing(...) -> cp.ui.Row.Builder
--- Function
--- Returns a `Builder` with the `Element` initializers for the items in the row.
---
--- Parameters:
---  * ... - A variable list of `Element` initializers, one for each item.
---
--- Returns:
---  * The `Row.Builder`

--- cp.ui.Row.matches(element) -> boolean
--- Method
--- Checks if the element is a `Row`.
---
--- Parameters:
---  * element - the `axuielement` to check.
---
--- Returns:
---  * `true` if it matches, otherwise `false`.
Row.static.matches = ax.matchesIf(Element.matches, ax.hasRole "AXRow")

--- cp.ui.Row(parent, uiFinder, ...) -> cp.ui.Row
--- Constructor
--- Creates a new `Row` instance with the specified `parent` and `uiFinder`.
---
--- Parameters:
---  * parent - the parent `Element`.
---  * uiFinder - a `function` or `cp.prop` containing the `axuielement`
---  * ... - a variable list of `Element` initializers, one for each item in the row.
---
--- Returns:
---  * The new `Row`.
function Row:initialize(parent, uiFinder, ...)
    Element.initialize(self, parent, uiFinder)
    self.childInits = pack(...)
end

--- cp.ui.Row.childrenUI <cp.prop: table of axuielement>
--- Field
--- Contains the list of `axuielement` children of the row.
function Row.lazy.prop:childrenUI()
    return ax.prop(self.UI, "AXChildren")
end

--— cp.ui.Row.children <table of cp.ui.Element>
--— Field
--— A table of child `Element`s for the `Row`.
function Row.lazy.value:children()
    return ax.initElements(self, self.childrenUI, self.childInits)
end

--- cp.ui.Row.disclosing <cp.prop: boolean>
--- Field
--- Indicates if the `Row` is disclosing other `Rows`.
function Row.lazy.prop:disclosing()
    return ax.prop(self.UI, "AXDisclosing", true)
end

--- cp.ui.Row.disclosureLevel <cp.prop: number; read-only>
--- Field
--- The depth of disclosure. `0` is the top level.
function Row.lazy.prop:disclosureLevel()
    return ax.prop(self.UI, "AXDisclosureLevel")
end

--- cp.ui.Row:disclosedByRow() -> cp.ui.Row
--- Method
--- The `Row` which is disclosing this `Row`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `cp.ui.Row` object
function Row.lazy.prop:disclosedByRow()
    return ax.prop(self.UI, "AXDisclosedByRow"):mutate(function(original)
        return self:parent():fetchRow(original())
    end)
end

--- cp.ui.Row:disclosedRows() -> table of cp.ui.Row or nil
--- Method
--- If available, returns a table of [Row](cp.ui.Row.md)s that are disclosed by this `Row`.
--- If this row is currently unavailable, `nil` is returned.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `table` of Rows, or `nil`.
function Row:disclosedRows()
    local ui = self:UI()
    if ui then
        local rowsUI = ui:attributeValue("AXDisclosedRows")
        if rowsUI then
            return self:parent():fetchRows(rowsUI)
        end
    end
end

--- cp.ui.Row.selected <cp.prop: boolean>
--- Field
--- Indicates if the row is currently selected. May be set.
function Row.lazy.prop:selected()
    return ax.prop(self.UI, "AXSelected", true)
end

--- cp.ui.Row.index <cp.prop: number; read-only>
--- Field
--- The numeric index of this row in the overall container, with `0` being the first item.
function Row.lazy.prop:index()
    return ax.prop(self.UI, "AXIndex")
end

-- cp.ui.Row:__eq(other) -> boolean
-- Function
-- Checks if the two items are Rows with identical `axuielement`s, and both not `nil`.
function Row:__eq(other)
    local ui = self:UI()
    return ui ~= nil and other.UI and ui == other:UI()
end

return Row
