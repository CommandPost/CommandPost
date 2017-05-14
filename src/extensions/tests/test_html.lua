local test		= require("cp.test")
local log		= require("hs.logger").new("testhtml")

local html		= require("cp.web.html")

function run()
	test("Single Element", function()
		local element = html.element()
		ok(eq(tostring(element), "<element />"))
		
		element = html.element {attribute = "value"}
		ok(eq(tostring(element), "<element attribute=\"value\" />"))
	end)
	
	test("CDATA", function()
		local cdata = html.CDATA "This is CDATA."
		ok(eq(tostring(cdata), "<![CDATA[This is CDATA.]]>"))
	end)
	
	test("Comment", function()
		local comment = html.__ "This is a comment."
		ok(eq(tostring(comment), "<!-- This is a comment. -->"))
	end)
	
	test("Text Block", function()
		local escaped = html("1 < 2")
		ok(eq(tostring(escaped), "1 &lt; 2"))
		
		local unescaped = html("1 < 2", true)
		ok(eq(tostring(unescaped), "1 < 2"))
	end)
	
	test("Escaped Content", function()
		-- without attributes
		local p = html.p ("<b>bold</b>", true)
		ok(eq(tostring(p), "<p><b>bold</b></p>"))
		
		-- with attribute
		local p = html.p {attr = "value"} ("<b>bold</b>", true)
		ok(eq(tostring(p), "<p attr=\"value\"><b>bold</b></p>"))
	end)
end

return run