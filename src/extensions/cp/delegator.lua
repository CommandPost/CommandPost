--- === cp.delegator ===
---
--- `cp.delegator` is a [middleclass](https://github.com/kikito/middleclass) "mix-in" that allows for
--- simple specification of "delegated" values and functions in class definitions.
---
--- This allows you to compose an object from other objects, but allow methods or values from the
--- composed values to be accessed directly via the composing parent object.
---
--- For example:
---
--- ```lua
--- local class = require "middleclass"
--- local delegator = require "cp.delegator"
---
--- local Minion = class("Minion")
---
--- function Minion:doTask()
---    -- does something...
---    return true
--- end
---
--- local Boss = class("Boss"):include(delegator):delegateTo("minion")
---
--- function Boss:initialize()
--- end
---
--- function Boss:hireMinion(minion)
---     self.minion = minion
--- end
---
--- local johnSmith = Boss()
--- local joeBloggs = Minion()
---
--- johnSmith:doTask() -- error: no 'doTask' method available.
---
--- johnSmith:hireMinion(minion)
--- johnSmith:doTask() -- can now do the task, because his minion does it for him.
--- johnSmith.minion:doTask() -- The exact same thing.
--- ```
---
--- The order that `delegator` is included with other mixins can affect how it functions. For example,
--- when mixing with `cp.lazy`, if `cp.lazy` is mixed in second, like so:
---
--- ```lua
--- local MyClass = class("MyClass"):include(delegator):include(lazy):delegateTo("delegate")
---
--- function MyClass:initialize()
---     self.delegate = {
---         value = "delegated value"
---     }
--- end
---
--- function MyClass.lazy.value()
---     return "lazy value"
--- end
---
--- local myInstance = MyClass()
--- assert(myInstance.value == "delegated value") -- passes
--- assert(myInstance.delegated.value == "delegated value") -- passes
--- ```
---
--- ...then any delegated methods will take priority over lazy ones. Most likely you want to put `lazy` first, like so:
---
--- ```lua
--- local MyClass = class("MyClass"):include(lazy):include(delegator):delegateTo("delegate")
---
--- function MyClass:initialize()
---     self.delegate = {
---         value = "delegated value"
---     }
--- end
---
--- function MyClass.lazy.value()
---     return "lazy value"
--- end
---
--- local myInstance = MyClass()
--- assert(myInstance.value == "lazy value") -- passes
--- assert(myInstance.delegated.value == "delegated value") -- passes
--- ```
---
--- The easy way to remember is to read them together - "lazy delegator" sounds better than "delegator lazy".

-- local log           = require "hs.logger" .new("delegator")

local prop          = require "cp.prop"
local insert        = table.insert

local delegator = {}

delegator.static = {}

local DELEGATES = {}

-- _initDelegateStatics(klass, superDelegates) -> nil
-- Function
-- Initialises the `delegates` table in the provided `klass`, ensuring that any lazy configurations are inherited if provided.
--
-- Parameters:
-- * klass      - The middleclass `class` to augment.
-- * superDelegates  - The `delegates` table from the superclass, if available.
--
-- Returns:
-- * The class instance
local function _initDelegated(klass)
    local delegates = {}

    klass.static[DELEGATES] = delegates

    function klass.static:delegateTo(...)
        local myDelegates = self[DELEGATES]
        for i = 1,select("#", ...) do
            local value = select(i, ...)
            insert(myDelegates, value)
        end

        return klass
    end
end

local function _getDelegate(instance, key)
    local delegate = instance[key]
    local delegateType = type(delegate)

    if delegateType == "function" then
        delegate = delegate(instance)
    elseif prop.is(delegate) then
        delegate = delegate:get()
    end

    return delegate
end

-- _getDelegatedResult(instance, name[], klass]) -> anything
-- Function
-- Goes through the list of delegates and
--
-- Parameters:
-- * instance       - The instance to check.
-- * name           - The key to check for.
-- * klass          - The `class` to search in (optional). If none is provided, the instance class is used.
--
-- Returns:
-- * The value or `function`, depending on the factory type.
local function _getDelegatedResult(instance, name, klass)

    klass = klass or instance.class
    local delegates = klass.static[DELEGATES]

    local value = rawget(instance, name)

    if not value then
        for _,key in ipairs(delegates) do
            if key ~= name then
                local delegate = _getDelegate(instance, key)

                if delegate then
                    value = delegate[name]

                    if type(value) == "function" then
                        -- we wrap the function so that we can redirect to the delegate when appropriate.
                        local fn = value
                        value = function(self, ...)
                            if self == instance then
                                -- it's getting called as a method with the instance as `self` so redirect it to the delegate.
                                return fn(delegate, ...)
                            else
                                -- it's probably a direct function call
                                return fn(self, ...)
                            end
                        end
                        -- cache it for future access.
                        rawset(instance, name, value)
                    end

                    if prop.is(value) then
                        -- wrap it so it can get called directly.
                        value = value:wrap(instance):label(name)
                        -- cache it for future access.
                        rawset(instance, name, value)
                    end

                    if value then
                        return value
                    end
                end
            end
        end

        if klass.super then
            -- check the super-class hierarchy.
            value = _getDelegatedResult(instance, name, klass.super)
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
    local indexType = type(prevIndex)
    if indexType == 'function' then
        return function(instance, name) return prevIndex(instance, name) or _getDelegatedResult(instance, name) end
    elseif indexType == 'table' then
        return function(instance, name) return prevIndex[name] or _getDelegatedResult(instance, name) end
    else
        return _getDelegatedResult
    end
end

-- _modifyInstanceIndex(klass) -> nothing
-- Function
-- Updates the `__index` function to the wrapper for delegator.
--
-- Parameters:
-- * klass      - The middleclass `class` instance to modify.
local function _modifyInstanceIndex(klass)
    klass.__instanceDict.__index = _getNewInstanceIndex(klass.__instanceDict.__index)
end

-- _newSublassMethod(prevSubclass) -> function
-- Function
-- Creates a wrapper function to replace the existing `subclass` method to pass on delegations.
--
-- Parameters:
-- * prevSubclass       - The previous `subclass` function/method
local function _getNewSubclassMethod(prevSubclass)
    return function(klass, name)
        local subclass = prevSubclass(klass, name)
        _initDelegated(subclass, klass.static[DELEGATES])
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
function delegator:included(klass) -- luacheck: ignore
    _initDelegated(klass)
    _modifyInstanceIndex(klass)
    _modifySubclassMethod(klass)
end

return delegator