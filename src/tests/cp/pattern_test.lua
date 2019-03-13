-- test cases for `cp.pattern`
local test      = require("cp.test")
local pattern   = require("cp.pattern")

local doesMatch = pattern.doesMatch

return test.suite("cp.app"):with {
    test("doesMatch default", function()
        ok(eq(doesMatch("foobar", "foo"), true))
        ok(eq(doesMatch("foobar", "bar"), true))
        ok(eq(doesMatch("foobar", "foobar"), true))
        ok(eq(doesMatch("foobar", "foo bar"), true))
        ok(eq(doesMatch("foobar", "bar foo"), true))
        ok(eq(doesMatch("foobar", "FOO"), true))

        ok(eq(doesMatch("blahfoobarblah", "foo"), true))
    end),

    test("doesMatch caseSensitive", function()
        ok(eq(doesMatch("foobar", "FOO", {caseSensitive = true}), false))
        ok(eq(doesMatch("foobar", "FOO", {caseSensitive = false}), true))
    end),

    test("doesMatch exact", function()
        ok(eq(doesMatch("foobar", "foo bar", {exact = true}), false))
        ok(eq(doesMatch("foobar", "foo bar", {exact = false}), true))

        ok(eq(doesMatch("foo bar", "bar foo", {exact = false}), true))
        ok(eq(doesMatch("foo bar", "bar foo", {exact = true}), false))

        ok(eq(doesMatch("foobar", "FOOBAR", {exact = true}), true))
        ok(eq(doesMatch("foobar", "FOOBAR", {exact = true, caseSensitive = true}), false))
    end),

    test("doesMatch wholeWords", function()
        ok(eq(doesMatch("blah foobar blah", "foobar", {wholeWords = true}), true))
        ok(eq(doesMatch("blah foobar blah", "foo", {wholeWords = true}), false))
        ok(eq(doesMatch("blah foobar blah", "bar", {wholeWords = true}), false))
        ok(eq(doesMatch("blah foobar blah", "blah", {wholeWords = true}), true))
    end),
}