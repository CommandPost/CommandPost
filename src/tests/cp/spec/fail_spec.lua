local spec      = require "cp.spec"
local it        = spec.it

return it "fails when passed `false`"
    :doing(function(this)
        this:expectFail("Should fail.")

        assert(false, "Should fail.")
    end)
