local spec  = require "cp.spec"
local timer = require "hs.timer"
-- local log   = require "hs.logger" .new "asyncspec"

local describe, it = spec.describe, spec.it

return describe "async specs" {
    it "passes asynchronously"
    :doing(function(this)
        this:wait(10)
        assert(true, "should not fail")

        timer.doAfter(1, function()
            assert(true, "also should not fail")
            this:done()
        end)
    end),

    it "fails asynchronously"
    :doing(function(this)
        this:wait(5)
        assert(true, "should not fail")

        timer.doAfter(1, function()
            this:expectFail("this should fail")

            assert(false, "this should fail")

            this:done()
        end)
    end)
}