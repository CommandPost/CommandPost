local test          = require("cp.test")

local Throw         = require("cp.rx.go.Throw")

return test.suite("cp.rx.go.Throw"):with {
    test("Throw", function()
        -- straight throw:
        local error = false

        Throw("Message %s", "Test"):Now(
            function(_)
                ok(false, "Should not be called.")
            end,
            function(message)
                ok(message, "Message Test")
                error = true
            end,
            function()
                ok(false, "Completed should not be called.")
            end
        )

        ok(eq(error, true))
    end),
}