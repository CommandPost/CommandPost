--- === cp.fn ===
---
--- A collection of functions that are useful for working with functions.
--- Heavily inspired by Point-Free's [Overture](https://github.com/pointfreeco/swift-overture) library for Swift.
---
--- In general, the functions in this module come in two categories:
---
--- 1. Functions which perform an action directly.
--- 2. Functions which return a new function.
---
--- The second category of functions are called "combinators". A combinator is a function that returns a new function,
--- often with configuration parameters passed in.

local require               = require

local log                   = require "hs.logger".new "cp.fn"
local inspect               = require "cp.dev" .inspect

local fnutils               = require "hs.fnutils"
local is                    = require "cp.is"

local pack                  = table.pack
local unpack                = table.unpack
local insert                = table.insert

local isTable               = is.table
local isCallable            = is.callable

local fnargs                = require "cp.fn.args"
local packArgs, unpackArgs  = fnargs.pack, fnargs.unpack
local hasNone               = fnargs.hasNone

-- the list of submodules that can be loaded dynamically.
local submodules = {"args", "ax", "prop", "string", "table", "value"}

local mod = {}
setmetatable(mod, {
    -- allows loading permitted submodules as properties of `cp.fn`.
    __index = function(t, k)
        if fnutils.contains(submodules, k) then
            local submodule = require("cp.fn." .. k)
            t[k] = submodule
            return submodule
        end
    end,
})

-- ============================================================================
-- Functions
-- ============================================================================

--- cp.fn.all(fns | ...) -> function(...) -> any | nil
--- Function
--- A combinator that returns a function that passes its arguments to all the functions in `fns` and
--- returns the last result, if all functions return a `truthy` value.
--- Otherwise, it returns `nil`.
---
--- Parameters:
---  * fns | ... - A table or list of functions to call.
---
--- Returns:
---  * A function that passes its arguments to all the functions in `fns` and returns the last result, if all functions return a `truthy` value.
function mod.all(...)
    local fns = packArgs(...)
    local fnCount = #fns
    if fnCount == 0 then
        return function() end
    elseif fnCount == 1 then
        return fns[1]
    end
    return function(...)
        local result = {}
        for i = 1, fnCount do
            local fn = fns[i]
            result = pack(fn(...))
            if #result == 0 or not result[1] then
                return unpack(result)
            end
        end
        return unpack(result)
    end
end

--- cp.fn.any(fns | ...) -> function(...) -> any | nil
--- Function
--- A combinator that returns a function that passes its arguments to all the functions in
--- `fns` and returns the first `truthy` result, or `nil` if all functions return a `falsy` value.
---
--- Parameters:
---  * fns | ... - A table or list of functions to call.
---
--- Returns:
---  * A function that passes its arguments to all the functions in `fns` and returns the first `truthy` result,
---    or `nil` if all functions return a 'falsy' value.
function mod.any(...)
    local fns = packArgs(...)
    local fnCount = #fns
    if fnCount == 0 then
        return function() end
    elseif fnCount == 1 then
        return fns[1]
    end
    return function(...)
        local result = nil
        for i = 1, fnCount do
            local fn = fns[i]
            result = pack(fn(...))
            if #result > 0 and result[1] then
                return unpack(result)
            end
        end
        return unpack(result)
    end
end

--- cp.fn.none(fns | ...) -> function(...) -> any | nil
--- Function
--- A combinator that returns a function that passes its arguments to all the functions in `fns` and
--- returns `true` if the first return value from each is `falsey`, otherwise it returns `false`.
---
--- Parameters:
---  * fns | ... - A table or list of functions to call.
---
--- Returns:
---  * A function which will be `true` if all of the functions in `fns` are `falsy`.
function mod.none(...)
    local fns = packArgs(...)
    local fnCount = #fns
    if fnCount == 0 then
        return function() return true end
    end
    return function(...)
        for i = 1, fnCount do
            local fn = fns[i]
            local result = pack(fn(...))
            if #result > 0 and result[1] then
                return false
            end
        end
        return true
    end
