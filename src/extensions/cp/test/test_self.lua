-- A test script to test cp.test.lua

local test		= require("cp.test.neu")

return test("cp.test", function()
	test("passes", function()
		ok(eq(1+1, 2))
	end)

	test("error happens", function()
		local str = nil .. "foo"
	end)

	test("fails", function()
		ok(false, "This should be true.")
	end)

end)