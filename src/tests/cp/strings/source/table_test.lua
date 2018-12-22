local test              = require "cp.test"
local table             = require "cp.strings.source.table"

return test.suite("cp.strings.source.plist"):with {
    test("pathToAbsolute", function()
        local src = table.new()
        src:add({foo = "bar"})
    end),

    test("find", function()
        local src = table.new()
        src:add({foo = "bar"})
        ok(eq(src:find("foo"), "bar"))
        ok(eq(src:find("foo", {locale = "es"}), "bar"))
        ok(eq(src:find("foo", {locale = {"de", "German"}}), "bar"))
    end),

    test("findKeys", function()
        local src = table.new()
        src:add({foo = "bar"})
        ok(eq(src:findKeys("bar"), {"foo"}))
    end),
}