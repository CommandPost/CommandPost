local test          = require("cp.test")

local Retry         = require("cp.rx.go.Retry")
local Throw         = require("cp.rx.go.Throw")

local insert        = table.insert

return test.suite("cp.rx.go.Retry"):with {
    test("Retry UpTo 10", function()
        local results = {}
        local message = nil
        local completed = false

        local count = 0

        Retry(function()
            if count < 5 then
                count = count + 1
                return Throw("count: %d", count)
            else
                return true
            end
        end)
        :UpTo(10)
        :Now(
            function(value)
                insert(results, value)
            end,
            function(msg)
                message = msg
            end,
            function()
                completed = true
            end
        )

        ok(eq(count, 5))
        ok(eq(results, {true}))
        ok(eq(message, nil))
        ok(eq(completed, true))
    end),

    test("Retry failed", function()
        local results = {}
        local message = nil
        local completed = false

        local count = 0

        Retry(function()
            if count < 5 then
                count = count + 1
                return Throw("count: %d", count)
            else
                return true
            end
        end)
        :UpTo(2)
        :Now(
            function(value)
                insert(results, value)
            end,
            function(msg)
                message = msg
            end,
            function()
                completed = true
            end
        )

        ok(eq(count, 2))
        ok(eq(results, {}))
        ok(eq(message, "count: 2"))
        ok(eq(completed, false))
    end),

}