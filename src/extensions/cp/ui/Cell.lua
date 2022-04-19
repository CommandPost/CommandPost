--- === cp.ui.Cell ===
---
--- Represents an `AXCell` `axuielement`. This can be used directly, or can be subclassed to provide more specific access to the cell contents.
--- It is typically used in conjunction with a container type such as [Table](cp.ui.Table.md), something like this:
---
--- ```lua
--- function MyPanel.lazy.value:tableOfStuff()
---     return Table:withRowsOf(
---         Row:containing(
---             Cell:with(TextField), Cell:with(Button)
---         )
---     )(self, self.UI:mutate(chain // uielement >> attribute "AXContents"))
--- end
--- ```
---
--- This is a subclass of [Element](cp.ui.Element.md).

local require                       = require

local fn                            = require "cp.fn"
local ax	                        = require "cp.fn.ax"
local is                            = require "cp.is"
local Element	                    = require "cp.ui.Element"

local pack                          = table.pack

local Cell = Element:subclass("cp.ui.Cell")
    :defineBuilder("with")

--- cp.ui.Cell.matches(element) ->  boolean
--- Function
--- Checks if the `element` is an `AXCell`.
---
--- Parameters:
---  * element - An element to check
---
--- Returns:
---  * A boolean
Cell.static.matches = ax.matchesIf(Element.matches, ax.hasRole "AXCell")

--- cp.ui.Cell:with(...) -> function(parent, uiFinder) -> cp.ui.Cell.Builder
--- Function
--- A combinator function that returns a `Cell.Builder` that accepts the `parent` and `uiFinder` to construct a new `Cell`.
---
--- Parameters:
---  * ... - One or more arguments to pass to the constructor.
---
--- Returns:
---  * A [Cell.Builder](cp.ui.Cell.Builder.md)
---
--- Notes:
---  * For example, if a cell contains a [Button](cp.ui.Button.md), you can use `cp.ui.Cell:with(Button)`, and it will return a `Cell`
---    `Builder` that accepts the `parent` and `uiFinder` parameters, and whose contents is expected to be a `Button`.
---    That `Button` instance can be accessed via the `children[1]` value.
---    ```

--- cp.ui.Cell(parent, uiFinder[, childInits]) -> Cell
--- Constructor
--- Creates a new `Cell` instance.
---
--- Parameters:
---  * parent - The parent `Element`.
---  * uiFinder - A `cp.prop` or `axuielement` that will be used to find this `Cell`'s `axuielement`.
---  * ... - The list of child `Element` builders to initialize.
---
--- Returns:
---  * A new `Cell` instance.
function Cell:initialize(parent, uiFinder, ...)
    Element.initialize(self, parent, uiFinder)
    self.childInits = pack(...)
end

--- cp.ui.Cell.columnIndexRange <cp.prop: table; read-only>
--- Field
--- Returns a table of `{len,loc}`, which indicates if the cell covers multiple columns.
function Cell.lazy.prop:columnIndexRange()
    return ax.prop(self.UI, "AXColumnIndexRange")
end

--- cp.ui.Cell.rowIndexRange <cp.prop: table; read-only>
--- Field
--- Returns a table of `{len,loc}`, which indicates if the cell covers multiple rows.
function Cell.lazy.prop:rowIndexRange()
    return ax.prop(self.UI, "AXRowIndexRange")
end

--- cp.ui.Cell.selected <cp.prop: table>
--- Field
--- Indicates if the cell is currently selected.
function Cell.lazy.prop:selected()
    return ax.prop(self.UI, "AXSelected")
end

--- cp.ui.Cell.childrenUI <cp.prop: table of axuielement; read-only>
--- Field
--- The list of `axuielement`s which are children of this `Cell`.
function Cell.lazy.prop:childrenUI()
    return ax.prop(self.UI, "AXChildren")
end

--- cp.ui.Cell.children <table of cp.ui.Element; live?; read-only>
--- Field
--- The list of `Element`s which are children of this `Cell`, if the `childInits` were provided to the constructor.
function Cell.lazy.value:children()
    return ax.initElements(self, self.childrenUI, self.childInits)
end

--- cp.ui.Cell.value <cp.prop: anything>
--- Field
--- The cell value.
function Cell.lazy.prop:value()
    return ax.prop(self.UI, "AXValue", true)
end

--- cp.ui.Cell.value <cp.prop: string>
--- Field
--- The cell value, if it is a string.
function Cell.lazy.prop:textValue()
    return self.value:mutate(fn.value.filter(is.string))
end

--- cp.ui.Cell.textValueIs(value) -> boolean
--- Method
--- Checks if the cell's text value equals `value`.
---
--- Parameters:
---  * `value`	- The text value to compare.
---
--- Returns:
---  * `true` if the cell text value equals the provided `value`.
function Cell.static:textValueIs(value)
    return self:textValue() == value
end

return Cell