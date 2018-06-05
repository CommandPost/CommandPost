local test		= require("cp.test")
-- local log		= require("hs.logger").new("testwktbl")

local tableSrc	= require("cp.strings.source.table")
local plistSrc	= require("cp.strings.source.plist")
local strings	= require("cp.strings")
local config	= require("cp.config")

return test.suite("cp.strings"):with(
    test("Strings from multiple sources", function()
        local src1 = tableSrc.new()
            :add({foo = "bar"})

        local src2 = tableSrc.new()
            :add({yada = "yada"})

        local strs = strings.new():from(src1):from(src2)

        ok(eq(strs:find("foo"), "bar"))
        ok(eq(strs:find("yada"), "yada"))
    end),

    test("Strings from plist", function()
        local src = plistSrc.new(config.scriptPath .. "/tests/test.${language}.plist")
        local strs = strings.new():from(src)
            :context({language = "en"})

        ok(eq(strs:find("foo"), "bar"))
        ok(eq(strs:find("foo", {language = "es"}), "baz"))
        ok(eq(strs:find("foo", {language = "fr"}), nil))
        ok(eq(strs:find("xxx"), nil))
    end),

    test("Keys from plist", function()
        local strs = strings.new():fromPlist(config.scriptPath .. "/tests/test.${language}.plist")
            :context({language = "en"})
        ok(eq(strs:findKeys("bar"), {"foo"}))
    end)

)