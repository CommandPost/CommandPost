--- === plugins.core.tangent.manager.action ===
---
--- Represents a Tangent Action

local require = require

local is                = require "cp.is"
local prop              = require "cp.prop"
local x                 = require "cp.web.xml"

local named             = require "named"

local format            = string.format

local action = named:subclass "core.tangent.manager.action"

--- plugins.core.tangent.manager.action(id[, name[, parent[, localActive]]]) -> action
--- Constructor
--- Creates a new `Action` instance.
---
--- Parameters:
--- * id        - The ID number of the action.
--- * name      - The name of the action.
--- * parent    - The parent group. (optional)
--- * localActive - If set to `true`, the parent's `active` state will be ignored when determining if this action is active. Defaults to `false`.
---
--- Returns:
--- * the new `action`.
function action:initialize(id, name, parent, localActive)
    named.initialize(self, id, name, parent)
    self._localActive = localActive
end

--- plugins.core.tangent.manager.action.localActive <cp.prop: boolean>
--- Field
--- Indicates if the action should ignore the parent's `enabled` state when determining if the action is active.
function action.lazy.prop:localActive()
    return prop.THIS(self._localActive == true)
end

--- plugin.core.tangent.manager.action.active <cp.prop: boolean; read-only>
--- Field
--- Indicates if the action is active. It will only be active if
--- the current action is `enabled` and if the parent group (if present) is `active`.
function action.lazy.prop:active()
    local parent = self:parent()
    return parent and prop.AND(self.localActive:OR(parent.active), self.enabled) or self.enabled:IMMUTABLE()
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
function action.static.is(thing)
    return type(thing) == "table" and thing.isInstanceOf ~= nil and thing:isInstanceOf(action)
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
function action:onPress(pressFn)
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
function action:press()
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
function action:onRelease(releaseFn)
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
function action:release()
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
function action:xml()
    return x.Action { id=format("%#010x", self.id) } (
        named.xml(self)
    )
end

function action:__tostring()
    return format("action: %s (%#010x)", self:name(), self.id)
end

return action
