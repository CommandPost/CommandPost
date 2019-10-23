local spec          = require "cp.spec"
local it            = spec.it

return it "always fails"
:doing(function()
    assert(false, "This always fails")
end)