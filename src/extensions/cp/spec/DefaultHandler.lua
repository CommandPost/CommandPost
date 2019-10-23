local Handler           = require "cp.spec.Handler"
local format            = string.format

-- prints with an optionally formatted string.
local function printf(msg, ...)
    if select("#", ...) > 0 then
        msg = format(msg, ...)
    end
    print(msg)
end

--- === cp.spec.DefaultHandler ===
---
--- Default implementation of [Handler](cp.spec.Handler.md), which
--- outputs via the standard `print` function.
local DefaultHandler = Handler:subclass("cp.spec.DefaultHandler")

--- cp.spec.DefaultHandler:printSpacer()
--- Method
--- Prints a blank line if this is not the first time it has been called.
function DefaultHandler:printSpacer()
    if self.spacerSkipped then
        print()
    end
    self.spacerSkipped = true
end

--- cp.spec.DefaultHandler:printf(test, ...)
--- Method
--- Prints a spacer (if not the first line), followed by the text,
--- optionally formatted with the provided parameters.
---
--- Parameters:
--- * text      - The message to print.
--- * ...       - The parameters to interpolate into the text message.
function DefaultHandler:printf(text, ...)
    self:printSpacer()
    printf(text, ...)
end

--- cp.spec.DefaultHandler:start(run)
--- Method
--- If the handler or run is verbose, prints a "[START]" message.
---
--- Parameters:
--- * run      - the [run](cp.spec.Run.md)
function DefaultHandler:start(run)
    if self:checkVerbose(run) then self:printf(" [START] %s", run) end
end

--- cp.spec.DefaultHandler:stop(run)
--- Method
--- If the handler or run is verbose, prints a "[STOP]" message.
---
--- Parameters:
--- * run      - the [run](cp.spec.Run.md)
function DefaultHandler:stop(run)
    if self:checkVerbose(run) then self:printf("  [STOP] %s", run) end
end

--- cp.spec.DefaultHandler:start(run, msg)
--- Method
--- If the handler or run is verbose, prints a "[PASS]" message.
---
--- Parameters:
--- * run      - the [run](cp.spec.Run.md)
--- * msg       - the message string.
function DefaultHandler:passed(run, msg)
    if self:checkVerbose(run) then
        local tag = msg and ": " .. msg or ""
        self:printf("  [PASS] %s%s", run, tag)
    end
end

--- cp.spec.DefaultHandler:failed(run, msg)
--- Method
--- Prints a "[FAIL]" message.
---
--- Parameters:
--- * run      - the [run](cp.spec.Run.md)
--- * msg       - the message string.
function DefaultHandler:failed(run, msg)
    self:printf("  [FAIL] %s: %s", run, msg)
end

--- cp.spec.DefaultHandler:aborted(run, msg)
--- Method
--- Prints an "[ABORT]" message.
---
--- Parameters:
--- * run      - the [run](cp.spec.Run.md)
--- * msg       - the message string.
function DefaultHandler:aborted(run, msg)
    self:printf(" [ABORT] %s: %s", run, msg)
end

--- cp.spec.DefaultHandler:waiting(run, timeout)
--- Method
--- Prints a "[WAIT]" message with the timeout value..
function DefaultHandler:waiting(run, timeout)
    if self:checkVerbose(run) then
        local seconds = timeout == 1 and "second" or "seconds"
        self:printf("  [WAIT] %s: Waiting asynchronously for %d %s.", run, timeout, seconds)
    end
end

--- cp.spec.DefaultHandler:filter(run, msg)
--- Method
--- Prints a "[FILTER]" message.
---
--- Parameters:
--- * run      - the [run](cp.spec.Run.md)
--- * msg       - the message string.
function DefaultHandler:filter(run, msg)
    self:printf("[FILTER] %s: %s", run, msg)
end

--- cp.spec.DefaultHandler:summary(run, report)
--- Method
--- If the handler or run is verbose, prints a "[RESULT]" message.
---
--- Parameters:
--- * run      - the [run](cp.spec.Run.md)
--- * report    - the [report](cp.spec.Report.md)
function DefaultHandler:summary(run, report)
    self:printf("[RESULT] %s: %s", run, report)
end

-- set DefaultHandler to the default.
Handler.default(DefaultHandler())

return DefaultHandler