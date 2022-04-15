--- === cp.fn.prop ===
---
--- A module of free-standing functions for working with [cp.prop](cp.prop.md) values.

local require                       = require

local mod = {}

--- cp.fn.prop.mutate(getFn[, setFn]) -> function(prop) -> cp.prop
--- Function
--- A function combinator which returns a function that receives a [cp.prop](cp.prop.md) and creates a mutated `cp.prop`
--- based on the `getFn` and `setFn` provided.
---
--- Parameters:
---  * getFn - A function that receives the current value and returns the modified value of the prop.
---  * setFn - (optional) A function that receives the modified value, along with the current value of the prop and returns a original value of the prop.
---
--- Returns:
---  * A [cp.prop](cp.prop.md) that is the result of the mutation.
---
--- Notes:
---  * Unlike `cp.prop:mutate(...)`, the `getFn` receives the actual current value when called, rather than the `cp.prop` itself, and no additional parameters.
---  * Also unlike `cp.prop:mutate(...)`, the `setFn` is called with the mutated value and the current value, rather than the `cp.prop` itself, and no additional parameters.
function mod.mutate(getFn, setFn)
    return function(originalProp)
        local getMutatedFn = function(original)
            return getFn(original:get())
        end
        local setMutatedFn
        if setFn then
            setMutatedFn = function(modified, original)
                local value = setFn(modified, original:get())
                original:set(value)
            end
        end
        return originalProp:mutate(getMutatedFn, setMutatedFn)
    end
end

return mod