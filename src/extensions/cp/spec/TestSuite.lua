local require           = require

local Specification     = require "cp.spec.Specification"
local TestCase          = require "cp.spec.TestCase"
local test              = require "cp.test"

local TestSuite = Specification:subclass("cp.spec.TestSuite")

local function wrapTest(child)
    if test.suite.is(child) then
        return TestSuite(child)
    elseif test.case.is(child) then
        return TestCase(child)
    else
        error("Unsupported test type: " .. type(child))
    end
end

function TestSuite:initialize(testSuite)
    self.suite = testSuite

    Specification.initialize(self, testSuite.name)

    if testSuite._beforeEach then
        self:onBeforeEach(function(this)
            testSuite._beforeEach(this:run().source.case)
        end)
    end

    if testSuite._afterEach then
        self:onAfterEach(function(this)
            testSuite._afterEach(this:run().source.case)
        end)
    end

    -- add test cases
    for _,child in ipairs(testSuite.tests) do
        self:with(wrapTest(child))
    end
end

return TestSuite