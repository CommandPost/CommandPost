local spec      = require "cp.spec"
local it        = spec.it

return it "fails when passed `false`"
    :doing(function()
        assert(false, "Should fail.")
    end)
