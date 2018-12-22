--- === cp.text ===
---
--- This module provides support for loading, manipulating, and comparing unicode text data.
--- It works by storing characters with their Unicode 'codepoint` value. In practice, this means that every character is a 64-bit integer, so a `text` value will use substantially more memory than the equivalent encoded `string` value.
---
--- The advantages of `text` over `string` representations for Unicode are:
---  * comparisons, equality checks, etc. actually work for Unicode text and are not encoding-dependent.
---  * direct access to codepoint values.
---
--- The advantages of `string` representations for Unicode are:
---  * compactness.
---  * reading/writing to files via the standard `io` library.
---
--- ## Strings and Unicode
---
--- LUA has limited built-in support for Unicode text. `string` values are "8-bit clean", which means it is an array of 8-bit characters. This is also how binary data from files is usually loaded, as 8-bit 'bytes'. Unicode characters can be up to 32-bits, so there are several standard ways to represent Unicode characters using 8-bit characters. Without going into detail, the most common encodings are called 'UTF-8' and 'UTF-16'. There are two variations of 'UTF-16', depending on the hardware architecture, known as 'big-endian' and 'little-endian'.
---
--- The built-in functions for `string`, such as `match`, `gsub` and even `len` will not work as expected when a string contains Unicode text. As such, this library fills some of the gaps for common operations when working with Unicode text.
---
--- ## Examples
---
--- You can convert to and from `string` and `text` values like so:
---
--- ```lua
--- local text = require("cp.text")
---
--- local simpleString		= "foobar"
--- local simpleText		= text(stringValue)
--- local utf8String		= "a丽𐐷"				-- contains non-ascii characters, defaults to UTF-8.
--- local unicodeText		= text "a丽𐐷"			-- contains non-ascii characters, converts from a UTF-8 string.
--- local utf8String		= tostring(unicodeText) -- `tostring` will default to UTF-8 encoding
--- local utf16leString		= unicodeText:encode(text.encoding.utf16le) -- or you can be more specific
--- ```
---
--- Note that `text` values are not in any specific encoding, since they are stored as 64-bit integer `code-points` rather than 8-bit characers.

--- === cp.text.matcher ===
---
--- This module provides support for loading, manipulating, and comparing unicode text data.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log					= require("hs.logger").new("text")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local utf16LE							= require("cp.utf16.le")
local utf16BE							= require("cp.utf16.be")
local protect							= require("cp.protect")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local utf8char, utf8codepoint 			= utf8.char, utf8.codepoint
local utf16LEchar, utf16LEcodepoint 	= utf16LE.char, utf16LE.codepoint
local utf16BEchar, utf16BEcodepoint 	= utf16BE.char, utf16BE.codepoint
local unpack, pack						= table.unpack, table.pack
local floor								= math.floor

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local text = {}

text.mt = {}
text.mt.__index = text.mt

-- Loads the 'cp.text.matcher' module on demand, to avoid a dependency loop.
local matcher
matcher = function(...)
    matcher = require("cp.text.matcher")
    return matcher(...)
end

--- cp.text.encoding
--- Constant
--- The list of supported encoding formats:
---  * `utf8`		- UTF-8. The most common format on the web, backwards compatible with ANSI/ASCII.
---  * `utf16le`	- UTF-16 (little-endian). Commonly used in Windows and Mac text files.
---  * `utf16be`	- UTF-16 (big-endian). Alternate 16-bit format, common on Linux and PowerPC-based architectures.
text.encoding = protect {
    utf8	= "utf8",
    utf16le	= "utf16le",
    utf16be	= "utf16be",
}

local decoders = {
    utf8	= utf8codepoint,
    utf16le	= utf16LEcodepoint,
    utf16be	= utf16BEcodepoint,
}

local encoders = {
    utf8	= utf8char,
    utf16le	= utf16LEchar,
    utf16be	= utf16BEchar,
}

local BOM = 0xFEFF
local boms = {
    utf8	= string.char(239, 187, 191),
    utf16le	= string.char(255, 254),
    utf16be = string.char(254, 255),
}

