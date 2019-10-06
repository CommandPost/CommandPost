--- === cp.spec.TestCase ===
---
--- Wraps [cp.test](cp.test.md) into a subclass of [Scenario](cp.spec.Scenario.md).

local require           = require
local expect            = require "cp.spec.expect"
local Scenario          = require "cp.spec.Scenario"

local TestCase = Scenario:subclass("cp.spec.TestCase")

local HANDLED = {}
local OK = {}
local EQ = {}

-- wraps the `ok` function from `cp.test`
local function ok(check, message, level)
    if check ~= HANDLED then
        _G.assert(check, message, level)
    end
end

-- wraps the `eq` function from `cp.test`.
local function eq(left, right, message)
    expect.given(message):level(2):that(left):is(right)
    return HANDLED
end

function TestCase:initialize(testCase)
    self.case = testCase
    Scenario.initialize(self, "test " .. testCase.name, testCase.executeFn)
end

function TestCase:run()
    return Scenario.run(self)
    :onBefore(function(this)
        this:run()[OK] = _G.ok
        this:run()[EQ] = _G.eq
        _G.ok = ok
        _G.eq = eq
    end)
    :onAfter(function(this)
        _G.ok = this:run()[OK]
        _G.eq = this:run()[EQ]
    end)
end

return TestCase