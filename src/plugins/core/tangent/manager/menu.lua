--- === plugins.core.tangent.manager.menu ===
---
--- Represents a Tangent Menu. Menus are controls that have a fixed set of
--- non-numerical values. This could be as simple as "On" and "Off", or a long
--- list of options.

local require = require

local tangent           = require "hs.tangent"

local x                 = require "cp.web.xml"
local is                = require "cp.is"

local named             = require "named"

local format            = string.format

local menu = named:subclass "core.tangent.manager.menu"

--- plugins.core.tangent.manager.menu(id[, name[, parent]]) -> menu
--- Constructor
--- Creates a new `Action` instance.
---
--- Parameters:
--- * id        - The ID number of the menu.
--- * name      - The name of the menu.
--- * parent    - The parent of the menu.
---
--- Returns:
--- * the new `menu`.
function menu:initialize(id, name, parent)
    named.initialize(self, id, name, parent)
end

--- plugins.core.tangent.manager.menu.is(thing) -> boolean
--- Function
--- Checks if the `thing` is a `menu` instance.
---
--- Parameters:
--- * thing     - The other object to test.
---
--- Returns:
--- * `true` if it is a `menu`, `false` if not.
function menu.static.is(thing)
    return type(thing) == "table" and thing.isInstanceOf ~= nil and thing:isInstanceOf(named)
end

--- plugins.core.tangent.manager.menu:onGet(getFn) -> self
--- Method
--- Sets the function that will be called when the Tangent sends a `menu string request`.
--- This function should have this signature:
---
--- `function() -> string`
---
--- Parameters:
--- * getFn     - The function to call when the Tangent requests the `menu string`.
---
--- Returns:
--- * The `parameter` instance.
function menu:onGet(getFn)
    if is.nt.fn(getFn) then
        error("Please provide a function: %s", type(getFn))
    end
    self._get = getFn
    return self
end

--- plugins.core.tangent.manager.menu:get() -> string
--- Method
--- Executes the `get` function, if present, returning the string value for the current menu.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `nil`
function menu:get()
    if self._get and self:active() then
        return self._get()
    end
end

--- plugins.core.tangent.manager.menu:onNext(nextFn) -> self
--- Method
--- Sets the function that will be called when the Tangent sends a `menu change +1` request.
--- This function should have this signature:
---
--- `function() -> nil`
---
--- It is suggested that when arriving at the end of the list of options a subsequent `next` call
--- will cycle back to the beginning of the options. This is particularly useful for menus with
--- two options.
---
--- Parameters:
--- * nextFn     - The function to call when the Tangent requests the `menu change +1`.
---
--- Returns:
--- * The `parameter` instance.
function menu:onNext(nextFn)
    if is.nt.fn(nextFn) then
        error("Please provide a function: %s", type(nextFn))
    end
    self._next = nextFn
    return self
end

--- plugins.core.tangent.manager.menu:onReset(resetFn) -> self
--- Method
--- Sets the function that will be called when the Tangent sends a 'parameter reset' request.
--- This function should have this signature:
---
--- `function() -> nil`
---
--- Parameters:
---  * resetFn     - The function to call when the Tangent requests the parameter reset.
---
--- Returns:
---  * The `parameter` instance.
function menu:onReset(resetFn)
    if is.nt.callable(resetFn) then
        error(format("Please provide a `reset` function: %s", type(resetFn)))
    end
    self._reset = resetFn
    return self
end

--- plugins.core.tangent.manager.menu:reset() -> number
--- Method
--- Executes the `reset` function if present. Returns the current value of the parameter after reset.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The current value, or `nil` if it can't be accessed.
function menu:reset()
    if self._reset and self:active() then
        self._reset()
    end
    return self:get()
end


--- plugins.core.tangent.manager.menu:next() -> nil
--- Method
--- Executes the `next` function, if present.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `nil`
function menu:next()
    if self._next and self:active() then
        self._next()
    end
end

--- plugins.core.tangent.manager.menu:onPrev(prevFn) -> self
--- Method
--- Sets the function that will be called when the Tangent sends a `menu change -1` request.
--- This function should have this signature:
---
--- `function() -> nil`
---
--- It is suggested that when arriving at the start of the list of options a subsequent `prev` call
--- will cycle to the end of the options. This is particularly useful for menus with
--- two options.
---
--- Parameters:
--- * prevFn     - The function to call when the Tangent requests the `menu change -1`.
---
--- Returns:
--- * The `parameter` instance.
function menu:onPrev(prevFn)
    if is.nt.fn(prevFn) then
        error("Please provide a function: %s", type(prevFn))
    end
    self._prev = prevFn
    return self
end

--- plugins.core.tangent.manager.menu:prev() -> nil
--- Method
--- Executes the `prev` function, if present.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `nil`
function menu:prev()
    if self._prev and self:active() then
        self._prev()
    end
end

--- plugins.core.tangent.manager.menu:update() -> nil
--- Method
--- Updates the Tangent panel with the current value.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if the update was sent.
function menu:update()
    if self:active() then
        return self:tangent():sendMenuString(self.id, self:get())
    end
    return false
end

--- plugins.core.tangent.manager.menu:xml() -> cp.web.xml
--- Method
--- Returns the `xml` configuration for the Action.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `xml` for the Action.
function menu:xml()
    return x.Menu { id=format("%#010x", self.id) } (
        named.xml(self)
    )
end

return menu
