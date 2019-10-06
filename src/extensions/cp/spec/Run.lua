local require                   = require

local log                       = require "hs.logger" .new "spec"
local inspect                   = require "hs.inspect"

local class                     = require "middleclass"

local timer                     = require "hs.timer"
local interpolate               = require "cp.interpolate"
local Handled                   = require "cp.spec.Handled"
local Message                   = require "cp.spec.Message"
local Report                    = require "cp.spec.Report"

local Observer                  = require "cp.rx" .Observer

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
---   * waiting     - The Run is waiting, and will terminate when [done()](#done) is called. (asynchronous).
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

--- cp.spec.Run.This(run, actionFn, index) -> cp.spec.Run.This
--- Constructor
--- Creates a new `Run.This` instance for a [Run](cp.spec.Run.md).
---
--- Parameters:
--- * run       - The [Run](cp.spec.Run.md).
--- * actionFn  - The action function to execute.
--- * index     - The index of the action in the current phase.
---
--- Returns:
--- * The new `Run.This`.
function Run.This:initialize(run, actionFn, index)
    assert(run ~= nil, "The Run must be provided.")
    assert(type(run) == "table", "The Run must be a Run instance.")
    self._run = run
    self._actionFn = actionFn
    self._index = index or 1
    self._phase = run.phase
    self.shared = run.shared
    self.state = Run.This.state.running
end

--- cp.spec.Run.This:run() -> cp.spec.Run
--- Method
--- Returns the current [Run](cp.spec.Run.md)
function Run.This:run()
    return self._run
end

--- cp.spec.Run:expectFail([messagePattern]) -> Run
--- Method
--- Indicates that this spec is expecting an assert/fail to occur.
--- When this is expected, it doesn't log the problem as a 'fail'. In fact, if the
--- fail doesn't occur, it will raise a failure at the end of the run.
--- The `messagePattern` can be used to ensure it's the fail you expect.
--- This should be called before the actual assert/fail would occur.
---
--- Parameters:
--- * messagePattern - The pattern to check the fail message against. If not provided, any message will match.
---
--- Returns:
--- * The same `Run` instance.
function Run:expectFail(messagePattern)
    self._expectFail = true
    self._expectFailPattern = messagePattern
    self:log("Expecting to fail, matching %q", messagePattern or ".*")
    return self
end

--- cp.spec.Run.This:expectFail([messagePattern]) -> Run.This
--- Method
--- Indicates that this spec is expecting an assert/fail to occur.
--- When this is expected, it doesn't log the problem as a 'fail'. In fact, if the
--- fail doesn't occur, it will raise a failure at the end of the run.
--- The `messagePattern` can be used to ensure it's the fail you expect.
--- This should be called before the actual assert/fail would occur.
---
--- Parameters:
--- * messagePattern - The pattern to check the fail message against. If not provided, any message will match.
---
--- Returns:
--- * The same `Run.This` instance.
function Run.This:expectFail(messagePattern)
    self:run():expectFail(messagePattern)
    return self
end

--- cp.spec.Run:isExpectingFail() -> boolean, string or nil
--- Method
--- Checks if the run is expecting a fail to occur.
--- If so, it will return the expected message pattern, if specified.
---
--- Parameters:
--- * None
---
--- Returns:
--- * boolean - `true`, if a fail is expected.
--- * string - the message pattern, if specified.
function Run:isExpectingFail()
    return self._expectFail == true, self._expectFailPattern
end

-- cp.spec.Run:_resetExpectedFail() -> nil
-- Method
-- Resets any expected fail that may be set will be cleared.
function Run:_resetExpectedFail()
    self._expectFail = nil
    self._expectFailPattern = nil
end

-- cp.spec.Run:_checkExpectedFail(message[, reset]) -> boolean
-- Method
-- Checks if the provided message matches an expected fail. If so, the expected
-- fail is reset, and `true` is returned.
--
-- Parameters:
-- * message - The fail message to check.
-- * reset - (optional) If set to `false`, the run will not be reset. Defaults to `true`.
--
-- Returns:
-- * `true` if the fail message was expected or `false` if not.
function Run:_checkExpectedFail(message, reset)
    if self._expectFail then
        local pattern = self._expectFailPattern
        if pattern == nil or message:match(pattern) then
            self:log("Expected `fail` occurred: %q", message)
            if reset ~= false then
                self:_resetExpectedFail()
            end
            return true
        end
    end
    return false
end

--- cp.spec.Run:expectAbort([messagePattern]) -> Run
--- Method
--- Indicates that this spec is expecting an abort/`error` to occur.
--- When this is expected, it doesn't log the problem as a 'fail'. In fact, if the
--- it doesn't occur at some point during the run, it will raise a failure at the end of the run.
--- The `messagePattern` can be used to ensure it's the fail you expect.
--- This should be called before the actual abort/`error` would occur.
---
--- Parameters:
--- * messagePattern - The pattern to check the fail message against. If not provided, any message will match.
---
--- Returns:
--- * The same `Run` instance.
function Run:expectAbort(messagePattern)
    self._expectAbort = true
    self._expectAbortPattern = messagePattern
    self:log("Expecting to abort, matching %q", messagePattern or ".*")
    return self
end

--- cp.spec.Run.This:expectAbort([messagePattern]) -> Run.This
--- Method
--- Indicates that this spec is expecting an abort/`error` to occur.
--- When this is expected, it doesn't log the problem as a 'fail'. In fact, if the
--- it doesn't occur at some point during the run, it will raise a failure at the end of the run.
--- The `messagePattern` can be used to ensure it's the fail you expect.
--- This should be called before the actual abort/`error` would occur.
---
--- Parameters:
--- * messagePattern - The pattern to check the fail message against. If not provided, any message will match.
---
--- Returns:
--- * The same `Run.This` instance.
function Run.This:expectAbort(messagePattern)
    self:run():expectAbort(messagePattern)
    return self
end

--- cp.spec.Run:isExpectingAbort() -> boolean, string or nil
--- Method
--- Checks if the run is expecting a abort/error to occur.
--- If so, it will return the expected message pattern as the second value, if specified.
---
--- Parameters:
--- * None
---
--- Returns:
--- * boolean - `true`, if a fail is expected.
--- * string - the message pattern, if specified.
function Run:isExpectingAbort()
    return self._expectAbort == true, self._expectAbortPattern
end

-- cp.spec.Run:_resetExpectedAbort() -> nil
-- Method
-- Resets any expected abort/error that may be set will be cleared.
function Run:_resetExpectedAbort()
    self._expectAbort = nil
    self._expectAbortPattern = nil
end

-- cp.spec.Run:_checkExpectedAbort(message[, reset]) -> boolean
-- Method
-- Checks if the provided message matches an expected abort/error. If so, the expected
-- fail is reset, and `true` is returned.
--
-- Parameters:
-- * message - The fail message to check.
-- * reset - (optional) If set to `false`, the run will not be reset. Defaults to `true`.
--
-- Returns:
-- * `true` if the fail message was expected or `false` if not.
function Run:_checkExpectedAbort(message, reset)
    if self._expectAbort then
        local pattern = self._expectAbortPattern
        if pattern == nil or message:match(pattern) then
            self:log("Expected `fail` occurred: %q", message)
            if reset ~= false then
                self:_resetExpectedAbort()
            end
            return true
        end
    end
    return false
end

--- cp.spec.Run.This:toObserver([onNext[, onError[, onCompleted]]) -> cp.rx.Observer
--- Method
--- Creates an [Observer](cp.rx.Observer.md). If the `onNext`/`onError`/`onCompleted` functions are
--- not provided, then it will provide defaults. `onNext` will be logged, `onError` will throw an error,
--- and `onCompleted` will trigger [done](#done).
---
--- Parameters:
--- * onNext - The `next` handler.
--- * onError - The `error` handler.
--- * onCompleted - The `completed` handler.
function Run.This:toObserver(onNext, onError, onCompleted)
    onNext = onNext or function(value) self:log("onNext: %s", inspect(value)) end
    onError = onError or error
    onCompleted = onCompleted or function() self:done() end
    return Observer.create(onNext, onError or error, onCompleted)
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
        self:run():timeoutAfter(timeout, function()
            local seconds = timeout == 1 and "second" or "seconds"
            self:abort(format("Timed out after %d %s.", timeout, seconds))
        end)
        self:run().report:waiting(timeout)
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

--- cp.spec.Run.This:done()
--- Method
--- Indicates that the test is completed.
function Run.This:done()
    self:log("This: done")
    local expecting, pattern = self:run():isExpectingFail()
    if expecting then
        local withPattern = format(" with %q", pattern) or ""
        self:run():_resetExpectedFail()
        self:fail(format("[%s:%d] %s", debug.getinfo(2, 'S').short_src, debug.getinfo(2, 'l').currentline, "Expected to fail" ..withPattern))
        return
    end

    expecting, pattern = self:run():isExpectingAbort()
    if expecting then
        local withPattern = format(" with %q", pattern) or ""
        self:run():_resetExpectedAbort()
        self:fail(format("[%s:%d] %s", debug.getinfo(2, 'S').short_src, debug.getinfo(2, 'l').currentline, "Expected to abort" ..withPattern))
        return
    end

    self.state = Run.This.state.done
    self:run():_doPhaseAction(self._index + 1)
end

-- cp.spec.Run.This:_complete()
-- Method
-- Completes this run.
function Run.This:_complete()
    -- log.df("Run.This:_complete: index = %d", self._index)
    self:cleanup()
    if self:isActive() then
        -- log.df("Run.This:_complete: is active...")
        self.state = Run.This.state.done
        self:run():_doPhaseAction(self._index + 1)
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
    local expecting, pattern = self:run():isExpectingAbort()
    if expecting then
        local matchPattern = pattern == nil or (message or ""):match(".*" .. pattern) ~= false
        if matchPattern then
            self:log("This: abort: was expected: %s", message)
            self:run():_resetExpectedAbort()
            return false
        end
    end
    self:run():_doAbort(message)
    return true
end

--- cp.spec.Run.This:fail([message])
--- Method
--- Indicates the run has failed.
---
--- Parameters:
--- * message   - The optional message to output.
function Run.This:fail(message)
    self:log("This: fail: %s", message)
    local expecting, pattern = self:run():isExpectingFail()
    if expecting then
        local matchPattern = pattern == nil or (message or ""):match(".*" .. pattern) ~= false
        if matchPattern then
            self:log("This: fail: was expected: %s", message)
            self:run():_resetExpectedFail()
            return false
        end
    end
    self:run():_doFail(message)
    return true
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

    if ok ~= true then
        if not Handled.is(err) then
            -- there was an error, and is has not been handled already
            self:log("Action #%d failed. Aborting...", self._index)
            self:run():_doAbort(err)
        end
    elseif not self:isWaiting() then
        self:log("Action #%d completed.", self._index)
        self:run():_doPhaseAction(self._index + 1)
    else
        self:log("Action #%d is waiting...", self._index)
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
    self:run():timeoutCancelled()
end

-- looks up the value from the shared data.
function Run.This:__index(key)
    return self.shared[key]
end

function Run.This:__tostring()
    return format("This: %s: %s #%d", self:run(), self._phase, self._index)
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
--- * source        - The object (typically a [Definition](cp.spec.Definition.md)) that initiated the run.
function Run:initialize(name, source)

--- cp.spec.Run.report <cp.spec.Report>
--- Field
--- The reports of the run.
    self.report = Report(self)

    self._name = name
    -- log.df("Run:initialize: self.realName = %s", type(self.realName))

--- cp.spec.Run.source
--- Field
--- The object that initiated the run. Typically a [Definition](cp.spec.Definition.md).
    self.source = source

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
    -- self:log("_do: called...")
    self:_doCancelled()
    -- self:log("_do: previous 'do' cancelled...")
    self._runTimer = timer.doAfter(0, function()
        -- log.df("Run:_do: doAfter: called...")
        self._runTimer = nil
        -- log.df("Run:_do: Executing runFn...")
        runFn()
    end)
    -- self:log("_do: timer running...")
end

function Run:_doCancelled()
    -- log.df("Run:_doCancelled: called...")
    if self._runTimer then
        -- log.df("Run:_doCancelled: cancelling _runTimer")
        self._runTimer:stop()
        self._runTimer = nil
    end
end

function Run:timeoutAfter(seconds, thenFn)
    -- log.df("Run:timeoutAfter: seconds = %s", seconds)
    self:timeoutCancelled()
    self._timeoutTimer = timer.doAfter(seconds, function()
        self:timeoutCancelled()
        thenFn()
    end)
end

function Run:timeoutCancelled()
    -- log.df("Run:timeoutCancelled: called...")
    if self._timeoutTimer then
        -- log.df("Run:timeoutCancelled: got timer to cancel.")
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

--- cp.spec.Run.This:log(message[, ...])
--- Method
--- When the current [Run](cp.spec.Run.md) is in [debug](#debug) mode, output the message to the console.
---
--- Parameters:
--- * message   - the text message to output.
--- * ...       - optional parameters, to be injected into the message, ala `string.format`.
function Run.This:log(message, ...)
    return self:run():log(message, ...)
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
    -- self:log("_doPhaseAction: %d", index)
    local currentPhase = self.phase
    local currentActions = self.phaseActions[currentPhase]
    local actionFn = currentActions and currentActions[index]
    if actionFn then
        self:log("Running action #%d (%s) in %s phase...", index, type(actionFn), currentPhase)
        self:_do(function()
            -- log.df("_doPhaseAction: _do: running _this...")
            self._this = Run.This(self, actionFn, index)
            self._this()
            -- log.df("_doPhaseAction: _do: _this queued...")
        end)
        -- log.df("_doPhaseAction: #%d sent to _do...", index)
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
    -- log.df("Run:_doFail: called")
    self:timeoutCancelled()
    self.report:failed(err)
    self.result = Run.result.failed

    local currentPhase = self.phase
    if currentPhase then
        -- log.df("Run:_doFail: doing phase %s", currentPhase.abort)
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
    return interpolate(self._name, self.shared)
end

function Run:fullName()
    local parent = self:parent()
    local parentName = parent and parent:fullName() .. " > " or ""
    return parentName .. self:realName()
end

function Run:__tostring()
    return self:fullName()
end

return Run