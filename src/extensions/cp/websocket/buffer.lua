--- === cp.websocket.buffer ===
---
--- Internal byte buffer type. Allows additional chunks of bytes
--- to be concatonated relatively inexpensively, as well as `peek` and `pop` operations
--- to preview/read in chunks of bytes.
---
---  For example:
---
--- ```lua
--- local buff = buffer.new()
--- buff:push("Hello")
--- buff:len()       -- 5
--- buff:peek(2)     -- "He"
--- buff:peek(7)     -- nil
--- buff:write(" world!")
--- buff:len()       -- 12
--- buff:peek(7)     -- "Hello w"
--- buff:pop(3)      -- "Hel"
--- buff:len()       -- 9
--- buff:bytes()     -- "lo world!"
--- ```

local require           = require

-- local log               = require "hs.logger" .new "ws_buff"
-- local inspect           = require "hs.inspect"
-- local hexDump           = require "hs.utf8" .hexDump

local bytes             = require "hs.bytes"

local hexToBytes        = bytes.hexToBytes

local mod = {}

mod.mt = {}
mod.mt.__index = mod.mt

mod.maxChunks = 0xFFFFFFFF

-- nextChunk(current) -> number
-- Function
-- Determines the next chunk number after the current one. Loops back if we hit maxChunks
local function nextChunk(current)
    -- we reset to 0 so that there will be a 1-space gap between the loop.
    return current < mod.maxChunks and current+1 or 0
end

--- cp.websocket.buffer.is(value) -> boolean
--- Function
--- Checks if the `value` is an instance of a `buffer`.
---
--- Parameters:
---  * `value`  - The value to check.
---
--- Returns:
---  * `true` if the value is an instance of `buffer`.
function mod.is(value)
    if value and type(value) == "table" then
        local mt = getmetatable(value)
        return mt == mod.mt
    end
    return false
end

--- cp.websocket.buffer.new(...) -> buffer
--- Constructor
--- Creates a new byte string buffer containing the provided `string` chunks.
---
--- Parameters:
---  * ... - The new `string` chunks to add to the end of the buffer.
---
--- Returns:
---  * The new `buffer`.
function mod.new(...)
    local o = {
        -- the 1-based index of the first chunk
        _first = 1,
        -- the 1-based index after the last chunk
        _last = 1,
        -- the index within the first chunk to start reading from
        _index = 1,
    }
    setmetatable(o, mod.mt)

    o:push(...)

    return o
end

--- cp.websocket.buffer.fromHex(hexString[, spacer]) -> cp.websocket.buffer
--- Constructor
--- Creates a buffer from the bytes represented by the provided hex string.
---
--- Parameters:
---  * hexString - The string of hex characters to convert.
---  * spacer - The character to ignore as a spacer. Defaults to space (" ").
---
--- Returns:
---  * The new `buffer`.
---
--- Notes:
---  * Examples:
---   * `buffer.fromHex("ABCDE")`
---   * `buffer.fromHex("12-34-56", "-")`
function mod.fromHex(hexString, spacer)
    local hexBytes = hexToBytes(hexString, spacer)
    return mod.new(hexBytes)
end

--- cp.websocket.buffer.clone(otherBuffer) -> buffer
--- Constructor
--- Creates a copy of the provided buffer. It shares data with the original, but can be modified
--- via `pop`/`push`, etc without affecting the original.
---
--- Parameters:
---  * otherBuffer - The `buffer` to clone.
---
--- Returns:
---  * the clone of the original `buffer`.
function mod.clone(otherBuffer)
    local o = {}
    for key,value in pairs(otherBuffer) do
        o[key] = value
    end
    setmetatable(o, mod.mt)
    return o
end

mod.mt.clone = mod.clone

function mod.mt:_indexes()
    return self._first, self._last, self._index
end

