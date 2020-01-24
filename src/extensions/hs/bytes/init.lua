--- === hs.bytes ===
---
--- A library for reading and writing byte streams.
---
--- Because it has no native 8-bit byte type, Lua uses `string` values to store binary data. Each character is a single byte.
--- However, `string` values are immutible, and every time you concatonate or subtract values, it creates a new copy in memory.
--- This library helps creating and reading byte streams as efficiently as possible.
---
--- ## Reading
---
--- To read a byte string, simply create the `bytes` instance from the source `string`, then use the [read](#read) method to retrieve values.
---
--- For example:
---

-- TODO: Review this example, and make sure it actually works:

--- ```lua
--- local bytes = require "hs.bytes"
--- local data = [[\0\1\2\3\4\5]]
--- local a, b, c, d = bytes.read(data, bytes.int8, bytes.int16be, bytes.int8, bytes.int16le)
--- print(string.format("a: %02X; b: %04X; c: %%02X, d: %04X)) -- a: 00; b: 0102; c: 03; d: 0504
--- ```

--local log           = require "hs.logger".new("bytes")

local concat        = table.concat
local char          = string.char
local byte          = string.byte
local format        = string.format

local bytes = {}

bytes.mt = {}
bytes.mt.__index = bytes.mt

--- hs.bytes([ otherBytes | ... ]) -> hs.bytes
--- Constructor
--- Creates a new `bytes` instance, with either a
---
--- Parameters:
---  * otherBytes  - (optional) either a `string` with the bytes, or a `hs.bytes` instance.
---
--- Returns:
---  * The new `hs.bytes` instance.
function bytes.new(...)
    -- internally, `data` is a list of string values.
    local data = {}
    local o = {
        _data = data,
    }

    setmetatable(o, bytes.mt)

    return o:write(...)
end

--- hs.bytes.is(thing) -> boolean
--- Function
--- Checks if the `thing` is an instance of `hs.bytes`.
---
--- Parameters:
---  * thing     - the thing to check.
---
--- Returns:
---  * `true` if the thing is an instance of `hs.bytes`.
function bytes.is(thing)
    return type(thing) == "table" and getmetatable(thing) == bytes.mt
end

--- hs.bytes:write(...) -> hs.bytes
--- Method
--- Appends the provided `string` values to the end of the byte string, in the order they are provided.
---
--- Parameters:
---  * ...   - the list of `string` values to append.
---
--- Returns:
---  * the same `hs.bytes` instance, for additional writes/etc.
---
--- Notes:
---  * This function works well with the type-conversion functions in `hs.bytes`, such as [int8](#int8), [int32be](#int32be), etc.
---  * For example:
---    * ```lua
---      local result = hs.bytes():write(hs.bytes.int8(1), hs.bytes.int16be(2), hs.bytes.int32le(3)) -- result: 01 00 02 03 00 00 00
---      print(hs.utf8.hexDump(result:bytes()))
---      ```
function bytes.mt:write(...)
    local arguments = {...}
    if #arguments < 1 then
        return self
    end

    self._cache = nil

    local data = self._data
    local len = #data

    for i=1,#arguments do
        local v = arguments[i]
        if bytes.is(v) then
            v = v:bytes()
        end
        if type(v) == "string" then
            data[len+i] = v
        else
            error(format("invalid data type at #%d: %s", i, type(v), 2))
        end
    end
    return self
end

-- doRead(data, index, ...) -> any, any, ...
-- Function
-- Reads the values from the `data` `string`, starting at the specified `index`, interpreting with the provided `function`s.
--
-- Parameters:
-- * data   - the data `string` to read from.
-- * index  - the index to start reading from.
-- * ...    - the list of one or more `function`s which will interpret the data.
local function doRead(data, index, fn, ...)
    if fn then
        local value, newIndex = fn(data, index)
        return value, doRead(data, newIndex, ...)
    end
end

--- bytes.read(data[, index], ...) -> any, any, ...
--- Function
--- Reads values from the `data` byte string, starting at the specified `index` (or `1` if not specified), then converted by the list of functions provided.
---
--- Parameters:
---  * data      - The byte string to read from.
---  * index     - optional `number` to indicate where to start reading from in the byte stream. Defaults to `1`.
---  * ...       - a list of one or more `function`s with the following signature: `function(data, index) -> any, number`. See Notes for details.
---
--- Returns:
---  * The list of values read, one from each of the `function`s provided in the parameter list.
---
--- Notes:
---  * This is designed to be passed in functions like [bytes.int8](#int8), [bytes.int32be](#int32be), etc.
---  * For example:
---   * ```lua
---     bytes.new("\1\2\3\4"):read(bytes.int8, bytes.int8, bytes.int16be) -- returns: `1`, `2`, `772`
---     ```
function bytes.read(data, index, ...)
    local iType = type(index)
    if iType == "number" then
        return doRead(data, index, ...)
    elseif iType == "function" then
        return doRead(data, 1, index, ...)
    else
        error(format("unsupported `index` type: %s", type(index)), 2)
    end
end

--- hs.bytes:read([index, ]...) -> any, any, ...
--- Method
--- Reads from the start of the byte string, working its way through each `function` provided and returning each result as an additional return value.
---
--- Parameters:
---  * index     - Optional `number` to indicate where to start reading from in the byte stream. Defaults to `1`.
---  * ...       - a list of one or more `function`s with the following signature: `function(data, index) -> any, number`. See Notes for details.
---
--- Returns:
---  * The list of values read, one from each of the `function`s provided in the parameter list.
---
--- Notes:
---  * This is designed to be passed in functions like [bytes.int8](#int8), [bytes.int32be](#int32be), etc.
---  * For example:
---   * ```lua
---     hs.bytes.new("\1\2\3\4"):read(hs.bytes.int8, hs.bytes.int8, hs.bytes.int16be) -- returns: `1`, `2`, `772`
---     ```
function bytes.mt:read(index, ...)
    return bytes.read(self:bytes(), index, ...)
end

--- hs.bytes:len() -> number
--- Method
--- Returns the length of the byte string.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The number of bytes in the byte string.
function bytes.mt:len()
    if self._cache then
        return #self._cache
    end
    local len = 0
    for _,v in ipairs(self._data) do
        len = len + v:len()
    end
    return len
end

--- hs.bytes:bytes() -> string
--- Method
--- Returns the byte collection as a single `string` containing all bytes.
---
--- Notes:
---  * This may be an expensive operation. Caching results is recommended if using more than once.
function bytes.mt:bytes()
    local data = self._data
    if data[2] then -- got more than one chunk. consolidate!
        data = {concat(data)}
        self._data = data
    end
    return data[1]
end

-- converts the contents to a byte string.
function bytes.mt:__tostring()
    return self:bytes()
end

-- readInt8(value, index) -> number, number
-- Function
-- Reads the the byte at the index as a number. No safety checks.
--
-- Paramters:
-- * value  - a `string` of bytes.
-- * index  - the point to start reading from
--
-- Returns:
-- * number - the actual number value
-- * number - the next index to read from.
local function readInt8(value, index)
    return value:byte(index), index+1
end

-- readInt16be(value, index) -> number, number
-- Function
-- Reads the the two bytes at the index as a 16-bit number, big-endian. No safety checks.
--
-- Paramters:
-- * value  - a `string` of bytes.
-- * index  - the point to start reading from
--
-- Returns:
-- * number - the actual number value
-- * number - the next index to read from.
local function readInt16be(value, index)
    local big, little
    big, index = readInt8(value, index)
    little, index = readInt8(value, index)
    return (big << 8) | little, index
end

-- readInt16le(value, index) -> number, number
-- Function
-- Reads the the two bytes at the index as a 16-bit number, little-endian. No safety checks.
--
-- Paramters:
-- * value  - a `string` of bytes.
-- * index  - the point to start reading from
--
-- Returns:
-- * number - the actual number value
-- * number - the next index to read from.
local function readInt16le(value, index)
    local big, little
    little, index = readInt8(value, index)
    big, index = readInt8(value, index)
    return (big << 8) | little, index
end

-- readInt24be(value, index) -> number, number
-- Function
-- Reads the the three bytes at the index as a 24-bit number, big-endian. No safety checks.
--
-- Paramters:
-- * value  - a `string` of bytes.
-- * index  - the point to start reading from
--
-- Returns:
-- * number - the actual number value
-- * number - the next index to read from.
local function readInt24be(value, index)
    local big, middle, little
    big, index = readInt8(value, index)
    middle, index = readInt8(value, index)
    little, index = readInt8(value, index)
    return (big << 16) | (middle << 8) | little, index
end

-- readInt24le(value, index) -> number, number
-- Function
-- Reads the the three bytes at the index as a 24-bit number, little-endian. No safety checks.
--
-- Paramters:
-- * value  - a `string` of bytes.
-- * index  - the point to start reading from
--
-- Returns:
-- * number - the actual number value
-- * number - the next index to read from.
local function readInt24le(value, index)
    local big, middle, little
    little, index = readInt8(value, index)
    middle, index = readInt8(value, index)
    big, index = readInt8(value, index)
    return (big << 16) | (middle << 8) | little, index
end

-- readInt32be(value, index) -> number, number
-- Function
-- Reads the the two bytes at the index as a 32-bit number, big-endian. No safety checks.
--
-- Paramters:
-- * value  - a `string` of bytes.
-- * index  - the point to start reading from
--
-- Returns:
-- * number - the actual number value
-- * number - the next index to read from.
local function readInt32be(value, index)
    local big, little
    big, index = readInt16be(value, index)
    little, index = readInt16be(value, index)
    return (big << 16) | little, index
end

-- readInt32le(value, index) -> number, number
-- Function
-- Reads the the two bytes at the index as a 32-bit number, little-endian. No safety checks.
--
-- Paramters:
-- * value  - a `string` of bytes.
-- * index  - the point to start reading from
--
-- Returns:
-- * number - the actual number value
-- * number - the next index to read from.
local function readInt32le(value, index)
    local big, little
    little, index = readInt16le(value, index)
    big, index = readInt16le(value, index)
    return (big << 16) | little, index
end

-- readInt64be(value, index) -> number, number
-- Function
-- Reads the the two bytes at the index as a 64-bit number, big-endian. No safety checks.
--
-- Paramters:
-- * value  - a `string` of bytes.
-- * index  - the point to start reading from
--
-- Returns:
-- * number - the actual number value
-- * number - the next index to read from.
local function readInt64be(value, index)
    local big, little
    big, index = readInt32be(value, index)
    little, index = readInt32be(value, index)
    return (big << 32) | little, index
end

-- readInt64le(value, index) -> number, number
-- Function
-- Reads the the two bytes at the index as a 64-bit number, little-endian. No safety checks.
--
-- Paramters:
-- * value  - a `string` of bytes.
-- * index  - the point to start reading from
--
-- Returns:
-- * number - the actual number value
-- * number - the next index to read from.
local function readInt64le(value, index)
    local big, little
    little, index = readInt32le(value, index)
    big, index = readInt32le(value, index)
    return (big << 32) | little, index
end

-- writeInt8(value) -> number
-- Function
-- Returns the lowest 8 bits of the value as a `number`.
--
-- Parameters:
-- * values - the `number` to write as an 8-bit int.
--
-- Returns:
-- * one 8-bit number provided, as a `number`.
local function writeInt8(value)
    return value & 0xFF
end

-- writeInt16be(value) -> number, number
-- Function
-- Returns the lowest 16 bits of the value as a two 8-bit `number`s, in big-endian order.
--
-- Parameters:
-- * values - the `number` to write as two 8-bit ints.
--
-- Returns:
-- * two 8-bit numbers, highest to lowest significance.
local function writeInt16be(value)
    return writeInt8(value >> 8), writeInt8(value)
end

-- writeInt16le(value) -> number, number
-- Function
-- Returns the lowest 16 bits of the value as a two 8-bit `number`s, in little-endian order.
--
-- Parameters:
-- * values - the `number` to write as two 8-bit ints.
--
-- Returns:
-- * two 8-bit numbers, lowest to highest significance.
local function writeInt16le(value)
    return writeInt8(value), writeInt8(value >> 8)
end

-- writeInt24be(value) -> number, number, number
-- Function
-- Returns the lowest 24 bits of the value as a three 8-bit `number`s, in big-endian order.
--
-- Parameters:
-- * values - the `number` to write as three 8-bit ints.
--
-- Returns:
-- * two 8-bit numbers, highest to lowest significance.
local function writeInt24be(value)
    return writeInt8(value >> 16), writeInt8(value >> 8), writeInt8(value)
end

-- writeInt24le(value) -> number, number, number
-- Function
-- Returns the lowest 16 bits of the value as a two 8-bit `number`s, in little-endian order.
--
-- Parameters:
-- * values - the `number` to write as two 8-bit ints.
--
-- Returns:
-- * two 8-bit numbers, lowest to highest significance.
local function writeInt24le(value)
    return writeInt8(value), writeInt8(value >> 8), writeInt8(value >> 16)
end

-- writeInt32be(value) -> number, number, number, number
-- Function
-- Returns the lowest 32 bits of the value as a four 8-bit `number`s, big-endian order.
--
-- Parameters:
-- * values - the `number` to write as four 8-bit ints.
--
-- Returns:
-- * four 8-bit numbers, highest to lowest significance.
local function writeInt32be(value)
    return writeInt16be(value >> 16), writeInt16be(value)
end

-- writeInt32le(value) -> number, number, number, number
-- Function
-- Returns the lowest 32 bits of the value as a four 8-bit `number`s, little-endian order.
--
-- Parameters:
-- * values - the `number` to write as an four 8-bit ints.
--
-- Returns:
-- * four 8-bit numbers, lowest to highest significance.
local function writeInt32le(value)
    return writeInt16le(value), writeInt16le(value >> 16)
end

-- writeInt64be(value) -> number, number, number, number, number, number, number, number
-- Function
-- Returns the lowest 64 bits of the value as a eight 8-bit `number`s, big-endian order.
--
-- Parameters:
-- * values - the `number` to write as an eight 8-bit ints.
--
-- Returns:
-- * eight 8-bit numbers, highest to lowest significance.
local function writeInt64be(value)
    return writeInt32be(value >> 32), writeInt32be(value)
end

-- writeInt64le(value) -> number, number, number, number, number, number, number, number
-- Function
-- Returns the lowest 64 bits of the value as a eight 8-bit `number`s, little-endian order.
--
-- Parameters:
-- * values - the `number` to write as an eight 8-bit ints.
--
-- Returns:
-- * eight 8-bit numbers, lowest to highest significance.
local function writeInt64le(value)
    return writeInt32le(value), writeInt32le(value >> 32)
end

-- intMask(bits) -> number
-- Function
-- Creates a number with the specified number of bits set to `1`.
local function intMask(bits)
    local result = 0
    for _=1,bits do
        result = (result << 1) | 1
    end
    return result
end

-- doInt(value, index, bits, read, write) -> number, number | string
-- Function
-- Converts a byte `string` value to an integer of the specified `bits` in length, or a `number` to a `string` of the specified bit size.
--
-- Parameters:
-- * value      - either a `string` to retrieve an integer from, or a `number` to convert to a byte string.
-- * index      - (optional) if `value` is a `string`, indicates the byte number to start reading from. Defaults to `1`.
-- * bits       - the number of bits in the integer. Typically 8/16/32/64.
-- * read       - the function which will read the bytes from the string.
-- * write      - the function which will output a series of number bytes to combine into a string.
--
-- Returns:
---  * if `value` is a `string`, returns the integer provided by the `read` function, followed by the next index.
---  * if `value` is a `number`, returns a `string` containing the integer value in the order provided by the `write` function.
local function doInt(value, index, bits, read, write)
    if type(value) == "string" then
        index = index or 1
        if value:len() < (index + (bits/8) - 1) then
            error(format("need %d bytes but %d are available from index %d", bits/8, value:len()-index+1, index), 2)
        end
        return read(value, index)
    elseif type(value) == "number" then
        if value & intMask(bits) ~= value then
            error(format("value is larger than %d bits: 0x%04X", bits, value), 2)
        end
        return char(write(value))
    else
        error(format("unsupported value type: %s", type(value)), 2)
    end
end

--- hs.bytes.int8(value[, index]) -> number, number | string
--- Function
--- Converts a byte `string` value to an 8-bit integer or a `number` to a 1-byte `string`.
---
--- Parameters:
---  * value     - either a `string` to retrieve an 8-bit int from, or a `number` to convert to a byte string.
---  * index     - (optional) if `value` is a `string`, indicates the byte number to start reading from. Defaults to `1`.
---
--- Returns:
---  * if `value` is a `string`, returns the 8-bit integer at the `index`, followed by the next index.
---  * if `value` is a `number`, returns a 1-byte `string` containing the integer value.
---
--- Notes:
---  * if the `value` `number` is larger than can fit in an 8-bit int, an error is thrown.
---  * if the `value` is a `string` and the `index` is larger than the length of the `string`, an error is thrown.
function bytes.int8(value, index)
    return doInt(value, index, 8, readInt8, writeInt8)
end

--- hs.bytes.int16be(value[, index]) -> number, number | string
--- Function
--- Converts a byte `string` value to a 16-bit integer or a `number` to a 2-byte `string`, using big-endian encoding.
---
--- Parameters:
---  * value     - either a `string` to retrieve a 16-bit int from, or a `number` to convert to a byte string.
---  * index     - (optional) if `value` is a `string`, indicates the byte number to start reading from. Defaults to `1`.
---
--- Returns:
---  * if `value` is a `string`, returns the 16-bit integer at the `index`, followed by the next index.
---  * if `value` is a `number`, returns a 2-byte `string` containing the integer value.
---
--- Notes:
---  * this function reads/writes as 'big-endian', so the more significant byte is read/written first, then the less significant byte.
---  * if the `value` `number` is larger than can fit in a 16-bit int, an error is thrown.
---  * if the `value` is a `string` and the `index` is larger than the length of the `string`, an error is thrown.
function bytes.int16be(value, index)
    return doInt(value, index, 16, readInt16be, writeInt16be)
end

--- hs.bytes.int16le(value[, index]) -> number, number | string
--- Function
--- Converts a byte `string` value to a 16-bit integer or a `number` to a 2-byte `string`, using little-endian encoding.
---
--- Parameters:
---  * value     - either a `string` to retrieve a 16-bit int from, or a `number` to convert to a byte string.
---  * index     - (optional) if `value` is a `string`, indicates the byte number to start reading from. Defaults to `1`.
---
--- Returns:
---  * if `value` is a `string`, returns the 16-bit integer at the `index`, followed by the next index.
---  * if `value` is a `number`, returns a 2-byte `string` containing the integer value.
---
--- Notes:
---  * this function reads/writes as 'little-endian', so the less significant byte is read/written first, then the more significant byte.
---  * if the `value` `number` is larger than can fit in a 16-bit int, an error is thrown.
---  * if the `value` is a `string` and the `index` is larger than the length of the `string`, an error is thrown.
function bytes.int16le(value, index)
    return doInt(value, index, 16, readInt16le, writeInt16le)
end

--- hs.bytes.int24be(value[, index]) -> number, number | string
--- Function
--- Converts a byte `string` value to a 24-bit integer or a `number` to a 3-byte `string`, using big-endian encoding.
---
--- Parameters:
---  * value     - either a `string` to retrieve a 24-bit int from, or a `number` to convert to a byte string.
---  * index     - (optional) if `value` is a `string`, indicates the byte number to start reading from. Defaults to `1`.
---
--- Returns:
---  * if `value` is a `string`, returns the 24-bit integer at the `index`, followed by the next index.
---  * if `value` is a `number`, returns a 3-byte `string` containing the integer value.
---
--- Notes:
---  * this function reads/writes as 'big-endian', so the more significant byte is read/written first, then the less significant byte.
---  * if the `value` `number` is larger than can fit in a 24-bit int, an error is thrown.
---  * if the `value` is a `string` and the `index` is larger than the length of the `string`, an error is thrown.
function bytes.int24be(value, index)
    return doInt(value, index, 24, readInt24be, writeInt24be)
end

--- hs.bytes.int24le(value[, index]) -> number, number | string
--- Function
--- Converts a byte `string` value to a 24-bit integer or a `number` to a 3-byte `string`, using little-endian encoding.
---
--- Parameters:
---  * value     - either a `string` to retrieve a 24-bit int from, or a `number` to convert to a byte string.
---  * index     - (optional) if `value` is a `string`, indicates the byte number to start reading from. Defaults to `1`.
---
--- Returns:
---  * if `value` is a `string`, returns the 24-bit integer at the `index`, followed by the next index.
---  * if `value` is a `number`, returns a 3-byte `string` containing the integer value.
---
--- Notes:
---  * this function reads/writes as 'little-endian', so the less significant byte is read/written first, then the more significant byte.
---  * if the `value` `number` is larger than can fit in a 24-bit int, an error is thrown.
---  * if the `value` is a `string` and the `index` is larger than the length of the `string`, an error is thrown.
function bytes.int24le(value, index)
    return doInt(value, index, 24, readInt24le, writeInt24le)
end

--- hs.bytes.int32be(value[, index]) -> number, number | string
--- Function
--- Converts a byte `string` value to a 32-bit integer or a `number` to a 4-byte `string`, using big-endian encoding.
---
--- Parameters:
---  * value     - either a `string` to retrieve a 32-bit int from, or a `number` to convert to a byte string.
---  * index     - (optional) if `value` is a `string`, indicates the byte number to start reading from. Defaults to `1`.
---
--- Returns:
---  * if `value` is a `string`, returns the 32-bit integer at the `index`, followed by the next index.
---  * if `value` is a `number`, returns a 4-byte `string` containing the integer value.
---
--- Notes:
---  * this function reads/writes as 'big-endian', so the more significant byte is read/written first, then the less significant byte.
---  * if the `value` `number` is larger than can fit in a 32-bit int, an error is thrown.
---  * if the `value` is a `string` and the `index` is larger than the length of the `string`, an error is thrown.
function bytes.int32be(value, index)
    return doInt(value, index, 32, readInt32be, writeInt32be)
end

--- hs.bytes.int32le(value[, index]) -> number, number | string
--- Function
--- Converts a byte `string` value to a 32-bit integer or a `number` to a 4-byte `string`, using little-endian encoding.
---
--- Parameters:
---  * value     - either a `string` to retrieve a 32-bit int from, or a `number` to convert to a byte string.
---  * index     - (optional) if `value` is a `string`, indicates the byte number to start reading from. Defaults to `1`.
---
--- Returns:
---  * if `value` is a `string`, returns the 32-bit integer at the `index`, followed by the next index.
---  * if `value` is a `number`, returns a 4-byte `string` containing the integer value.
---
--- Notes:
---  * this function reads/writes as 'big-endian', so the more significant byte is read/written first, then the less significant byte.
---  * if the `value` `number` is larger than can fit in a 32-bit int, an error is thrown.
---  * if the `value` is a `string` and the `index` is larger than the length of the `string`, an error is thrown.
function bytes.int32le(value, index)
    return doInt(value, index, 32, readInt32le, writeInt32le)
end

--- hs.bytes.int64be(value[, index]) -> number, number | string
--- Function
--- Converts a byte `string` value to a 64-bit integer or a `number` to an 8-byte `string`, using big-endian encoding.
---
--- Parameters:
---  * value     - either a `string` to retrieve a 64-bit int from, or a `number` to convert to a byte string.
---  * index     - (optional) if `value` is a `string`, indicates the byte number to start reading from. Defaults to `1`.
---
--- Returns:
---  * if `value` is a `string`, returns the 64-bit integer at the `index`, followed by the next index.
---  * if `value` is a `number`, returns a 8-byte `string` containing the integer value.
---
--- Notes:
---  * this function reads/writes as 'big-endian', so the more significant byte is read/written first, then the less significant byte.
---  * if the `value` `number` is larger than can fit in a 64-bit int, an error is thrown.
---  * if the `value` is a `string` and the `index` is larger than the length of the `string`, an error is thrown.
function bytes.int64be(value, index)
    return doInt(value, index, 64, readInt64be, writeInt64be)
end

--- hs.bytes.int64le(value[, index]) -> number, number | string
--- Function
--- Converts a byte `string` value to a 64-bit integer or a `number` to a 4-byte `string`, using little-endian encoding.
---
--- Parameters:
---  * value     - either a `string` to retrieve a 32-bit int from, or a `number` to convert to a byte string.
---  * index     - (optional) if `value` is a `string`, indicates the byte number to start reading from. Defaults to `1`.
---
--- Returns:
---  * if `value` is a `string`, returns the 32-bit integer at the `index`, followed by the next index.
---  * if `value` is a `number`, returns a 4-byte `string` containing the integer value.
---
--- Notes:
---  * this function reads/writes as 'big-endian', so the more significant byte is read/written first, then the less significant byte.
---  * if the `value` `number` is larger than can fit in a 32-bit int, an error is thrown.
---  * if the `value` is a `string` and the `index` is larger than the length of the `string`, an error is thrown.
function bytes.int64le(value, index)
    return doInt(value, index, 64, readInt64le, writeInt64le)
end

--- hs.bytes.remainder(value[, index]) -> string
--- Function
--- Returns the remainder of the byte string as a `string`, starting at the specified `index`.
---
--- Parameters:
---  * value     - the byte string.
---  * index     - (optional) the starting index, defaults to `1`.
---
--- Returns:
---  * The remainder as a byte string.
function bytes.remainder(value, index)
    return index and value:sub(index) or value
end

--- hs.bytes.exactly(size) -> function
--- Function
--- Returns a `function` that can be passed to `bytes.read(...)` and will read exactly the specified number of bytes.
---
--- Parameters:
---  * size      - the exact number of bytes the function will read.
---
--- Returns:
---  * a `function` that can be passed to `bytes.read(...)`
---
--- Notes:
---  * Unlike most functions here, this one  needs to be called called when passing to the `read` function.
---  * For example, this will read an 8-bit integer then a 4 bytes as a `string`: `bytes.read(byteData, bytes.int8, bytes.exactly(4))`
function bytes.exactly(size)
    return function(value, index)
        index = index or 1
        local last = index + size -1
        if value:len() < last then
            error(format("requested exactly %d bytes but only %d are available", size, value:len()-index+1), 2)
        end
        return value:sub(index, last), index + size
    end
end

-----------------------------------------------------
-- Hexadecimal conversion functions.
-----------------------------------------------------

-- ASCII values for "0", "9", "A", "Z", "a", "z"
local ZERO, NINE, A_UPPER, Z_UPPER, A_LOWER, Z_LOWER = 48, 57, 65, 70, 97, 102

--- hs.bytes.hexToInt4(str[, index]) -> value: number, nextIndex: number
--- Function
--- Converts a single hex character at the specified index into a 4-bit integer between `0` and `15` (aka `F`).
--- Supports upper and lower-case characters for values from A-F.
---
--- Parameters:
---  * str       - the string containing the hex character.
---  * index     - the index of the hex character in the string (defaults to `1`)
---
--- Returns:
---  * The 4-bit `number` value of the specified hex string.
---  * The index value for the next character in the string.
function bytes.hexToInt4(str, index, errorLevel)
    local b = byte(str, index or 1)
    if b >= ZERO and b <= NINE then
        return b - ZERO, index+1
    elseif b >= A_UPPER and b <= Z_UPPER then
        return b - A_UPPER + 10, index+1
    elseif b >= A_LOWER and b <= Z_LOWER then
        return b - A_LOWER + 10, index+1
    end
    error(format("expected '0' to 'F' at %d but got '%s'", index, char(b)), (errorLevel or 1)+1)
end

--- hs.bytes.hexToInt8(str[, index]) -> value: number, nextIndex: number
--- Function
--- Converts two hex characters (eg. `"FF"`), starting at the specified index, into a number between 0 and 255.
--- Supports upper and lower-case characters for values from A-F.
---
--- Parameters:
---  * str - The string containing two hex digits ("0" to "F")
---  * index - The index of the first hex character in the string (defaults to `1`)
---
--- Returns:
---  * value        - the 8-bit `number` value of the specified hex string.
---  * nextIndex    - the index value for the next character in the string.
function bytes.hexToInt8(str, index, errorLevel)
    index = index or 1
    errorLevel = (errorLevel or 1) + 1
   return (bytes.hexToInt4(str, index, errorLevel) << 4) + bytes.hexToInt4(str, index+1, errorLevel), index+2
end

--- hexToBytes(str[, spacer]) -> string
--- Function
--- Converts a hex string representation to hex data.
---
--- Parameters:
---  * str      - the string to process.
---  * spacer   - the spacer character (defaults to ' ')
---
--- Returns:
---  * A string
function bytes.hexToBytes(str, spacer)
    local spacerByte = (spacer or ' '):byte(1)
    local out = {}
    local j = 1
    local b
    for i=1,#str,2 do
        if str:byte(i) ~= spacerByte then
            b = bytes.hexToInt8(str, i, 2)
            out[j] = string.char(b)
            j = j+1
        end
    end
    return concat(out)
end

-- int4ToHexChar(value[, lowerCase]) -> number
-- Function
-- Converts an integer value between 0 and 15 into a single hex character from "0" to "F".
--
-- Parameters:
--  * value        - the number to convert, between 0-15.
--  * lowerCase    - if `true`, the characters will be lower-case (defaults to `false`)
--
-- Returns:
--  * A number representing the character byte value.
local function int4ToHexChar(value, lowerCase)
    if value >= 0 and value <= 9 then
        return value + ZERO
    elseif value >= 10 and value <= 15 then
        return value - 10 + (lowerCase and A_LOWER or A_UPPER)
    end
    error(format("int value must be between 0 and 15, but was " .. tostring(value), 3))
end

-- int8ToHexChar(value[, lowerCase]) -> number
-- Function
-- Converts an integer value between 0 and 255 into a two hex characters from "0" to "F".
--
-- Parameters:
--  * value        - the number to convert, between 0-255.
--  * lowerCase    - if `true`, the characters will be lower-case (defaults to `false`)
--
-- Returns:
--  * A number representing the character byte value.
local function int8ToHexChars(value, lowerCase)
    return int4ToHexChar(value >> 4, lowerCase), int4ToHexChar(value & 0xF, lowerCase)
end

--- hs.bytes.int4ToHex(value[, lowerCase]) -> number
--- Function
--- Converts an integer value between 0 and 15 into a single hex character from "0" to "F".
---
--- Parameters:
---  * byteString   - the string of bytes to output as hex characters
---  * lowerCase    - if `true`, the characters will be lower-case (defaults to `false`)
---
--- Returns:
---  * A single character representing the byte value.
function bytes.int4ToHex(value, lowerCase)
    return char(int4ToHexChar(value, lowerCase))
end

--- hs.bytes.int4ToHex(value[, lowerCase]) -> number
--- Function
--- Converts an integer value between 0 and 15 into a single hex character from "0" to "F".
---
--- Parameters:
---  * byteString   - the string of bytes to output as hex characters
---  * lowerCase    - if `true`, the characters will be lower-case (defaults to `false`)
---
--- Returns:
---  * A single character representing the byte value.
function bytes.int8ToHex(value, lowerCase)
    return char(int8ToHexChars(value, lowerCase))
end

--- hs.bytes.bytesToHex(byteString[, lowerCase][, spacer]) -> string
--- Function
--- Converts a string of binary data into a hexadecimal representation of the data.
---
--- Parameters:
---  * byteString   - the byte string.
---  * lowerCase    - if `true`, the ouput hex values will be lower-case (defaults to `false`)
---  * spacer       - if provided, each byte is separated by the first character in the spacer.
function bytes.bytesToHex(byteString, lowerCase, spacer)
    if type(lowerCase) == "string" then
        spacer = lowerCase
        lowerCase = false
    end

    local spacerByte
    if spacer then
        spacerByte = spacer:byte(1)
    end

    local out = {}
    local b
    for i=1,#byteString do
        b = byte(byteString, i)
        if spacerByte and i ~= 1 then
            out[i] = char(spacerByte, int8ToHexChars(b, lowerCase))
        else
            out[i] = char(int8ToHexChars(b, lowerCase))
        end
    end
    return concat(out)
end

setmetatable(bytes, {
    __call = function(_, ...)
        return bytes.new(...)
    end
})

return bytes