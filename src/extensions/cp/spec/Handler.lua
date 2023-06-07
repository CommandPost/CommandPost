--- === cp.spec.Handler ===
---
--- Subclasses of this can customise how reports are handled.
--- All methods do nothing.
---
--- See [DefaultHandler](cp.spec.DefaultHandler.md).

local require               = require

local class                 = require "middleclass"

local Handler = class("cp.spec.Handler")

local currentHandler

--- cp.spec.Handler.default([handler]) -> cp.spec.Handler
--- Function
--- Gets and sets the current default `Handler` implementation. This is used when processing test runs.
---
--- Parameters:
---  * handler - (optional) when provided, sets the default to the specified handler.
---
--- Returns:
---  * The current `Handler` implementation.
function Handler.static.default(handler)
    if handler then
        if handler:isInstanceOf(Handler) then
            currentHandler = handler
        else
            error("The handler must be a subclass of `Handler`.")
        end
    end
    return currentHandler
end

--- cp.spec.Handler() -> cp.spec.Handler
--- Constructor
--- Creates a new `Handler`
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function Handler.initialized() end

--- cp.spec.Handler:verbose([isVerbose]) -> self
--- Method
--- Indicate that the handler is (or is not) verbose. If not provided, this is set to `true`.
---
--- Parameters:
---  * isVerbose - (optional) If set to `false`, the handler will not be verbose. Defaults to `true`.
---
--- Returns:
---  * The `Handler` instance, for chaining.
function Handler:verbose(isVerbose)
    self._verbose = isVerbose ~= false
    return self
end

--- cp.spec.Handler:checkVerbose(run) -> boolean
--- Method
--- Indicates if either the handler or the individual [Run](cp.spec.Run.md) is "verbose". If so, more messages may be output by the handler.
---
--- Parameters:
---  * run
---
--- Returns:
---  * None
function Handler:checkVerbose(run)
    return self._verbose or run and run:verbose()
end

--- cp.spec.Handler:start(run) -> none
--- Method
--- Call to indicate the [run](cp.spec.Run.md) has started.
---
--- Parameters:
---  * run - The test run.
---
--- Returns:
---  * None
function Handler.start(_) end

--- cp.spec.Handler:stop(run) -> none
--- Method
--- Call to indicate the [run](cp.spec.Run.md) has completed.
---
--- Parameters:
---  * run - The test run.
---
--- Returns:
---  * None
function Handler.stop(_) end

--- cp.spec.Handler:passed(run) -> none
--- Method
--- Call to indicate the [run](cp.spec.Run.md) has passed.
---
--- Parameters:
---  * run - The test run.
---
--- Returns:
---  * None
function Handler.passed(_, _) end

--- cp.spec.Handler:failed(run, msg) -> none
--- Method
--- Call to indicate the [run](cp.spec.Run.md) has failed.
---
--- Parameters:
---  * run      - The test run.
---  * msg       - The message.
---
--- Returns:
---  * None
function Handler.failed(_, _) end

--- cp.spec.Handler:aborted(run, msg) -> none
--- Method
--- Call to indicate the [run](cp.spec.Run.md) has had an abort.
---
--- Parameters:
---  * run - The test run.
---  * msg - The message.
---
--- Returns:
---  * None
function Handler.aborted(_, _) end

--- cp.spec.Handler:waiting(run, timeout) -> none
--- Method
--- Call to indicate that the run is waiting asynchronously.
---
--- Parameters:
---  * run      - The test run.
---  * timeout  - The timeout, in seconds.
---
--- Returns:
---  * None
function Handler.waiting(_, _) end

--- cp.spec.Handler:filter(run, msg) -> none
--- Method
--- Call to indicate the [run](cp.spec.Run.md) is running due to being filtered.
---
--- Parameters:
---  * run      - The test run.
---  * msg       - The message.
---
--- Returns:
---  * None
function Handler.filter(_, _) end

--- cp.spec.Handler:summary(run, report) -> none
--- Method
--- Call to indicate the [run](cp.spec.Run.md) has passed with the given [report](cp.spec.Report.md).
---
--- Parameters:
---  * run  - The test run.
---  * report - The test reports.
---
--- Returns:
---  * None
function Handler.summary(_, _) end

return Handler