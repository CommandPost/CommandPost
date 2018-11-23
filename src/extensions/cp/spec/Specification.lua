local require               = require

local log                   = require "hs.logger" .new "Specification"

local Definition            = require "cp.spec.Definition"
local Run                   = require "cp.spec.Run"

local insert                = table.insert

--- === cp.spec.Specification ===
---
--- A Specification is a list of [definitions](cp.spec.Definition.md) which
--- will be run in sequence, and the results are collated. It is often created via
--- the [describe](cp.spec.md#describe) function.
local Specification = Definition:subclass("cp.spec.Specification")

--- cp.spec.Specification(name) -> cp.spec.Specification
--- Constructor
--- Creates a new test suite.
function Specification:initialize(name)
    self.definitions = {}
    Definition.initialize(self, name)
end

--- cp.spec.Specification:run() -> cp.spec.Run
--- Runs the specification, returning the [Run](cp.spec.Run.md) instance, already running.
---
--- Returns:
--- * The [Run](cp.spec.Run.md) instance.
function Specification:run()
    return Run(self.name)
    :onRunning(function(this)
        log.df("%s: onRunning: marking as waiting, calling runNext", self.name)
        this:wait()
        self:runNext(1, this)
    end)
    :onComplete(function(this)
        log.df("%s: onComplete: checking if we should output the summary.", self.name)
        -- output the summary if this is the root.
        if this.run:parent() == nil or this.run:verbose() then
            this.run.result:summary()
        end
    end)
end

-- runNext(suite, index, this)
-- Function
-- Runs the next test definition at the specified `index`, if available.
-- If not, the `this:passed()` method is called to complete the test.
function Specification:runNext(index, this)
    log.df("runNext()")
    local t = self.definitions[index]
    if t then
        log.df("%s: runNext: Running definition %s", self.name, index)
        local run
        run = t:run()
        :onComplete(function()
            -- add the run results
            this.run.result:add(run.result)
            -- onto the next run...
            self:runNext(index + 1, this)
        end)

        -- set ourselves as the parent
        run:parent(this.run)

        if self._beforeEach then
            run:onBefore(self._beforeEach)
        end
        if self._afterEach then
            run:onAfter(self._afterEach)
        end
    else
        log.df("%s: runNext: No more definitions. We're done.", self.name)
        this:done()
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