local schar = string.char

local mod = {}

--[[
UTF-16 encoding (from Wikipedia):
U+0000 to U+D7FF uses 2-byte 0000hex to D7FFhex
U+D800 to U+DFFF are invalid codepoints reserved for 4-byte UTF-16
U+E000 to U+FFFF uses 2-byte E000hex to FFFFhex

U+10000 to U+10FFFF uses 4-byte UTF-16 encoded as follows:

Subtract 10000hex from the codepoint.
Express result as 20-bit binary.
Use the pattern 110110xxxxxxxxxx 110111xxxxxxxxxxbin to encode the upper- and lower- 10 bits into two 16-bit words.
]]

local TWO_BYTE_MIN		= 0x0000
local TWO_BYTE_MAX		= 0xFFFF
local FOUR_BYTE_MIN		= 0x10000
local FOUR_BYTE_MAX		= 0x10FFFF

local FOUR_BYTE_SHIFT	= 0x10000

-- Used as a mask to manage breaking up bytes
local ONE_BYTE_MASK		= 0x00FF
local UPPER_MASK		= 0xD800
local LOWER_MASK		= 0xDC00
local TEN_BIT_MASK		= 0x03FF

-- toBytes(number[, count[, bigEndian]])
-- Function
-- Returns the integer as a series of bytes.
local function toBytes(number, count, bigEndian)
	local byte = number & ONE_BYTE_MASK
	count = count or 8 -- 8 bytes in a 64-bit integer
	if count > 1 then
		if bigEndian then
			return toBytes(number >> 8, count-1, bigEndian), byte
		else
			return byte, toBytes(number >> 8, count-1, bigEndian)
		end
	else
		return byte
	end
end

--- cp.utf16.le.char([bigEndian, ]...) -> string
--- Function
--- Receives zero or more integers, converts each one to its corresponding UTF-16 byte sequence and returns a string with the concatenation of all these sequences.
---
--- Parameters:
---  * `bigEndian`	- If `true`, the output will list the 'big' bytes first. Defaults to `false`.
---  * `...`		- The list of UCL codepoint integers to convert.
---
--- Returns:
---  * All the codepoints converted to UTF-16, concatonated into a string.
local function char(bigEndian, ...)
	if type(bigEndian) == "number" then
		return char(false, bigEndian, ...)
	end
	
	local result = ""
	for n=1,select('#',...) do
	  local cp = select(n,...)
	  
	  if cp < TWO_BYTE_MIN or cp > FOUR_BYTE_MAX then
		  error(string.format("bad argument #%s to 'char' (value out of range)", n))
	  end
	  
	  if cp & UPPER_MASK == UPPER_MASK or cp & LOWER_MASK == LOWER_MASK then
		  error(string.format("bad argument #%s to 'char' (reserved value)", n))
	  end
	  
	  if cp < FOUR_BYTE_MIN then -- 2-byte character
		  result = result .. schar(toBytes(cp, 2, bigEndian))
	  else -- 4-byte character
		  local shifted = cp - FOUR_BYTE_SHIFT
		  local lower = (shifted & TEN_BIT_MASK) + LOWER_MASK
		  local upper = ((shifted >> 10) & TEN_BIT_MASK) + UPPER_MASK
		  result = result .. schar(toBytes(upper, 2, bigEndian)) .. schar(toBytes(lower, 2, bigEndian))
	  end
	end
	return result
end

-- read2Bytes(bigEndian, s, i) -> number
-- Function
-- Reads two bytes from `s`, starting at position `i`, with either 'big-endian' or 'little-endian' encoding.
--
-- Parameters:
--  * `bigEndian`	- If `true`, the string is encoded in 'big-endian' format.
--  * `s`			- The string to read from.
--  * `i`			- The index to start reading from.
--
-- Returns:
--  * The integer read by combining two bytes, in the order specified.
local function read2Bytes(bigEndian, s, i)
	local first, second = s:byte(i), s:byte(i+1)
	return bigEndian and (first << 8) + second or first + (second << 8)
end

-- fromBytes([bigEndian, ]s, i) -> number, number
-- Function
-- Returns a single 'codepoint' integer value, reading from the string, starting at position `i`.
-- Because UTF-16 can be stored in 'big-endian` or `little-endian` format, the
--
-- Parameters:
--  * `bigEndian`	- If `true`, the string is encoded in 'big-endian' format.
--  * `s`			- The string containing the text.
--  * `i`			- The index to start reading from.
--
-- Returns:
--  * `codepoint`	- The codepoint integer value.
--  * `length`		- The number of bytes used by the codepoint.
local function fromBytes(bigEndian, s, i)
	local length = 2
	local result = read2Bytes(bigEndian, s, i)
	if result & UPPER_MASK == UPPER_MASK then -- it's a 4-byte codepoint
		local second = read2Bytes(bigEndian, s, i+2)
		if second & LOWER_MASK ~= LOWER_MASK then
			error "invalid UTF-16 code"
		end
		result = ((result - UPPER_MASK) << 10) + (second - LOWER_MASK) + FOUR_BYTE_SHIFT
		length = 4
	elseif result & LOWER_MASK == LOWER_MASK then -- it's invalid - it can't come first.
		error "invalid UTF-16 code"
	end
	return result, length
end

local function codepoint(bigEndian, s, i, j)
	if type(bigEndian) == "string" then
		return codepoint(false, bigEndian, s, i)
	end
	assert(s ~= nil, "bad argument #2 to 'codepoint' (string expected, got nil)")
	
	local count = #s
	
	i = i and (i < 0 and count+i+1) or i or 1
	assert(i >= 1 or i <= count, "bad argument #3 to 'codepoint' (out of range)")
	
	j = j and (j < 0 and count+j+1) or j or i
	assert(j >= 1 or j <= count, "bad argument #4 to 'codepoint' (out of range)")
	
	local cp, length = fromBytes(bigEndian, s, i)
	if i + length <= j then
		return cp, codepoint(bigEndian, s, i+length, j)
	else
		return cp
	end
end

return {
	_toBytes	= toBytes,
	char		= char,
	codepoint	= codepoint,
	_fromBytes	= fromBytes,
	_read2Bytes	= read2Bytes,
}