--- cp.websocket.buffer:len() -> number
--- Method
--- Returns the total number of bytes in the buffer.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The number of bytes in the buffer.
function mod.mt:len()
    local first, last, index = self:_indexes()
    if first == last then
        return 0
    end

    local len = 0
    local current = first
    while current ~= last do
        local chunk = self[current]
        len = len + #chunk - index + 1
        index = 1
        current = nextChunk(current)
    end

    return len
end

-- cp.websocket.buffer:_read(len, remove) -> string | nil
-- Method
-- Reads the specified number of bytes, optionally removing them as it does so.
--
-- Parameters:
--  * len - the number of bytes to read.
--  * remove - if `true`, the read bytes will be removed from the buffer.
--
-- Returns:
--  * The read bytes, or `nil` if there are insufficient bytes in the buffer for the required `len`
--
-- Note:
--  * Internally, chunks are only removed once the whole chunk has been read,
--   so some long chunks may hang around if not read completely.
function mod.mt:_read(len, remove)
    local first, last, index = self:_indexes()
    if first == last then
        return nil
    elseif len > self:len() then
        return nil
    end

    local value = bytes()
    local current = first
    while current ~= last and len > 0 do
        local chunk = self[current]
        local available = #chunk - index + 1
        if available <= len then
            if index > 1 then
                chunk = chunk:sub(index)
            end
            if remove then
                self[current] = nil
                self._first = nextChunk(current)
                self._index = 1
            end
        else
            local j = index+len
            chunk = chunk:sub(index, j-1)
            if remove then
                self._index = j
            end
        end
        value:write(chunk)

        len = len-#chunk
        index = 1
        current = nextChunk(current)
    end

    return value:bytes()
end

--- cp.websocket.buffer:peek(len) -> string | nil
--- Method
--- Reads the specified `len` of bytes from the start of the buffer without removing them.
---
--- Parameters:
---  * len - The number of bytes to read.
---
--- Returns:
---  * The `string` of bytes or `nil` if there are not enough bytes available for the requested `len`.
function mod.mt:peek(len)
    return self:_read(len, false)
end

--- cp.websocket.buffer:pop(len) -> string | nil
--- Method
--- Reads the specified `len` of bytes from the start of the buffer, removing them.
---
--- Parameters:
---  * len - The number of bytes to read.
---
--- Returns:
---  * The `string` of bytes or `nil` if there are not enough bytes available for the requested `len`.
function mod.mt:pop(len)
    return self:_read(len, true)
end

--- cp.websocket.buffer:push(...) -> buffer
--- Method
--- Pushes the provided `string`s onto the end of the buffer.
---
--- Parameters:
---  * ... - The new `string` chunks to add to the end of the buffer.
---
--- Returns:
---  * The same `buffer` instance.
---
--- Notes:
---  * Throws an error if more than `cp.websocket.buffer.maxChunks` are currently in the buffer when a new value is pushed.
function mod.mt:push(...)
    local last = self._last

    for i=1,select("#", ...) do
        self[last] = select(i, ...)
        last = nextChunk(last)
        if last == self._first then
            error("buffer is full")
        end
    end

    self._last = last
    return self
end

--- cp.websocket.buffer:drop(len) -> boolean
--- Method
--- Drops the specified `len` of bytes from the start of the buffer.
---
--- Parameters:
---  * len - The number of bytes to read.
---
--- Returns:
---  * `true` if successful, or `false` if there are not enough bytes available for the requested `len`.
---
--- Notes:
---  * Equivalent to, but more efficient than `pop` if you don't need the bytes being dropped.
function mod.mt:drop(len)
    local first, last, index = self:_indexes()
    if first == last then
        return false
    elseif len > self:len() then
        return false
    end

    local current = first
    while current ~= last and len > 0 do
        local chunk = self[current]
        local available = #chunk - index + 1
        if available <= len then
            self[current] = nil
            self._first = nextChunk(current)
            self._index = 1
            len = len-available
        else
            local j = index+len
            self._index = j
            len = 0
        end
        index = 1
        current = nextChunk(current)
    end

    return true
end

return mod