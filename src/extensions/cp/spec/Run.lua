local require                   = require

local log                       = require "hs.logger" .new "Run"

local class                     = require "middleclass"
local timer                     = require "hs.timer"
local Result                    = require "cp.spec.Result"

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

local asyncTimeout = 60

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

--- cp.spec.Run.This(run) -> cp.spec.Run.This
--- Constructor
--- Creates a new `Run.This` instance for a [Run](cp.spec.Run.md).
---
--- Parameters:
--- * run       - The [Run](cp.spec.Run.md).
--- * index     - The index of the action in the current phase.
---
--- Returns:
--- * The new `Run.This`.
function Run.This:initialize(run, index)
    self.run = run
    self.index = index
    self.currentPhase = run.phase
    self.state = Run.This.state.running
    self.passing = true
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
---     If not provided, [Run.This.defaultTimeout()](cp.spec.Run.This.md#defaultTimeout) is used.
function Run.This:wait(timeout)
    self.state = Run.This.state.waiting
    if timeout then
        self.timeout = timeout or Run.This.defaultTimeout()
        self.timeoutTimer = timer.doAfter(self.timeout, function()
            self.timeoutTimer = nil
            local seconds = self.timeout == 1 and "second" or "seconds"
            self:abort(format("Timed out after %d %s.", self.timeout, seconds))
        end)
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
--- Indicates that the test is completed. Must only be called after calling [Run.This:wait(...)](#wait).
---
--- Parameters:
--- * message       - (optional) The message to send if successful.
function Run.This:done()
    log.df("%s: This: done", self.run.name)
    if self.timeoutTimer then
        self.timeoutTimer:stop()
        self.timeoutTimer = nil
    end
    if self:isActive() then
        self.state = Run.This.state.done
        self.run:_doNextAction(self.index + 1)
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
    log.df("This: abort: %s", message)
    self.run.result:aborted(message)
    self.passing = false
    self:done()
end

--- cp.spec.Run.This:fail([message])
--- Method
--- Indicates the run has failed.
---
--- Parameters:
--- * message   - The optional message to output.
function Run.This:fail(message)
    log.df("This: fail: %s", message)
    self.run.result:failed(message)
    self.passing = false
    self:done()
end

--- cp.spec.Run.This:prepare()
--- Method
--- Prepares this to run.
function Run.This:prepare()
    if not self._error then
        self._error = _G.error
        _G.error = function(message, level, skipAbort)
            if not skipAbort then
                self:abort(message)
            end
            self._error(message, level)
        end
    end
end

--- cp.spec.Run.This:cleanup()
--- Method
--- Cleans up This after a step.
function Run.This:cleanup()
    if self._error then
        _G.error = self._error
        self._error = nil
    end
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

--- cp.spec.Run(name) -> cp.spec.Run
--- Constructor
--- Creates a new test run.
---
--- Parameters:
--- * name          - The name of the run.
function Run:initialize(name)

--- cp.spec.Run.result <cp.spec.Result>
--- Field
--- The results of the run.
    self.result = Result(self)

    self.name = name

    self.phaseActions = {}

--- cp.spec.Run.phase <cp.spec.Run.phase>
--- Field
--- The current [phase](#phase) of the run.
    self.phase = nil

    -- set a timer to automatically start the run
    self._currentTimer = timer.doAfter(0, function()
        self._currentTimer = nil
        self:_doPhase(Run.phase.start)
    end)
end

-- cp.spec.Run:_doPhase(nextPhase)
-- Method
-- If `nextPhase` is `nil`, starts performing any actions for that phase.
-- Once all actions are completed, it moves onto the `next` phase. If there
-- is an abort (error), it will move on to the `abort` phase.
function Run:_doPhase(nextPhase)
    -- log.df("_doPhase: %s", nextPhase)
    if type(nextPhase) == "string" then
        nextPhase = Run.phase[nextPhase]
    end
    if nextPhase then
        self.phase = nextPhase
        self:_doNextAction(1)
    end
end

-- cp.spec.Run._doNextAction(index)
-- Method
-- Performs the next action in the current phase at the specifed index.
-- If none is available, it moves onto the next phase. If the action
-- triggers an error, it is logged in the `result` and we move to the `abort`
-- phase for the current phase.
function Run:_doNextAction(index)
    -- log.df("_doNextAction: %d", index)
    local currentPhase = self.phase
    local currentActions = self.phaseActions[currentPhase]
    local actionFn = currentActions and currentActions[index]
    if actionFn then
        self._currentTimer = timer.doAfter(0, function()
            -- log.df("_doNextAction: running timer...")
            self._currentTimer = nil
            local this = Run.This(self, index)
            this:prepare()
            local ok, err = xpcall(function() actionFn(this) end, debug.traceback)
            this:cleanup()

            log.df("_doNextAction: this.passing: %s", hs.inspect(this.passing))
            if ok ~= true and this.passing then
                log.df("_onNextAction: not ok. Aborting...")
                self:_doAbort(err)
            elseif not this:isWaiting() then
                log.df("_onNextAction: not waiting.")
                this:done()
            end
        end)
    else
        -- log.df("_doNextAction: From: %s; Next phase: %s", currentPhase, currentPhase.next)
        self:_doPhase(currentPhase.next)
    end
end

-- cp.spec.Run:_doAbort(err)
-- Method
-- Logs the error with the current result's `aborted` log and begins processing the
-- `abort` phase for the current phase.
function Run:_doAbort(err)
    self.result:aborted(err)
    local currentPhase = self.phase
    if currentPhase then
        self:_doPhase(currentPhase.abort)
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
        return self._verbose == true or parent and parent:verbose()
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

--- cp.spec.Run:childCompleted(childRun)
--- Method
--- This is called when the specified child Run has completed.
--- The default implementation does nothing. Subclasses should override if relevant.
---
--- Parameters:
--- * childRun      - The child `Run` which has completed.
function Run.childCompleted() end

function Run:fullName()
    local parent = self:parent()
    local parentName = parent and parent:fullName() .. " > " or ""
    return parentName .. self.name
end

function Run:__tostring()
    return self:fullName()
end

return Run