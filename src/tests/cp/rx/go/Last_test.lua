local test          = require("cp.test")

local rx            = require("cp.rx")
local Last          = require("cp.rx.go.Last")

local Observable    = rx.Observable

return test.suite("cp.rx.go.Last"):with {
    test("Last", function()
        local result = nil
        local error = false
        local completed = true

        Last(Observable.of(1, 2, 3)):
        Now(
            function(value)
                result = value
            end,
            function(message)
                ok(false, message)
            end,
            function()
                completed = true
            end
        )

        ok(eq(result, 3))
        ok(eq(error, false))
        ok(eq(completed, true))
    end),
}