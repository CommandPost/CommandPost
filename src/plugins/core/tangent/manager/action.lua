--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                T A N G E N T    M A N A G E R    P L U G I N               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.tangent.manager.action ===
---
--- Represents a Tangent Action
local prop              = require("cp.prop")
local x                 = require("cp.web.xml")
local is                = require("cp.is")

local named             = require("named")

local format            = string.format

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
function action.new(id, name)
    local o = prop.extend({
        id = id,
    }, action.mt)

    o:name(name)

    return o
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
    if is.nt.fn(pressFn) then
        error("Please provide a function: %s", type(pressFn))
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
    if self._press then
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
    if self._release then
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

return action
