local spec              = require "cp.spec"
local timer             = require "hs.timer"

local describe, context, it      = spec.describe, spec.context, spec.it

return describe "cp.spec.tests" {
    it "passes when all asserts are true"
    :doing(function()
        assert(true, "OK")
    end),

    it "fails when an assert is false"
    :doing(function()
        assert(false, "This should fail.")
    end),

    it "passes again"
    :doing(function()
        assert(true, "This should not fail.")
    end),

    it "will wait until an async is done"
    :doing(function(this)
        this:log("waiting...")
        this:wait(10)
        timer.doAfter(2, function()
            this:log("completing...")
            assert(true, "Asynched!")
            this:done()
        end)
    end),

    it "will time out before the async completes"
    :doing(function(this)
        this:wait(1)
        timer.doAfter(2, function()
            assert(not this:isActive(), "Timeout failed!")
            this:done()
        end)
    end),

    it "will send an error in an async before being done."
    :doing(function(this)
        this:wait(2)
        timer.doAfter(0.5, function()
            error("This should be an abort.")
            this:done()
        end)
    end),

    context "in a context" {
        it "will pass with an assertion of true"
        :doing(function()
            assert(true, "this passes")
        end),
    },
}