local spec                  = require("cp.spec")

local describe, it, context = spec.describe, spec.it, spec.context

return describe "cp.spec.simple" {
    context "test assert" {
        it "succeeds when passed `true`"
        :doing(function()
            assert(true, "Should not fail.")
        end),
    },
}