end

--- cp.fn.fork(...) -> function(value) -> ...
--- Function
--- A combinator that returns a function that returns the result of calling `...` with the functions passed in.
--- This can be used to split an input into multiple outputs.
---
--- Parameters:
---  * ... - A table or list of functions to call.
---
--- Returns:
---  * A function that returns the result of calling `...` with the functions passed in.
function mod.fork(...)
    local fns, packed = packArgs(...)
    local fnCount = #fns
    if fnCount == 0 then
        return function() end
    elseif fnCount == 1 then
        return fns[1]
    end
    return function(...)
        local result = {}
        for i = 1, fnCount do
            local fn = fns[i]
            for _, v in ipairs(pack(fn(...))) do
                insert(result, v)
            end
        end
        return unpackArgs(result, packed)
    end
end

--- cp.fn.call(fn) -> ...
--- Function
--- Calls the function `fn` with no arguments, returning the result.
---
--- Parameters:
---  * fn - The function to call.
---  * ... - The arguments to pass to the function.
---
--- Returns:
---  * The results of the function call.
function mod.call(fn)
    return fn()
end

--- cp.fn.compare(...) -> function(...) -> boolean
--- Function
--- A combinator that returns a function that checks each provided comparator in turn,
--- returning `true` if the given comparator returns `true`, otherwise if the values are equal,
--- checks the next comparator, and so on.
---
--- Parameters:
---  * ... - A list of comparators.
---
--- Returns:
---  * A function that takes two inputs and `true` if the first input is less than the second input.
---
--- Notes:
---  * The comparators are called in the order they are provided.
---  * If no comparators are provided, this will return `nil`.
function mod.compare(...)
    local comparators = packArgs(...)
    if #comparators == 0 then
        return
    elseif #comparators == 1 then
        return comparators[1]
    end

    return function(a, b)
        local previousComparator = nil
        for _, comparator in ipairs(comparators) do
            -- if the previous comparator says b is before a, they are not equal, so return false
            if previousComparator and previousComparator(b, a) then
                return false
            end
            -- if the comparator is true, then a is before b
            if comparator(a, b) then
                return true
            end
            -- we don't know if a and b are equal, so save the comparator for later
            previousComparator = comparator
        end
        return false
    end
end

--- cp.fn.compose(fns | ...) -> function(...) -> ...
--- Function
--- A combinator that performs backwards composition of functions, returning a function that
--- is the composition of a list of functions processed from last to first.
---
--- Parameters:
---  * fns | ... - A table or a list of functions.
---
--- Returns:
---  * A function that takes the input for the last function, and returns the result of the first function.
function mod.compose(...)
    local fns = packArgs(...)
    return function(...)
        local inputs = pack(...)
        for i = #fns, 1, -1 do
            inputs = pack(fns[i](unpack(inputs)))
        end
        return unpack(inputs)
    end
end

--- cp.fn.constant(value) -> function(...) -> value
--- Function
--- A combinator that returns a function that always returns the `value`.
---
--- Parameters:
---  * value - The value to return.
---
--- Returns:
---  * A function that always returns the value `value`.
function mod.constant(value)
    return function()
        return value
    end
end

-- _curryWith(fn, argCount, ...) -> function
-- Function
-- Curries a function with the given number of arguments.
--
-- Parameters:
--  * fn - The function to curry.
--  * argCount - The number of arguments the function is expecting
--  * ... - The current collection of arguments to pass to the function.
--
-- Returns:
--  * A function that takes one argument, and returns a function which either takes the next argument, or returns the result of the function.
local function _curryWith(fn, argCount, ...)
    local actualCount = select("#", ...)
    if actualCount == argCount then
        return fn(...)
    end
    local args = pack(...)
    return function(value)
        local newArgs = { unpack(args) }
        newArgs[actualCount + 1] = value
        return _curryWith(fn, argCount, unpack(newArgs))
    end
end

