--- === cp.spec.expect ===
---
--- Provides a way of checking values match expected results. At it's core, it uses `assert` to check.
---
--- For example:
---
--- ```lua
--- expect("Hello World"):is("Hello World")
--- expect("Hello World"):isNot("Hello Mars")
--- expect(value):isAtLeast(10)
--- ```

local class     = require "middleclass"
local inspect   = require "hs.inspect"
local format    = string.format

local Expect = class("cp.spec.Expect")

function Expect:initialize(value)
    self.value = value
end

function Expect:is(other)
    assert(self.value == other, format("Expected value of %s, but it was %s", inspect(other), inspect(self.value)), 2)
end

function Expect:isNot(other)
    assert(self.value ~= other, format("Expected value to not be %s, but it was %s", inspect(other), inspect(self.value)), 2)
end

function Expect:isAtLeast(other)
    assert(self.value >= other, format("Expected value to be at least %s, but it was %s", inspect(other), inspect(self.value)), 2)
end

function Expect:isAtMost(other)
    assert(self.value <= other, format("Expected value to be at most %s, but it was %s", inspect(other), inspect(self.value)), 2)
end

function Expect:isLessThan(other)
    assert(self.value < other, format("Expected value to be less than %s, but it was %s", inspect(other), inspect(self.value)), 2)
end

function Expect:isGreaterThan(other)
    assert(self.value > other, format("Expected value to be greater than %s, but it was %s", inspect(other), inspect(self.value)), 2)
end

local expect = {}

setmetatable(expect, {
    __call = function(_, value)
        return Expect(value)
    end
})

return expect