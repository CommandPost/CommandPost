--- === cp.fn.table ===
---
--- Table-related functions.

local require           = require

-- local log               = require "hs.logger".new "fntable"

local cpfn              = require "cp.fn"
local cpfnargs          = require "cp.fn.args"
local is                = require "cp.is"

local LazyList          = require "cp.collect.LazyList"

local packArgs          = cpfnargs.pack
local unpackArgs        = cpfnargs.unpack

local insert            = table.insert
local pack, unpack      = table.pack, table.unpack

local mod = {}

--- cp.fn.table.call(name, ...) -> function(table) -> ...
--- Function
--- Calls a function on a table with the specified `name`. Any additional arguments are passed to the function.
---
--- Parameters:
---  * name - The name of the function to call.
---  * ... - Any additional arguments to pass to the function.
---
--- Returns:
---  * The function that will accept a table and call the function with the specified `name`.
function mod.call(name, ...)
    local args = pack(...)
    return function(table)
        if not is.object(table) then
            return
        end
        local fn = table[name]
        if is.callable(fn) then
            return fn(table, unpack(args))
        end
    end
end

--- cp.fn.table.copy(table) -> table
--- Function
--- Performs a shallow copy of the specified table using `pairs`.
---
--- Parameters:
---  * table - The table to copy.
---
--- Returns:
---  * A copy of the table.
function mod.copy(table)
    local result = {}
    for k, v in pairs(table) do
        result[k] = v
    end
    return result
end

--- cp.fn.table.filter([predicate]) -> function(table) -> table
--- Function
--- Returns a function that filters a table using the given predicate. If the predicate is not provided, the original table will be returned unchanged.
---
--- Parameters:
---  * predicate - A function that takes a value and returns true if the value should be included in the filtered table.
---
--- Returns:
---  * A function that takes a table and returns a filtered table.
function mod.filter(predicate)
    return function(t)
        if not predicate then return t end
        local result = {}
        for _,v in pairs(t) do
            if predicate(v) then
                insert(result, v)
            end
        end
        return result
    end
end

--- cp.fn.table.first(table) -> any | nil
--- Function
--- Returns the first value in the table.
---
--- Parameters:
---  * table - The table to get the first value from.
---
--- Returns:
---  * The first value in the table. May be `nil`.
function mod.first(t)
    return t[1]
end

--- cp.fn.table.firstMatching(predicate) -> function(table) -> any | nil
--- Function
--- Returns a function that will return the first value in the table that matches the predicate.
---
--- Parameters:
---  * predicate - A function that will be passed each value in the table. If it returns `true`, the value will be returned.
---
--- Returns:
---  * A function that will return the first value in the table that matches the predicate. May be `nil`.
function mod.firstMatching(predicate)
    return function(t)
        for _, v in ipairs(t) do
            if predicate(v) then
                return v
            end
        end
    end
end

--- cp.fn.table.flatten(t) -> table
--- Function
--- Flattens a table.
---
--- Parameters:
---  * t - The table to flatten.
---
--- Returns:
---  * A new table with all values flattened.
---
--- Notes:
---  * This function will not flatten nested tables.
---  * If the table has an `n` field, it will be used as the length, instead of `#t`.
function mod.flatten(t)
    local len = t.n or #t
    local result = { n = 0 }
    for i = 1, len do
        local v = t[i]
        if is.table(v) then
            local vlen = v.n or #v
            for j = 1, vlen do
                result.n = result.n + 1
                result[result.n] = v[j]
            end
        else
            result.n = result.n + 1
            result[result.n] = v
        end
    end
    return result
end

--- cp.fn.table.get(key) -> function(table) -> any
--- Function
--- Returns a function that returns the value at the specified key in a table.
---
--- Parameters:
---  * key - The key to get the value for.
---
--- Returns:
---  * A function that takes a table and returns the value at the specified key.
function mod.get(key)
    return function(t)
        return t[key]
    end
end

--- cp.fn.table.this -> table
--- Constant
--- A `table` which can have any named property key, which will be a function combinator that expects to receive a `table` and returns the value at the specified key. These are essentially equivalent statements: `cp.fn.table.this.key` and `cp.fn.table.get "key"`.
mod.this = setmetatable({}, {
    __index = function(_, key)
        return mod.get(key)
    end,
})

--- cp.fn.ifilter([predicate]) -> function(table) -> table
--- Function
--- Returns a function that filters a table using the given predicate, in index order. If the predicate is not provided, the original table will be returned unchanged.
---
--- Parameters:
---  * predicate - A function that takes a value and returns true if the value should be included in the filtered table.
---
--- Returns:
---  * A function that takes a table and returns a filtered table.
function mod.ifilter(predicate)
    return function(t)
        if not predicate then return t end
        local results = {}
        for _,v in ipairs(t) do
            if predicate(v) then
                insert(results, v)
            end
        end
        return results
    end
end

