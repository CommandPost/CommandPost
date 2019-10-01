local spec          = require "cp.spec"
local describe, it  = spec.describe, spec.it

return describe "cp.spec.Specification" {
    it "passes"
    :doing(function()
        assert(true, "passes")
    end),

    it "fails"
    :doing(function(this)
        this:expectFail("fails")
        assert(false, "fails")
    end),

    it "aborts"
    :doing(function(this)
        this:expectAbort("aborts")
        error("aborts")
    end),
}