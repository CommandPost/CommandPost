--- === cp.rx.go.List ===
---
--- _Extends:_ [Statement](cp.rx.go.Statement.md)
---
--- A [Statement](cp.rx.go.Statement.md) that will loop through a table as a list from item `1` to the table length.

local log                   = require("hs.logger").new("List")

local Statement             = require("cp.rx.go.Statement")
local Observable            = require("cp.rx").Observable

local function isCallable(value)
    local valueType = type(value)
    if valueType == "table" and #value == 0 then
        local mt = getmetatable(value)
        return mt ~= nil and type(mt.__call) == "function"
    end
    return valueType == "function"
end

local function isIterable(value)
    local valueType = type(value)
    return valueType == "table" or valueType == "userdata"
end

--- cp.rx.go.List(values) -> List
--- Constructor
--- Creates a new `List` `Statement` that will loop through the provided table as a list.
---
--- Example:
---
--- ```lua
--- List(someTable)
--- ```
---
--- Parameters:
---  * values  - a `table` value, or a `function` which returns a table.
---
--- Returns:
---  * The `Statement` which will return the first value when executed.
local List = Statement.named("List")
:onInit(function(context, values)
    assert(isIterable(values) or isCallable(values), "The values must be a table/userdata or a function returning a table/userdata.")
    context.values = values
end)
:onObservable(function(context)
    local values = context.values
    if isCallable(values) then
        values = values()
        assert(isIterable(values), "The value function must return a table or userdata.")
    end

    if context.sort then
        table.sort(values, context.sort)
    end

    return Observable.fromTable(values, ipairs, true)
end)
:define()

local function naturalSort(a, b)
    return a < b
end

--- === cp.rx.go.List.Sorted ===
---
--- A `Statement.Modifier` that specifies the list should be sorted by its 'natural' order - that is `a < b`.

--- cp.rx.go.List.Sorted <cp.rx.go.Statement.Modifier>
--- Constant
--- This is a configuration of `List`, which should be created via `List:Sorted()`.

--- cp.rx.go.List:Sorted() -> List.Sorted
--- Method
--- Indicates the List should be sorted by its natural order before being sent out individually.
---
--- For example:
--- ```lua
--- Sort(9,2,5):Sorted()
--- ```
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Sorted` `Statement.Modifier`.
List.modifier("Sorted")
:onInit(function(context)
    context.sort = naturalSort
end)
:define()

--- === cp.rx.go.List.SortedBy ===
---
--- A `Statement.Modifier` that specifies the list should be sorted by the specified `function`.

--- cp.rx.go.List.SortedBy <cp.rx.go.Statement.Modifier>
--- Constant
--- This is a configuration of `List`, which should be created via `List:SortedBy(...)`.

--- cp.rx.go.List:SortedBy(...) -> List.SortedBy
--- Method
--- Indicates the List should be sorted by the provided `function`.
---
--- For example:
--- ```lua
--- Sort(9,2,5):SortedBy(function(a, b) return b < a)
--- ```
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `SortedBy` `Statement.Modifier`.
List.modifier("SortedBy")
:onInit(function(context, sortFn)
    assert(type(sortFn) == "function", "Please provide a function to sort with.")
    context.sort = sortFn
end)
:define()

return List