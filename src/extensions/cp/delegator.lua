--- === cp.delegated ===
---
--- `cp.delegated` is a [middleclass](https://github.com/kikito/middleclass) "mix-in" that allows for
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
--- local Boss = class("Boss"):extends(delegator)
--- Boss.delegateTo("minion")
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
--- Delegates can be hard-coded into the class type, or set later.

-- local log           = require "hs.logger".new("lazy")

local prop          = require "cp.prop"
local format        = string.format
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
-- * Nothing
local function _initDelegateTo(klass)
    if klass.static.delegates then
        error("An existing static `delegates` already exists.")
    end
    if klass.static.delegateTo then
        error("An existing static `delegateTo` function already exists.")
    end

    local delegates = {}

    klass.static[DELEGATES] = delegates
    function klass.static.delegateTo(...)
        for i = 1,select("#", ...) do
            insert(delegates, select(i, ...))
        end
    end
end

-- _getDelegatedResult(instance, name) -> anything
-- Function
-- Goes through the list of delegates and
--
-- Parameters:
-- * instance       - The instance to check.
-- * name           - The key to check for.
--
-- Returns:
-- * The value or `function`, depending on the factory type.
local function _getDelegatedResult(instance, name)
    local klass = instance.class
    local delegates = instance and klass[DELEGATES]

    local value = instance[name]

    if not value then
        for _,key in ipairs(delegates) do
            local delegate = delegates[key]
            local delegateType = type(delegate)

            if delegateType == "function" then
                delegate = delegate()
            elseif prop.is(delegate) then
                delegate = prop()
            end

            if delegate then
                value = delegate[name]

                if value then
                    break
                end
            end
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
        return function(instance, name) return prevIndex(instance, name) or _getDelegatedResult(instance, name) end
    end
    return function(instance, name) return prevIndex[name] or _getDelegatedResult(instance, name) end
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
        _initDelegateTo(subclass, klass.static.lazy)
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
    _initDelegateTo(klass)
    _modifyInstanceIndex(klass)
    _modifySubclassMethod(klass)
end

return delegator