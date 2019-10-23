local spec          = require "cp.spec"
local describe, it  = spec.describe, spec.it

local function sum(a, b)
    return a + b
end

return describe "sum" {
    it "results in 3 when you add 1 and 2"
    :doing(function()
        assert(sum(1, 2) == 3)
    end),
    it "results in 0 when you add 1 and -1"
    :doing(function()
        assert(sum(1, -1) == 0)
    end),
}
