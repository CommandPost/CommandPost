local test				= require("cp.test")
local log				= require("hs.logger").new("t_utf16")
local inspect			= require("hs.inspect")

local bench				= require("cp.bench")

local config			= require("cp.config")
local utf16				= require("cp.utf16")

local TEXT_PATH = config.scriptPath .. "/tests/unicode/"

function expectError(fn, ...)
	local success, result = pcall(fn, ...)
	ok(not success)
	return result
end

function run()
	test("toBytes", function()
		local toBytes = utf16._toBytes
		
		ok(eq({toBytes(1)}, {0x1, 0, 0, 0, 0, 0, 0, 0}))
		ok(eq({toBytes(0x1234)}, {0x34, 0x12, 0, 0, 0, 0, 0, 0}))
		ok(eq({toBytes(0x1234, 2)}, {0x34, 0x12}))
		ok(eq({toBytes(0x1234, 2, true)}, {0x12, 0x34}))
	end)
	
	test("UTF-16 Invalid Codepoints", function()
		local char = utf16.char
		expectError(char, -1)		-- less than 0x0
		expectError(char, 0xD800)	-- reserved
		expectError(char, 0xDFFF)	-- reserved
		expectError(char, 0x110000)	-- the maximum codepoint is 0x10FFFF
	end)
	
	test("UTF-16LE file", function()
		for line in io.lines(TEXT_PATH .. "utf16le.txt") do
			ok(eq(line, "\xFF\xFEA\x00B\x00C\x001\x002\x003\x00"))
		end
	end)

	test("UTF-16BE file", function()
		for line in io.lines(TEXT_PATH .. "utf16be.txt") do
			ok(eq(line, "\xFE\xFF\x00A\x00B\x00C\x001\x002\x003"))
		end
	end)
	
	test("UTF-16 char conversion", function()
		local char = utf16.char
		
		-- ASCII character
		ok(eq(char(utf8.codepoint("a")),		"a\x00"))				-- default to little-endian.
		ok(eq(char(true, utf8.codepoint("a")),	"\x00a"))				-- big-endian
		
		-- non-ASCII character
		ok(eq(char(utf8.codepoint("丽")),		"\x3D\x4E"))			-- default to little-endian.
		ok(eq(char(true, utf8.codepoint("丽")),	"\x4E\x3D"))			-- big-endian
		
		-- test a character above 0x10000
		ok(eq(char(false, utf8.codepoint("𐐷")),	"\x01\xD8\x37\xDC"))	-- little-endian
		ok(eq(char(true, utf8.codepoint("𐐷")),	"\xD8\x01\xDC\x37"))	-- big-endian
		
		ok(eq(char(false, 0xFEFF), "\xFF\xFE"))							-- marker
		ok(eq(char(true,  0xFEFF), "\xFE\xFF"))							-- marker
		
		-- combo
		local utf8text = 	"a".."丽".."𐐷"
		
		local utf16le = char(false, utf8.codepoint(utf8text, 1, #utf8text))
		ok(eq(utf16le,		"a\x00".."\x3D\x4E".."\x01\xD8\x37\xDC"))

		local utf16be = char(true,  utf8.codepoint(utf8text, 1, #utf8text))
		ok(eq(utf16be,		"\x00a".."\x4E\x3D".."\xD8\x01\xDC\x37"))
	end)
	
	test("read2Bytes", function()
		local read2Bytes = utf16._read2Bytes
		
		local string = "\x00\x01\x00\x02\x00\x03"
		
		ok(eq(read2Bytes(false, string, 1), 0x0100))			-- little-endian `1`
		ok(eq(read2Bytes(true,  string, 1), 0x0001))			-- big-endian `1`
		
		ok(eq(read2Bytes(true,  string, 5), 0x0003))			-- big-endian `2`
		ok(eq(read2Bytes(false, string, 5), 0x0300))			-- little-endian `768`
		
		expectError(read2Bytes, true,  string, -1)				-- out of range
		expectError(read2Bytes, true,  string, 6)				-- not enough bits left for 16 bytes.
	end)
	
	test("fromBytes", function()
		local fromBytes = utf16._fromBytes
		local utf16le = "a\x00".."\x3D\x4E".."\x01\xD8\x37\xDC"	-- "a".."丽".."𐐷" (little-endian)
		
		local cp, length = fromBytes(false, utf16le, 1)			-- "a"
		ok(eq(cp, utf8.codepoint("a")))
		ok(eq(length, 2))
		
		cp, length = fromBytes(false, utf16le, 3)			-- "丽"
		ok(eq(cp, utf8.codepoint("丽")))
		ok(eq(length, 2))

		cp, length = fromBytes(false, utf16le, 5)			-- "𐐷"
		ok(eq(cp, utf8.codepoint("𐐷")))
		ok(eq(length, 4))
		
		local utf16be = "\x00a".."\x4E\x3D".."\xD8\x01\xDC\x37" -- "a".."丽".."𐐷" (big-endian)
		
		cp, length = fromBytes(true, utf16be, 1)			-- "a"
		ok(eq(cp, utf8.codepoint("a")))
		ok(eq(length, 2))
		
		cp, length = fromBytes(true, utf16be, 3)			-- "丽"
		ok(eq(cp, utf8.codepoint("丽")))
		ok(eq(length, 2))

		cp, length = fromBytes(true, utf16be, 5)			-- "𐐷"
		ok(eq(cp, utf8.codepoint("𐐷")))
		ok(eq(length, 4))
		
		cp, length = fromBytes(false, utf16le, -4)			-- "𐐷", searching from rear.
		ok(eq(cp, utf8.codepoint("𐐷")))
		ok(eq(length, 4))
		
		cp, length = fromBytes(false, "\xFF\xFE", 1)		-- BOM marker (little-endian)
		ok(eq(cp, 0xFEFF))
		ok(eq(length, 2))

		cp, length = fromBytes(true, "\xFE\xFF", 1)			-- BOM marker (big-endian)
		ok(eq(cp, 0xFEFF))
		ok(eq(length, 2))
		
		expectError(fromByes, true, "\xDC\x37", 1)				-- 2-bytes, but match 'excluded' range
		
		expectError(fromBytes, false, utf16le, 7)				-- reading half way into "𐐷"
		expectError(fromBytes, true,  utf16be, 7)				-- reading half way into "𐐷"
		
		expectError(fromBytes, false, utf16le, 0)
		expectError(fromBytes, false, utf16le, 8)
		expectError(fromBytes, false, utf16le, 9)
	end)
	
	test("codepoint", function()
		local codepoint = utf16.codepoint
		local utf16le = "a\x00".."\x3D\x4E".."\x01\xD8\x37\xDC"	-- "a".."丽".."𐐷" (little-endian)
		local utf16be = "\x00a".."\x4E\x3D".."\xD8\x01\xDC\x37" -- "a".."丽".."𐐷" (big-endian)
		
		ok(eq(codepoint(utf16le), utf8.codepoint("a")))					-- first character of the string, little-endian
		ok(eq(codepoint(utf16le, 3), utf8.codepoint("丽")))				-- second character of the string, little-endian
		ok(eq(codepoint(utf16le, 5), utf8.codepoint("𐐷")))				-- third character of the string, little-endian

		ok(eq(codepoint(true, utf16be), utf8.codepoint("a")))			-- first character of the string, big-endian
		ok(eq(codepoint(true, utf16be, 3), utf8.codepoint("丽")))		-- second character of the string, big-endian
		ok(eq(codepoint(true, utf16be, 5), utf8.codepoint("𐐷")))		-- third character of the string, big-endian

		ok(eq({codepoint(false, utf16le, 1, 3)}, {utf8.codepoint("a丽𐐷", 1, 3)}))
		ok(eq({codepoint(false, utf16le, 1, 3)}, {utf8.codepoint("a丽𐐷", 1, 3)}))
		ok(eq({codepoint(false, utf16le, 1, 8)}, {utf8.codepoint("a丽𐐷", 1, 8)}))
		ok(eq({codepoint(false, utf16le, 3, 8)}, {utf8.codepoint("a丽𐐷", 2, 8)}))
		
		ok(eq(codepoint(true, utf16be, -4), utf8.codepoint("𐐷")))		-- third character of the string, big-endian
	end)
	
	test("codes", function()
		local codes = utf16.codes
		local utf16le = "a\x00".."\x3D\x4E".."\x01\xD8\x37\xDC"	-- "a".."丽".."𐐷" (little-endian)
		local utf16be = "\x00a".."\x4E\x3D".."\xD8\x01\xDC\x37" -- "a".."丽".."𐐷" (big-endian)
		local codepoints = {utf8.codepoint("a丽𐐷", 1, 8)}		-- "a".."丽".."𐐷" (codepoints)
		
		local result = {}
		for i,cp in codes(utf16le) do							-- little-endian by default
			table.insert(result, cp)
		end
		ok(eq(result, codepoints))

		result = {}
		for i,cp in codes(false, utf16le) do					-- explicitly little-endian
			table.insert(result, cp)
		end
		ok(eq(result, codepoints))

		result = {}
		for i,cp in codes(true, utf16be) do						-- explicitly big-endian
			table.insert(result, cp)
		end
		ok(eq(result, codepoints))
	end)
	
	test("len", function()
		local len = utf16.len
		local utf16le = "a\x00".."\x3D\x4E".."\x01\xD8\x37\xDC"	-- "a".."丽".."𐐷" (little-endian)
		local utf16be = "\x00a".."\x4E\x3D".."\xD8\x01\xDC\x37" -- "a".."丽".."𐐷" (big-endian)
		local utf8text = "a丽𐐷"
		
		ok(eq(len(utf16le),					utf8.len(utf8text)))
		ok(eq(len(false, utf16le),			utf8.len(utf8text)))
		ok(eq(len(false, utf16le, 3),		utf8.len(utf8text, 2)))
		ok(eq(len(false, utf16le, 1, 3),	utf8.len(utf8text, 1, 2)))
		
		ok(eq(len(true, utf16be),			utf8.len(utf8text)))
		ok(eq(len(true, utf16be, 3),		utf8.len(utf8text, 2)))
		ok(eq(len(true, utf16be, 1, 3),		utf8.len(utf8text, 1, 2)))
	end)
end

return run
