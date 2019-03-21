local require               = require

local class                 = require "middleclass"
local timer                 = require "hs.timer"

local Handler               = require "cp.spec.Handler"

local format                = string.format

--- === cp.spec.Report ===
---
--- The results of a test [run](cp.spec.Run.md).
local Report = class("cp.spec.Report")

--- cp.spec.Report(run) -> cp.spec.Report
--- Constructor
--- Creates a new test report.
function Report:initialize(run)

--- cp.spec.Report.run <cp.spec.Run>
--- Field
--- The [run](cp.spec.Run.md) the reports are for.
    self.run = run

--- cp.spec.Report.passes <number>
--- Field
--- The number of passes in the run.
    self.passes = 0

--- cp.spec.Report.failures <number>
--- Field
--- The number of failures in the run.
    self.failures = 0

--- cp.spec.Report.aborts <number>
--- Field
--- The number of aborts in the run.
    self.aborts = 0

--- cp.spec.Report.startTime <number>
--- Field
--- The number of seconds since epoch when the test started, or `nil` if not started yet.
    self.startTime = nil

--- cp.spec.Report.stopTime <number>
--- Field
--- The number of seconds since epoch when the tests stopped, or `nil` if not stopped yet.
    self.stopTime = nil

--- cp.spec.Report.totalTime <number>
--- Field
--- The number of seconds the run took (may be decimal), or `nil` if the test hasn't run.
    self.totalTime = nil
end

--- cp.spec.Report:start() -> nil
--- Method
--- Logs the start time.
function Report:start()
    self.startTime = timer.secondsSinceEpoch()
    Handler.default():start(self.run)
end

--- cp.spec.Report:stop() -> nil
--- Method
--- Logs the end time.
function Report:stop()
    self.stopTime = timer.secondsSinceEpoch()
    self.totalTime = self.stopTime - self.startTime
    Handler.default():stop(self.run)
end

--- cp.spec.Report:passed([message])
--- Method
--- Records a pass, with the specified message.
---
--- Parameters:
--- * message       - an optional additional message to output.
function Report:passed(message)
    self.passes = self.passes + 1
    Handler.default():passed(self.run, message)
end

--- cp.spec.Report:failed(message)
--- Method
--- Records a fail, with the specified message.
---
--- Parameters:
--- * message       - The related message to output.
function Report:failed(message)
    self.failures = self.failures + 1
    Handler.default():failed(self.run, message)
end

--- cp.spec.Report:aborted(message)
--- Method
--- Records an abort, with the specified message.
---
--- Parameters:
--- * message       - The related message to output.
function Report:aborted(message)
    self.aborts = self.aborts + 1
    Handler.default():aborted(self.run, message)
end

--- cp.spec.Report:waiting(timeout)
--- Method
--- Records that a run is waiting for up to the specified amount of time.
---
--- Parameters:
--- * timeout   - The timeout to wait for, in seconds.
function Report:waiting(timeout)
    Handler.default():waiting(self.run, timeout)
end

--- cp.spec.Report:summary()
--- Method
--- Summarise the reports.
function Report:summary()
    Handler.default():summary(self.run, self)
end

--- cp.spec.Report:add(otherReport) -> nil
--- Method
--- Adds the passes/failures/aborts from the other report into this one.
---
--- Parameters:
--- * otherReport   - The other report to add.
function Report:add(otherReport)
    self.passes = self.passes + otherReport.passes
    self.failures = self.failures + otherReport.failures
    self.aborts = self.aborts + otherReport.aborts
end

function Report:__tostring()
    return format("passed: %s; failed: %s; aborted: %s; time: %.4fs", self.passes, self.failures, self.aborts, self.totalTime or 0)
end

return Report