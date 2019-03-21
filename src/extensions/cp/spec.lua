--- === cp.spec ===
---
--- An asynchronous test suite for Lua.
local require               = require

local Handler               = require "cp.spec.Handler"
local DefaultHandler        = require "cp.spec.DefaultHandler"
local Report                = require "cp.spec.Report"
local Run                   = require "cp.spec.Run"
local Definition            = require "cp.spec.Definition"
local Where                 = require "cp.spec.Where"
local Scenario              = require "cp.spec.Scenario"
local Specification         = require "cp.spec.Specification"

local expect                = require "cp.spec.expect"

--- cp.spec.describe(name) -> function(definitions) -> cp.spec.Specification
--- Function
--- Returns a `function` which will accept a list of test [Definitions](cp.spec.Definition.md),
--- or a `table` of [Definitions](cp.spec.Definition.md).
---
--- Parameters:
--- * name      - The name of the test suite.
---
--- Returns:
--- * A `function` that must be called with the set of [Definitions](cp.spec.Definition.md) or [suites](cp.spec.Specification.md) to run.
local function describe(name)
    return function(...)
        return Specification(name):with(...)
    end
end

--- cp.spec.describe(name) -> function(definitions) -> cp.spec.Specification
--- Function
--- Returns a `function` which will accept a list of test [definitions](cp.spec.Definition.md),
--- or a `table` of [definitions](cp.spec.Definition.md).
---
--- Parameters:
--- * name      - The name of the test suite.
---
--- Returns:
--- * A `function` that must be called with the set of [definitions](cp.spec.Definition.md) or [suites](cp.spec.Specification.md) to run.
local context = describe

--- cp.spec.it(name[, ...]) -> cp.spec.Scenario
--- Function
--- Returns an [Scenario](cp.spec.Scenario.md) with the specified name and optional `doingFn` function.
--- If the function is not provided, it must be done via the [doing](#doing) method prior to running.
---
--- Parameters:
--- * name      - The name of the scenario.
--- * doingFn   - (optional) The `function` to call when doing the operation. Will be passed the [Run.This](cp.spec.Run.This.md)
---     instance for the definition.
---
--- Notes:
--- * See [doing](cp.spec.Scenario.md#doing) for more details regarding the function.
local function it(name, doingFn)
    return Scenario("it " .. name, doingFn)
end

--- cp.spec(item) -> cp.spec.Run
local function run(item)
    local spec = require(item .. "_spec")
    return spec:run()
end

return setmetatable({
    Handler = Handler,
    DefaultHandler = DefaultHandler,
    Report = Report,
    Run = Run,
    Definition = Definition,
    Scenario = Scenario,
    Where = Where,
    Specification = Specification,
    describe = describe,
    context = context,
    it = it,
    expect = expect,
}, {
    __call = function(_, ...)
        return run(...)
    end
})