local function startsWith(self, otherString)
    local len = otherString:len()

    if self:len() >= len then
        for i = 1,len do
            if self:byte(i) ~= otherString:byte(i) then return false end
        end
        return true
    end
    return false
end

local function isint(n)
  return n==floor(n)
end

local function constrain(value, min, max)
    if value < min then return min end
    if value > max then return max end
    return value
end

local codesKey = "codes"
-- gets the 'codes' value for a text value
local function getCodes(txt)
    return rawget(txt, codesKey)
end

-- sets the 'codes' value for a text value.
local function setCodes(txt, value)
    rawset(txt, codesKey, value)
end

--- cp.text.fromString(value[, encoding]) -> text
--- Constructor
--- Returns a new `text` instance representing the string value of the specified value. If no encoding is specified,
--- it will attempt to determine the encoding from a leading Byte-Order Marker (BOM). If none is present, it defaults to UTF-8.
---
--- Parameters:
---  * `value`		- The value to turn into a unicode text instance.
---  * `encoding`	- One of the falues from `text.encoding`: `utf8`, `utf16le`, or `utf16be`. Defaults to `utf8`.
---
--- Returns:
---  * A new `text` instance.
---
--- Notes:
---  * Calling `text(value)` is the same as calling `text.fromString(value, text.encoding.utf8)`, so simple text can be initialized via `local x = text "foo"` when the `.lua` file's encoding is UTF-8.
function text.fromString(value, encoding)
    local start = 1
    value = tostring(value)
    if not encoding then
        -- first, check if there are any BOMs
        for enc,bom in pairs(boms) do
            if startsWith(value, bom) then
                encoding = enc
                start = start + bom:len()
                break
            end
        end
        encoding = encoding or text.encoding.utf8
    end

    local decoder = decoders[encoding]
    if not decoder then
        error(string.format("unsupported encoding: %s", encoding))
    end
    return text.fromCodepoints({decoder(value, start, -1)})
end

--- cp.text.fromCodepoints(codepoints[, i[, j]]) -> text
--- Constructor
--- Returns a new `text` instance representing the specified array of codepoints. Since `i` and `j` default to the first
--- and last indexes of the array, simply passing in the array will convert all codepoints in that array.
---
--- Parameters:
---  * `codepoints`	- The array of codepoint integers.
---  * `i`			- The starting index to read from codepoints. Defaults to `1`.
---  * `j`			- The ending index to read from codepoints. Default to `-1`.
---
--- Returns:
---  * A new `text` instance.
---
--- Notes:
---  * You can use a *negative* value for `i` and `j`. If so, it will count back from then end of the `codepoints` array.
---  * If the codepoint array begins with a Byte-Order Marker (BOM), the BOM is skipped in the resulting text.
function text.fromCodepoints(codepoints, i, j)
    local result = {}
    local len = #codepoints

    if len > 0 then
        i = i or 1
        j = j or -1
        if type(i) ~= "number" then
            error("bad argument #2 (integer expected, got "..type(i)..")")
        end
        if type(j) ~= "number" then
            error("bad argument #3 (integer expected, got "..type(i)..")")
        end
        if not isint(i) then
            error(string.format("bad argument #2 (number has no integer representation: %s)", i))
        end
        if not isint(j) then
            error(string.format("bad argument #3 (number has no integer representation: %s)", j))
        end

        if i < 0 then i = len + 1 + i end
        if j < 0 then j = len + 1 + j end

        i = constrain(i, 1, len+1)
        j = constrain(j, 0, len)

        if codepoints[i] == BOM then
            i = i+1
        end

        for x = i,j do
            local cp = codepoints[x]
            if type(cp) ~= "number" then
                error("bad argument #1 for 'fromCodepoints (integer expected, got "..type(cp).." for codepoint #"..x..")")
            end
            result[x-i+1] = cp
        end
    end

    local o = {}
    setmetatable(o, text.mt)
    setCodes(o, result)
    return o
end

