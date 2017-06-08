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

-- asBytes(number[, count[, bigEndian]])
-- Function
-- Returns the integer as a series of bytes.
local function asBytes(number, count, bigEndian)
	local byte = number & ONE_BYTE_MASK
	count = count or 8 -- 8 bytes in a 64-bit integer
	if count > 1 then
		if bigEndian then
			return asBytes(number >> 8, count-1, bigEndian), byte
		else
			return byte, asBytes(number >> 8, count-1, bigEndian)
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
		  result = result .. schar(asBytes(cp, 2, bigEndian))
	  else -- 4-byte character
		  local shifted = cp - FOUR_BYTE_SHIFT
		  local lower = (shifted & TEN_BIT_MASK) + LOWER_MASK
		  local upper = ((shifted >> 10) & TEN_BIT_MASK) + UPPER_MASK
		  result = result .. schar(asBytes(upper, 2, bigEndian)) .. schar(asBytes(lower, 2, bigEndian))
	  end
	end
	return result
end

return {
	asBytes		= asBytes,
	char		= char,
}