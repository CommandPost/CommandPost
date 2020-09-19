--- === plugins.core.tangent.manager.named ===
---
--- Provides common functions for 'named' Tangent nodes
---
--- Tables with `named` in it's metatable chain will have `name` methods added
--- as described below.

local require           = require

-- local log               = require "hs.logger" .new "named"

local class             = require "middleclass"
local lazy              = require "cp.lazy"
local prop              = require "cp.prop"
local tools             = require "cp.tools"
local x                 = require "cp.web.xml"

local match             = string.match

local named = class "core.tangent.manager.named" :include(lazy)

local NAMES_KEY = {}

--- plugins.core.tangent.manager.named(id, name[, parent]) -> named
--- Constructor
--- Creates a new `named` instance, with the specified base name.
---
--- Parameters:
--- * id - the unique ID for the value.
--- * name - The base name of the
function named:initialize(id, name, parent)
    self.id = id
    self._parent = parent
    self._name = name
end

--- plugins.core.tangent.manager.named.enabled <cp.prop: boolean>
--- Field
--- Indicates if the parameter is enabled.
function named.lazy.prop.enabled()
    return prop.TRUE()
end

--- plugins.core.tangent.manager.named.active <cp.prop: boolean; read-only>
--- Field
--- Indicates if the parameter is active. It will only be active if
--- the current parameter is `enabled` and if the parent group (if present) is `active`.
function named.lazy.prop:active()
    local parent = self:parent()
    return parent and parent.active:AND(self.enabled) or self.enabled:IMMUTABLE()
end

--- plugins.core.tangent.manager.named:parent() -> group | controls
--- Method
--- Returns the `group` or `controls` that contains this parameter.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The parent.
function named:parent()
    return self._parent
end

--- plugins.core.tangent.manager.named:tangent() -> hs.tangent
--- Method
--- The Tangent Hub connection for this value, from the `parent`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `hs.tangent`, if available.
function named:tangent()
    return self:parent():tangent()
end

--- plugins.core.tangent.manager.named:controls()
--- Method
--- Returns the `controls` the parameter belongs to.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `controls`, or `nil` if not specified.
function named:controls()
    local parent = self:parent()
    if parent then
        return parent:controls()
    end
    return nil
end

-- makeStringTangentFriendly(value) -> none
-- Function
-- Removes any illegal characters from the value
--
-- Parameters:
--  * value - The string you want to process
--
-- Returns:
--  * A string that's valid for Tangent's panels
local function makeStringTangentFriendly(value)
    --------------------------------------------------------------------------------
    -- Replace "&"" with "and"
    --------------------------------------------------------------------------------
    value = string.gsub(value, "&", "and")

    local result = ""

    for i = 1, #value do
        local letter = value:sub(i,i)
        local byte = string.byte(letter)
        if byte >= 32 and byte <= 126 then
            result = result .. letter
        --else
            --log.df("Illegal Character: %s", letter)
        end
    end
    result = tools.trim(result)
    if #result == 0 then
        result = nil
    end
    return result
end

--- plugins.core.tangent.manager.named:name(value) -> string | self
--- Method
--- Gets or sets the full name.
---
--- Parameters:
--- * value - The new name value.
---
--- Returns:
--- * The current value, or `self` if a new value was provided.
local function getName(self, value)
    if value ~= nil then
        self._name = value
        return self
    else
        return self._name
    end
end

-- getNames(self, create) -> table
-- Function
-- Gets a table of names.
--
-- Parameters:
-- * self - The named module.
-- * create - A boolean.
--
-- Returns:
--  * Names as table.
local function getNames(self, create)
    local names = rawget(self, NAMES_KEY)
    if not names and create then
        names = {}
        rawset(self,NAMES_KEY, names)
    end
    return names
end

--- plugins.core.tangent.manager.named:nameX(value) -> string | self
--- Method
--- Sets the name `X`, where `X` is a number as defined when the `named` was created.
---
--- Parameters:
--- * value - The new name value.
---
--- Returns:
--- * The current value, or `self` if a new value was provided.
function named:__index(key)
    if key == "name" then
        return getName
    end
    local i = match(key, "name([0-9]+)")
    if i then
        i = tonumber(i)

        local fn = function(source, value)
            if value ~= nil then
                local names = getNames(source, true)
                names[i] = value:sub(1, i)
                return source
            else
                local names = getNames(source)
                return names and names[i]
            end
        end

        -- cache it for next time.
        self[key] = fn
        return fn
    end
    return nil
end

--- plugins.core.tangent.manager.named.xml(thing) -> cp.web.xml
--- Function
--- Returns the `xml` configuration for the Action.
---
--- Parameters:
--- * thing     - The thing to retrieve the names from.
---
--- Returns:
--- * The `xml` for the Action.
function named:xml()
    return x(function()
        local result = x()

        local theName = makeStringTangentFriendly(self:name())
        if theName then
            result(x.Name(theName))
        end

        local names = getNames(self)
        if names then
            for i,v in pairs(names) do
                if type(i) == "number" and v then
                    theName = makeStringTangentFriendly(v)
                    if theName then
                        result(x["Name"..i](theName))
                    end
                end
            end
        end
        return result
    end)
end

--- plugins.core.tangent.manager.named.is(thing) -> boolean
--- Function
--- Check if the `thing` is a `named` table.
---
--- Parameters:
--- * thing     - The thing to check.
---
--- Returns:
--- * `true` if it is `named.
function named.static.is(thing)
    return type(thing) == "table" and thing.isInstanceOf ~= nil and thing:isInstanceOf(named)
end

named.names = getNames

return named
