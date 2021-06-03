-- private utility class for running tests within CP.
-- Execute via:
--   require "cp.rx.go.test" .throwIfFalse(true):Now()

local If                = require "cp.rx.go.If"
local Throw             = require "cp.rx.go.Throw"

local test = {}

function test.throwIfFalse(value)
    return If(value):Then(true):Otherwise(Throw("Required 'true'"))
end

function test.errorIfFalse(value)
    return If(value):Then(true):Otherwise(function()
        error("Required 'true'")
    end)
end

return test