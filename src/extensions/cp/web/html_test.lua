-- local log		= require("hs.logger").new("t_html")
-- local inspect	= require("hs.inspect")

local test = require("cp.test")

local html = require("cp.web.html")

return test.suite("cp.web.html"):with(
    test("Is", function()
        ok(eq(html.is("text"), false))
        ok(eq(html.is({}), false))
        ok(eq(html.is(html), false))
        ok(eq(html.is(html.a()), true))
    end),

    test("Single Element", function()
        local element = html.element()
        ok(eq(tostring(element), "<element/>"))

        element = html.element {attribute = "value"}
        ok(eq(tostring(element), '<element attribute="value"/>'))
    end),

    test("CDATA", function()
        local cdata = html.CDATA "This is CDATA."
        ok(eq(tostring(cdata), "<![CDATA[This is CDATA.]]>"))
    end),

    test("Comment", function()
        local comment = html.__ "This is a comment."
        ok(eq(tostring(comment), "<!-- This is a comment. -->"))
    end),

    test("Text Block", function()
        local escaped = html("1 < 2")
        ok(eq(tostring(escaped), "1 &lt; 2"))

        local unescaped = html("1 < 2", false)
        ok(eq(tostring(unescaped), "1 < 2"))
    end),

    test("Unescaped Content", function()
        local p
        -- without attributes
        p = html.p ("<b>bold</b>", false)
        ok(eq(tostring(p), "<p><b>bold</b></p>"))

        -- with attribute
        p = html.p {attr = "value"} ("<b>bold</b>", false)
        ok(eq(tostring(p), '<p attr="value"><b>bold</b></p>'))
    end),

    test("Empty HTML", function()
        local empty = html()
        ok(eq(tostring(empty), ""))
    end),

    test("Simple Function Result", function()
        local v
        local fn = function()
            return "<b/>"
        end

        -- escape non-html objects by default
        v = html.a(fn)
        ok(eq(tostring(v), "<a>&lt;b&#47;&gt;</a>"))

        -- override any internal 'unescape' value with `true`.
        v = html.a(fn, false)
        ok(eq(tostring(v), "<a><b/></a>"))

        -- override any internal `unescape` value with `false`.
        v = html.a(fn, true)
        ok(eq(tostring(v), "<a>&lt;b&#47;&gt;</a>"))
    end),

    test("HTML Function Result", function()
        local v

        local fn = function()
            return html.b {}
        end

        v = html.a(fn)

        ok(eq(tostring(v), "<a><b/></a>"))

        v = html.a(fn, false)
        ok(eq(tostring(v), "<a><b/></a>"))

        v = html.a(fn, true)
        ok(eq(tostring(v), "<a>&lt;b&#47;&gt;</a>"))
    end),

    test("Concatination", function()
        ok(eq(tostring(html.a() .. html.b()), "<a/><b/>"))
        ok(eq(tostring("before " .. html.a() .. " after"), "before <a/> after"))
    end)
)
