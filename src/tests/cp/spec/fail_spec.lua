local spec      = require "cp.spec"
local describe, it        = spec.describe, spec.it

return describe "cp.spec.fail" {
    it "fails when passed `false`"
    :doing(function()
        assert(false, "Should fail.")
    end),
    it "fails again"
    :doing(function()
        assert(false, "Should also fail.")
    end)
}