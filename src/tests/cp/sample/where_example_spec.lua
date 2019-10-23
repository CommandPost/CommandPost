local spec          = require "cp.spec"
local describe, it  = spec.describe, spec.it

local function sum(a, b)
    return a + b
end

return describe "sum" {
    it "results in ${result} when you add ${a} and ${b}"
    :doing(function(this)
        assert(sum(this.a, this.b) == this.result)
    end)
    :where {
        { "a",  "b",    "result"},
        { 1,    2,      3 },
        { 1,    -1,     0 },
    },
}