--- cp.text.fromFile(path[, encoding]) -> text
--- Constructor
--- Returns a new `text` instance representing the text loaded from the specified path. If no encoding is specified,
--- it will attempt to determine the encoding from a leading Byte-Order Marker (BOM). If none is present, it defaults to UTF-8.
---
--- Parameters:
---  * `value`		- The value to turn into a unicode text instance.
---  * `encoding`	- One of the falues from `text.encoding`: `utf8`, `utf16le`, or `utf16be`. Defaults to `utf8`.
---
--- Returns:
---  * A new `text` instance.
function text.fromFile(path, encoding)
    local file = io.open(path, "r") 		-- r read mode
    if not file then
        error(string.format("Unable to open '%s'", path))
    end
    local content = file:read "*a" 					-- *a or *all reads the whole file
    file:close()

    return text.fromString(content, encoding)
end

--- cp.text.char(...) -> text
--- Constructor
--- Returns the list of one or more codepoint items into a text value, concatenating the results.
---
--- Parameters:
---  * `...`	- The list of codepoint integers.
---
--- Returns:
---  * The `cp.text` value for the list of codepoint values.
function text.char(...)
    return text.fromCodepoints(pack(...))
end

--- cp.text.is(value) -> boolean
--- Function
--- Checks if the provided value is a `text` instance.
---
--- Parameters:
---  * `value`	- The value to check
---
--- Returns:
---  * `true` if the value is a `text` instance.
function text.is(value)
    return value and getmetatable(value) == text.mt
end

--- cp.text:sub(i [, j]) -> cp.text
--- Method
--- Returns the substring of this text that starts at `i` and continues until `j`; `i` and `j` can be negative.
--- If `j` is absent, then it is assumed to be equal to `-1` (which is the same as the string length).
--- In particular, the call `cp.text:sub(1,j)` returns a prefix of `s` with length `j`, and `cp.text:sub(-i)` (for a positive `i`) returns a suffix of s with length i.
function text.mt:sub(i, j)
    j = j or -1
    return text.fromCodepoints(getCodes(self), i, j)
end

--- cp.text:find(pattern [, init [, plain]])
--- Method
--- Looks for the first match of pattern in the string `value`. If it finds a match, then find returns the indices of `value` where this occurrence starts and ends; otherwise, it returns `nil`. A third, optional numerical argument `init` specifies where to start the search; its default value is `1` and can be negative. A value of `true` as a fourth, optional argument plain turns off the pattern matching facilities, so the function does a plain "find substring" operation, with no characters in pattern being considered "magic". Note that if plain is given, then `init` must be given as well.
---
--- If the pattern has captures, then in a successful match the captured values are also returned, after the two indices.
---
--- Preferences:
---  * `pattern`		- The pattern to find.
---  * `init`			- The index to start matching from. Defaults to `1`.
---  * `plain`			- If `true`, the pattern is treated as plain text.
---
--- Returns:
---  * the start index, the end index, followed by any captures
function text.mt:find(pattern, init, plain)
    return matcher(pattern):find(self, init, plain)
end

--- cp.text:match(pattern[, start]) -> ...
--- Method
--- Looks for the first match of the `pattern` in the text value. If it finds one, then match returns the captures from the pattern; otherwise it returns `nil`. If pattern specifies no captures, then the whole match is returned. A third, optional numerical argument `init` specifies where to start the search; its default value is `1` and can be negative.
---
--- Parameters:
---  * `pattern`	- The text pattern to process.
---  * `start`		- If specified, indicates the starting position to process from. Defaults to `1`.
---
--- Returns:
---  * The capture results, the whole match, or `nil`.
function text.mt:match(pattern, start)
    return matcher(pattern):match(self, start)
end

--- cp.text.matcher:gmatch(pattern[, start]) -> function
--- Method
--- Returns an iterator function that, each time it is called, returns the next captures from pattern over string s. If pattern specifies no captures, then the whole match is produced in each call.
---
--- Parameters:
---  * `pattern`		- The `cp.text` value to process.
---
--- Returns:
---  * The iterator function.
function text.mt:gmatch(pattern, all)
    return matcher(pattern):gmatch(self, all)
