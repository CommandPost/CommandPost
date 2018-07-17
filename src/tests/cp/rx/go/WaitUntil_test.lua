local test          = require("cp.test")

local WaitUntil     = require("cp.rx.go.WaitUntil")

local Subject       = require("cp.rx").Subject

return test.suite("cp.rx.go.WaitUntil"):with {
    test("WaitUntil", function()
        -- local scheduler = rx.CooperativeScheduler.create(0)

        local subject = Subject.create()
        local received = nil
        local completed = false

        local wait = WaitUntil(subject):Is("green")

        wait:Now(
            function(value)
                ok(eq(value, "green"))
                received = value
            end,
            function(message)
                ok(false, message)
            end,
            function()
                completed = true
            end
        )

        ok(subject == wait:context().requirement)

        ok(eq(received, nil))

        subject:onNext("red")
        ok(eq(received, nil))
        ok(eq(completed, false))

        subject:onNext("green")
        ok(eq(received, "green"))
        ok(eq(completed, true))
    end),
}