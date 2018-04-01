--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                T A N G E N T    M A N A G E R    P L U G I N               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.tangent.manager.parameter ===
---
--- Represents a Tangent Parameter
local prop              = require("cp.prop")
local x                 = require("cp.web.xml")
local is                = require("cp.is")

local named             = require("named")

local format            = string.format

local parameter = {}

parameter.mt = named({})

--- plugins.core.tangent.manager.parameter.new(id[, name]) -> parameter
--- Constructor
--- Creates a new `Parameter` instance.
---
--- Parameters:
--- * id        - The ID number of the parameter.
--- * name      - The name of the parameter.
---
--- Returns:
--- * the new `parameter`.
function parameter.new(id, name)
    local o = prop.extend({
        id = id,
    }, parameter.mt)

    o:name(name)

    return o
end

--- plugins.core.tangent.manager.parameter.is(other) -> boolean
--- Function
--- Checks if the `other` is a `parameter` instance.
---
--- Parameters:
--- * other     - The other object to test.
---
--- Returns:
--- * `true` if it is a `parameter`, `false` if not.
function parameter.is(other)
    return type(other) == "table" and getmetatable(other) == parameter.mt
end

--- plugins.core.tangent.manager.parameter:minValue([value]) -> number | self
--- Method
--- Gets or sets the minimum value for the parameter.
---
--- Parameters:
--- * value     - The new value.
---
--- Returns:
--- * If `value` is `nil`, the current value is returned, otherwise returns `self`.
function parameter.mt:minValue(value)
    if value ~= nil then
        self._minValue = value
        return self
    else
        return self._minValue
    end
end


--- plugins.core.tangent.manager.parameter:maxValue([value]) -> number | self
--- Method
--- Gets or sets the maximum value for the parameter.
---
--- Parameters:
--- * value     - The new value.
---
--- Returns:
--- * If `value` is `nil`, the current value is returned, otherwise returns `self`.
function parameter.mt:maxValue(value)
    if value ~= nil then
        self._maxValue = value
        return self
    else
        return self._maxValue
    end
end

--- plugins.core.tangent.manager.parameter:stepSize([value]) -> number | self
--- Method
--- Gets or sets the step size for the parameter.
---
--- Parameters:
--- * value     - The new value.
---
--- Returns:
--- * If `value` is `nil`, the current value is returned, otherwise returns `self`.
function parameter.mt:stepSize(value)
    if value ~= nil then
        self._stepSize = value
        return self
    else
        return self._stepSize
    end
end

--- plugins.core.tangent.manager.parameter:onGet(getFn) -> self
--- Method
--- Sets the function that will be called when the Tangent sends a 'parameter value' request.
--- This function should have this signature:
---
--- `function() -> number`
---
--- Parameters:
--- * getFn     - The function to call when the Tangent requests the parameter value.
---
--- Returns:
--- * The `parameter` instance.
function parameter.mt:onGet(getFn)
    if is.nt.fn(getFn) then
        error("Please provide a `get` function: %s", type(getFn))
    end
    self._get = getFn
    return self
end

--- plugins.core.tangent.manager.parameter:get() -> number
--- Method
--- Executes the `get` function if present, and returns the result. If
--- none has been set, `nil` is returned.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The current value, or `nil` if it can't be accessed.
function parameter.mt:get()
    if self._get then
        return self._get()
    end
    return nil
end

--- plugins.core.tangent.manager.parameter:onChange(changeFn) -> self
--- Method
--- Sets the function that will be called when the Tangent sends a 'parameter change' request.
--- This function should have this signature:
---
--- `function(amount) -> number`
---
--- The return value should be the new value of the parameter.
---
--- Parameters:
--- * getFn     - The function to call when the Tangent requests the parameter change.
---
--- Returns:
--- * The `parameter` instance.
function parameter.mt:onChange(changeFn)
    if is.nt.fn(changeFn) then
        error("Please provide a `change` function: %s", type(changeFn))
    end
    self._change = changeFn
    return self
end

--- plugins.core.tangent.manager.parameter:change(amount) -> number
--- Method
--- Executes the `change` function if present, and returns the new result. If
--- none has been set, `nil` is returned.
---
--- Parameters:
--- * amount    - The amount to change the parameter.
---
--- Returns:
--- * The current value, or `nil` if it can't be accessed.
function parameter.mt:change(amount)
    if self._change then
        local value = self._change(amount)
        return value or self:get()
    end
    return nil
end

--- plugins.core.tangent.manager.parameter:onReset(resetFn) -> self
--- Method
--- Sets the function that will be called when the Tangent sends a 'parameter reset' request.
--- This function should have this signature:
---
--- `function() -> nil`
---
--- Parameters:
--- * resetFn     - The function to call when the Tangent requests the parameter reset.
---
--- Returns:
--- * The `parameter` instance.
function parameter.mt:onReset(resetFn)
    if is.nt.fn(resetFn) then
        error("Please provide a `reset` function: %s", type(resetFn))
    end
    self._reset = resetFn
    return self
end

--- plugins.core.tangent.manager.parameter:reset() -> number
--- Method
--- Executes the `reset` function if present. Returns the current value of the parameter after reset.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The current value, or `nil` if it can't be accessed.
function parameter.mt:reset()
    if self._reset then
        self._reset()
    end
    return self:get()
end

--- plugins.core.tangent.manager.parameter:xml() -> cp.web.xml
--- Method
--- Returns the `xml` configuration for the Parameter.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `xml` for the Parameter.
function parameter.mt:xml()
    return x.Parameter { id=format("%#010x", self.id) } (
        function()
            local result = named.xml(self)
            if self._minValue ~= nil then
                result(x.MinValue(self._minValue))
            end
            if self._maxValue ~= nil then
                result(x.MaxValue(self._maxValue))
            end
            if self._stepSize ~= nil then
                result(x.StepSize(self._stepSize))
            end
            return result
        end
    )
end

function parameter.mt:__tostring()
    return format("parameter: %s (%#010x)", self:name(), self.id)
end

return parameter
