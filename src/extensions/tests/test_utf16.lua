local test				= require("cp.test")
local log				= require("hs.logger").new("t_utf16")
local inspect			= require("hs.inspect")

local bench				= require("cp.bench")

local config			= require("cp.config")
local utf16le			= require("cp.utf16")

local TEXT_PATH = config.scriptPath .. "/tests/unicode/"

function expectError(fn, ...)
	local success, result = pcall(fn, ...)
	ok(not success)
	return result
end

function run()
	test("asBytes", function()
		local asBytes = utf16le.asBytes
		
		ok(eq({asBytes(1)}, {0x1, 0, 0, 0, 0, 0, 0, 0}))
		ok(eq({asBytes(0x1234)}, {0x34, 0x12, 0, 0, 0, 0, 0, 0}))
		ok(eq({asBytes(0x1234, 2)}, {0x34, 0x12}))
		ok(eq({asBytes(0x1234, 2, true)}, {0x12, 0x34}))
	end)
	
	test("UTF-16LE Invalid Codepoints", function()
		local char = utf16le.char
		expectError(char, -1)		-- less than 0x0
		expectError(char, 0xD800)	-- reserved
		expectError(char, 0xDFFF)	-- reserved
		expectError(char, 0x110000)	-- the maximum codepoint is 0x10FFFF
	end)
	
	test("UTF-16LE file", function()
		local file = io.open(TEXT_PATH .. "utf16le.txt", "rb")
		for line in file:lines() do
			ok(eq(line, "\xFF\xFEA\x00B\x00C\x001\x002\x003\x00"))
		end
	end)

	test("UTF-16BE file", function()
		local file = io.open(TEXT_PATH .. "utf16be.txt", "rb")
		for line in file:lines() do
			ok(eq(line, "\xFE\xFF\x00A\x00B\x00C\x001\x002\x003"))
		end
	end)
	
	test("UTF-16", function()
		local char = utf16le.char
		
		-- ASCII character
		ok(eq(char(string.byte("a")),		"a\x00"))			-- default to little-endian.
		ok(eq(char(true, string.byte("a")),	"\x00a"))			-- big-endian
		
		-- non-ASCII character
		for i, code in utf8.codes("丽") do
			ok(eq(char(code),			"\x3D\x4E"))			-- default to little-endian.
			ok(eq(char(true, code),		"\x4E\x3D"))			-- big-endian
		end
		
		-- test a character above 0x10000
		for i, code in utf8.codes("𐐷") do
			ok(eq(char(false, code),	"\x01\xD8\x37\xDC"))	-- little-endian
			ok(eq(char(true, code),		"\xD8\x01\xDC\x37"))	-- big-endian
		end
	end)
end

return run
