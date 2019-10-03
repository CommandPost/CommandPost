local require           = require
local expect            = require "cp.spec.expect"
local Scenario          = require "cp.spec.Scenario"

local Test = Scenario:subclass("cp.spec.Test")

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
    if message then
        expect.given(message):that(left):is(right)
    else
        expect(left):is(right)
    end
    return HANDLED
end

function Test:run()
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

return Test