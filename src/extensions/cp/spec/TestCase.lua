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
local SPY = {}

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

-- Compatibility for Lua 5.1 and Lua 5.2
local function args(...)
    return {n=select('#', ...), ...}
end

local function spy(f)
    local s = {}
    setmetatable(s, {__call = function(ss, ...)
        ss.called = ss.called or {}
        local a = args(...)
        table.insert(ss.called, {...})
        if f then
            local r
            r = args(xpcall(function() f(unpack(a, 1, a.n)) end, debug.traceback))
            if not r[1] then
                s.errors = s.errors or {}
                s.errors[#s.called] = r[2]
            else
                return unpack(r, 2, r.n)
            end
        end
    end})
    return s
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
        this:run()[SPY] = _G.spy
        _G.ok = ok
        _G.eq = eq
        _G.spy = spy
    end)
    :onAfter(function(this)
        _G.ok = this:run()[OK]
        _G.eq = this:run()[EQ]
        _G.spy = this:run()[SPY]
    end)
end

return TestCase