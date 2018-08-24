-- local log           = require("hs.logger").new("rxgotils")
-- local inspect       = require("hs.inspect")

local test          = require("cp.test")

local rx            = require("cp.rx")
local rxgo          = require("cp.rx.go")

local Subject       = rx.Subject
local Given, If, WaitUntil, Throw = rxgo.Given, rxgo.If, rxgo.WaitUntil, rxgo.Throw

return test.suite("cp.rx.go"):with {
    require("cp.rx.go.Statement_test"),
    require("cp.rx.go.Given_test"),
    require("cp.rx.go.If_test"),
    require("cp.rx.go.Last_test"),
    require("cp.rx.go.Retry_test"),
    require("cp.rx.go.Throw_test"),
    require("cp.rx.go.WaitUntil_test"),

    test("If WaitUntil", function()
        local ifSubject = Subject.create()
        local waitSubject = Subject.create()
        local received = nil
        local completed = false

        If(ifSubject):Then(function()
            return WaitUntil(waitSubject)
        end):Now(
            function(value)
                received = value
            end,
            function(message)
                ok(false, message)
            end,
            function()
                completed = true
            end
        )

        ok(eq(received, nil))
        ok(eq(completed, false))

        -- resolve the 'if'
        ifSubject:onNext(true)
        ok(eq(received, nil))
        ok(eq(completed, false))

        -- 'wait until' should not resolve yet
        waitSubject:onNext(false)
        ok(eq(received, nil))
        ok(eq(completed, false))

        -- 'wait until' now resolves
        waitSubject:onNext(true)
        ok(eq(received, true))
        ok(eq(completed, true))
    end),

    test("Given:Then:Throw", function()
        -- straight throw:
        local error = false

        Given(true)
        :Then(Throw("Message %s", "Test"))
        :Now(
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
