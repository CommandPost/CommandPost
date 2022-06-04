--- === cp.classtype ===
---
--- A `middleclass` extension that adds some useful methods to `class` objects.
---
--- By default, `middleclass` provides a couple of helper methods for checking class hierarchy.
--- These include:
---
--- * `value:isInstanceOf(class)` - Checks if the `value` is an instance of the given `class`.
--- * `class:isSubclassOf(class)` - Checks if the `class` is a subclass of the given `class`.
---
--- Unfortunately, these both work with the 'target' value or class, not the super-class. This
--- makes it inconvient to test if an unknown value is an instance of something else. Eg:
---
--- ```lua
--- local value = ...
--- if value:isInstanceOf(MyClass) then
---     -- do something
--- end
--- ```
---
--- This is likely to fail if our `value` isn't actually a middleclass object, since it won't have
--- the `isInstanceOf` method.
---
--- This extension adds a couple of helper methods to `class` objects, which are:
---
--- * `class:isClassFor(value)` - Checks if the `value` is an instance of the specific `class`.
--- * `class:isSuperclassFor(value)` - Checks if the `class` is a superclass of the given `value`.
--- * `class:isSuperclassOf(class)` - Checks if the `class` is a superclass of the given `class`.
---
--- These methods are useful for checking if a value is an instance of a specific class, or if a
--- class is a superclass of another class.

local log           = require "hs.logger".new "classtype"

local classtype = {}

--- cp.classtype:isClassFor(value) -> boolean
--- Function
--- Checks if the `value` is an instance of this specific `class`.
---
--- Parameters:
---  * value - The value to check.
---
--- Returns:
---  * `true` if the `value` is an instance of the specific `class`, otherwise `false`.
---
--- Notes:
---  * Called as a class function from the actual class.
---  * See also [isSuperclassFor](#isSuperclassFor).
local function isClassFor(klass, value)
    log.df("isClassFor: called with %s, %s",)
    return type(value) == "table" and type(value.class) == "table" and klass == value.class
end

--- cp.classtype:isSuperclassFor(value) -> boolean
--- Function
--- Checks if the value is an instance of this class, or is a superclass of this class.
local function isSuperclassFor(klass, value)
    return type(value) == "table" and value.isInstanceOf ~= nil and value:isInstanceOf(klass)
end

--- cp.classtype:isSuperclassOf(other) -> boolean
--- Function
--- Checks if the `class` is a superclass of this class.
---
--- Parameters:
---  * other - The other class to check.
---
--- Returns:
---  * `true` if this `class` is a superclass of the other class, otherwise `false`.
local function isSuperclassOf(klass, other)
    return type(other) == "table" and (klass == other or other.isSubclassOf ~= nil and other:isSubclassOf(klass))
end

-- initialises the provided class when it includes the `lazy` mix-in.
function classtype:included(klass) -- luacheck: ignore
    -- add the `isClassFor` method to the class.
    klass.isClassFor = isClassFor

    -- add the `isSuperclassFor` method to the class.
    klass.isSuperclassFor = isSuperclassFor

    -- add the `isSuperclassOf` method to the class.
    klass.isSuperclassOf = isSuperclassOf
end


return classtype