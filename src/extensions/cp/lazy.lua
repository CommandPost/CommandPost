--- === cp.lazy ===
---
--- Lazy Extension.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
-- local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log               = require("hs.logger").new("lazy")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
-- local inspect           = require("hs.inspect")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local format            = string.format

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- FACTORY -> table
-- Constant
-- Factory table.
local FACTORY = {}

-- FUNCTION -> string
-- Constant
-- Function string.
local FUNCTION = "function"

-- VALUE -> string
-- Constant
-- Value string.
local VALUE = "value"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

local setFactory, getFactory, getMetaFactory

setFactory = function(target, factory)
    rawset(target, FACTORY, factory)
end

getMetaFactory = function(owner)
    local mt = getmetatable(owner)
    local factory
    if mt then
        local index = mt.__index
        if type(index) == "table" then
            -- try pulling it from the __index table
            factory = getFactory(index)
        end

        if not factory then
            -- try getting it from the metatable itself
            factory = getFactory(mt)
        end
    end
    return factory
end

getFactory = function(owner)
    if type(owner) ~= "table" then
        return nil
    end
    local factory = rawget(owner, FACTORY)
    if not factory then
        factory = getMetaFactory(owner)
    end
    return factory
end

-- creates a new factory
local function newFactory(owner)
    return setmetatable({}, {
        __index = getMetaFactory(owner),
    })
end

-- This basically looks up the factory method and then assigns the created value to the target.
local function lazyIndex(index)
    return function(self, key)
        if key == FACTORY then
            -- don't bother looking
            return nil
        end

        -- check the factory functions.
        local factory = getFactory(self)
        if factory then
            local item = factory[key]
            if item then
                -- we have a factory
                local value
                local realValue = item.new(self)
                if item.type == FUNCTION then
                    value = function()
                        return realValue
                    end
                elseif item.type == VALUE then
                    value = realValue
                end
                self[key] = value
                return value
            end
        end

        -- then, check if the original index is available and returns a result.
        if type(index) == "function" then
            local value = index(self, key)
            if value then return value end
        elseif type(index) == "table" then
            local value = index[key]
            if value then return value end
        end

        return nil
    end
end

-- makeLazy(target) -> table
-- Function
-- Ensures the target table is a 'lazy loader', and returns the factory table.
-- If the table is already a lazy table, nothing changes.
--
-- Parameters:
-- * target     - the object to make a lazy loader.
--
-- Returns:
-- * the factory table
local function makeLazy(target)
    local factory = rawget(target, FACTORY)
    if not factory then
        factory = newFactory(target)
        setFactory(target, factory)

        -- check if we need to inherit any other factories...
        local targetMt = getmetatable(target) or {}
        local index = targetMt and targetMt.__index

        targetMt.__index = lazyIndex(index)
        setmetatable(target, targetMt)
    end
    return factory
end

local function checkFactory(factory, key, value)
    local oldItem = rawget(factory, key)
    if oldItem then
        error(format("There is already a lazy %s named '%s'", oldItem.type, key))
    end
    if type(value) ~= "function" then
        error(format("The '%s' value must be a function, but was a '%s'", key, type(value)))
    end
end

--- cp.lazy.fn(target) -> function
--- Function
--- Prepares the `target` to assign factory functions.
--- It returns a function which accepts a table of factory function definitions.
--- These factories will only ever be called once, when the 'surface' function is called the first time.
---
--- For example:
---
--- ```lua
--- local o = {}
--- local topId = 0
--- lazy.fn(o) {
---     id     = function(self) topId = topId + 1; return topId end,
--- }
--- print(o:id())   -- "1"
--- print(o:id())   -- still "1"
--- ```
function mod.fn(target)
    local factory = makeLazy(target)
    return function(factories)
        for k,v in pairs(factories) do
            checkFactory(factory, k, v)
            factory[k] = {type=FUNCTION, new=v}
        end
        return target
    end
end

--- cp.lazy.value(target) -> function
--- Function
--- Prepares the `target` to assign factory functions.
--- It returns a function which accepts a table of factory function definitions.
--- These factories will only ever be called once, when the 'surface' value is called the first time.
---
--- For example:
---
--- ```lua
--- local o = {}
--- local topId = 0
--- lazy.value(o) {
---     id     = function(self) topId = topId + 1; return topId end,
--- }
--- print(o.id)   -- "1"
--- print(o.id)   -- still "1"
--- ```
function mod.value(target)
    local factory = makeLazy(target)
    return function(factories)
        for k,v in pairs(factories) do
            checkFactory(factory, k, v)
            factory[k] = {type=VALUE, new=v}
        end
        return target
    end
end

mod._FACTORY = FACTORY
mod._getFactory = getFactory
mod._setFactory = setFactory
mod._newFactory = newFactory

return mod
