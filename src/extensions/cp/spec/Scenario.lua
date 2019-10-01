local require               = require

local log                   = require "hs.logger" .new "Scenario"

local Definition            = require "cp.spec.Definition"
local Handled               = require "cp.spec.Handled"
local Run                   = require "cp.spec.Run"
local Where                 = require "cp.spec.Where"

local format                = string.format

--- === cp.spec.Scenario ===
---
--- A [Definition](cp.spec.Definition.md) which describes a specific scenario.
---
--- A `Scenario` is most typically created via the [it](cp.spec.md#it) function, like so:
---
--- ```lua
--- local spec          = require "cp.spec"
--- local describe, it  = spec.describe, spec.it
---
--- local Rainbow       = require "my.rainbow"
---
--- return describe "a rainbow" {
---     it "has seven colors"
---     :doing(function()
---         local rainbow = Rainbow()
---         assert(#rainbow:colors() == 7, "the rainbow has seven colors")
---     end)
--- }
--- ```
---
--- Scenarios can be run asynchronously via the [Run.This](cp.spec.Run.This.md) instance passed to the `doing` function.
--- To indicate a scenario is asynchronous, call [`this:wait()`](cp.spec.Run.This.md#wait), then call
--- [`this:done()`](cp.spec.Run.This.md#done), to indicate it has completed. Any `assert` call which fails will
--- result in the run failing, and stop at that point.
---
--- For example:
---
--- ```lua
--- return describe "a rainbow" {
---     it "has a pot of gold at the end"
---     :doing(function(this)
---         this:wait()
---         local rainbow = Rainbow()
---         rainbow:goToEnd(function(whatIsThere)
---             assert(whatIsThere:isInstanceOf(PotOfGold))
---             this:done()
---         end)
---     end)
--- }
--- ```
---
--- Definitions can also be data-driven, via the [where](#where) method:
---
--- ```lua
--- return describe "a rainbow" {
---     it "has ${color} at index ${index}"
---     :doing(function(this)
---         local rainbow = Rainbow()
---         assert(rainbow[this.index] == this.color)
---     end)
---     :where {
---         { "index",  "color"     },
---         { 1,        "red"       },
---         { 2,        "orange"    },
---         { 3,        "yellow"    },
---         { 4,        "blue"      },
---         { 5,        "green"     },
---         { 6,        "indigo"    },
---         { 7,        "violet"    },
---     },
--- }
--- ```
---
--- This will do a run for each variation and interpolate the value into the run name for each.
---
--- **Note:** "where" parameters will not override built-in functions and fields in the [this](cp.spec.Run.This.md)
--- instance (such as "async" or "done") so ensure that you pick names that don't clash.
local Scenario = Definition:subclass("cp.spec.Scenario")

-- default `doing` function for Definitions.
local function doingNothing()
    error("It must be doing something.")
end

--- cp.spec.Scenario(name[, testFn]) -> cp.spec.Scenario
--- Constructor
--- Creates a new `Scenario` with the specified name.
---
--- Parameters:
--- * name          - The name of the scenario.
--- * testFn     - (optional) The `function` which performs the test for in the scenario.
---
--- Returns:
--- * The new `Scenario`.
---
--- Notes:
--- * If the `testFn` is not provided here, it must be done via the [doing](#doing) method prior to running,
---   an `error` will occur.
function Scenario:initialize(name, testFn)
    Definition.initialize(self, name)
    self.testFn = testFn or doingNothing
end

--- cp.spec.Scenario:doing(actionFn) -> self
--- Method
--- Specifies the `function` for the definition.
---
--- Parameters:
--- * testFn     - The function that will do the test.
---
--- Returns:
--- * The same `Definition`.
function Scenario:doing(testFn)
    if type(testFn) ~= "function" then
        error("Provide a function to execute.")
    end
    if self.testFn and self.testFn ~= doingNothing then
        error("It already has a test function.")
    end
    self.testFn = testFn
    return self
end

local ASSERT = {}
local ERROR = {}

-- hijacks the global `assert` and `error` functions and captures the results as part of the spec.
local function hijackAssert(this)
    -- log.df(">>> hijackAssert: called")
    this:run()[ASSERT] = _G.assert
    this:run()[ERROR] = _G.error
    _G.assert = function(ok, message, level)
        level = (level or 1) + 1
        -- log.df("hijacked assert: called with %s, %q", ok, string.format(message, ...))
        if ok then
            -- log.df("hijacked assert: passed")
            return ok, message
        else
            local msg = tostring(message)
            if this:fail(format("[%s:%d] %s", debug.getinfo(level, 'S').short_src, debug.getinfo(level, 'l').currentline, msg)) then
                this:run()[ASSERT](ok, Handled(msg, level))
            end
        end
    end

    _G.error = function(msg, level)
        level = (level or 1) + 1
        -- log.df("hijacked error: %s", msg)
        if this:abort(format("[%s:%d] %s", debug.getinfo(level, 'S').short_src, debug.getinfo(level, 'l').currentline, msg)) then
            this:run()[ERROR](msg, level)
        end
    end
end

-- restores the global `assert` and `error` functions to their previous values.
local function restoreAssert(this)
    -- log.df(">>> restoreAssert: called")
    if this:run()[ASSERT] then
        -- log.df("restoreAssert: resetting assert")
        _G.assert = this:run()[ASSERT]
        this:run()[ASSERT] = nil
    end
    if this:run()[ERROR] then
        _G.error = this:run()[ERROR]
        this:run()[ERROR] = nil
    end
end

--- cp.spec.Scenario:run(...) -> cp.spec.Run
--- Method
--- Runs the scenario.
---
--- Parameters:
--- * ...   - The list of filters. The first one will be compared to this scenario to determine it should be run.
function Scenario:run()
    -- TODO: support filtering
    return Run(self.name)
    :onBefore(hijackAssert)
    :onRunning(self.testFn)
    :onAfter(restoreAssert)
    :onComplete(function(this)
        if this:run().result == Run.result.running then
            this:run().report:passed()
        end
    end)
end

--- cp.spec.Scenario:where(data) -> cp.spec.Where
--- Method
--- Specifies a `table` of data that will be iterated through as multiple [Runs](cp.spec.Run.md), one row at a time.
--- The first row should be all strings, which will be the name of the parameter. Subsequent rows are the values for
--- those rows.
---
--- Parameters:
--- * data      - The data table.
---
--- Returns:
--- * The [Where](cp.spec.Where.md).
function Scenario:where(data)
    return Where(self, data)
end

return Scenario