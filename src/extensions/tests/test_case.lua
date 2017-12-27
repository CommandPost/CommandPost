local test				= require("cp.test")
local log				= require("hs.logger").new("t_case")

-- A simple test case, to test cp.test

return test("cp.test_case", function()
	ok(true, "passes")
end)