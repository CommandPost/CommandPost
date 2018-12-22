local test              = require "cp.test"
local plist             = require "cp.strings.source.plist"
local config            = require "cp.config"

local testsPath = config.testsPath .. "/cp/strings/_resources"
local testsPattern = "${path}/cp/strings/_resources/test.${locale}.plist"

return test.suite("cp.strings.source.plist"):with {
    test("pathToAbsolute", function()
        local src = plist.new(testsPattern)
        src:context({path = config.testsPath, locale="en"})
        ok(eq(src:pathToAbsolute(), testsPath .. "/test.en.plist"))
        ok(eq(src:pathToAbsolute({locale = "es"}), testsPath .. "/test.es.plist"))
        ok(eq(src:pathToAbsolute({locale = {"de", "German"}}), testsPath .. "/test.German.plist"))
    end),

    test("loadFile", function()
        local src = plist.new(testsPattern)
        src:context({path = config.testsPath, locale="en"})
        ok(eq(src:loadFile(), {foo = "bar"}))
        ok(eq(src:loadFile({locale = "es"}), {foo = "baz"}))
        ok(eq(src:loadFile({locale = {"de", "German"}}), {foo = "bür"}))
    end),

    test("find", function()
        local src = plist.new(testsPattern)
        src:context({path=config.testsPath, locale="en"})
        ok(eq(src:find("foo"), "bar"))
        ok(eq(src:find("foo", {locale = "es"}), "baz"))
        ok(eq(src:find("foo", {locale = {"de", "German"}}), "bür"))
    end),
}