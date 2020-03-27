--- === cp.spec.expect ===
---
--- Provides a way of checking values match expected results. At it's core, it uses `assert` to make the check.
---
--- For example:
---
--- ```lua
--- expect("Hello World"):is("Hello World")
--- expect("Hello World"):isNot("Hello Mars")
--- expect(value):isAtLeast(10)
--- expect.given("the world is a globe"):that(theEarth):isNot("flat")
--- ```

local class     = require "middleclass"
local inspect   = require "hs.inspect"
local format    = string.format

local expect = class("cp.spec.expect")

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

local function report(value)
    if type(value) == "string" then
        return format("%q", value)
    else
        return inspect(value)
    end
end

function expect.static.given(context)
    return expect(nil, context)
end

function expect.static.that(value)
    return expect(value)
end

function expect:initialize(value, context)
    self:that(value)
    self:given(context)
    self._level = 1
end

function expect:given(context)
    self.context = context
    return self
end

function expect:level(level)
    self._level = level
    return self
end

function expect:that(value)
    self.value = value
    return self
end

function expect:_expected(message, ...)
    local expected = self.context and "Given " .. self.context .. ", expected " or "Expected "
    return expected .. format(message, ...)
end

function expect:is(other)
    assert(deepeq(self.value, other), self:_expected("that the value would be %s, but it was %s", report(other), report(self.value)), self._level + 1)
end

function expect:isNot(other)
    assert(deepneq(self.value, other), self:_expected("that the value would not be %s, but it was %s", report(other), report(self.value)), self._level + 1)
end

function expect:isAtLeast(other)
    assert(self.value >= other, self:_expected("the value would be at least %s, but it was %s", report(other), report(self.value)), self._level + 1)
end

function expect:isAtMost(other)
    assert(self.value <= other, self:_expected("the value would be at most %s, but it was %s", report(other), report(self.value)), self._level + 1)
end

function expect:isLessThan(other)
    assert(self.value < other, self:_expected("the value would be less than %s, but it was %s", report(other), report(self.value)), self._level + 1)
end

function expect:isGreaterThan(other)
    assert(self.value > other, self:_expected("the value would be greater than %s, but it was %s", report(other), report(self.value)), self._level + 1)
end

function expect:matches(other)
    assert(type(self.value) == "string" and self.value:match(other) ~= nil, self:_expected("the value to match %s, but it was %s", report(other), report(self.value)), self._level + 1)
end

return expect