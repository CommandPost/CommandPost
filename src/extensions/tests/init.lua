return function()
	require("tests.test_fcp")()
	require("tests.test_prop")()
	require("tests.test_html")()
	require("tests.test_strings")()
	hs.openConsole()
	print("Tests Complete!")
end