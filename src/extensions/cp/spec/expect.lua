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

local function deepeq(a, b)
    -- Different types: false
    if type(a) ~= type(b) then return false end
    -- Functions
    if type(a) == 'function' then
        return string.dump(a) == string.dump(b)
    end
    -- Primitives and equal pointers
    if a == b then return true end
    -- Only equal tables could have passed previous tests
    if type(a) ~= 'table' then return false end
    -- Compare tables field by field
    for k,v in pairs(a) do
        if b[k] == nil or not deepeq(v, b[k]) then
            -- check for special `n` key for table length
            if k ~= "n" or b.n ~= nil or a.n ~= #b then
                return false
            end
        end
    end
    for k,v in pairs(b) do
        if a[k] == nil or not deepeq(v, a[k]) then
            -- check for special `n` key for table length
            if k ~= "n" or a.n ~= nil or b.n ~= #a then
                return false
            end
        end
    end
    return true
end

local function deepneq(a, b)
    local ok, _ = deepeq(a, b)
    if ok then
        return false
    else
        return true
    end
end

function Expect:initialize(value)
    self.value = value
end

function Expect:is(other)
    assert(deepeq(self.value, other), format("Expected value to be %s, but it was %s", inspect(other), inspect(self.value)), 2)
end

function Expect:isNot(other)
    assert(deepneq(self.value, other), format("Expected value to not be %s, but it was %s", inspect(other), inspect(self.value)), 2)
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