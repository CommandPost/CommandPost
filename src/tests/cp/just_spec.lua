local spec = require "cp.spec"
local expect = require "cp.spec.expect"
local describe, context, it = spec.describe, spec.context, spec.it

local just = require "cp.just"

return describe "cp.just" {
    context "doUntil" {
        it "calls the action once when succeeding immediately"
        :doing(function()
            local count = 0
            local result =
                just.doUntil(
                function()
                    count = count + 1
                    return true
                end
            )

            expect(count):is(1)
            expect(result):is(true)
        end),
        it "times out after the default number of seconds"
        :doing(function()
            local count = 0
            local result =
                just.doUntil(
                function()
                    count = count + 1
                    return false
                end
            )

            expect(result):is(false)
            expect(count):isGreaterThan(0)
        end),
        it "stops after 5 times if the total time is 0.5 seconds and the wait is 0.1 seconds"
        :doing(function()
            local count = 0
            local result =
                just.doUntil(
                function()
                    count = count + 1
                    return false
                end,
                0.5,
                0.1
            )

            expect(count):is(5)
            expect(result):is(false)
        end)
    },
    context "doWhile" {
        it "calls the action once when failing immediately"
        :doing(function()
            local count = 0
            local result =
                just.doWhile(
                function()
                    count = count + 1
                    return false
                end
            )

            expect(count):is(1)
            expect(result):is(false)
        end),

        it "times out after the default number of seconds"
        :doing(function()
            local count = 0
            local result =
                just.doWhile(
                function()
                    count = count + 1
                    return true
                end
            )

            expect(result):is(true)
        end),

        it "stops after 5 times if the total time is 0.5 seconds and the wait is 0.1 seconds"
        :doing(function()
            local count = 0
            local result =
                just.doWhile(
                function()
                    count = count + 1
                    return true
                end,
                0.5,
                0.1
            )

            expect(count):is(5)
            expect(result):is(true)
        end),
    }
}
