--- === plugins.core.tangent.manager.mode ===
---
--- Represents a Tangent Mode

local require = require

local class             = require "middleclass"
local x                 = require "cp.web.xml"
local is                = require "cp.is"

local format            = string.format


local mode = class "core.tangent.manager.mode"

--- plugins.core.tangent.manager.mode(id, name)
--- Constructor
--- Creates a new `Mode` instance.
---
--- Parameters:
---  * id        - The ID number of the mode.
---  * name      - The name of the mode.
---
--- Returns:
---  *
function mode:initialize(id, name, manager)
    self.id = id
    self.name = name
    self.manager = manager
end

--- plugins.core.tangent.manager.mode.is(thing) -> boolean
--- Function
--- Checks to see if `thing` is a `mode` or not.
---
--- Parameters:
---  * thing - The item to check
---
--- Returns:
---  * `true` if is a mode otherwise `false`
function mode.static.is(thing)
    return type(thing) == "table" and thing.isInstanceOf ~= nil and thing:isInstanceOf(mode)
end

--- plugins.core.tangent.manager.mode:onActivate(activateFn) -> self
--- Method
--- Sets the function that will be called when the Tangent sends a 'mode change' request.
--- This function should have this signature:
---
--- ```lua
--- function() -> nil
--- ```
---
--- Parameters:
---  * activateFn     - The function to call when the Tangent requests the mode change.
---
--- Returns:
---  * The `parameter` instance.
function mode:onActivate(activateFn)
    if is.nt.fn(activateFn) then
        error("Please provide a function: %s", type(activateFn))
    end
    self._activate = activateFn
    return self
end

--- plugins.core.tangent.manager.mode:activate() -> nil
--- Method
--- Executes the `activate` function, if present.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `nil`
function mode:activate()
    self.manager.activeMode(self)
end

--- plugins.core.tangent.manager.mode:onDeactivate(deactivateFn) -> self
--- Method
--- Sets the function that will be called when the Tangent sends a 'mode change' request and switche to a different mode.
--- This function should have this signature:
---
--- `function() -> nil`
---
--- Parameters:
---  * deactivateFn     - The function to call when the Tangent requests the mode change.
---
--- Returns:
---  * The `parameter` instance.
function mode:onDeactivate(deactivateFn)
    if is.nt.fn(deactivateFn) then
        error("Please provide a function: %s", type(deactivateFn))
    end
    self._deactivate = deactivateFn
    return self
end

--- plugins.core.tangent.manager.mode:xml() -> cp.web.xml
--- Method
--- Returns the `xml` configuration for the Mode.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `xml` for the Mode.
function mode:xml()
    return x.Mode { id=format("%#010x", self.id) } (
        x.Name (self.name)
    )
end

function mode:__tostring()
    return format("mode: %s (%#010x)", self.name, self.id)
end

return mode
