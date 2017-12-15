local test 		= require("cp.test")

return test.suite("cp"):with(
	"tests.test_fcp",
	"tests.test_fcpplugins",
	"tests.test_html",
	"tests.test_just",
	"tests.test_localized",
	"tests.test_matcher",
	"tests.test_prop",
	"tests.test_strings",
	"tests.test_text",
	"tests.test_utf16"
)