--- === cp.lazy ===
---
--- Lazy Extension.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log               = require("hs.logger").new("lazy")

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

-- creates a new factory
local function newFactory(owner)
    return setmetatable({}, {
        __index = function(_, key)
            log.df("FACTORY request for '%s'", key)
            local ownerMt = getmetatable(owner)
            if ownerMt then
                log.df("FACTORY searching the owner's metatable...")
                local mtFactory = setmetatable({}, ownerMt)[FACTORY]
                if mtFactory then
                    log.df("FACTORY found the owner's factory, returning '%s'", key)
                    return mtFactory[key]
                else
                    log.df("FACTORY unable to find owner FACTORY")
                end
            end
            return nil
        end,
    })
end

-- This basically looks up the factory method and then assigns the created value to the target.
local function lazyIndex(self, key)
    if key == FACTORY then
        log.df("ignoring a request for the FACTORY...")
        -- don't bother looking
        return nil
    end

    log.df("doing a lazy lookup for '%s'", key)
    -- check the factory functions.
    local factory = rawget(self, FACTORY)
    if factory then
        log.df("found the FACTORY, requesting '%s'", key)
        local item = factory[key]
        if item then
            log.df("found the '%s' item.", key)
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
    else
        log.df("didn't find the FACTORY...")
    end
    return nil
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
        rawset(target, FACTORY, factory)

        local lazyMt = {__index = lazyIndex}

        -- check if we need to inherit any other factories...
        local targetMt = getmetatable(target)
        if targetMt ~= nil then
            log.df("Found existing metatable, setting as lazy metatable")
            setmetatable(lazyMt, targetMt)
        end

        -- set the metatable for the target...
        setmetatable(target, lazyMt)
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
--- These factories will only ever be called once, when the 'surface' function is called the first time.
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

return mod