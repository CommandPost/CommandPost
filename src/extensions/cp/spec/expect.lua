local class     = require "middleclass"
local inspect   = require "hs.inspect"
local format    = string.format

local Expect = class("cp.spec.Expect")

function Expect:initialize(value)
    self.value = value
end

function Expect:is(other)
    assert(self.value == other, format("Expected value of %s, but was %s", inspect(self.value), inspect(other)) )
end

local expect = {}

setmetatable(expect, {
    __call = function(_, value)
        return Expect(value)
    end
})

return expect