end

--- cp.text.matcher:gsub(value, repl, limit) -> text, number
--- Method
--- Returns a copy of `value` in which all (or the first `n`, if given) occurrences of the pattern have been replaced by a replacement string specified by `repl`, which can be text, a string, a table, or a function. gsub also returns, as its second value, the total number of matches that occurred.
---
--- Parameters:
---  * `value`	- The text or string value to process.
---  * `repl`	- The replacement text/string/table/function
---  * `limit`	- The maximum number of times to do the replacement. Defaults to unlimited.
---
--- Returns:
---  * `text`	- The text value with replacements.
---  * `number`	- The number of matches that occurred.
---
--- Notes:
---  * If repl is text or a string, then its value is used for replacement. The character `%` works as an escape character: any sequence in repl of the form `%n`, with `n` between `1` and `9`, stands for the value of the `n`-th captured substring (see below). The sequence `%0` stands for the whole match. The sequence `%%` stands for a single `%`.
---  * If `repl` is a table, then the table is queried for every match, using the first capture as the key; if the pattern specifies no captures, then the whole match is used as the key.
---  * If `repl` is a function, then this function is called every time a match occurs, with all captured substrings passed as arguments, in order; if the pattern specifies no captures, then the whole match is passed as a sole argument.
---  * If the value returned by the table query or by the function call is a string or a number, then it is used as the replacement string; otherwise, if it is `false` or `nil`, then there is no replacement (that is, the original match is kept in the string).
function text.mt:gsub(pattern, repl, limit)
    return matcher(pattern):gsub(self, repl, limit)
end

-- provides access to the internal codes array
function text.mt:__index(key)
    if type(key) == "number" then
        local codes = getCodes(self)
        return codes[key]
    elseif key ~= codesKey then
        return rawget(text.mt, key)
    end
    return nil
end

-- prevents codes getting updated directly.
function text.mt.__newindex(_, _)
    error("read-only text value", 2)
end

function text.mt:__len()
    local codes = getCodes(self)
    return #codes
end

--- cp.text:len() -> number
--- Method
--- Returns the number of codepoints in the text.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The number of codepoints.
text.mt.len = text.mt.__len

-- concatenates the left and right values into a single text value.
function text.mt.__concat(left, right)
    return text.fromString(tostring(left) .. tostring(right), text.encoding.utf8)
end

--- cp.text:encode([encoding]) -> string
--- Method
--- Returns the text as an encoded `string` value.
---
--- Parameters:
---  * `encoding`	- The encoding to use when converting. Defaults to `cp.text.encoding.utf8`.
--
-- Returns:
--  * The `string` version of the `cp.text` value with the specified encoding..
function text.mt:encode(encoding)
    encoding = encoding or text.encoding.utf8
    local encoder = encoders[encoding]
    if not encoder then
        error(string.format("Unsupported encoding: %s", encoding))
    end
    return encoder(unpack(self))
end

-- cp.text:__tostring() -> string
-- Method
-- Returns the text as an `string` value encoded as UTF-8.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The `string` version of the `cp.text` value.
function text.mt:__tostring()
    return self:encode(text.encoding.utf8)
end

-- cp.text:__eq(other) -> boolean
-- Method
-- Checks if `other` is a `cp.text` instance, and if so, all codepoints are present in the same order.
--
-- Parameters:
--  * `other`	- The other value to compare to.
--
-- Returns:
--  * `true` if `other` is a `cp.text` and all codepoints are present in the same order.
function text.mt:__eq(other)
    if text.is(other) then
        local localCodes, otherCodes = getCodes(self), getCodes(other)
        local len = #localCodes
        if len == #otherCodes then
            for i = 1,len do
                if localCodes[i] ~= otherCodes[i] then
                    return false
                end
            end
            return true
        end
    end
    return false
end

function text.__call(_, ...)
    return text.fromString(..., text.encoding.utf8)
end

return setmetatable(text, text)
