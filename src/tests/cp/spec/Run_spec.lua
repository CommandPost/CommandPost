local require                   = require

local spec		                = require "cp.spec"
local expect                    = require "cp.spec.expect"
local describe, context, it     = spec.describe, spec.context, spec.it
-- local log		= require "hs.logger" .new "testjust"

local Run		    = require "cp.spec.Run"

return describe "cp.spec.Run" {
    context "This" {
        it "is constructed"
        :doing(function()
            local run = Run("foo")
            local this = Run.This(run, function() end, 1)
            expect(this.state):is(Run.This.state.running)
        end),

        it "isWaiting"
        :doing(function()
            local run = Run("foo")
            local this = Run.This(run, function() end, 1)
            expect(this:isWaiting()):is(false)
            this:wait(123)
            expect(this:isWaiting()):is(true)
            this:done()
            expect(this:isWaiting()):is(false)
        end),
    },
}