local test				= require("cp.test")
local log				= require("hs.logger").new("t_matcher")
local inspect			= require("hs.inspect")

local config			= require("cp.config")
local text				= require("cp.text")
local matcher			= require("cp.text.matcher")

local TEXT_PATH = config.scriptPath .. "/tests/unicode/"

function expectError(fn, ...)
	local success, result = pcall(fn, ...)
	ok(not success)
	return result
end

return test.suite("cp.text.matcher"):with(
	test("simple matcher", function()
		local value = text "banana"
		local m = matcher(text "an")

		local first, last = m:find(value)
		ok(eq(first, 2))
		ok(eq(last, 3))

		first, last = m:find(value, 4)
		ok(eq(first, 4))
		ok(eq(last, 5))
	end),

	test("simple group", function()
		local value = text "banana"
		local m = matcher(text "(an)")

		local first, last, grp1, grp2 = m:find(value)
		ok(eq(first, 2))
		ok(eq(last, 3))
		ok(eq(grp1, text "an"))
		ok(eq(grp2, nil))

		first, last = m:find(value, 4)
		ok(eq(first, 4))
		ok(eq(last, 5))
		ok(eq(grp1, text "an"))
		ok(eq(grp2, nil))
	end),

	test("string conversion", function()
		local m = matcher("(an)")
		local value = "banana"

		local first, last, grp1, grp2 = m:find(value)
		ok(eq(first, 2))
		ok(eq(last, 3))
		ok(eq(grp1, text "an"))
		ok(eq(grp2, nil))

		first, last = m:find(value, 4)
		ok(eq(first, 4))
		ok(eq(last, 5))
		ok(eq(grp1, text "an"))
		ok(eq(grp2, nil))
	end),

	test("character classes", function()
		local first, last = matcher("%a"):find("1!a")
		ok(eq(first, 3))
		ok(eq(last, 3))

		local first, last = matcher("%c"):find("1!a\001")
		ok(eq(first, 4))
		ok(eq(last, 4))

		local first, last = matcher("%d"):find("1!a")
		ok(eq(first, 1))
		ok(eq(last, 1))

		local first, last = matcher("%x"):find("ONE1")
		ok(eq(first, 3))
		ok(eq(last, 3))

		local first, last = matcher("%l"):find("abcABC")
		ok(eq(first, 1))
		ok(eq(last, 1))

		local first, last = matcher("%u"):find("abcABC")
		ok(eq(first, 4))
		ok(eq(last, 4))

		local first, last = matcher("%p"):find("1!a")
		ok(eq(first, 2))
		ok(eq(last, 2))

		local first, last = matcher("%s"):find("abc ABC")
		ok(eq(first, 4))
		ok(eq(last, 4))

		local first, last = matcher("%w"):find("?123 ABC")
		ok(eq(first, 2))
		ok(eq(last, 2))

		local first, last = matcher("%z"):find("abc\000ABC")
		ok(eq(first, 4))
		ok(eq(last, 4))
	end),

	test("multiple characters", function()
		local first, last = matcher("%x%x"):find("ONE1")
		ok(eq(first, 3))
		ok(eq(last, 4))
	end),

	test("custom character classes", function()
		local first, last = matcher("[E]"):find("ONE1")
		ok(eq(first, 3))
		ok(eq(last, 3))

		local first, last = matcher("[EN]"):find("ONE1")
		ok(eq(first, 2))
		ok(eq(last, 2))

		local first, last = matcher("[E-N]"):find("ONE1")
		ok(eq(first, 2))
		ok(eq(last, 2))

		local first, last = matcher("[^O]"):find("ONE1")
		ok(eq(first, 2))
		ok(eq(last, 2))

	end),

	test("quantifiers", function()
		local first, last = matcher("[EN]+"):find("ONE1")
		ok(eq(first, 2))
		ok(eq(last, 3))

		local first, last = matcher("[EN]?"):find("ONE1")
		ok(eq(first, 1))
		ok(eq(last, 0))

		local first, last = matcher("X*"):find("ONE1")
		ok(eq(first, 1))
		ok(eq(last, 0))

		local first, last = matcher("[EN]-"):find("ONE1")
		ok(eq(first, 1))
		ok(eq(last, 0))
	end),

	test("complex quantifiers", function()
		local first, last = matcher("[EN]+1"):find("ONE1")
		ok(eq(first, 2))
		ok(eq(last, 4))

		local first, last = matcher("[EN]?1"):find("ONE1")
		ok(eq(first, 3))
		ok(eq(last, 4))

		local first, last = matcher("X*1"):find("ONE1")
		ok(eq(first, 4))
		ok(eq(last, 4))

		local first, last = matcher("[EN]-1"):find("ONE1")
		ok(eq(first, 2))
		ok(eq(last, 4))
	end),

	test("first last", function()
		local first, last = matcher("^%a"):find("ONE1")
		ok(eq(first, 1))
		ok(eq(last, 1))

		local first, last = matcher("1$"):find("ONE1")
		ok(eq(first, 4))
		ok(eq(last, 4))

		local first, last = matcher("^.*$"):find("ONE1")
		ok(eq(first, 1))
		ok(eq(last, 4))
	end),

	test("complex pattern", function()
		local m = matcher("^([^@]+)@([^@]+)$")

		local first, last, grp1, grp2 = m:find("valid@email")
		ok(eq(first, 1))
		ok(eq(last, 11))
		ok(eq(grp1, text "valid"))
		ok(eq(grp2, text "email"))

		local first, last, grp1, grp2 = m:find("@bad")
		ok(eq(first, nil))
		ok(eq(last, nil))
		ok(eq(grp1, nil))
		ok(eq(grp2, nil))
	end),

	test("match", function()
		local m = matcher("^([^@]+)@([^@]+)$")

		local grp1, grp2 = m:match("valid@email")
		ok(eq(grp1, text "valid"))
		ok(eq(grp2, text "email"))

		local grp1, grp2 = m:match("@bad")
		ok(eq(grp1, nil))
		ok(eq(grp2, nil))

		local result = matcher("^.*$"):match("foobar")
		ok(eq(result, text "foobar"))

		local result = matcher("^%d*$"):match("foobar")
		ok(eq(result, nil))
	end),

	test("gmatch", function()
		local m = matcher("an")
		local count = 0
		for w in m:gmatch("banana") do
			ok(eq(w, text "an"))
			count = count + 1
		end
		ok(eq(count, 2))
	end),

	test("gsub", function()
		local x

		x = matcher("%w+"):gsub("hello world", "%1 %1")
		ok(eq(x, text "hello hello world world"))

		x = matcher("%w+"):gsub("hello world", "%0 %0", 1)
		ok(eq(x, text "hello hello world"))

		x = matcher("(%w+)%s*(%w+)"):gsub("hello world from Lua", "%2 %1")
		ok(eq(x, text "world hello Lua from"))

		x = matcher("%$(%w+)"):gsub("home = $HOME, user = $USER", {HOME = "/home/foo", USER = "foo"})
		ok(eq(x, text "home = /home/foo, user = foo"))

		x = matcher("%$(.-)%$"):gsub("4+5 = $return 4+5$", function (s)
			return load(tostring(s))()
		end)
		ok(eq(x, text "4+5 = 9"))

		local t = {name="lua", version="5.1"}
		x = matcher("%$(%w+)"):gsub("$name-$version.tar.gz", t)
		ok(eq(x, text "lua-5.1.tar.gz"))
	end)
)
