local require               = require

-- local log                   = require "hs.logger" .new "Specification"

local Definition            = require "cp.spec.Definition"
local Run                   = require "cp.spec.Run"

local insert                = table.insert

--- === cp.spec.Specification ===
---
--- A Specification is a list of [definitions](cp.spec.Definition.md) which
--- will be run in sequence, and the results are collated. It is often created via
--- the [describe](cp.spec.md#describe) function.
---
--- Example usage:
--- ```
--- local spec = require "cp.spec"
--- local describe, it = spec.describe, spec.it
---
--- return describe "a specification" {
---     it "performs an assertion"
---     :doing(function()
---         assert(true, "should not fail")
---     end),
--- }
--- ```
local Specification = Definition:subclass("cp.spec.Specification")

--- cp.spec.Specification.is(instance) -> boolean
--- Function
--- Checks if the `instance` is an instance of `Specification`.
---
--- Presentation:
--- * instance - The instance to check
---
--- Returns:
--- * `true` if it's a `Specification` instance.
function Specification.static.is(instance)
    return type(instance) == "table" and instance.isInstanceOf and instance:isInstanceOf(Specification)
end

--- cp.spec.Specification(name) -> cp.spec.Specification
--- Constructor
--- Creates a new test suite.
function Specification:initialize(name)
    self.definitions = {}
    Definition.initialize(self, name)
end

--- cp.spec.Specification:onBeforeEach(beforeEachFn) -> cp.spec.Specification
--- Method
--- Specifies a function to execute before each of the contained specifications is run.
--- The function will be passed the [Run.This](cp.spec.Run.This.md) for the current Run.
---
--- Parameters:
--- * beforeEachFn - The function to run before each child runs.
---
--- Returns:
--- * The same `cp.spec.Specification` instance.
function Specification:onBeforeEach(beforeEachFn)
    self._beforeEach = beforeEachFn
    return self
end

--- cp.spec.Specification:onAfterEach(afterEachFn) -> cp.spec.Specification
--- Method
--- Specifies a function to execute after each of the contained specifications is run.
--- The function will be passed the [Run.This](cp.spec.Run.This.md) for the current Run.
---
--- Parameters:
--- * afterEachFn - The function to run after each child runs.
---
--- Returns:
--- * The same `cp.spec.Specification` instance.
function Specification:onAfterEach(afterEachFn)
    self._afterEach = afterEachFn
    return self
end

--- cp.spec.Specification:run() -> cp.spec.Run
--- Runs the specification, returning the [Run](cp.spec.Run.md) instance, already running.
---
--- Returns:
--- * The [Run](cp.spec.Run.md) instance.
function Specification:run()
    return Run(self.name, self)
    :onRunning(function(this)
        this:wait()
        self:_runNext(1, this)
    end)
end

-- cp.spec.Specification:_runNext(suite, index, this)
-- Method
-- Runs the next test definition at the specified `index`, if available.
-- If not, the `this:passed()` method is called to complete the test.
function Specification:_runNext(index, this)
    local t = self.definitions[index]
    if t then
        this:log("Running definition #%s", index)
        local run
        run = t:run()
        :onComplete(function()
            -- add the run reports
            this:run().report:add(run.report)
            -- onto the next run...
            self:_runNext(index + 1, this)
        end)

        -- set ourselves as the parent
        run:parent(this:run())

        if self._beforeEach then
            run:onBefore(self._beforeEach)
        end
        if self._afterEach then
            run:onAfter(self._afterEach)
        end
    else
        this:log("No more definitions. We're done.")
        this:done(true)
    end
end

--- cp.spec.Specification:with(...) -> self
--- Method
--- Adds the provided [definitions](cp.spec.Definition.md) to the suite.
--- May also pass a single `table` containing a list of definitions.
---
--- Parameters:
--- * ...           - the [definitions](cp.spec.Definition.md) to add.
---
--- Returns:
--- * The same `Specification` instance, with the definitions added.
function Specification:with(...)
    local count = select("#", ...)
    if count == 1 then
        local definition = select(1, ...)
        if type(definition) == "table" and #definition > 0 then
            self:with(table.unpack(definition))
            return self
        end
    end
    for i = 1,count do
        local t = select(i, ...)
        insert(self.definitions, t)
    end
    return self
end

return Specification