--- === plugins.core.tangent.manager.action ===
---
--- Represents a Tangent Action

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local is                = require("cp.is")
local named             = require("named")
local prop              = require("cp.prop")
local x                 = require("cp.web.xml")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local format            = string.format

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local action = {}
action.mt = named({})

--- plugins.core.tangent.manager.action.new(id[, name]) -> action
--- Constructor
--- Creates a new `Action` instance.
---
--- Parameters:
--- * id        - The ID number of the action.
--- * name      - The name of the action.
---
--- Returns:
--- * the new `action`.
function action.new(id, name, parent)
    local o = prop.extend({
        id = id,
        _parent = parent,

        --- plugins.core.tangent.manager.action.enabled <cp.prop: boolean>
        --- Field
        --- Indicates if the action is enabled.
        enabled = prop.TRUE(),
    }, action.mt)

    prop.bind(o) {
        --- plugin.core.tangent.manager.action.active <cp.prop: boolean; read-only>
        --- Field
        --- Indicates if the action is active. It will only be active if
        --- the current action is `enabled` and if the parent group (if present) is `active`.
        active = parent and parent.active:AND(o.enabled) or o.enabled:IMMUTABLE()
    }

    o:name(name)

    return o
end

--- plugins.core.tangent.manager.action.is() -> boolean
--- Method
--- Is an object an action?
---
--- Parameters:
--- * otherThing - Object to test.
---
--- Returns:
--- * `true` if the object is an action otherwise `false`.
function action.is(otherThing)
    return is.table(otherThing) and getmetatable(otherThing) == action.mt
end

--- plugins.core.tangent.manager.action:parent() -> group | controls
--- Method
--- Returns the `group` or `controls` that contains this action.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The action's parent.
function action.mt:parent()
    return self._parent
end

--- plugins.core.tangent.manager.action:controls()
--- Method
--- Returns the `controls` the action belongs to.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `controls`, or `nil` if not specified.
function action.mt:controls()
    local parent = self:parent()
    if parent then
        return parent:controls()
    end
    return nil
end

--- plugins.core.tangent.manager.action:onPress(pressFn) -> self
--- Method
--- Sets the function that will be called when the Tangent sends a 'action on' request.
--- This function should have this signature:
---
--- `function() -> nil`
---
--- Parameters:
--- * pressFn     - The function to call when the Tangent requests the action on.
---
--- Returns:
--- * The `parameter` instance.
function action.mt:onPress(pressFn)
    if is.nt.callable(pressFn) then
        error(format("Please provide a function: %s", type(pressFn)))
    end
    self._press = pressFn
    return self
end

--- plugins.core.tangent.manager.parameter:press() -> nil
--- Method
--- Executes the `press` function, if present.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `nil`
function action.mt:press()
    if self._press and self:active() then
        self._press()
    end
end

--- plugins.core.tangent.manager.action:onRelease(releaseFn) -> self
--- Method
--- Sets the function that will be called when the Tangent sends a 'action off' request.
--- This function should have this signature:
---
--- `function() -> nil`
---
--- Parameters:
--- * releaseFn     - The function to call when the Tangent requests the action off.
---
--- Returns:
--- * The `parameter` instance.
function action.mt:onRelease(releaseFn)
    if is.nt.fn(releaseFn) then
        error("Please provide a function: %s", type(releaseFn))
    end
    self._release = releaseFn
    return self
end

--- plugins.core.tangent.manager.parameter:release() -> nil
--- Method
--- Executes the `release` function, if present.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `nil`
function action.mt:release()
    if self._release and self:active() then
        self._release()
    end
end

--- plugins.core.tangent.manager.action:xml() -> cp.web.xml
--- Method
--- Returns the `xml` configuration for the Action.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `xml` for the Action.
function action.mt:xml()
    return x.Action { id=format("%#010x", self.id) } (
        named.xml(self)
    )
end

function action.mt:__tostring()
    return format("action: %s (%#010x)", self:name(), self.id)
end

return action
