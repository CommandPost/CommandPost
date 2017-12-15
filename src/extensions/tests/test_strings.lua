local test		= require("cp.test")
local log		= require("hs.logger").new("testwktbl")

local tableSrc	= require("cp.strings.source.table")
local plistSrc	= require("cp.strings.source.plist")
local strings	= require("cp.strings")
local config	= require("cp.config")

return test("cp.strings", function()
	test("Table Source Test", function()
		local src = tableSrc.new()
			:add("en", {foo = "bar"})
			:add("es", {foo = "baz"})
		ok(eq(src:find("en", "foo"), "bar"))
		ok(eq(src:find("es", "foo"), "baz"))
		ok(eq(src:find("fr", "foo"), nil))
		ok(eq(src:find("en", "xxx"), nil))
	end)

	test("Strings from single source", function()
		local src = tableSrc.new()
			:add("en", {foo = "bar"})
			:add("es", {foo = "baz"})

		local strs = strings.new():from(src)

		ok(eq(strs:find("en", "foo"), "bar"))
		ok(eq(strs:find("es", "foo"), "baz"))
		ok(eq(strs:find("fr", "foo"), nil))
		ok(eq(strs:find("en", "xxx"), nil))
	end)

	test("Strings from multiple sources", function()
		local src1 = tableSrc.new()
			:add("en", {foo = "bar"})
			:add("es", {foo = "baz"})

		local src2 = tableSrc.new()
			:add("en", {yada = "yada"})
			:add("es", {yada = "nada"})
			:add("fr", {yada = "fada", foo = "baf"})

		local strs = strings.new():from(src1):from(src2)

		ok(eq(strs:find("en", "foo"), "bar"))
		ok(eq(strs:find("es", "foo"), "baz"))
		ok(eq(strs:find("fr", "foo"), "baf"))
		ok(eq(strs:find("en", "xxx"), nil))

		ok(eq(strs:find("en", "yada"), "yada"))
		ok(eq(strs:find("es", "yada"), "nada"))
	end)

	test("Strings from plist", function()
		local src = plistSrc.new(config.scriptPath .. "/tests/test.${language}.plist")

		local strs = strings.new():from(src)

		ok(eq(strs:find("en", "foo"), "bar"))
		ok(eq(strs:find("es", "foo"), "baz"))
		ok(eq(strs:find("fr", "foo"), nil))
		ok(eq(strs:find("en", "xxx"), nil))
	end)

	test("Keys from plist", function()
		local strs = strings.new():fromPlist(config.scriptPath .. "/tests/test.${language}.plist")
		ok(eq(strs:findKeys("en", "bar"), {"foo"}))
	end)

end)