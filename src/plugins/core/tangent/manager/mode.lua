--- === plugins.core.tangent.manager.mode ===
---
--- Represents a Tangent Mode

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log               = require("hs.logger").new("tng_mode")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local prop              = require("cp.prop")
local x                 = require("cp.web.xml")
local is                = require("cp.is")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local format            = string.format

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mode = {}
mode.mt = {}

--- plugins.core.tangent.manager.mode.new(id, name)
--- Constructor
--- Creates a new `Mode` instance.
---
--- Parameters:
---  * id        - The ID number of the mode.
---  * name      - The name of the mode.
---
--- Returns:
---  *
function mode.new(id, name, manager)
    local o = prop.extend({
        id = id,
        name = name,
        manager = manager,
    }, mode.mt)

    return o
end

--- plugins.core.tangent.manager.mode.is(other) -> boolean
--- Function
--- Checks to see if other is a mode or not.
---
--- Parameters:
---  * other - The item to check
---
--- Returns:
---  * `true` if is a mode otherwise `false`
function mode.is(other)
    return is.table(other) and getmetatable(other) == mode.mt
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
function mode.mt:onActivate(activateFn)
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
function mode.mt:activate()
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
function mode.mt:onDeactivate(deactivateFn)
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
function mode.mt:xml()
    return x.Mode { id=format("%#010x", self.id) } (
        x.Name (self.name)
    )
end

function mode.mt:__tostring()
    return format("mode: %s (%#010x)", self.name, self.id)
end

return mode
