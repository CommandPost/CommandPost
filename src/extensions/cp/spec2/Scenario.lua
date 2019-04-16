local class                 = require "middleclass"
local Action                = require "cp.spec2.Action"

local Scenario = class("cp.spec2.Scenario")

function Scenario:initialize(name, testFn)
    self._name = name
    self._testFn = testFn
end

function Scenario:doing(testFn)
    assert(self._testFn == nil, "Already a test function provided.")
    self._testFn = testFn
end

function Scenario:run()

end

return Scenario