--- cp.fn.curry(fn(a1, a2, ..., an), argCount) -> function(a1) -> function(a2) -> ... -> function(an) -> any
--- Function
--- Curries a function with the specified number of arguments, returning a function that accepts the first
--- argument. It will return other functions that accept the second argument, and so on, until the final argument is collected,
--- and the values are passed to the original function.
---
--- Parameters:
---  * fn - The function to curry.
---  * argCount - The number of arguments to accept.
---
--- Returns:
---  * A function that accepts the first argument.
function mod.curry(fn, argCount)
    if argCount <= 1 then return fn end

    return _curryWith(fn, argCount)
end

--- cp.fn.flip(fn) -> function(...) -> function(...) -> any
--- Function
--- A cobinator that flips the order of the next two arguments to a curried function.
---
--- Parameters:
---  * fn - The function to flip.
---
--- Returns:
---  * A function that accepts the second argument and returns
---     a function expecting the first argument.
function mod.flip(fn)
    return function(...)
        local args = pack(...)
        return function(...)
            return fn(...)(unpack(args))
        end
    end
end

--- cp.fn.identity(...) -> ...
--- Function
--- Returns the values passed in.
---
--- Parameters:
---  * ... - The values to return.
---
--- Returns:
---  * The values passed in.
function mod.identity(...)
    return ...
end

--- cp.fn.over(setter, fn) -> function
--- Function
--- A combinator that returns a function that applies the transform function to the `setter`.
---
--- Parameters:
---  * setter - An immutable setter function.
---  * tx - A value transform function.
---
--- Returns:
---  * A root transform function.
function mod.over(setter, tx)
    return setter(tx)
end

--- cp.fn.pipe(fns | ...) -> function(...) -> ...
--- Function
--- A combinator that pipes a series of functions together, passing the results of each function on to the next one.
--- The returned function takes any number of inputs and may return any number of inputs,
--- depending on the results of the final function.
---
--- Parameters:
---  * fns |... - A table or list of functions.
---
--- Returns:
---  * A function that takes any number of inputs and returns any number of inputs.
---
--- Notes:
---  * The difference between `chain` and `pipe` is that chain will fail early with a `nil` result, while `pipe` will pass the `nil` onto the next function.
function mod.pipe(...)
    local fns = packArgs(...)
    return function(...)
        local inputs = pack(...)
        for _, fn in ipairs(fns) do
            inputs = pack(fn(unpack(inputs)))
        end
        return unpack(inputs)
    end
end

-- TODO: Figure out the common name for `prefix` in functional programming. Similar to `with`.

--- cp.fn.prefix(fn, ...) -> function(...) -> ...
--- Function
--- Prefixes the provided values as the first arguments to the function.
---
--- Parameters:
---  * fn - The function to prefix.
---  * ... - The arguments to prefix the function with.
---
--- Returns:
---  * A function that takes the remainder of `fn`'s arguments and returns the result of `fn` with the provided arguments prepended.
function mod.prefix(fn, ...)
    local argCount = select("#", ...)
    local args = pack(...)
    return function(...)
        local inputs = {}
        for i = 1, argCount do
            inputs[i] = args[i]
        end
        for i = 1, select("#", ...) do
            inputs[i + argCount] = select(i, ...)
        end
        return fn(unpack(inputs))
    end
end

--- cp.fn.reduce(fn, initial, values | ...) -> any
--- Function
--- Reduces a list of values into a single value.
---
--- Parameters:
---  * fn - The function to reduce with.
---  * initial - The initial value to start with.
---  * values | ... - The table or list of values to reduce.
---
--- Returns:
---  * The reduced value.
function mod.reduce(fn, initial, ...)
    local inputs = packArgs(...)
    local result = initial
    for _, value in ipairs(inputs) do
        result = fn(result, value)
    end
    return result
end

--- cp.fn.resolve(value, ...) -> any
--- Function
--- If the value is a function, calls it with the provided arguments, otherwise returns the value.
---
--- Parameters:
---  * value - The value to resolve.
---  * ... - The arguments to pass to the function.
---
--- Returns:
---  * The resolved value.
function mod.resolve(value, ...)
    if isCallable(value) then
        return value(...)
    end
    return value
