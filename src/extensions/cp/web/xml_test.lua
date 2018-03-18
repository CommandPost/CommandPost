-- local log		= require("hs.logger").new("t_xml")
-- local inspect	= require("hs.inspect")

local test = require("cp.test")

local xml = require("cp.web.xml")

return test.suite("cp.web.xml"):with(
	test("Is", function()
		ok(eq(xml.is("text"), false))
		ok(eq(xml.is({}), false))
		ok(eq(xml.is(xml), false))
		ok(eq(xml.is(xml.a()), true))
	end),

	test("Single Element", function()
		local element = xml.element()
		ok(eq(tostring(element), "<element/>"))

		element = xml.element {attribute = "value"}
		ok(eq(tostring(element), '<element attribute="value"/>'))
	end),

	test("CDATA", function()
		local cdata = xml.CDATA "This is CDATA."
		ok(eq(tostring(cdata), "<![CDATA[This is CDATA.]]>"))
	end),

	test("Comment", function()
		local comment = xml.__ "This is a comment."
		ok(eq(tostring(comment), "<!-- This is a comment. -->"))
	end),

	test("Text Block", function()
		local escaped = xml("1 < 2")
		ok(eq(tostring(escaped), "1 &lt; 2"))

		local unescaped = xml("1 < 2", false)
		ok(eq(tostring(unescaped), "1 < 2"))
	end),

	test("Unescaped Content", function()
		local p
		-- without attributes
		p = xml.p ("<b>bold</b>", false)
		ok(eq(tostring(p), "<p><b>bold</b></p>"))

		-- with attribute
		p = xml.p {attr = "value"} ("<b>bold</b>", false)
		ok(eq(tostring(p), '<p attr="value"><b>bold</b></p>'))
	end),

	test("Empty HTML", function()
		local empty = xml()
		ok(eq(tostring(empty), ""))
	end),

	test("Simple Function Result", function()
		local v
		local fn = function()
			return "<b/>"
		end

		-- escape non-xml objects by default
		v = xml.a(fn)
		ok(eq(tostring(v), "<a>&lt;b/&gt;</a>"))

		-- override any internal 'unescape' value with `true`.
		v = xml.a(fn, false)
		ok(eq(tostring(v), "<a><b/></a>"))

		-- override any internal `unescape` value with `false`.
		v = xml.a(fn, true)
		ok(eq(tostring(v), "<a>&lt;b/&gt;</a>"))
	end),

	test("HTML Function Result", function()
		local v

		local fn = function()
			return xml.b {}
		end

		v = xml.a(fn)

		ok(eq(tostring(v), "<a><b/></a>"))

		v = xml.a(fn, false)
		ok(eq(tostring(v), "<a><b/></a>"))

		v = xml.a(fn, true)
		ok(eq(tostring(v), "<a>&lt;b/&gt;</a>"))
	end),

	test("Concatination", function()
		ok(eq(tostring(xml.a() .. xml.b()), "<a/><b/>"))
		ok(eq(tostring("before " .. xml.a() .. " after"), "before <a/> after"))
	end)
)
