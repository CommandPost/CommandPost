--- === cp.rx.test ===
---
--- A support extension for testing `Rx` instances and functions.

local mod = {}

local insert = table.insert

mod.result = {}
mod.result.mt = {}
mod.result.mt.__index = mod.result.mt

--- === cp.rx.test.result ===
---
--- A `cp.rx.test.result` collates responses from a [subscription](#subscribe).

--- cp.rx.test.result.new() -> cp.rx.test.result
--- Constructor
--- Creates a new `cp.rx.test.result` instance.
---
--- Returns:
--- * The new `cp.rx.test.result`.
function mod.result.new()
    return setmetatable({
        next = {},
        error = nil,
        completed = false,
    }, mod.result.mt)
end

--- cp.rx.test.result:is(next, error, completed) -> boolean, string
--- Method
--- Checks if the current `result` has matching `next`, `error` and `completed` next.
---
--- Parameters:
--- * next    - a `table` of next sent to `onNext`.
--- * error     - any message send to `onError`.
--- * completed - `true` or `false`, to indicate if the `Observable` has completed.
---
--- Returns:
--- * boolean   - `true` if it matches, `false` if not.
--- * string    - The first mismatch.
---
--- Notes:
--- * It checks `next`, `error`, then `completed`. Only the first mismatch will be reported.
function mod.result.mt:is(next, error, completed)
    local ok, msg
    ok, msg = eq(self.next, next, "next")
    if ok then
        ok, msg = eq(self.error, error, "error")
        if ok then
            ok, msg = eq(self.completed, completed, "completed")
        end
    end
    return ok, msg
end

--- cp.rx.test.subscribe(observable) -> cp.rx.test.result
--- Function
--- Subscribes to the provided [Observable](cp.rx.Observable.md) and returns a `result` which will collate the responses.
---
--- Parameters:
--- * observable        - an [Observable](cp.rx.Observable.md) instance.
---
--- Returns:
--- * The `cp.rx.test.result` value.
function mod.subscribe(observable)
    local result = mod.result.new()

    observable:subscribe(
        function(value)
            insert(result.next, value)
        end,
        function(msg)
            result.error = msg
        end,
        function()
            result.completed = true
        end
    )

    return result
end

return mod