local spec          = require "cp.spec"
local expect        = require "cp.spec.expect"
local inspect       = require "hs.inspect"

local it            = spec.it

return it("expects ${left} AND ${right} to be ${result}")
:doing(function(this)
    this:log("left: %s; right %s; result; %s", inspect(this.left), inspect(this.right), inspect(this.result))
    expect(this.left and this.right):is(this.result)
end)
:where {
    { "left",   "right",    "result" },
    { true,     true,       true },
    { true,     false,      false },
    { false,    false,      false },
    { false,    true,       false },
}
