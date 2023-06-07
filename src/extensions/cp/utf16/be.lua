--- === cp.utf16.be ===
---
--- A pure-LUA implementation of UTF-16 decoding with big-endian ordering.

local require = require
local utf16				= require("cp.utf16")

local utf16char, utf16codepoint, utf16codes, utf16len, utf16offset = utf16.char, utf16.codepoint, utf16.codes, utf16.len, utf16.offset

--- cp.utf16.be.char(...) -> string
--- Function
--- Receives zero or more integers, converts each one to its corresponding UTF-16 byte sequence and returns a string with the concatenation of all these sequences.
---
--- Parameters:
---  * `...`		- The list of UCL codepoint integers to convert.
---
--- Returns:
---  * All the codepoints converted to UTF-16, concatonated into a string.
local function char(...) return utf16char(true, ...) end

--- cp.utf16.be.codepoint(s [, i [, j]]) -> integer...
--- Function
--- Returns the codepoints (as integers) from all characters in `s` that start between byte position `i` and `j` (both included). The default for `i` is 1 and for `j` is `i`. It raises an error if it meets any invalid byte sequence.
---
--- Parameters:
---  * `s`				- The string
---  * `i`				- The starting index. Defaults to `1`.
---  * `j`				- The ending index. Defaults to `i`.
---
--- Returns:
---  * a list of codepoint integers for all characters in the matching range.
local function codepoint(s, i, j) return utf16codepoint(true, s, i, j) end

--- cp.utf16.be.codes(s) -> iterator
--- Function
--- Returns values so that the construction
---
--- Parameters:
---  * `s`				- The string to iterate through.
---
--- Returns:
---  * An iterator
---
--- Notes:
---  * For example:
---
--- ```lua
---      for p, c in utf16.codes(s) do body end
--- ```
---
--- will iterate over all characters in string `s`, with `p` being the position (in bytes) and `c` the code point of each character. It raises an error if it meets any invalid byte sequence.

local function codes(s) return utf16codes(true, s) end

--- cp.utf16.be.len (s [, i [, j]]) -> number | boolean, number
--- Function
--- Returns the number of UTF-16 characters in string `s` that start between positions `i` and `j` (both inclusive). The default for `i` is 1 and for `j` is -1. If it finds any invalid byte sequence, returns a false value plus the position of the first invalid byte.
---
--- Parameters:
---  * `s`				- The UTF-16 string
---  * `i`				- The starting index. Defaults to `1`.
---  * `j`				- The ending index. Defaults to `-1`.
---
--- Returns:
---  * the length, or `false` and the first invalid byte index.
local function len(s, i, j) return utf16len(true, s, i, j) end

--- cp.utf16.be.offset (s, n [, i]) -> number
--- Function
--- Returns the position (in bytes) where the encoding of the `n`-th character of `s` (counting from position `i`) starts. A negative `n` gets characters before position `i`. The default for `i` is 1 when `n` is non-negative and `#s + 1` otherwise, so that `utf8.offset(s, -n)` gets the offset of the `n`-th character from the end of the string. If the specified character is neither in the subject nor right after its end, the function returns nil.
---
--- Parameters:
---  * `s`				- The string
---  * `n`				- The character number to find.
---  * `i`				- The initial position to start from.
---
--- Returns:
---  * The index
---
--- Notes:
---  * As a special case, when `n` is 0 the function returns the start of the encoding of the character that contains the `i`-th byte of `s`.
---  * This function assumes that `s` is a valid UTF-16 string
local function offset(s, n, i) return utf16offset(true, s, n, i) end

return {
    char		= char,
    codepoint	= codepoint,
    codes		= codes,
    len			= len,
    offset		= offset,
}
