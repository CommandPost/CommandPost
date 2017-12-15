local test 		= require("cp.test")

-- return test.suite("cp", {
-- 	"tests.test_text",
-- 	"tests.test_utf16"
-- })

return test.suite("cp"):with(

	-- require("tests.test_fcp")()
	-- require("tests.test_fcpplugins")()
	-- require("tests.test_html")()
	-- require("tests.test_just")()
	-- require("tests.test_localized")()
	-- require("tests.test_matcher")()
	-- require("tests.test_prop")()
	-- require("tests.test_strings")()
	-- require("tests.test_text")()
	"tests.test_utf16"
)