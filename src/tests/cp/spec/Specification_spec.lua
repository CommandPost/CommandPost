local spec          = require "cp.spec"
local describe, it  = spec.describe, spec.it

return describe "Specification" {
    it "passes"
    :doing(function()
        assert(true, "passes")
    end),

    it "fails"
    :doing(function()
        assert(false, "fails")
    end),
}