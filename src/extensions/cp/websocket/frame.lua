--- === cp.websocket.frame ===
---
--- Implementation of [RFC-6455](https://tools.ietf.org/html/rfc6455), Section 5
---
--- Reads and writes data to and from websocket frame wire protocol data.

-- local log               = require "hs.logger" .new "wsframe"

local bytes             = require "hs.bytes"

local bytesToHex        = bytes.bytesToHex
local hexToBytes        = bytes.hexToBytes
local exactly           = bytes.exactly
local uint16be          = bytes.uint16be
local uint32be          = bytes.uint32be
local uint64be          = bytes.uint64be
local uint8             = bytes.uint8

local stringbyte        = string.byte
local format            = string.format

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
local MAX_16BIT         = 0xF

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
    local key = {maskingKey >> 24 & 0x7, maskingKey >> 16 & 0x7, maskingKey >> 8 & 0x7, maskingKey & 0x7}

    for i = 1, #unmasked do
        unmasked[i] = unmasked[i] ~ key[i % 4 + 1]
    end

    return string.char(table.unpack(unmasked))
end

-- generateMaskingKey(mask) -> number | nil
-- Function
-- Generates a new 32-bit key.
--
-- Parameters:
--  * mask - If `true`, the masking key is generated, otherwise `nil` is returned
--
-- Returns:
--  * The new masking key, or `nil`.
local function generateMaskingKey(mask)
    if mask then
        return math.random(0, MAX_16BIT)
    end
end

--- cp.websocket.frame.fromBytes(data, index[, extensionLen]) -> frame, number | nil
--- Function
--- Reads a Websocket Frame from the provided `string` of binary data.
---
--- Parameters:
---  * data - The `string` of bytes to read from.
---  * index - The 1-based index `number` to start reading from.
---  * extensionLen - An optional number indicating the number of expected extension bytes.
---
--- Returns:
---  * The `frame` of binary payload data plus the next index `number` to read from the `data` `string`, or `nil` if the data was invalid.
function mod.fromBytes(data, index, extensionLen)
    local frame = {}

    -- read the FIN/RSV/OPCODE byte
    local finalOp = bytes.read(data, index, uint8)
    local nextIndex = index + 1

    frame.final = isSet(finalOp, FIN)
    frame.rsv1 = isSet(finalOp, RSV1)
    frame.rsv2 = isSet(finalOp, RSV2)
    frame.rsv3 = isSet(finalOp, RSV3)

    -- Reserved bits only allowed if extensions have been negotiated on the handshake.
    if extensionLen == nil and (frame.rsv1 or frame.rsv2 or frame.rsv3) then
        error(format("unexpected reserved flags: rsv1: %s; rsv2: %s; rsv3: %s", frame.rsv1, frame.rsv2, frame.rsv3))
    end

    frame.opcode = finalOp & OPCODE

    -- read the MASK
    frame.mask = isSet(bytes.read(data, nextIndex, uint8), MASK)
    -- read the full payload length, taking into account extended bytes.
    frame.payloadLen, nextIndex = readPayloadLen(data, nextIndex)

    if frame.mask then
        frame.maskingKey = bytes.read(data, nextIndex, uint32be)
        nextIndex = nextIndex + 4
    end

    local payloadData = bytes.read(data, exactly(frame.payloadLen))

    if frame.mask then
        payloadData = maskData(payloadData, frame.maskingKey)
    end

    if extensionLen ~= nil then
        frame.extensionData = payloadData:sub(1, extensionLen)
        payloadData = payloadData:sub(extensionLen)
    end

    frame.applicationData = payloadData

    setmetatable(frame, mod.mt)

    return frame, nextIndex + frame.payloadLen
end

-- fromHex(value) -> frame
-- Function
-- Convenience function for converting "XX XX" strings to a binary string, then parsing it into a frame.
function mod.fromHex(value, spacer)
    return mod.fromBytes(hexToBytes(value, spacer), 1)
end

--- cp.websocket.frame.new(opcode, mask, applicationData) -> cp.websocket.frame
--- Constructor
--- Creates a new `frame` instance.
---
--- Parameters:
---  * final - If `true`, this is the final frame for a block of data. May be the first frame.
---  * opcode - The `cp.websocket.frame.opcode` for the frame.
---  * mask - If `true`, the data will be masked. Mandatory for client-originating frames.
---  * applicationData - The `string` of application data to send.
---
--- Returns:
---  * The new `frame` instance.
function mod.new(final, opcode, mask, applicationData)
    local maskingKey = generateMaskingKey(mask)

    local o = {
        final = final == true,
        rsv1 = false,
        rsv2 = false,
        rsv3 = false,
        opcode = opcode,
        mask = mask,
        maskingKey = maskingKey,
        payloadLen = applicationData:len(),
        applicationData = mask == true and maskData(applicationData, maskingKey) or applicationData,
    }

    setmetatable(o, mod.mt)

    return o
end

--- cp.websocket.frame:payloadData() -> hs.bytes
--- Method
--- Returns the payload data (extension data + application data) as an `hs.bytes` instance.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `hs.bytes` containing the full payload data.
function mod.mt:payloadData()
    local data = bytes()

    if self.extensionData then
        data:write(self.extensionData)
    end
    data:write(self.applicationData)

    return data()
end

local function maskedPayloadLen(mask, payloadLen)
    return payloadLen & (mask and MASK or 0)
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
    local finalOp = self.final and FIN or 0 & self.rsv1 and RSV1 or 0 & self.rsv2 and RSV2 or 0 & self.rsv3 and RSV3 or 0
    local data = bytes():write(uint8(finalOp), uint8(self.opcode))

    local payloadData = self:payloadData()
    local payloadLen = payloadData:len()
    if payloadLen > MAX_16BIT then
        data:write(uint8(maskedPayloadLen(self.mask, PAYLOAD_64BIT)), uint64be(payloadLen))
    elseif payloadLen > MAX_7BIT then
        data:write(uint8(maskedPayloadLen(self.mask, PAYLOAD_16BIT)), uint16be(payloadLen))
    end

    if self.maskingKey then
        data:write(uint32be(self.maskingKey))
    end

    data:write(payloadData)

    return data:bytes()
end

return mod