--- cp.fn.table.imap(fn, values) -> table of any | ...
--- Function
--- Maps a function over a table using `ipairs`. The function is passed the current `value` and the `key`.
---
--- Parameters:
---  * fn - The function to map.
---  * values - The table or list of arguments to map over.
---
--- Returns:
---  * A table or list of the results of the function.
---
--- Notes:
---  * If the values are a table, the results will be a table. Otherwise, the results will be a vararg list.
function mod.imap(fn, ...)
    local args, packed = packArgs(...)
    local results = LazyList(
        function() return #args end,
        function(i)
            local value = args[i]
            return fn(value, i)
        end
    )
    return unpackArgs(results, packed)
end

--- cp.fn.table.last(table) -> any | nil
--- Function
--- Returns the last value in the table.
---
--- Parameters:
---  * table - The table to get the last value from.
---
--- Returns:
---  * The last value in the table. May be `nil`.
function mod.last(t)
    return t[#t]
end

--- cp.fn.table.matchesExactItems(...) -> function(table) -> boolean
--- Function
--- Returns a function that will return `true` if the table exactly the number of items that match the provided list of predicates.
---
--- Parameters:
---  * ... - A list of predicates.
---
--- Returns:
---  * A function that will return `true` if the table exactly the number of items that match the provided list of predicates.
function mod.matchesExactItems(...)
    local predicates = pack(...)
    return function(value)
        if #value ~= #predicates then
            return false
        end
        for i, predicate in ipairs(predicates) do
            if not predicate(value[i]) then
                return false
            end
        end
        return true
    end
end

--- cp.fn.table.map(fn, t) -> table of any
--- Function
--- Maps a function over a table using `pairs`. The function is passed the current `value` and the `key`.
---
--- Parameters:
---  * fn - The function to map.
---  * t - The table arguments to map over.
---
--- Returns:
---  * A table with the values updated via the function.
function mod.map(fn, t)
    local results = {}
    for i,arg in pairs(t) do
        results[i] = fn(arg, i)
    end
    return results
end

--- cp.fn.table.mutate(key) -> function(fn) -> function(table) -> table
--- Function
--- Returns a function that accepts an immutible transformer function, which returns another function that accepts a table. When called, it will apply the transformation to the named `key` in the table.
---
--- Parameters:
---  * key - The key to set.
---
--- Returns:
---  * A function.
---
--- Notes:
---  * The returned function will mutate the table passed in, as well as returning it.
---  * Example usage: `fn.table.mutate("foo")(function(value) return value + 1 end)({value = 1})`
function mod.mutate(key)
    return function(fn)
        return function(t)
            t[key] = fn(t[key])
            return t
        end
    end
end

--- cp.fn.table.set(key, value) -> function(table) -> table
--- Function
--- Returns a function that accepts a table and sets the value at the specified key.
---
--- Parameters:
---  * key - The key to set.
---  * value - The value to set.
---
--- Returns:
---  * A function.
function mod.set(key, value)
    return function(t)
        t[key] = value
        return t
    end
end

--- cp.fn.table.size(t) -> number
--- Function
--- Returns the size of the table.
---
--- Parameters:
---  * t - The table to get the size of.
---
--- Returns:
---  * The size of the table.
function mod.size(t)
    return #t
end

--- cp.fn.table.sort(...) -> function(table) -> table
--- Function
--- A combinator that returns a function that accepts a table and returns a new table, sorted with the compare functions.
---
--- Parameters:
---  * ... - The list of compare functions to use, in order.
---
--- Returns:
---  * A function.
---
--- Notes:
---  * The compare functions should take two arguments and return `true` if the first argument is less than the second.
---  * The returned result will be a shallow copy of the original in a new table. The original table will not be modified.
---  * If no compare functions are provided, the table will be sorted "natural" sorting order (`a < b`).
---  * Example usage: `fn.table.sort(function(a, b) return a > b end)({1, 2, 3})`
function mod.sort(...)
    local compareFn = cpfn.compare(...)
    return function(t)
        local result = mod.copy(t)
        table.sort(result, compareFn)
        return result
    end
end

--- cp.fn.table.split(predicate) -> function(table) -> table of tables, table
--- Function
--- Returns a function that accepts a table and splits it into multiple tables whenever it encounters a value that matches the `predicate`. The final table is a list containing each table that was split, followed by a table containing the splitter values.
---
--- Parameters:
---  * predicate - A function that will be passed each value in the table. If it returns `true`, the value will be returned.
---
--- Returns:
---  * A function that accepts a table to split and returns a table of tables, followed by a table of splitter values
function mod.split(predicate)
    return function(t)
        local results = {}
        local current = {}
        local splits = {}
        for _, v in ipairs(t) do
            if predicate(v) then
                insert(results, current)
                current = {}
                insert(splits, v)
            else
                insert(current, v)
            end
        end
        insert(results, current)
        return results, splits
    end
end

-- _minListSize(lists) -> number
-- Function
-- Returns the smallest list size from the provided `lists`.
--
-- Parameters:
--  * lists - A list of tables.
--
-- Returns:
--  * The smallest list size.
local function _minListSize(lists)
    local min = nil
    for _, list in ipairs(lists) do
        min = min and math.min(min, #list) or #list
    end
    return min
end

-- _maxListSize(lists) -> number
-- Function
-- Returns the largest list size from the provided `lists`.
--
-- Parameters:
--  * lists - A list of tables.
--
-- Returns:
--  * The largest list size.
local function _maxListSize(lists)
    local max = nil
    for _, list in ipairs(lists) do
        max = max and math.max(max, #list) or #list
    end
    return max
end

--- cp.fn.table.zip(lists) -> table | ...
--- Function
--- Zips a series of lists together, returning a list combining the values from the provided lists. The returned list will have the same length as the shortest list. Each sub-list will contain the values from the corresponding list in the argument list.
---
--- Parameters:
---  * lists - A table or list of lists.
---
--- Returns:
---  * A function which returns a list combining the values from the provided lists.
---
--- Notes:
---  * If a table is provided, a table is returned. If a vararg is provided, a vararg is returned.
function mod.zip(...)
    local results = {}
    local inputs = packArgs(...)
    local minSize = _minListSize(inputs)
    if minSize == 0 then
        return results
    end

    for i = 1, minSize do
        local value = {}
        for j,list in ipairs(inputs) do
            value[j] = list[i]
        end
        results[i] = value
    end

    return results
end

--- cp.fn.table.zipAll(lists) -> function
--- Function
--- Zips a series of lists together, returning a list of lists. The returned list will have the same length as the longest list. Each sub-list will contain the values from the corresponding list in the argument list.
---
--- Parameters:
---  * lists - A table or list of lists.
---
--- Returns:
---  * A list of lists.
function mod.zipAll(...)
    local results = {}
    local inputs = packArgs(...)
    local maxSize = _maxListSize(inputs)
    if maxSize == 0 then
        return results
    end

    for i = 1, maxSize do
        local value = {}
        for j,list in ipairs(inputs) do
            value[j] = list[i]
        end
        results[i] = value
    end

    return results
end

-- ========================================================================
-- Predicates
-- ========================================================================

--- cp.fn.table.isEmpty(table) -> boolean
--- Function
--- Returns `true` if the table is empty.
---
--- Parameters:
---  * table - The table to check.
---
--- Returns:
---  * `true` if the table is empty, otherwise `false`.
function mod.isEmpty(table)
    return not next(table)
end

--- cp.fn.table.isNotEmpty(table) -> boolean
--- Function
--- Returns `true` if the table is not empty.
---
--- Parameters:
---  * table - The table to check.
---
--- Returns:
---  * `true` if the table is not empty, otherwise `false`.
function mod.isNotEmpty(table)
    return next(table) ~= nil
end

--- cp.fn.table.hasAtLeast(count) -> function(table) -> boolean
--- Function
--- Returns a function that checks if the table has at least the given number of items.
---
--- Parameters:
---  * count - The number of items to check for.
---
--- Returns:
---  * A function that takes a table and returns `true` if the table has at least the given number of items, otherwise `false`.
function mod.hasAtLeast(count)
    return function(table)
        return #table >= count
    end
end

--- cp.fn.table.hasAtMost(count) -> function(table) -> boolean
--- Function
--- Returns a function that checks if the table has at most the given number of items.
---
--- Parameters:
---  * count - The number of items to check for.
---
--- Returns:
---  * A function that takes a table and returns `true` if the table has at most the given number of items, otherwise `false`.
function mod.hasAtMost(count)
    return function(table)
        return #table <= count
    end
end

--- cp.fn.table.hasExactly(count) -> function(table) -> boolean
--- Function
--- Returns a function that checks if the table has exactly the given number of items.
---
--- Parameters:
---  * count - The number of items to check for.
---
--- Returns:
---  * A function that takes a table and returns `true` if the table has exactly the given number of items, otherwise `false`.
function mod.hasExactly(count)
    return function(table)
        return #table == count
    end
end

--- cp.fn.table.hasMoreThan(count) -> function(table) -> boolean
--- Function
--- Returns a function that checks if the table has more than the given number of items.
---
--- Parameters:
---  * count - The number of items to check for.
---
--- Returns:
---  * A function that takes a table and returns `true` if the table has more than the given number of items, otherwise `false`.
function mod.hasMoreThan(count)
    return function(table)
        return #table > count
    end
end

--- cp.fn.table.hasLessThan(count) -> function(table) -> boolean
--- Function
--- Returns a function that checks if the table has less than the given number of items.
---
--- Parameters:
---  * count - The number of items to check for.
---
--- Returns:
---  * A function that takes a table and returns `true` if the table has less than the given number of items, otherwise `false`.
function mod.hasLessThan(count)
    return function(table)
        return #table < count
    end
end

--- cp.fn.table.hasValue(key[, predicate]) -> function(table) -> boolean
--- Function
--- Returns a function that checks if the table has a value at the specified `key`. If a predicate is provided, the value is checked using the predicate.
---
--- Parameters:
---  * key - The value to check for.
---  * predicate - An optional predicate to use to check the value.
---
--- Returns:
---  * A function that takes a table and returns `true` if the table has the given value, otherwise `false`.
function mod.hasValue(key, predicate)
    predicate = predicate or is.something
    return function(t)
        return predicate(t[key])
    end
end

return mod