--- === cp.lazy ===
---
--- `cp.lazy` is a [middleclass](https://github.com/kikito/middleclass) "mix-in" that allows for
--- simple specification of "lazy-loaded" values and functions in class definitions.
---
--- Some values and function results in classes are only created once, and may never be created,
--- depending on what happens in the class's lifetime.
---
--- In these cases, it is useful to have the value created on demand, rather than when the instance
--- is initialised.
---
--- For methods, this can be done like so with standard Lua code:
---
--- ```lua
--- local class = require "middleclass"
---
--- local MyClass = class("MyClass")
--- function MyClass:expensiveThing()
---     if self._expensiveThing == nil then
---         self._expensiveThing = ExpensiveThing.new()
---     end
---     return self._expensiveThing
--- end
---
--- local myThing = MyClass()
--- local myExpensiveThing = myThing:expensiveThing()
--- ```
---
--- For values, it is much trickier, and involves overriding the `metatable.__init` function. Which is
--- what this mix-in does for you. It allows you to provide a factory function which will be called just
--- once in the object's lifetime, and the result is stored for future calls.
---
--- To create a lazy `function` or method, do the following:
---
--- ```lua
--- local class     = require "middleclass"
--- local lazy      = require "cp.lazy"
---
--- local MyClass = class("MyClass"):include(lazy)
--- function MyClass.lazy.method:expensiveThing()
---     return someObject.new()
--- end
---
--- local myThing = MyClass()
--- local myExpensiveThing = myThing:expensiveThing()
--- ```
---
--- To create a lazy `value`, it's the same, except applied to the `value` table:
---
--- ```lua
--- local class     = require "middleclass"
--- local lazy      = require "cp.lazy"
---
--- local MyClass = class("MyClass"):include(lazy)
--- function MyClass.lazy.value:expensiveThing()
---     return someObject.new()
--- end
---
--- local myThing = MyClass()
--- local myExpensiveThing = myThing.expensiveThing
--- ```
---
--- Note that it is a 'method' function, so you can use `self` to refer to the specific instance
--- that the result will be applied to. The factory function is also passed the key value the
--- result is getting applied to as the next parameter, so you can do something like this:
---
--- ```lua
--- function lookup(instance, key)
---     return instance:expensiveLookup(key)
--- end
--- MyClass.lazy.method.oneThing = lookup
--- MyClass.lazy.method.otherThing = lookup
--- ```
---
--- The `expensiveLookup` function would only get called once for each method, caching the result for future calls.
---
--- You can also create [cp.prop](cp.prop.md) values:
---
--- ```lua
--- function MyClass.lazy.prop.enabled()
---     return prop.TRUE()
--- end
--- ```
---
--- It is very similar to the `value` factory, but the returned `cp.prop` will be automatically bound
--- to the new instance and labeled with the key ("enabled" in the example above).

local prop          = require "cp.prop"
local format        = string.format

local lazy = {}

lazy.static = {}

-- _initLazyStatics(klass, superLazy) -> nil
-- Function
-- Initialises the `lazy` table in the provided `klass`, ensuring that any lazy configurations are inherited if provided.
--
-- Parameters:
-- * klass      - The middleclass `class` to augment.
-- * superLazy  - The `lazy` table from the superclass, if available.
--
-- Returns:
-- * Nothing
local function _initLazyStatics(klass, superLazy)
    local lzy
    lzy = {
        value = {},
        method = {},
        prop = {},
    }

    local function checkKey(key)
        for k,v in pairs(lzy) do
            if rawget(v, key) then
                error(format("There is already a lazy %s value factory for %q", k, key))
            end
        end
    end

    setmetatable(lzy.value, {
        __newindex = function(self, key, value)
            checkKey(key)
            rawset(self, key, value)
        end,
        __index = superLazy and superLazy.value,
    })

    setmetatable(lzy.method, {
        __newindex = function(self, key, value)
            checkKey(key)
            rawset(self, key, value)
        end,
        __index = superLazy and superLazy.method
    })

    setmetatable(lzy.prop, {
        __newindex = function(self, key, value)
            checkKey(key)
            rawset(self, key, value)
        end,
        __index = superLazy and superLazy.prop
    })

    klass.static.lazy = lzy
end

-- _getLazyResults(instance, name) -> anything
-- Function
-- Checks if there is a `lazy` factory function for the specified name, and if so returns
-- either the `value` or `method` function for that result.
--
-- Parameters:
-- * instance       - The instance to check.
-- * name           - The key to check for.
--
-- Returns:
-- * The value or `function`, depending on the factory type.
local function _getLazyResults(instance, name)
    local klass = instance.class
    local lzy = instance and klass.lazy
    local value
    if lzy.value[name] then
        value = lzy.value[name](instance, name)
        rawset(instance, name, value)
    elseif lzy.method[name] then
        local result = lzy.method[name](instance, name)
        value = function() return result end
        rawset(instance, name, value)
    elseif lzy.prop[name] then
        value = lzy.prop[name](instance, name)
        if prop.is(value) then
            local owner = value:owner()
            if owner and owner ~= instance then
                value = value:wrap()
            end
            rawset(instance, name, value)
            value:bind(instance, name)
        else
            error(format("Expected a cp.prop for the lazy prop named '%s', but got %s", name, value))
        end
    end
    return value
end

-- _getNewInstanceIndex(prevIndex) -> function
-- Function
-- Creates a wrapper function around the previous `__index` metatable function which adds lazy lookups.
--
-- Parameters:
-- * prevIndex  - The previous `__index` function or table.
--
-- Returns:
-- * The new `__index` `function`.
local function _getNewInstanceIndex(prevIndex)
    if type(prevIndex) == 'function' then
        return function(instance, name) return prevIndex(instance, name) or _getLazyResults(instance, name) end
    end
    return function(instance, name) return prevIndex[name] or _getLazyResults(instance, name) end
end

-- _modifyInstanceIndex(klass) -> nothing
-- Function
-- Updates the `__index` function to the wrapper for lazy.
--
-- Parameters:
-- * klass      - The middleclass `class` instance to modify.
local function _modifyInstanceIndex(klass)
    klass.__instanceDict.__index = _getNewInstanceIndex(klass.__instanceDict.__index)
end

-- _newSublassMethod(prevSubclass) -> function
-- Function
-- Creates a wrapper function to replace the existing `subclass` method to pass on lazy configurations.
--
-- Parameters:
-- * prevSubclass       - The previous `subclass` function/method
local function _getNewSubclassMethod(prevSubclass)
    return function(klass, name)
        local subclass = prevSubclass(klass, name)
        _initLazyStatics(subclass, klass.static.lazy)
        _modifyInstanceIndex(subclass)
        return subclass
    end
end

-- _modifySubclassMethod(klass) -> nothing
-- Function
-- Modifies the `subclass` method to add lazy factory support to subclasses.
local function _modifySubclassMethod(klass)
    klass.static.subclass = _getNewSubclassMethod(klass.static.subclass)
end

-- initialises the provided class when it includes the `lazy` mix-in.
function lazy:included(klass) -- luacheck: ignore
    _initLazyStatics(klass)
    _modifyInstanceIndex(klass)
    _modifySubclassMethod(klass)
end

return lazy