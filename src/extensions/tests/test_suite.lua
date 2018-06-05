local test				= require("cp.test")
-- local log				= require("hs.logger").new("t_suite")

-- A simple test case, to test cp.test

return test.suite("cp.test_suite", {
    "tests.test_case",
    test("direct_case", function()
        ok(true, "passes")
        ok(false, "fails")
    end)
})