local test 		= require("cp.test")

return test.suite("cp"):with {
	"tests.test_fcp",
	"tests.test_fcpplugins",
	"tests.test_ids",
	"tests.test_just",
	"tests.test_localized",
	"tests.test_matcher",
	"tests.test_strings",
	"tests.test_text",
	"tests.test_utf16",
	"cp.is_test",
	"cp.prop.test",
	"cp.web.html_test",
	"cp.web.xml_test",
	"cp.ui.notifier_test",
}