local require               = require

local class                 = require "middleclass"

--- === cp.spec.Definition ===
---
--- A [Definition](cp.spec.Definition.md) is a superclass for a "runnable" specification.
--- It doesn't do anything itself, but provides a common ancestor for all implementation
--- classes like [Specification](cp.spec.Specification.md) and [Scenario](cp.spec.Scenario.md).

local Definition = class("cp.spec.Definition")

--- cp.spec.Definition(name[, doing]) -> cp.spec.Definition
--- Constructor
--- Creates a new test definition.
---
--- Parameters:
--- * name      - The name
function Definition:initialize(name)
    if type(name) ~= "string" or #name == 0 then
        error "The name must be at least one character long."
    end
    self.name = name
end

--- cp.spec.Definition.is(instance) -> boolean
--- Function
--- Called as a method, this will check if the provided object is an instance of this class.
---
--- Parameters:
--- * instance - The instance to check.
---
--- Returns:
--- * `true` if the instance is an instance of this class.
function Definition.static.is(instance)
    return type(instance) == "table" and instance.isInstanceOf and instance:isInstanceOf(Definition)
end

--- cp.spec.Definition:run([...]) -> cp.spec.Run
--- Method
--- Runs the definition with the specified filter `string`, `function` or `table` of `string`s and `function`s.
--- The [Run](cp.spec.Run.md) will have already started with the provided `filter`.
---
--- Parameters:
--- * ...    - (optional) The list of filters to apply to any child definitions.
---
--- Returns:
--- * The [Run](cp.spec.Run.md).
function Definition.run()
    error "Undefined."
end

function Definition:__tostring()
    return self.name
end

function Definition:__call(...)
    return self:run(...)
end

return Definition