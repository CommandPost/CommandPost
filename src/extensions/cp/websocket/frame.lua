--- === cp.websocket.frame ===
---
--- Implementation of [RFC-6455](https://tools.ietf.org/html/rfc6455), Section 5
---
--- Reads and writes data to and from websocket frame wire protocol data.

-- local log               = require "hs.logger" .new "wsframe"

local bytes             = require "hs.bytes"
local utf8              = require "hs.utf8"
local buffer            = require "cp.websocket.buffer"
local result            = require "cp.result"

local hexToBytes        = bytes.hexToBytes
local exactly           = bytes.exactly
local uint16be          = bytes.uint16be
local uint32be          = bytes.uint32be
local uint64be          = bytes.uint64be
local uint8             = bytes.uint8

local hexDump           = utf8.hexDump

local stringbyte        = string.byte
local format            = string.format
local insert            = table.insert

local mod = {}

mod.mt = {}
mod.mt.__index = mod.mt

local FIN               = 1 << 7    -- 0b10000000
local RSV1              = 1 << 6    -- 0b01000000
local RSV2              = 1 << 5    -- 0b00100000
local RSV3              = 1 << 4    -- 0b00010000
local OPCODE            = 0xF       -- 0b00001111

local MASK              = 1 << 7    -- 0b10000000
local PAYLOAD_LEN       = 0x7F      -- 0b01111111
local PAYLOAD_16BIT     = 126
local PAYLOAD_64BIT     = 127

local MAX_7BIT          = 125
local MAX_16BIT         = 0xFFFF

local function isSet(byte, mask)
    return (byte & mask) == mask
end

mod.opcode = {
    continuation    = 0x0,
    text            = 0x1,
    binary          = 0x2,
    -- 0x3-7 reserved for non-control frames
    close           = 0x8,
    ping            = 0x9,
    pong            = 0xA,
    -- 0xB-F reserved for control frames
}


-- readPayloadLen(data, index) -> number, number
-- Function
-- A `bytes` reader function that reads from the data `string`, starting at `index`,
-- returning the total payload length and the next byte `index` to read.
--
-- Parameters:
--  * data  - The `string` of bits to read.
--  * index - The index to read from (typically `1`) for this field.
local function readPayloadLen(data, index)
    local payloadLength = bytes.read(data, index, uint8) & PAYLOAD_LEN
    local nextByte = index + 1

    if payloadLength == PAYLOAD_16BIT then
        payloadLength = bytes.read(data, nextByte, uint16be)
        nextByte = nextByte + 2
    elseif payloadLength == PAYLOAD_64BIT then
        payloadLength = bytes.read(data, nextByte, uint64be)
        nextByte = nextByte + 8
    end

    return payloadLength, nextByte
end

-- maskData(data, maskingKey) -> string
-- Function
-- Masks (and unmasks) the provided data using the provided 4-byte `table`.
--
-- Parameters:
--  * data - The data `string` to mask or unmmask.
--  * maskingKey - The table of 4 1-byte keys.
local function maskData(data, maskingKey)
    local unmasked = {stringbyte(data, 1, #data)}
    local key = {maskingKey >> 24 & 0xFF, maskingKey >> 16 & 0xFF, maskingKey >> 8 & 0xFF, maskingKey & 0xFF}

    for i = 1, #unmasked do
        unmasked[i] = unmasked[i] ~ key[((i-1) % 4) + 1]
    end

    return string.char(table.unpack(unmasked))
end

-- generateMaskingKey() -> number
-- Function
-- Generates a new 32-bit key.
--
-- Parameters:
--  * None
--
-- Returns:
--  * The new masking key, or `nil`.
function mod.generateMaskingKey()
    -- An actual mask generator:
    -- return math.random(0xFFFFFF, 0xFFFFFFFF)
    -- Sends data unmodified:
    return 0
end

-- TODO: Delete fromBytes once we are using fromBuffer everywhere.

--- cp.websocket.frame.fromBytes(data, index) -> frame, number
--- Function
--- Reads a Websocket Frame from the provided `string` of binary data.
---
--- Parameters:
---  * data - The `string` of bytes to read from.
---  * index - The 1-based index `number` to start reading from.
---
--- Returns:
---  * The `frame` of binary payload data plus the next index `number` to read from the `data` `string`.
---
--- Notes:
---  * Throws an error if any of the bytes are invalid.
function mod.fromBytes(data, index)
    local frame = {}

    -- read the FIN/RSV/OPCODE byte
    local finalOp = bytes.read(data, index, uint8)
    local nextIndex = index + 1

    frame.final = isSet(finalOp, FIN)
    frame.rsv1 = isSet(finalOp, RSV1)
    frame.rsv2 = isSet(finalOp, RSV2)
    frame.rsv3 = isSet(finalOp, RSV3)

    -- Reserved bits only allowed if extensions have been negotiated on the handshake.
    if frame.rsv1 or frame.rsv2 or frame.rsv3 then
        error(format("unexpected reserved flags: rsv1: %s; rsv2: %s; rsv3: %s", frame.rsv1, frame.rsv2, frame.rsv3))
    end

    frame.opcode = finalOp & OPCODE

    -- read the MASK
    frame.mask = isSet(bytes.read(data, nextIndex, uint8), MASK)

    -- read the full payload length, taking into account extended bytes.
    frame.payloadLen, nextIndex = readPayloadLen(data, nextIndex)

    local maskingKey
    if frame.mask then
        maskingKey = bytes.read(data, nextIndex, uint32be)
        nextIndex = nextIndex + 4
    end

    -- For debugging:
    frame.indexWhenDataStarted = nextIndex

    local payloadData = bytes.read(data, nextIndex, exactly(frame.payloadLen))

    if maskingKey then
        payloadData = maskData(payloadData, maskingKey)
    end

    frame.payloadData = payloadData

    setmetatable(frame, mod.mt)

    return frame, nextIndex + frame.payloadLen
end

local function toBuffer(data, cloned)
    local buff
    if buffer.is(data) then
        buff = data
    elseif type(data) == "string" then
        buff = buffer.new(data)
    else
        return nil
    end

    if cloned then
        buff = buff:clone()
    end
    return buff
end

-- readFrameHeader(buff) -> result<{frame:frame, bytes:number}>
-- Private Function
-- Attempts to read the payload length and masking key from the buffer and add them to the provided `frame`.
--
-- Parameters:
--  * buff - the `buffer` to read, which will be modified.
--
-- Returns:
--  * If `successful`, a `result` containing the updated `frame` and the total `bytes` read to retrieve them.
--  * Otherwise a `failure` with the `error` message if there was a problem while reading.
local function readFrameHeader(buff)
    local frame = setmetatable({}, mod.mt)

    -- read the FIN/RSV/OPCODE/MASK/PAYLOAD LEN bytes
    local header = buff:pop(2)
    if not header then
        return result.failure("expected the FIN | RSV1/2/3 byte and MASK | PAYLOAD LEN byte")
    end

    local finalOp, maskPayloadByte = bytes.read(header, uint8, uint8)

    frame.final = isSet(finalOp, FIN)
    frame.rsv1 = isSet(finalOp, RSV1)
    frame.rsv2 = isSet(finalOp, RSV2)
    frame.rsv3 = isSet(finalOp, RSV3)

    frame.opcode = finalOp & OPCODE

    -- is there a mask?
    frame.mask = maskPayloadByte & MASK == MASK

    -- how big is the payload?
    local payloadLen = maskPayloadByte & PAYLOAD_LEN

    local extendedLen, uint = 0, nil

    if payloadLen == PAYLOAD_64BIT then
        extendedLen = 8
        uint = uint64be
    elseif payloadLen == PAYLOAD_16BIT then
        extendedLen = 2
        uint = uint16be
    end

    if extendedLen > 0 then
        local extendedBytes = buff:pop(extendedLen)
        if not extendedBytes then
            return result.failure("expected %d bytes for the EXTENDED PAYLOAD LEN", extendedLen)
        end
        payloadLen = bytes.read(extendedBytes, uint)
    end

    frame.payloadLen = payloadLen

    return result.success {frame = frame, bytes = 2 + extendedLen}
end

--- cp.websocket.frame.bytesRequired(data) -> number | nil
--- Function
--- Checks bytes in the data `string` or `buffer`. If it contains a valid frame header (everything up to but not including the masking key/payload)
--- it will return the total required bytes for a valid frame, otherwise it will return `nil`.
---
--- Parameters:
---  * data: the `string` or `buffer` to check.
---
--- Returns:
---  * The `number` of bytes required based on the frame header, or `nil` if not enough information is available.
---
--- Notes:
---  * The `data` will be unmodified after returning from this function.
function mod.bytesRequired(data)
    data = toBuffer(data, true)
    if not data then
       return nil
    end

    local outcome = readFrameHeader(data)
    if outcome.failure then
        return nil
    end
    local frame = outcome.value.frame
    return outcome.value.bytes + (frame.mask and 4 or 0) + frame.payloadLen
end

--- cp.websocket.frame.isValid(data) -> number
--- Function
--- Checks bytes in the data `string` or `buffer` contains a valid `frame`.
---
--- Parameters:
---  * data: the `string` or `buffer` to check.
---
--- Returns:
---  * `true` if the data contains both a valid frame header and sufficient bytes for the whole frame.
function mod.isValid(data)
    data = toBuffer(data)
    if not data then
        return false
    end

    local requiredLen = mod.bytesRequired(data)
    if not requiredLen then
        return false
    end

    return requiredLen ~= nil and data:len() >= requiredLen
end

--- cp.websocket.frame.fromBuffer(data) -> result<{frame:frame, bytes:number}>
--- Function
--- Reads a Websocket Frame from the provided `string` or `cp.websocket.buffer` of binary data.
---
--- Parameters:
---  * data - The `string` or `cp.websocket.buffer` of bytes to read from. It will not be modified.
---
--- Returns:
---  * The a `cp.result` with either `success` and the `frame` of binary payload data plus the number of `bytes` read from the `data`,
---   or `failure` with a `message` if there was an error.
function mod.fromBuffer(data)
    data = toBuffer(data, true)
    if not data then
       return result.failure("expected a `string` or `buffer`")
    end

    local outcome = readFrameHeader(data)
    if outcome.failure then
        return outcome
    end

    local frame = outcome.value.frame

    local maskingKey
    if frame.mask then
        local maskingKeyBytes = data:pop(4)
        if not maskingKeyBytes then
            return result.failure("expected %d bytes for the MASKING KEY", 4)
        end
        maskingKey = bytes.read(maskingKeyBytes, uint32be)
    end

    local payloadData = data:pop(frame.payloadLen)
    if not payloadData then
        return result.failure("expected %d bytes of payload data", frame.payloadLen)
    end

    -- handle the MASK
    if maskingKey then
        payloadData = maskData(payloadData, maskingKey)
    end

    frame.payloadData = payloadData

    return result.success {frame = frame, bytes = outcome.bytes + (frame.mask and 4 or 0) + frame.payloadLen }
end

--- cp.websocket.frame.fromHex(value, spacer) -> frame, number | nil
--- Function
--- Convenience function for converting "XX XX" strings to a binary string, then parsing it into a frame.
---
--- Parameters:
---  * value - The hex value as a string
---  * spacer - The spacer used, for example " " (a space)
---
--- Returns:
---  * The `frame` of binary payload data plus the next index `number` to read from the `data` `string`, or `nil` if the data was invalid.
function mod.fromHex(value, spacer)
    return mod.fromBuffer(hexToBytes(value, spacer))
end

--- cp.websocket.frame.new(opcode, mask, payloadData) -> cp.websocket.frame
--- Constructor
--- Creates a new `frame` instance.
---
--- Parameters:
---  * final - If `true`, this is the final frame for a block of data. May be the first frame.
---  * opcode - The `cp.websocket.frame.opcode` for the frame.
---  * mask - If `true`, the data will be masked. Mandatory for client-originating frames.
---  * payloadData - The `string` of application data to send.
---
--- Returns:
---  * The new `frame` instance.
function mod.new(final, opcode, mask, payloadData)
    local o = {
        final = final == true,
        rsv1 = false,
        rsv2 = false,
        rsv3 = false,
        opcode = opcode,
        mask = mask,
        payloadLen = payloadData:len(),
        payloadData = payloadData,
    }

    setmetatable(o, mod.mt)

    return o
end

--- cp.websocket.frame:isNonControlFrame() -> boolean
--- Method
--- Checks if the frame has a non-control frame opcode.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if this is a non-control frame.
function mod.mt:isNonControlFrame()
    return self.opcode & 0x8 == 0
end

--- cp.websocket.frame:isControlFrame() -> boolean
--- Method
--- Checks if the frame has a control frame opcode.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if this is a control frame.
function mod.mt:isControlFrame()
    return self.opcode & 0x8 ~= 0
end

local function maskedPayloadLen(mask, payloadLen)
    return (mask and MASK or 0) | payloadLen
end

--- cp.websocket.frame:toBytes() -> string
--- Method
--- Converts the frame to its byte string form.
---
--- Parameters:
---  * None
---
--- Returns:
--- The byte `string` containing the frame in binary format.
function mod.mt:toBytes()
    local finalOp = self.final and FIN or 0 + self.rsv1 and RSV1 or 0 + self.rsv2 and RSV2 or 0 + self.rsv3 and RSV3 or 0
    finalOp = finalOp + self.opcode

    local data = bytes():write(uint8(finalOp))

    local payloadData = self:payloadData()
    local payloadLen = payloadData:len()
    if payloadLen > MAX_16BIT then
        data:write(uint8(maskedPayloadLen(self.mask, PAYLOAD_64BIT)), uint64be(payloadLen))
    elseif payloadLen > MAX_7BIT then
        data:write(uint8(maskedPayloadLen(self.mask, PAYLOAD_16BIT)), uint16be(payloadLen))
    else
        data:write(uint8(maskedPayloadLen(self.mask, payloadLen)))
    end

    if self.mask then
        local maskingKey = mod.generateMaskingKey()
        data:write(uint32be(maskingKey))
        payloadData = maskData(payloadData, maskingKey)
    end

    data:write(payloadData)

    return data:bytes()
end

function mod.mt:__tostring()
    local result = {}
    insert(result, "frame: ")

    if self.final then
        insert(result, "FIN ")
    end

    if self.opcode == mod.opcode.binary then
        insert(result, "BINARY")
    elseif self.opcode == mod.opcode.close then
        insert(result, "CLOSE")
    elseif self.opcode == mod.opcode.continuation then
        insert(result, "CONTINUATION")
    elseif self.opcode == mod.opcode.text then
        insert(result, "TEXT")
    elseif self.opcode == mod.opcode.ping then
        insert(result, "PING")
    elseif self.opcode == mod.opcode.pong then
        insert(result, "PONG")
    else
        insert(result, "UNKNOWN")
    end

    insert(result, " ")

    if self.mask then
        insert(result, "MASK ")
    end

    local payloadData = self:payloadData()

    insert(result, "PAYLOAD LEN: " .. tostring(#payloadData) .. "\n")

    insert(result, hexDump(payloadData))

    return table.concat(result)
end

return mod
