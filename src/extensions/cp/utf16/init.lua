--- === cp.utf16 ===
---
--- A pure-LUA implementation of UTF-16 decoding
-- local log				= require("hs.logger").new("utf16")

local schar = string.char

local TWO_BYTE_MIN		= 0x0000
-- local TWO_BYTE_MAX		= 0xFFFF
local FOUR_BYTE_MIN		= 0x10000
local FOUR_BYTE_MAX		= 0x10FFFF

local FOUR_BYTE_SHIFT	= 0x10000

-- Used as a mask to manage breaking up bytes
local ONE_BYTE_MASK		= 0x00FF
local UPPER_MASK		= 0xD800
local LOWER_MASK		= 0xDC00
local TEN_BIT_MASK		= 0x03FF

local UPPER_MAX			= UPPER_MASK + TEN_BIT_MASK
local LOWER_MAX			= LOWER_MASK + TEN_BIT_MASK

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

--- cp.utf16.char(bigEndian, ...) -> string
--- Function
--- Receives zero or more integers, converts each one to its corresponding UTF-16 byte sequence and returns a string with the concatenation of all these sequences.
---
--- Parameters:
---  * `bigEndian`	- If `true`, the output will list the 'big' bytes first
---  * `...`		- The list of UCL codepoint integers to convert.
---
--- Returns:
---  * All the codepoints converted to UTF-16, concatonated into a string.
local function char(bigEndian, ...)
    local result = ""
    for n=1,select('#',...) do
      local cp = select(n,...)

      if cp < TWO_BYTE_MIN or cp > FOUR_BYTE_MAX then
          error(string.format("bad argument #%s to 'char' (value out of range)", n))
      end

      if cp >= UPPER_MASK and cp <= LOWER_MAX then
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
    if result >= UPPER_MASK and result <= UPPER_MAX then -- it's a 4-byte codepoint
        local second = read2Bytes(bigEndian, s, i+2)
        if second < LOWER_MASK or second > LOWER_MAX then
            error(string.format("invalid UTF-16 code at byte %s: 0x%04X", i+2, second))
        end
        result = ((result - UPPER_MASK) << 10) + (second - LOWER_MASK) + FOUR_BYTE_SHIFT
        length = 4
    elseif result >= LOWER_MASK and result <= LOWER_MAX then -- it's invalid - it can't come first.
        error(string.format("initial position is a continuation byte: 0x%04X", i, result))
    end
    return result, length
end

--- cp.utf16.codepoint(bigEndian, s [, i [, j]]) -> integer...
--- Function
--- Returns the codepoints (as integers) from all characters in `s` that start between byte position `i` and `j` (both included). The default for `i` is 1 and for `j` is `i`. It raises an error if it meets any invalid byte sequence.
---
--- Parameters:
---  * `bigEndian`		- (optional) If set to `true`, the string is encoded in 'big-endian' format.
---  * `s`				- The string
---  * `i`				- The starting index. Defaults to `1`.
---  * `j`				- The ending index. Defaults to `i`.
---
--- Returns:
---  * a list of codepoint integers for all characters in the matching range.
local function codepoint(bigEndian, s, i, j)
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

--- cp.utf16.codes(bigEndian, s) -> iterator
--- Function
--- Returns values so that the construction
---
--- ```lua
---      for p, c in utf16.codes(s) do body end
--- ```
---
--- will iterate over all characters in string `s`, with `p` being the position (in bytes) and `c` the code point of each character. It raises an error if it meets any invalid byte sequence.
---
--- Parameters:
---  * `bigEndian`		- If `true`, the provided string is in 'big-endian' encoding.
---  * `s`				- The string to iterate through.
---
--- Returns:
---  * An iterator
local function codes(bigEndian, s)
    local count = s:len()
    local pos, code, length = 1, nil, 0

    return function()
        pos = pos + length
        if pos > count then
            return nil
        else
            code, length = fromBytes(bigEndian, s, pos)
            return pos, code
        end
    end
end

