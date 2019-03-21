local spec          = require "cp.spec"
local timer         = require "hs.timer"
local describe, it  = spec.describe, spec.it

return describe "a describe" {
    it "passes when asserting `true`"
    :doing(function()
        assert(true, "this should not fail.")
    end),

    it "passes when async"
    :doing(function(this)
        this:wait(10)
        timer.doAfter(1, function()
            assert(true, "this should not fail either")
            this:done()
        end)
    end)
}