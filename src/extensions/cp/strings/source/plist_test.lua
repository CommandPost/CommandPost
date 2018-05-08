local test              = require "cp.test"
local plist             = require "cp.strings.source.plist"
local config            = require "cp.config"

local testsPath = config.scriptPath .. "/tests"

return test.suite("cp.strings.source.plist"):with {
    test("pathToAbsolute", function()
        local src = plist.new("${path}/tests/test.${locale}.plist")
        src:context({path = config.scriptPath, locale="en"})
        ok(eq(src:pathToAbsolute(), testsPath .. "/test.en.plist"))
        ok(eq(src:pathToAbsolute({locale = "es"}), testsPath .. "/test.es.plist"))
        ok(eq(src:pathToAbsolute({locale = {"de", "German"}}), testsPath .. "/test.German.plist"))
    end),

    test("loadFile", function()
        local src = plist.new("${path}/tests/test.${locale}.plist")
        src:context({path = config.scriptPath, locale="en"})
        ok(eq(src:loadFile(), {foo = "bar"}))
        ok(eq(src:loadFile({locale = "es"}), {foo = "baz"}))
        ok(eq(src:loadFile({locale = {"de", "German"}}), {foo = "bür"}))
    end),

    test("find", function()
        local src = plist.new("${path}/tests/test.${locale}.plist")
        src:context({path=config.scriptPath, locale="en"})
        ok(eq(src:find("foo"), "bar"))
        ok(eq(src:find("foo", {locale = "es"}), "baz"))
        ok(eq(src:find("foo", {locale = {"de", "German"}}), "bür"))
    end),
}