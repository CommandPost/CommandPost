--- === cp.ui.Builder ===
---
--- A utility class, which provides support for allowing creation of [Element](cp.ui.Element.md) instances in a "builder" style.
---
--- This is useful for creating complex UI elements, such as a [Table](cp.ui.Table.md) or [ScrollArea](cp.ui.ScrollArea.md),
--- which can have custom sub-elements.
---
--- A `Builder` instance can be called like a function, expecting a `parent` and `uiFinder`, which are the basic values required
--- to create a new `Element` instance. Specific subclasses have extra values, which a `Builder` can define to pass in.
---
--- For example, a [Table](cp.ui.Table.md) has a `headerType` and `rowType` in its constructor, which are used to create the
--- header and row elements when required:
---
--- ```lua
--- local myTable = cp.ui.Table(parent, uiFinder, Group, Row)
--- ```
---
--- However, its quite common for a `ScrollArea` to contain a [Table](cp.ui.Table.md), and in order to use the `ScrollArea:containing(Table)`
--- method, you would have to provide a wrapper function that hard-codes the `headerType` and `rowType` values:
---
--- ```lua
--- local scrollArea = ScrollArea:containing(function(parent, uiFinder)
---     return Table(parent, uiFinder, Group, Row)
--- end)
--- ```
---
--- However, `Table` has its own helper method for this to make it easier to use:
---
--- ```lua
--- local scrollArea = ScrollArea:containing(Table:withRowsOf(Row):withHeaderOf(Group))
--- scrollArea.contents.header -- A cp.ui.Group instance
--- scrollArea.contents.rows[1] -- A cp.ui.Row instance
--- ```
---
--- Internally, the `Table:withRowsOf(rowType)` function returns a `Builder` configured to accept `"withRowsOf"` and `"withHeaderOf"`
--- values, which are then passed to the `Table` constructor.
---
--- To create your own `Builder` instances, you can just return a new `Builder`, specifying the type (typically `self`) and the names
--- of the constructor arguments to accept. For example:
---
--- ```lua
--- local MyElement = Element:subclass("foo.MyElement")
---
--- function MyElement:initialize(parent, uiFinder, leftType, rightType)
---     -- TODO
--- end
---
--- function MyElement.static:withLeftOf(leftType)
---     return Builder(self, "withLeftOf", "withRightOf"):withLeftOf(leftType)
--- end
--- ```
---
--- The `Builder` instance can then be used to create new `MyElement` instances:
---
--- ```lua
--- local myElementBuilder = MyElement:withLeftOf(Group):withRightOf(Button)
--- local myElement = myElementBuilder(parent, uiFinder)
--- ```
---
--- The order of the arguments is important, because it defines what order the constructor arguments will be passed in.
--- For example, if we added a `withRightOf` method definition, it would look like this:
---
--- ```lua
--- function MyElement.static:withRightOf(rightType)
---     return Builder(self, "withLeftOf", "withRightOf"):withRightOf(rightType)
--- end
--- local myElementBuilder = MyElement:withRightOf(Group):withLeftOf(Button)
--- ```
---
--- The `"withLeftOf"` value will still be passed to the constructor first, because it is listed first in the `Builder` constructor.


local require                   = require

local log                       = require "hs.logger" .new "Builder"

local class                     = require "middleclass"

local pack, unpack              = table.pack, table.unpack
local flatten                   = require "cp.fn.table".flatten

local ELEMENT_TYPE = {}
local EXTRA_ARGS = {}
local EXTRA_VALUES = {}

local function _extraArgs(builder)
    local extraValues = flatten(builder[EXTRA_VALUES])
    return unpack(extraValues, 1, extraValues.n)
end

local Builder = class("cp.ui.Builder")

function Builder:initialize(elementType, ...)
    self[ELEMENT_TYPE] = elementType
    local extraArgs = {}
    local extraArgsCount = select("#", ...)
    for i = 1, extraArgsCount do
        local arg = select(i, ...)
        extraArgs[arg] = i
    end
    self[EXTRA_ARGS] = extraArgs
    self[EXTRA_VALUES] = { n = extraArgsCount }
end

--- cp.ui.Builder:build(parent, uiFinder) -> cp.ui.Element
--- Method
--- Builds a new [Element](cp.ui.Element.md) instance, passing in the `parent` and `uiFinder` parameters,
--- followed by any extra arguments that have been set, in the order passed to the constructor.
---
--- Parameters:
---  * parent - The parent `Element`.
---  * uiFinder - A `cp.prop` or `axuielement` that will be used to find this `Element`'s `axuielement`.
---
--- Returns:
---  * A new `Element` instance.
function Builder:build(parent, uiFinder)
    return self[ELEMENT_TYPE](parent, uiFinder, _extraArgs(self))
end

function Builder:__index(key)
    local args = self[EXTRA_ARGS]
    local index = args[key]
    if index then
        local extraValues = self[EXTRA_VALUES]
        return function(builder, ...)
            local values = pack(...)
            extraValues[index] = values
            return builder
        end
    end
end

function Builder:__call(parent, uiFinder)
    return self:build(parent, uiFinder)
end

return Builder