--- cp.utf16.len (bigEndian, s [, i [, j]]) -> number | boolean, number
--- Function
--- Returns the number of UTF-16 characters in string `s` that start between positions `i` and `j` (both inclusive). The default for `i` is 1 and for `j` is -1. If it finds any invalid byte sequence, returns a false value plus the position of the first invalid byte.
---
--- Parameters:
---  * `bigEndian`		- If true, the string is 'big-endian'.
---  * `s`				- The UTF-16 string
---  * `i`				- The starting index. Defaults to `1`.
---  * `j`				- The ending index. Defaults to `-1`.
---
--- Returns:
---  * the length, or `false` and the first invalid byte index.
local function len(bigEndian, s, i, j)
    i = i or 1
    j = j or -1
    if j < 0 then
        j = #s + j
    end
    local length = 0
    local bytes
    local k, size = i
    while k <= j do
        bytes = read2Bytes(bigEndian, s, k)
        if bytes >= UPPER_MASK and bytes <= UPPER_MAX then
            bytes = read2Bytes(bigEndian, s, k+2)
            if bytes < LOWER_MASK or bytes > LOWER_MAX then -- invalid bytes
                return false, k+2
            end
            size = 4
        elseif bytes >= LOWER_MASK and bytes <= LOWER_MAX then
            return false, k
        else
            size = 2
        end
        length = length + 1
        k = k + size
    end

    return length
end

--- cp.utf16.offset (bigEndian, s, n [, i]) -> number
--- Function
--- Returns the position (in bytes) where the encoding of the `n`-th character of `s` (counting from position `i`) starts. A negative `n` gets characters before position `i`. The default for `i` is 1 when `n` is non-negative and `#s + 1` otherwise, so that `utf8.offset(s, -n)` gets the offset of the `n`-th character from the end of the string. If the specified character is neither in the subject nor right after its end, the function returns nil.
---
--- As a special case, when `n` is 0 the function returns the start of the encoding of the character that contains the `i`-th byte of `s`.
---
--- This function assumes that `s` is a valid UTF-16 string
---
--- Parameters:
---  * `bigEndian`		- If `true`, the encoding is 'big-endian'. Defaults to `false`
---  * `s`				- The string
---  * `n`				- The character number to find.
---  * `i`				- The initial position to start from.
---
--- Returns:
---  * The index
local function offset(bigEndian, s, n, i)
    if not s then
        error("bad argument #2 to 'offset' (string expected, got nil)")
    end
    local count = #s
    local shift = n < 0 and -1 or 1

    -- shift i to the end of the string, or the beginning, if no value is provided.
    i = i or (n < 0 and count+1 or 1)
    i = i < 0 and count+1+i or i
    if i < 1 or i > count+1 then
        error(string.format("bad argument #4 to 'offset' (position out of range): %s", i))
    end

    if n == 0 then -- find the start of the char at i
        -- round down to nearest odd number
        if i % 2 == 0 then i = i-1 end
        local bytes = read2Bytes(bigEndian, s, i)
        if bytes >= LOWER_MASK and bytes <= LOWER_MAX then
            return i-2
        else
            return i
        end
    else -- find the nth character, starting from i
        if i > count then
            error(string.format("bad argument #4 to 'offset' (position out of range): %s", i))
        elseif i % 2 == 0 then
            error("initial position #%s is a continuation byte", i)
        end
        local bytes = read2Bytes(bigEndian, s, i)
        if bytes >= LOWER_MASK and bytes <= LOWER_MAX then
            error("initial position #%s is a continuation byte: 0x%04X", i, bytes)
        end

        local nx = 1
        while i < count and nx ~= n do
            bytes = read2Bytes(bigEndian, s, i)
            if bytes >= UPPER_MASK and bytes <= UPPER_MAX then
                bytes = read2Bytes(bigEndian, s, i+2)
                if bytes < LOWER_MASK or bytes > LOWER_MAX then
                    error("position #%s should be a continuation byte: 0x%04X", i, bytes)
                end
                i = i + 4
            else
                i = i + 2
            end
            nx = nx + shift
        end
        if nx == n then
            return i
        else
            error("the string is not valid UTF-16 text")
        end
    end
end

-- Adds support for calling `require("cp.utf16").le` directly, rather than `require("cp.utf16.le")`
local function __index(t,k)
    local value = rawget(t,k)
    if not value and (k == "be" or k == "le") then
        value = require("cp.utf16."..k)
        t[k] = value
    end
    return value
end

return setmetatable(
    {
        _toBytes	= toBytes,
        _fromBytes	= fromBytes,
        _read2Bytes	= read2Bytes,
        char		= char,
        codepoint	= codepoint,
        codes		= codes,
        len			= len,
        offset		= offset,
    },
    {__index		= __index}
)