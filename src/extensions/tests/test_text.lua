local test				= require("cp.test")
local log				= require("hs.logger").new("t_text")
local inspect			= require("hs.inspect")

local config			= require("cp.config")
local text				= require("cp.text")

local TEXT_PATH = config.scriptPath .. "/tests/unicode/"

function expectError(fn, ...)
	local success, result = pcall(fn, ...)
	ok(not success)
	return result
end

function run()
	test("text round-trip", function()
		local utf8text = "a丽𐐷"
		local utf16le = "a\x00".."\x3D\x4E".."\x01\xD8\x37\xDC"	-- "a".."丽".."𐐷" (little-endian)
		local utf16be = "\x00a".."\x4E\x3D".."\xD8\x01\xDC\x37" -- "a".."丽".."𐐷" (big-endian)
		local codepoints = {97, 20029, 66615}					-- "a".."丽".."𐐷" (codepoints)
		
		local value = text.new(utf8text)

		ok(text.is(value))
		
		ok(eq(value, codepoints))
		ok(eq(value:encode(), utf8text))
		ok(eq(value:encode(text.encoding.utf16le), utf16le))
		ok(eq(value:encode(text.encoding.utf16be), utf16be))
		
		ok(eq(tostring(value), utf8text))
	end)
	
	test("read-only", function()
		local value = text "a丽𐐷"
		expectError(function() value[1] = 1 end)
	end)
	
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
	end)
	
	
	test("len", function()
		local utf8String = "a丽𐐷"
		local unicodeText = text "a丽𐐷"
		
		ok(eq(utf8String:len(), 8))
		ok(eq(unicodeText:len(), 3))
	end)
	
end

return run
