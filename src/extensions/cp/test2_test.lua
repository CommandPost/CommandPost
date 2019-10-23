local spec              = require "cp.spec"
local it                = spec.it

return it "will pass once and fail once"
:doing(function()
    assert(true, "A simple pass")
    assert(false, "A simple failure")
end)