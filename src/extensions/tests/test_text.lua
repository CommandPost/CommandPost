local test				= require("cp.test")
local log				= require("hs.logger").new("t_text")
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

return test.suite("cp.text"):with(
	test("text from string", function()
		local utf8text = "a丽𐐷"
		local utf16le = "a\x00".."\x3D\x4E".."\x01\xD8\x37\xDC"	-- "a".."丽".."𐐷" (little-endian)
		local utf16be = "\x00a".."\x4E\x3D".."\xD8\x01\xDC\x37" -- "a".."丽".."𐐷" (big-endian)
		local codepoints = {97, 20029, 66615}					-- "a".."丽".."𐐷" (codepoints)

		local value = text.fromString(utf8text)

		ok(text.is(value))

		for i,cp in ipairs(value) do
			ok(eq(cp, codepoints[i]))
		end

		ok(eq(value:encode(), utf8text))
		ok(eq(value:encode(text.encoding.utf16le), utf16le))
		ok(eq(value:encode(text.encoding.utf16be), utf16be))

		ok(eq(tostring(value), utf8text))
	end),

	test("text from codepoints", function()
		local utf8text = "a丽𐐷"
		local utf16le = "a\x00".."\x3D\x4E".."\x01\xD8\x37\xDC"	-- "a".."丽".."𐐷" (little-endian)
		local utf16be = "\x00a".."\x4E\x3D".."\xD8\x01\xDC\x37" -- "a".."丽".."𐐷" (big-endian)
		local codepoints = {97, 20029, 66615}					-- "a".."丽".."𐐷" (codepoints)

		local value = text.fromCodepoints(codepoints)

		ok(text.is(value))

		for i,cp in ipairs(value) do
			ok(eq(cp, codepoints[i]))
		end

		ok(eq(value:encode(), utf8text))
		ok(eq(value:encode(text.encoding.utf16le), utf16le))
		ok(eq(value:encode(text.encoding.utf16be), utf16be))

		ok(eq(tostring(value), utf8text))

		ok(eq(text.fromCodepoints(codepoints, 2),		text "丽𐐷"))
		ok(eq(text.fromCodepoints(codepoints, -1),		text "𐐷"))
		ok(eq(text.fromCodepoints(codepoints, 2, 1),	text ""))
		ok(eq(text.fromCodepoints(codepoints, 4),		text ""))
	end),

	test("read-only", function()
		local value = text "a丽𐐷"
		expectError(function() value[1] = 1 end)
	end),

	test("concatenation", function()
		local utf8String = "a丽𐐷"
		local direct = text "a丽𐐷"
		local joined = text "a" .. text "丽𐐷"
		local left = text "a" .. "丽𐐷"
		local right = "a" .. text "丽𐐷"

		ok(eq(direct, joined))
		ok(text.is(joined))
		ok(text.is(left))
		ok(text.is(right))
		ok(eq(direct, left))
		ok(eq(direct, right))
	end),


	test("len", function()
		local utf8String = "a丽𐐷"
		local unicodeText = text "a丽𐐷"

		ok(eq(utf8String:len(), 8))
		ok(eq(unicodeText:len(), 3))
		ok(eq(#unicodeText, 3))
		ok(eq(unicodeText:encode(text.encoding.utf16le):len(), 8))
	end),

	test("equality", function()
		ok("a丽𐐷" == "a丽𐐷", "string == string")
		ok("a丽𐐷" ~= text "a丽𐐷" ,"string ~= text")
		ok(text "a丽𐐷" == text "a丽𐐷", "text == text")
		ok(text "a丽𐐷" ~= text "other text", "text ~= different text")
	end),

	test("sub", function()
		local value = text("123456789")

		ok(eq(value:sub(1),			text "123456789"))
		ok(eq(value:sub(1,1),		text "1"))
		ok(eq(value:sub(5),			text "56789"))
		ok(eq(value:sub(5,7),		text "567"))
		ok(eq(value:sub(-2),		text "89"))
		ok(eq(value:sub(-5, -3),	text "567"))
		ok(eq(value:sub(5,1),		text ""))
	end),

	test("text with BOM", function()
		local utf8text		= "\239\187\191".."a丽𐐷"								-- BOM.."a丽𐐷"
		local utf16le		= "\255\254".."a\x00".."\x3D\x4E".."\x01\xD8\x37\xDC"	-- BOM.."a".."丽".."𐐷" (little-endian)
		local utf16be		= "\254\255".."\x00a".."\x4E\x3D".."\xD8\x01\xDC\x37"	-- BOM.."a".."丽".."𐐷" (big-endian)
		local codepoints	= {97, 20029, 66615}									-- "a".."丽".."𐐷" (codepoints - BOM is skipped)

		ok(eq(text.fromString(utf8text).codes, codepoints))
		ok(eq(text.fromString(utf16le).codes, codepoints))
		ok(eq(text.fromString(utf16be).codes, codepoints))
	end),

	test("text from file", function()
		-- loading from BOM
		ok(eq(text.fromFile(TEXT_PATH.."utf8.txt"), text "ABC123"))
		ok(eq(text.fromFile(TEXT_PATH.."utf16le.txt"), text "ABC123"))
		ok(eq(text.fromFile(TEXT_PATH.."utf16be.txt"), text "ABC123"))
	end),


	test("match", function()
		local grp1, grp2 = text("valid@email"):match("^([^@]+)@([^@]+)$")
		ok(eq(grp1, text "valid"))
		ok(eq(grp2, text "email"))

		local grp1, grp2 = text("@bad"):match("^([^@]+)@([^@]+)$")
		ok(eq(grp1, nil))
		ok(eq(grp2, nil))

		local result = text("foobar"):match("^.*$")
		ok(eq(result, text "foobar"))

		local result = text("foobar"):match("^%d*$")
		ok(eq(result, nil))
	end),

	test("gmatch", function()
		local v = text("banana")
		local count = 0
		for w in v:gmatch("an") do
			ok(eq(w, text "an"))
			count = count + 1
		end
		ok(eq(count, 2))
	end),

	test("gsub", function()
		local x

		x = text("hello world"):gsub("%w+", "%0 %0")
		ok(eq(x, text "hello hello world world"))

		x = text("hello world"):gsub("%w+", "%0 %0", 1)
		ok(eq(x, text "hello hello world"))

		x = text("hello world from Lua"):gsub("(%w+)%s*(%w+)", "%2 %1")
		ok(eq(x, text "world hello Lua from"))

		x = text("home = $HOME, user = $USER"):gsub("%$(%w+)", {HOME = "/home/foo", USER = "foo"})
		ok(eq(x, text "home = /home/foo, user = foo"))

		x = text("4+5 = $return 4+5$"):gsub("%$(.-)%$", function (s)
			return load(tostring(s))()
		end)
		ok(eq(x, text "4+5 = 9"))

		local t = {name="lua", version="5.1"}
		x = text("$name-$version.tar.gz"):gsub("%$(%w+)", t)
		ok(eq(x, text "lua-5.1.tar.gz"))


		x = text("Is \\Escaped"):gsub('%\\(.)', '%1')
		ok(eq(x, text "Is Escaped"))

		x = text('Is \\"Escaped\\"'):gsub('%\\(.)', '%1')
		ok(eq(x, text 'Is "Escaped"'))

		x = text("Is Unescaped"):gsub('%\\(.)', '%1')
		ok(eq(x, text "Is Unescaped"))

		x = text("A\\U1234B"):gsub('%\\[Uu]%d%d%d%d', function(s)
			return utf8.char(tonumber(s:sub(3):encode()))
		end)
		ok(eq(x, text "AӒB"))
	end),

	test("quotes matcher", function()
		local keyValue = matcher('^%"(.+)%"%s*%=%s*%"(.+)%";.*$')
		local key, value = keyValue:match('"key" = "value";')
		ok(eq(key, text "key"))
		ok(eq(value, text "value"))

		key, value = keyValue:match('"key" = "\\"quoted\\"";')
		ok(eq(key, text "key"))
		ok(eq(value, text '\\"quoted\\"'))

		local CHAR_ESCAPE = matcher('%\\(.)')
		local escaped = text 'Is \\"Escaped\\"'
		ok(eq(tostring(escaped), 'Is \\"Escaped\\"'))
		local x = CHAR_ESCAPE:gsub(escaped, '%1')
		ok(eq(tostring(x), 'Is "Escaped"'))
		-- Ensure it works twice in a row
		local x = CHAR_ESCAPE:gsub(escaped.." ", '%1')
		ok(eq(tostring(x), 'Is "Escaped" '))

	end)
)