end

--- cp.fn.set(setter, value) -> function
--- Function
--- Applies a value to an immutable `setter` function.
---
--- Parameters:
---  * setter - An immutable setter function (function(A -> B) -> function(S) -> T)
---  * value - A new value.
---
--- Returns:
---  * A root transform function.
function mod.set(setter, value)
    return mod.over(setter, function(_) return value end)
end

-- _uncurryWith(fn, argCount) -> function
-- Function
-- Returns a function that accepts the specified number of arguments, passing them to the original
-- curried function and the subsequently returned functions.
--
-- Parameters:
--  * fn - The function to uncurry.
--  * argCount - The number of arguments to accept.
--
-- Returns:
--  * A function that accepts the specified number of arguments.
local function _uncurryWith(fn, argCount)
    if argCount <= 1 then return fn end

    return function(value, ...)
        return _uncurryWith(fn(value), argCount - 1)(...)
    end
end

--- cp.fn.uncurry(fn, argCount) -> function
--- Function
--- Uncurry a curried function with the specified number of arguments, returning a function the specified number of arguments.
---
--- Parameters:
---  * fn - The function to uncurry.
---  * argCount - The number of arguments to uncurry.
---
--- Returns:
---  * A function that takes the specified number of arguments.
function mod.uncurry(fn, argCount)
    if argCount <= 1 then return fn end

    return _uncurryWith(fn, argCount)
end

--- cp.fn.with(value, fn) -> function(...) -> ...
--- Function
--- A combinator that returns a function that will call the provided function with the provided value as the first argument.
---
--- Parameters:
---  * value - The value to pass to the function.
---  * fn - The function to call.
---
--- Returns:
---  * A function that will call the provided function with the provided value as the first argument.
function mod.with(value, fn)
    return function(...)
        return fn(value, ...)
    end
end

-- ============================================================================
-- Operator Functions
-- ============================================================================

-- A key for retrieving the original function from wrapper tables.
local FN = {}

-- _callable(value) -> function
-- Function
-- Returns the function from the value.
-- If the value is a chain_link, it returns the function from the chain_link.
-- If the value is callable, return the value.
-- Otherwise, return `nil`.
--
-- Parameters:
--  * value - The value to get the function from.
--
-- Returns:
--  * The function from the value.
local function _callable(value)
    if isTable(value) and value[FN] then
        return value[FN]
    elseif isCallable(value) then
        return value
    else
        error("Expected a callable value but got " .. tostring(value), 3)
    end
end

-- _callIfHasArgs(fn, ...) -> ...
-- Function
-- Calls the function `fn` with the arguments `...` if the function has arguments.
-- If not, it returns `nil`.
--
-- Parameters:
--  * fn - The function to call.
--  * ... - The arguments to pass to the function.
--
-- Returns:
--  * The results of the function call, or nothing if the function has no arguments.
local function _callIfHasArgs(fn, ...)
    if hasNone(...) then return end
    return fn(...)
end

-- ============================================================================
-- chain
-- ============================================================================

-- _chain2(a, b) -> function(...) -> any
-- Function
-- Returns a function that calls `a` with the arguments `...`. If `a` returns any values, it calls `b` with the results of `a`.
-- Otherwise, it does not call `b` and returns `nil`.
--
-- Parameters:
--  * a - The first function to call.
--  * b - The second function to call.
--
-- Returns:
--  * A function that chains `a` with `b`.
local function _chain2(a, b)
    return function(...)
        return _callIfHasArgs(b, a(...))
    end
end

-- _chainN(...) -> function(...) -> any
-- Function
-- Returns a function which will chain each function in `...` together.
-- If any of the functions does not return any values, it will return `nil`
-- and not call any further functions in the chain.
--
-- Parameters:
--  * ... - A list of functions to call.
--
-- Returns:
--  * A function that chains each function in `...` together.
local function _chainN(a, b, ...)
    if not a then
        -- return values unchanged
        return function(...) return ... end
    end
    if not b then
        return a
    end
    return _chainN(_chain2(a, b), ...)
