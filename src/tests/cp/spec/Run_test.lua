local test		= require("cp.test")
-- local log		= require "hs.logger" .new "testjust"

local Run		= require("cp.spec.Run")

return test.suite("cp.spec.Run"):with {
    test("Run.This()", function()
        local run = Run("foo")
        local this = Run.This(run, 1)
        ok(eq(this.passing, true))
        ok(eq(this.state, Run.This.state.running))
    end),
    test("Run.This:isWaiting()", function()
        local run = Run("foo")
        local this = Run.This(run, 1)
        ok(eq(this.passing, true))
        ok(eq(this:isWaiting(), false))
        this:wait(123)
        ok(eq(this:isWaiting(), true))
        this:done()
        ok(eq(this:isWaiting(), false))
    end),
}