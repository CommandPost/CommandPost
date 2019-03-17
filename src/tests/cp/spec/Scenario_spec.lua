local spec = require("cp.spec")
local it = spec.it

return it "passes"
:doing(function()
    assert(true, "when passed true")
end)