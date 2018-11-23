local require               = require

local class                 = require "middleclass"
local timer                 = require "hs.timer"

local Handler               = require "cp.spec.Handler"

local format                = string.format

--- === cp.spec.Result ===
---
--- The results of a test [run](cp.spec.Run.md).
local Result = class("cp.spec.Result")

--- cp.spec.Result(run) -> cp.spec.Result
--- Constructor
--- Creates a new test result.
function Result:initialize(run)

--- cp.spec.Result.run <cp.spec.Run>
--- Field
--- The [run](cp.spec.Run.md) the results are for.
    self.run = run

--- cp.spec.Result.passes <number>
--- Field
--- The number of passes in the run.
    self.passes = 0

--- cp.spec.Result.failures <number>
--- Field
--- The number of failures in the run.
    self.failures = 0

--- cp.spec.Result.aborts <number>
--- Field
--- The number of aborts in the run.
    self.aborts = 0

--- cp.spec.Result.startTime <number>
--- Field
--- The number of seconds since epoch when the test started, or `nil` if not started yet.
    self.startTime = nil

--- cp.spec.Result.stopTime <number>
--- Field
--- The number of seconds since epoch when the tests stopped, or `nil` if not stopped yet.
    self.stopTime = nil

--- cp.spec.Result.totalTime <number>
--- Field
--- The number of seconds the run took (may be decimal), or `nil` if the test hasn't run.
    self.totalTime = nil
end

--- cp.spec.Result:start() -> nil
--- Method
--- Logs the start time.
function Result:start()
    self.startTime = timer.secondsSinceEpoch()
    Handler.default():start(self.run)
end

--- cp.spec.Result:stop() -> nil
--- Method
--- Logs the end time.
function Result:stop()
    self.stopTime = timer.secondsSinceEpoch()
    self.totalTime = self.stopTime - self.startTime
    Handler.default():stop(self.run)
end

--- cp.spec.Result:passed([message])
--- Method
--- Records a pass, with the specified message.
---
--- Parameters:
--- * message       - an optional additional message to output.
function Result:passed(message)
    self.passes = self.passes + 1
    Handler.default():passed(self.run, message)
end

--- cp.spec.Result:failed(message)
--- Method
--- Records a fail, with the specified message.
---
--- Parameters:
--- * message       - The related message to output.
function Result:failed(message)
    self.failures = self.failures + 1
    Handler.default():failed(self.run, message)
end

--- cp.spec.Result:aborted(message)
--- Method
--- Records an abort, with the specified message.
---
--- Parameters:
--- * message       - The related message to output.
function Result:aborted(message)
    self.aborts = self.aborts + 1
    Handler.default():aborted(self.run, message)
end

--- cp.spec.Result:summary()
--- Method
--- Summarise the results.
function Result:summary()
    Handler.default():summary(self.run, self)
end

--- cp.spec.Result:add(otherResult) -> nil
--- Method
--- Adds the passes/failures/aborts from the other result into this one.
---
--- Parameters:
--- * otherResult   - The other result to add.
function Result:add(otherResult)
    self.passes = self.passes + otherResult.passes
    self.failures = self.failures + otherResult.failures
    self.aborts = self.aborts + otherResult.aborts
end

function Result:__tostring()
    return format("passed: %s; failed: %s; aborted: %s; time: %.4fs", self.passes, self.failures, self.aborts, self.totalTime or 0)
end

return Result