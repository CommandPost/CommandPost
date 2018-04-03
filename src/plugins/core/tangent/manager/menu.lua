--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                T A N G E N T    M A N A G E R    P L U G I N               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.tangent.manager.menu ===
---
--- Represents a Tangent Menu. Menus are controls that have a fixed set of
--- non-numerical values. This could be as simple as "On" and "Off", or a long
--- list of options.
local tangent           = require("hs.tangent")

local prop              = require("cp.prop")
local x                 = require("cp.web.xml")
local is                = require("cp.is")

local named             = require("named")

local format            = string.format

local menu = {}

menu.mt = named({})

--- plugins.core.tangent.manager.menu.new(id[, name[, parent]]) -> menu
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
function menu.new(id, name, parent)
    local o = prop.extend({
        id = id,
        _parent = parent,

        --- plugins.core.tangent.manager.menu.enabled <cp.prop: boolean>
        --- Field
        --- Indicates if the menu is enabled.
        enabled = prop.TRUE(),
    }, menu.mt)

    prop.bind(o) {
        --- plugin.core.tangent.manager.menu.active <cp.prop: boolean; read-only>
        --- Field
        --- Indicates if the menu is active. It will only be active if
        --- the current menu is `enabled` and if the parent group (if present) is `active`.
        active = parent and parent.active:AND(o.enabled) or o.enabled:IMMUTABLE()
    }

    o:name(name)

    return o
end

--- plugins.core.tangent.manager.menu.is(other) -> boolean
--- Function
--- Checks if the `other` is a `menu` instance.
---
--- Parameters:
--- * other     - The other object to test.
---
--- Returns:
--- * `true` if it is a `menu`, `false` if not.
function menu.is(other)
    return type(other) == "table" and getmetatable(other) == menu.mt
end

--- plugins.core.tangent.manager.menu:parent() -> group | controls
--- Method
--- Returns the `group` or `controls` that contains this menu.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The parent.
function menu.mt:parent()
    return self._parent
end

--- plugins.core.tangent.manager.menu:controls()
--- Method
--- Returns the `controls` the menu belongs to.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `controls`, or `nil` if not specified.
function menu.mt:controls()
    local parent = self:parent()
    if parent then
        return parent:controls()
    end
    return nil
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
function menu.mt:onGet(getFn)
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
function menu.mt:get()
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
function menu.mt:onNext(nextFn)
    if is.nt.fn(nextFn) then
        error("Please provide a function: %s", type(nextFn))
    end
    self._next = nextFn
    return self
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
function menu.mt:next()
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
function menu.mt:onPrev(prevFn)
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
function menu.mt:prev()
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
function menu.mt:update()
    if self:active() then
        return tangent.sendMenuString(self.id, self:get())
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
function menu.mt:xml()
    return x.Menu { id=format("%#010x", self.id) } (
        named.xml(self)
    )
end

return menu
