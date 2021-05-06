--- === cp.websocket.frame ===
---
--- Implementation of [RFC-6455](https://tools.ietf.org/html/rfc6455), Section 5
---
--- Reads and writes data to and from websocket frame wire protocol data.

local log               = require "hs.logger" .new "wsframe"

local bytes             = require "hs.bytes"

local bytesToHex        = bytes.bytesToHex
local hexToBytes        = bytes.hexToBytes
local int16be           = bytes.int16be
local int8              = bytes.int8
local remainder         = bytes.remainder
local uint16be          = bytes.uint16be
local uint16le          = bytes.uint16le
local uint24be          = bytes.uint24be
local uint32be          = bytes.uint32be
local uint64be          = bytes.unit64be
local uint8             = bytes.uint8

local stringbyte = string.byte

local mod = {}

local FIN               = 1 << 7    -- 0b10000000
local RSV1              = 1 << 6    -- 0b01000000
local RSV2              = 1 << 5    -- 0b00100000
local RSV3              = 1 << 4    -- 0b00010000
local OPCODE            = 0xF       -- 0b00001111

local MASK              = 1 << 7    -- 0b10000000
local PAYLOAD_LEN       = 0x7F      -- 0b01111111
local PAYLOAD_16BIT     = 126
local PAYLOAD_64BIT     = 127

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

-- payloadLen(data, index) -> number, number
-- Function
--
-- A `bytes` reader function that reads from the data `string`, starting at `index`,
-- returning the total payload length and the next byte `index` to read.
--
-- Parameters:
--  * data  - The `string` of bits to read.
--  * index - The index to read from (typically `1`) for this field.
local function payloadLen(data, index)
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
--
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

--- cp.websocket.frame.readFrame(data[, extensionLen]) -> frame | nil
--- Function
---
--- Reads a Websocket Frame from the provided `string` of binary data.
---
--- Parameters:
---  * data - The `string` of bytes to read from.
---  * extensionLen - An optional number indicating the number of expected extension bytes.
---
--- Returns:
---  * The `string` of binary payload data, or `nil` if the data was invalid.
function mod.readFrame(data, extensionLen)
    if data:len() < 2 then
        return nil
    end

    local frame = {}

    -- read the FIN/RSV/OPCODE byte
    local finOp = bytes.read(data, uint8)
    local nextIndex = 2

    frame.fin = isSet(finOp, FIN)
    frame.rsv1 = isSet(finOp, RSV1)
    frame.rsv2 = isSet(finOp, RSV2)
    frame.rsv3 = isSet(finOp, RSV3)

    -- Reserved bits only allowed if extensions have been negotiated on the handshake.
    if extensionLen == nil and (frame.rsv1 or frame.rsv2 or frame.rsv3) then
        return nil
    end

    frame.opcode = finOp & OPCODE

    -- read the MASK
    frame.mask = isSet(bytes.read(data, nextIndex, uint8), MASK)
    -- read the full payload length, taking into account extended bytes.
    frame.payloadLen, nextIndex = payloadLen(data, nextIndex)

    if frame.mask then
        frame.maskingKey = bytes.read(data, nextIndex, uint32be)
        nextIndex = nextIndex + 4
    end

    local payloadData = data:sub(nextIndex)

    if frame.mask then
        payloadData = maskData(payloadData, frame.maskingKey)
    end

    if extensionLen ~= nil then
        frame.extensionData = payloadData:sub(1, extensionLen)
        payloadData = payloadData:sub(extensionLen)
    end

    frame.applicationData = payloadData

    return frame
end

return mod