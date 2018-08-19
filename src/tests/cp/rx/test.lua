--- === cp.rx.test ===
---
--- A support extension for testing `Rx` instances and functions.

-- local log           = require("hs.logger").new("rx_test")

local inspect       = require("hs.inspect")
local rx            = require("cp.rx")

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
        next = setmetatable(
            {n=0},
            {
                __len = function(self)
                    return self.n
                end,
            }
        ),
        error = nil,
        completed = false,
        reference = nil,
    }, mod.result.mt)
end

--- cp.rx.test.result:is(next, error, completed) -> boolean, string
--- Method
--- Checks if the current `result` has matching `next`, `error` and `completed` next.
---
--- Parameters:
--- * next      - a `table` of next sent to `onNext`, or a `function` that will be passed the `next` table and should return `true/false`, and optional error message if `false`.
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
    if type(next) == "function" then
        ok, msg = next(self.next)
    else
        ok, msg = eq(self.next, next, "next")
    end
    if ok then
        if type(error) == "function" then
            ok, msg = error(self.next)
        else
            ok, msg = eq(self.error, error, "error")
        end
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

    result.reference = observable:subscribe(
        function(...)
            local value
            if select("#", ...) == 1 then
                value = select(1, ...)
            else
                value = table.pack(...)
            end
            local len = #result.next
            insert(result.next, value)
            -- ensures that `nil` values are preserved
            result.next.n = len + 1
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

-- returns `true` if the `tbl` contains the `value`
local function contains(tbl, value)
    for _,v in ipairs(tbl) do
        if eq(v, value) then
            return true
        end
    end
    return false
end

-- cp.rx.test.containsOnly(values) -> function
-- Function
-- Returns a "match" function which will check its input value to see if it is a table which contains the same values in any order.
--
-- Parameters:
-- * values     - A [Set](cp.collect.Set.md) or `table` specifying exactly what items must be in the matching table, in any order.
--
-- Returns:
-- * A `function` that will accept a single input value, which will only return `true` the input is a `table` containing exactly the items in `values` in any order.
function mod.containsOnly(values)
    return function(other)
        if other and values and #other == #values then
            for _,v in ipairs(other) do
                if not contains(values, v) then
                    return false, string.format("result contains %s: %s ~= %s", inspect(v), inspect(other), inspect(values))
                end
            end
            return true
        end
        return false, string.format("expected %d items, actually has %d: %s ~= %s", #values, #other, inspect(other), inspect(values))
    end
end

-- cp.rx.test.notNil() -> function
-- Function
-- Returns a "match" function which will check its input value to see if it is not `nil`.
--
-- Parameters:
-- * None
--
-- Returns:
-- * A `function` that will accept a single input value, which will pass if the value is not `nil`.
function mod.notNil()
    return function(other) return other ~= nil end
end

-- cp.rx.test.lengthIs(length) -> function
-- Function
-- Returns a "match" function which will check if the value is a table and the length matches `length`.
function mod.lengthIs(length)
    return function(other)
        if type(other) == "table" and #other == length then
            return true
        else
            return false, string.format("expected %d items, actually has %d: %s", length, #other, inspect(other))
        end
    end
end

mod.CANCELLED = {}
mod.COMPLETED = {}

-- cp.rx.test.mockScheduler(delay) -> scheduler
-- Function
-- Returns a 'mock' scheduler, which will only proceed when `scheduler:next()` is called.
function mod.mockScheduler(delay)
    return {
        delay = delay,
        schedule = function(self, fn, d)
            ok(eq(d, self.delay))
            insert(self, fn)
            local id = #self
            return rx.Reference.create(function()
                self[id] = mod.CANCELLED
            end)
        end,
        count = 0,
        next = function(self)
            local count = self.count
            ok(count < #self, "no more actions scheduled")
            count = count + 1
            self.count = count
            local action = self[count]
            if action == mod.CANCELLED then
                ok(false, string.format("action #%d already cancelled", count))
            elseif action == mod.COMPLETED then
                ok(false, string.format("action #%d already completed", count))
            else
                self[count] = mod.COMPLETED
                action()
            end
        end
    }
end

return mod