local require                   = require

local log                       = require "hs.logger" .new "spec"

local class                     = require "middleclass"
local timer                     = require "hs.timer"
local Handled                   = require "cp.spec.Handled"
local Message                   = require "cp.spec.Message"
local Report                    = require "cp.spec.Report"

local format                    = string.format
local insert                    = table.insert

--- === cp.spec.Run ===
---
--- An individual run of a test [Definition](cp.spec.Definition.md) or [Specification](cp.spec.Specification.md).
local Run = class("cp.spec.Run")

--- === cp.spec.Run.This ===
---
--- A token passed to test functions to allow them to indicate if a test [run](cp.spec.Run.md)
--- will complete asynchronously.
Run.static.This = class("cp.spec.Run.This")

--- cp.spec.Run.This.state
--- Constant
--- A collection of states that a `Run.This` can be in.
---
--- Notes:
--- * States include:
---   * running     - The Run is currently running and will terminate at the end of the function (synchrnonous).
---   * waiting     - The Run is waiting,  and will terminate when [done()](#done) is called. (asynchronous).
---   * done        - The Run is done.
Run.This.static.state = {
    running = "running",
    waiting = "waiting",
    done = "done",
}

local asyncTimeout = 10

--- cp.spec.Run.This.defaultTimeout([timeout]) -> number
--- Function
--- Gets and/or sets the default timeout for asynchronous tests.
--- Defaults to 60 seconds.
---
--- Parameters:
--- * timeout       - (optional) the new timeout, in seconds.
---
--- Returns:
--- * The current default timeout, in seconds.
function Run.This.static.defaultTimeout(timeout)
    if timeout then
        asyncTimeout = timeout
    end
    return asyncTimeout
end

--- cp.spec.Run.This(run, index) -> cp.spec.Run.This
--- Constructor
--- Creates a new `Run.This` instance for a [Run](cp.spec.Run.md).
---
--- Parameters:
--- * run       - The [Run](cp.spec.Run.md).
--- * index     - The index of the action in the current phase.
---
--- Returns:
--- * The new `Run.This`.
function Run.This:initialize(run, actionFn, index)
    assert(run ~= nil, "The Run must be provided.")
    assert(type(run) == "table", "The Run must be a Run instance.")
    self._run = run
    self._actionFn = actionFn
    self._index = index
    self._phase = run.phase
    self.shared = run.shared
    self.state = Run.This.state.running
end

--- cp.spec.Run.This:isActive() -> boolean
--- Method
--- Checks if the this is in an active state - either `running` or `waiting`.
---
--- Returns:
--- * `true` if isActive.
function Run.This:isActive()
    return self.state == Run.This.state.running or self.state == Run.This.state.waiting
end

--- cp.spec.Run.This:wait([timeout])
--- Method
--- Indicates that the test is continuing asynchronously, and will
--- be completed by calling [done](#done).
---
--- Parameters:
--- * timeout       - (optional) The number of seconds to wait before timing out.
---
--- Notes:
--- * If not provided, [Run.This.defaultTimeout()](cp.spec.Run.This.md#defaultTimeout) is used.
function Run.This:wait(timeout)
    self.state = Run.This.state.waiting
    timeout = timeout or Run.This.defaultTimeout()

    if timeout then
        self._run:timeoutAfter(timeout, function()
            local seconds = timeout == 1 and "second" or "seconds"
            self:abort(format("Timed out after %d %s.", timeout, seconds))
        end)
        self._run.report:waiting(timeout)
    end
end

--- cp.spec.Run.This:isWaiting() -> boolean
--- Method
--- Checks if the [Run](cp.spec.Run.md) is waiting for this execution to complete via the
--- [done](cp.spec.Run.This.md#done) method.
---
--- Returns:
--- * `true` if the waiting.
function Run.This:isWaiting()
    return self.state == Run.This.state.waiting
end

--- cp.spec.Run.This:log(message[, ...])
--- Method
--- When the current [Run](cp.spec.Run.md) is in [debug](cp.spec.Run.md#debug) mode, output the message to the console.
---
--- Parameters:
--- * message   - the text message to output.
--- * ...       - optional parameters, to be injected into the message, ala `string.format`.
function Run.This:log(message, ...)
    self._run:log(message, ...)
end

--- cp.spec.Run.This:done()
--- Method
--- Indicates that the test is completed.
function Run.This:done()
    self:log("This: done")
    self.state = Run.This.state.done
    self._run:_doPhaseAction(self._index + 1)
end

-- cp.spec.Run.This:_complete()
-- Method
-- Completes this run.
function Run.This:_complete()
    log.df("Run.This:_complete: index = %d", self.index)
    self:cleanup()
    if self:isActive() then
        log.df("Run.This:_complete: is active...")
        self.state = Run.This.state.done
        self._run:_doPhaseAction(self.index + 1)
    end
end

--- cp.spec.Run.This:isDone() -> boolean
--- Method
--- Returns `true` if this is done.
function Run.This:isDone()
    return self.state == Run.This.state.done
end

--- cp.spec.Run.This:abort([message])
--- Method
--- Indicates the stage has aborted.
---
--- Parameters:
--- * message   - The optional message to output.
function Run.This:abort(message)
    self:log("This: abort: %s", message)
    self._run:_doAbort(message)
end

--- cp.spec.Run.This:fail([message])
--- Method
--- Indicates the run has failed.
---
--- Parameters:
--- * message   - The optional message to output.
function Run.This:fail(message)
    self:log("This: fail: %s", message)
    self._run:_doFail(message)
end

function Run.This:__call()
    local ok, err = xpcall(function() self._actionFn(self) end, function(err)
        -- if there's an error, make sure it's a Message.
        if not Message.is(err) then
            err = Message(err)
        end
        -- Then dump the traceback.
        err:traceback()
        -- then return it.
        return err
    end)

    if ok ~= true and not Handled.is(err) then
        -- there was an error, and is has not been handled already
        self:log("Action #%d failed. Aborting...", index)
        self:_doAbort(err)
    elseif not this:isWaiting() then
        self:log("Action #%d completed.", index)
        self:_doPhaseAction(index + 1)
    else
        self:log("Action #%d is waiting...", index)
    end
end

--- cp.spec.Run.This:prepare()
--- Method
--- Prepares this to run.
function Run.This.prepare()
end

--- cp.spec.Run.This:cleanup()
--- Method
--- Cleans up This after a step.
function Run.This:cleanup()
    self._run:timeoutCancelled()
end

-- looks up the value from the shared data.
function Run.This:__index(key)
    return self.shared[key]
end

function Run.This:__tostring()
    return format("This: %s: %s #%d", self._run, self._phase, self._index)
end

Run.Phase = class("cp.spec.Run.Phase")

function Run.Phase:initialize(name)
    self.name = name
end

function Run.Phase:__tostring()
    return self.name
end

function Run.Phase:__eq(other)
    return self.name == other.name
end

function Run.Phase:onNext(next)
    if next then
        self.next = next
    end
    return self
end

function Run.Phase:onAbort(abort)
    if abort then
        self.abort = abort
    end
    return self
end

--- cp.spec.Run.phase <table>
--- Constant
--- The list of phases a `run` can be in.
---
--- Notes:
--- * Maybe one of:
---   * `start`         - has been initiated, but not started any actual actions.
---   * `before`        - any `before` callbacks present are being processed.
---   * `running`       - the actual test is running.
---   * `after`         - any `after` callbacks are being processed.
---   * `completed`     - the run has completed.
Run.static.phase = {
    start = Run.Phase("start"):onNext("before"):onAbort("complete"),
    before = Run.Phase("before"):onNext("running"):onAbort("after"),
    running = Run.Phase("running"):onNext("after"):onAbort("after"),
    after = Run.Phase("after"):onNext("complete"):onAbort("complete"),
    complete = Run.Phase("complete"),
}

--- cp.spec.Run.result <table>
--- Constant
--- A collection of result states for a `Run`.
---
--- Notes:
--- * Report states include:
---   * running         - The Run is currently running. Runs start in this state by default.
---   * failed          - An assertion failed.
---   * aborted         - An unexpected error happened.
Run.static.result = {
    running = "running",
    failed = "failed",
    aborted = "aborted",
}

--- cp.spec.Run(name) -> cp.spec.Run
--- Constructor
--- Creates a new test run.
---
--- Parameters:
--- * name          - The name of the run.
function Run:initialize(name)

--- cp.spec.Run.report <cp.spec.Report>
--- Field
--- The reports of the run.
    self.report = Report(self)

    self._name = name
    -- log.df("Run:initialize: self.realName = %s", type(self.realName))

    self.phaseActions = {}

--- cp.spec.Run.shared <table>
--- Field
--- The set of data shared by all phases of the Run. Data from parent Runs will also be available.
    self.shared = setmetatable({}, {
        __index = function(_, key)
            -- look up the parent Run's shared data, if available.
            if self._parent then
                return self._parent.shared[key]
            end
        end
    })

--- cp.spec.Run.phase <cp.spec.Run.phase>
--- Field
--- The current [phase](#phase) of the run.
    self.phase = nil

--- cp.spec.Run.result <cp.spec.Run.result>
--- Field
--- The current result. Defaults to `Run.result.passing`.
    self.result = nil

    -- set a timer to automatically start the run
    self:_do(function()
        self.report:start()
        self.result = Run.result.running
        self:_doPhase(Run.phase.start)
    end)
end

function Run:_do(runFn)
    self:_doCancelled()
    self._runTimer = timer.doAfter(0, function()
        self._runTimer = nil
        runFn()
    end)
end

function Run:_doCancelled()
    if self._runTimer then
        self._runTimer:stop()
        self._runTimer = nil
    end
end

function Run:timeoutAfter(seconds, thenFn)
    log.df("Run:timeoutAfter: seconds = %s", seconds)
    self:timeoutCancelled()
    self._timeoutTimer = timer.doAfter(seconds, function()
        self:timeoutCancelled()
        thenFn()
    end)
end

function Run:timeoutCancelled()
    log.df("Run:timeoutCancelled: called...")
    if self._timeoutTimer then
        log.df("Run:timeoutCancelled: got timer to cancel.")
        self._timeoutTimer:stop()
        self._timeoutTimer = nil
    end
end

--- cp.spec.Run:debug() -> cp.spec.Run
--- Method
--- Enables debugging on this `Run`. Any calls to [#log] will be output to the console.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The same `Run` instance.
function Run:debug()
    self._debug = true
    return self
end

--- cp.spec.Run:isDebugging() -> boolean
--- Method
--- Checks if `debug` has been enabled on this or any parent `Run`.
function Run:isDebugging()
    return self._debug or self._parent ~= nil and self._parent:isDebugging()
end

--- cp.spec.Run:log(message[, ...])
--- Method
--- When the current [Run](cp.spec.Run.md) is in [debug](#debug) mode, output the message to the console.
---
--- Parameters:
--- * message   - the text message to output.
--- * ...       - optional parameters, to be injected into the message, ala `string.format`.
function Run:log(message, ...)
    if self:isDebugging() then
        log.df("%s: " .. message, self, ...)
    end
end

-- cp.spec.Run:_doPhase(nextPhase)
-- Method
-- If `nextPhase` is `nil`, starts performing any actions for that phase.
-- Once all actions are completed, it moves onto the `next` phase. If there
-- is an abort (error), it will move on to the `abort` phase.
function Run:_doPhase(nextPhase)
    self:log("Starting phase: %s", nextPhase)
    if type(nextPhase) == "string" then -- find the next phase.
        nextPhase = Run.phase[nextPhase]
    end

    if nextPhase then -- we found it...
        self.phase = nextPhase
        self:_doPhaseAction(1)
    else -- no more phases. Do the report.
        self:_doReport()
    end
end

-- cp.spec.Run._doPhaseAction(index)
-- Method
-- Performs the next action in the current phase at the specifed index.
-- If none is available, it moves onto the next phase. If the action
-- triggers an error, it is logged in the `report` and we move to the `abort`
-- phase for the current phase.
function Run:_doPhaseAction(index)
    self:log("_doPhaseAction: %d", index)
    local currentPhase = self.phase
    local currentActions = self.phaseActions[currentPhase]
    local actionFn = currentActions and currentActions[index]
    if actionFn then
        self:log("Running action #%d in %s phase...", index, currentPhase)
        self:_do(function()
            -- self:log("_doPhaseAction: running timer...")
            self._this = Run.This(self, actionFn, index)
            self._this()
        end)
    else
        self:_doNext()
    end
end

-- cp.spec.Run:_doNext(index)
-- Method
-- Moves on the next phase for the run.
function Run:_doNext()
    self:timeoutCancelled()
    local currentPhase = self.phase
    if currentPhase then
        self:_doPhase(currentPhase.next)
    end
end

-- cp.spec.Run:_doAbort(err)
-- Method
-- Logs the error with the current report's `aborted` log and begins processing the
-- `abort` phase for the current phase.
function Run:_doAbort(err)
    self:timeoutCancelled()
    self.report:aborted(err)
    self.result = Run.result.aborted

    local currentPhase = self.phase
    if currentPhase then
        self:_doPhase(currentPhase.abort)
    end
end

-- cp.spec.Run:_doFail(err)
-- Method
-- Logs the error with the current report's `fail` log and begins processing the
-- `abort` phase for the current phase.
function Run:_doFail(err)
    self:timeoutCancelled()
    self.report:failed(err)
    self.result = Run.result.failed

    local currentPhase = self.phase
    if currentPhase then
        self:_doPhase(currentPhase.abort)
    end
end

-- cp.spec.Run:_doReport()
-- Method
-- Outputs the [Report](cp.spec.Report.md) for the run, if appropriate.
function Run:_doReport()
    self.report:stop()
    if self:parent() == nil or self:verbose() then
        self.report:summary()
    end
end

-- cp.spec.Run:_addAction(phase, actionFn)
-- Method
-- Adds the specified `actionFn` function to the specified phase.
function Run:_addAction(phase, actionFn)
    assert(type(actionFn) == "function", "The action must be a function")
    local phaseActions = self.phaseActions[phase]
    if not phaseActions then
        phaseActions = {}
        self.phaseActions[phase] = phaseActions
    end
    insert(phaseActions, actionFn)
    return self
end

--- cp.spec.Run:parent([parent]) -> cp.spec.Run
--- Method
--- Gets and/or sets the parent `Run` for this run.
---
--- Parameters:
--- * parent        - (optional) If set, will set the parent `Run`.
---
--- Returns:
--- * The current parent `Run`.
---
--- Notes:
--- * If a `parent` is provided and there is already another Run set as a parent, an error is thrown.
function Run:parent(parent)
    if parent then
        if self._parent then
            error(format("Run already has a parent: %s", self._parent))
        else
            self._parent = parent
            return self
        end
    end
    return self._parent
end

--- cp.spec.Run:verbose([isVerbose]) -> boolean | self
--- Method
--- Either sets the `verbose` value and returns itself for further chaining, or returns
--- the current verbose status.
---
--- Parameters:
--- * isVerbose     - (optional) if `true` or `false` will update the verbose status and return this `Run`.
---
--- Returns:
--- * The current `verbose` status, or this `Run` if `isVerbose` is provided.
function Run:verbose(isVerbose)
    if isVerbose ~= nil then
        self._verbose = isVerbose ~= false
        return self
    else
        local parent = self:parent()
        return self._verbose == true or parent ~= nil and parent:verbose()
    end
end

function Run:onStart(actionFn)
    return self:_addAction(Run.phase.start, actionFn)
end

--- cp.spec.Run:onBefore(actionFn) -> self
--- Method
--- Adds a callback function to run prior to executing the actual test.
---
--- Parameters:
--- * actionFn      - The function to run, passed this `Run.This` as the first parameter.
function Run:onBefore(beforeFn)
    return self:_addAction(Run.phase.before, beforeFn)
end

--- cp.spec.Run:onRunning(actionFn) -> self
--- Method
--- Adds a callback function to run during the test.
---
--- Parameters:
--- * runningFn     - The function to run, passed [Run.This](cp.spec.Run.This.md) as the first parameter.
function Run:onRunning(runningFn)
    return self:_addAction(Run.phase.running, runningFn)
end

--- cp.spec.Run:onBfter(actionFn) -> self
--- Method
--- Adds a callback function to run after to executing the actual test, pass or fail.
---
--- Parameters:
--- * actionFn      - The function to run, passed this `Run` as the first parameter.
function Run:onAfter(actionFn)
    return self:_addAction(Run.phase.after, actionFn)
end

function Run:onComplete(actionFn)
    return self:_addAction(Run.phase.complete, actionFn)
end

function Run:realName()
    -- self:log("Retrieving name: %s", self._name)
    -- return interpolate(self._name, self.shared)
    return self._name
end

function Run:fullName()
    local parent = self:parent()
    local parentName = parent and parent:fullName() .. " > " or ""
    -- log.df("Run:fullName: realName = %s", hs.inspect(self.realName))
    -- log.df("Run:fullName: _name = %s", hs.inspect(self._name))
    return parentName .. self:realName()
end

function Run:__tostring()
    return self:fullName()
end

return Run