end

-- chain_link is the metatable for tables returned when creating linked chains via the `//` and `>>` operators.
local chain_link = {}

-- new_chain_link(fn) -> table
-- Constructor
-- Creates a new table that represents a chain link.
--
-- Parameters:
--  * fn - The function to call.
--
-- Returns:
--  * A new table that represents a chain link.
local function new_chain_link(fn)
    return setmetatable({[FN] = fn}, chain_link)
end

-- chain.link >> function(...) -> chain.link
-- Operator
-- Receives a function and returns a chain.link
function chain_link.__shr(left, right)
    left = _callable(left)
    right = _callable(right)
    return new_chain_link(_chain2(left, right))
end

-- chain.link(...) -> any
-- Method
-- Returns the result of the chained functions.
--
-- Parameters:
--  * ... - The arguments for the chained functions.
--
-- Returns:
--  * The result of the chained functions.
function chain_link:__call(...)
    return self[FN](...)
end

-- internal table for the chain functions
local chain = setmetatable({}, {
    -- allows the table to be called like a function.
    __call = function(_, ...) return _chainN(...) end,

    -- allow using `//` to chain functions.
    __idiv = function(_, right)
        return new_chain_link(_callable(right))
    end
})

--- cp.fn.chain(...) -> function(...) -> ...
--- Function
--- Chain a series of functions together, passing the results of each function on to the next one, returning the last result,
--- or returning `nil` immediately after all results of a function are `nil`.
---
--- Parameters:
---  * ... - A list of functions.
---
--- Returns:
---  * A function that takes any number of inputs and returns any number of inputs.
---
--- Notes:
---  * The difference between `chain` and `pipe` is that chain will fail early with a `nil` result, while `pipe` will pass the `nil` onto the next function.
---  * Alternately, you can create a chain using the `//` operator, followed by `>>` for each subsequent function. Eg: `chain // fn1 >> fn2 >> fn3`.
---  * If using the alternate syntax, you may have to put parentheses around the chain if mixing with other operators like `pipe` or `compose`.
mod.chain = chain

-- ============================================================================
-- Debugging
-- ============================================================================

--- cp.fn.debug(message, ...) -> function(...) -> ...
--- Function
--- Returns a function that will print the provided message to the console.
--- Optional functions can be passed in, which will be provided the values passed to the returned function.
--- If not provided, the values will be passed into the message for formatting directly.
--- The returned function will always return the values passed in.
---
--- Parameters:
---  * message - The message to print to the console.
---  * ... - Optional functions to call with the values passed to the returned function.
---
--- Returns:
---  * A function that will print the provided message to the console.
---
--- Notes:
---  * This is useful for debugging, but is not recommended for production code.
---  * For example, the following will return "b" and also print `"table: 0xXXXXXXXXX"` and `"b"` to the console:
---    `fn.chain // fn.constant({"a", "b", "c"}) >> fn.debug("%d") >> fn.table.get(2) >> fn.debug("%d")`
function mod.debug(message, ...)
    local args = pack(...)
    return function(...)
        local values = pack(...)
        -- if present, use the matching function to process each value
        for i,arg in ipairs(args) do
            values[i] = arg(values[i])
        end
        -- print the message
        log.df(message, unpack(values))
        -- return the values
        return ...
    end
end

-- cp.fn.inspect(options) -> function(value) -> string
-- Function
-- Returns a function that will inspect the value and return a string.
--
-- Parameters:
--  * options - The options to use when inspecting the value.
--
-- Returns:
--  * A function that will inspect the value and return a string.
function mod.inspect(options)
    options = options or {depth=2}
    return function(value)
        return inspect(value, options)
    end
end

-- private functions, for testing.
mod._private = {
    _chain2 = _chain2,
    _chainN = _chainN,
    _callIfHasArgs = _callIfHasArgs,
}

return mod