local require               = require

local class                 = require "middleclass"

--- === cp.spec.Definition ===
--- A [Definition](cp.spec.Definition.md) is an optional collection of [Scenarios](cp.spec.Scenario.md).
--- It should not contain any `assert` checks itself.

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

return Definition