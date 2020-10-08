--- === plugins.core.tangent.manager.parameter ===
---
--- Represents a Tangent Parameter control.

local require = require

local log               = require "hs.logger" .new "tng_param"

local x                 = require "cp.web.xml"
local is                = require "cp.is"

local named             = require "named"

local format            = string.format

local parameter = named:subclass "core.tangent.manager.parameter"

--- plugins.core.tangent.manager.parameter(id[, name[, parent]) -> parameter
--- Constructor
--- Creates a new `Parameter` instance.
---
--- Parameters:
---  * id        - The ID number of the parameter.
---  * name      - The name of the parameter.
---  * parent    - The parent of the parameter.
---
--- Returns:
---  * the new `parameter`.
function parameter:initialize(id, name, parent)
    named.initialize(self, id, name, parent)
end

--- plugins.core.tangent.manager.parameter.is(thing) -> boolean
--- Function
--- Checks if the `thing` is a `parameter` instance.
---
--- Parameters:
---  * thing     - The other object to test.
---
--- Returns:
---  * `true` if it is a `parameter`, `false` if not.
function parameter.static.is(thing)
    return type(thing) == "table" and thing.isInstanceOf ~= nil and thing:isInstanceOf(parameter)
end

--- plugins.core.tangent.manager.parameter:minValue([value]) -> number | self
--- Method
--- Gets or sets the minimum value for the parameter.
---
--- Parameters:
---  * value     - The new value.
---
--- Returns:
---  * If `value` is `nil`, the current value is returned, otherwise returns `self`.
function parameter:minValue(value)
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
---  * value     - The new value.
---
--- Returns:
---  * If `value` is `nil`, the current value is returned, otherwise returns `self`.
function parameter:maxValue(value)
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
---  * value     - The new value.
---
--- Returns:
---  * If `value` is `nil`, the current value is returned, otherwise returns `self`.
function parameter:stepSize(value)
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
---  * getFn     - The function to call when the Tangent requests the parameter value.
---
--- Returns:
---  * The `parameter` instance.
function parameter:onGet(getFn)
    if is.nt.callable(getFn) then
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
---  * None
---
--- Returns:
---  * The current value, or `nil` if it can't be accessed.
function parameter:get()
    if self._get and self:active() then
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
---  * getFn     - The function to call when the Tangent requests the parameter change.
---
--- Returns:
---  * The `parameter` instance.
function parameter:onChange(changeFn)
    if is.nt.callable(changeFn) then
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
---  * amount    - The amount to change the parameter.
---
--- Returns:
---  * The current value, or `nil` if it can't be accessed.
function parameter:change(amount)
    if self._change and self:active() then
        local ok, result = xpcall(function() self._change(amount) end, debug.traceback)
        if not ok then
            log.ef("Error while changing parameter (%#010x): %s", self.id, result)
        end

        return self:get()
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
---  * resetFn     - The function to call when the Tangent requests the parameter reset.
---
--- Returns:
---  * The `parameter` instance.
function parameter:onReset(resetFn)
    if is.nt.callable(resetFn) then
        error(format("Please provide a `reset` function: %s", type(resetFn)))
    end
    self._reset = resetFn
    return self
end

--- plugins.core.tangent.manager.parameter:reset() -> number
--- Method
--- Executes the `reset` function if present. Returns the current value of the parameter after reset.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The current value, or `nil` if it can't be accessed.
function parameter:reset()
    if self._reset and self:active() then
        self._reset()
    end
    return self:get()
end

--- plugins.core.tangent.manager.parameter:update()
--- Function
--- Updates the Tangent with the current value of the parameter.
---
--- Parameters:
--- * None
---
--- Returns:
--- * Nothing.
function parameter:update()
    if self:active() and self:tangent():connected() then
        local value = self:get()
        if value ~= nil then
            self:tangent():sendParameterValue(self.id, value)
        end
    end
end

--- plugins.core.tangent.manager.parameter:xml() -> cp.web.xml
--- Method
--- Returns the `xml` configuration for the Parameter.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `xml` for the Parameter.
function parameter:xml()
    return x.Parameter { id=format("%#010x", self.id) } (
        function()
            local result = named.xml(self)
            if self._minValue ~= nil then
                result(x.MinValue(format("%#0.10f", self._minValue)))
            end
            if self._maxValue ~= nil then
                result(x.MaxValue(format("%#0.10f", self._maxValue)))
            end
            if self._stepSize ~= nil then
                result(x.StepSize(format("%#0.10f", self._stepSize)))
            end
            return result
        end
    )
end

function parameter:__tostring()
    return format("parameter: %s (%#010x)", self:name(), self.id)
end

return parameter
