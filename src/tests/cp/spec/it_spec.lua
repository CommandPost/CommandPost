local spec      = require "cp.spec"
local it        = spec.it

return it "succeeds when passed `true`"
:doing(function()
    assert(true, "Should not fail.")
end)