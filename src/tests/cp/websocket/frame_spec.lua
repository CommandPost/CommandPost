-- test cases for `cp.websocket.frame`
local spec              = require "cp.spec"
local expect            = require "cp.spec.expect"
local describe, it      = spec.describe, spec.it

local buffer            = require "cp.websocket.buffer"

local frame             = require "cp.websocket.frame"
local bytes             = require "hs.bytes"

local hexToBytes        = bytes.hexToBytes
local uint8             = bytes.uint8
local uint32be          = bytes.uint32be

return describe "cp.websocket.frame" {
    it "creates a unmasked frame"
    :doing(function()
        local value = frame.new(true, frame.opcode.binary, false, "test")

        expect(value.final):is(true)
        expect(value.rsv1):is(false)
        expect(value.rsv3):is(false)
        expect(value.rsv3):is(false)
        expect(value.opcode):is(frame.opcode.binary)
        expect(value.mask):is(false)
        expect(value.payloadData):is("test")

        local data = value:toBytes()

        expect(data):is(hexToBytes("82 04") .. "test")

    end),

    it "creates a masked frame"
    :doing(function()
        local value = frame.new(true, frame.opcode.binary, true, hexToBytes("07 02 02 15"))

        expect(value.final):is(true)
        expect(value.rsv1):is(false)
        expect(value.rsv3):is(false)
        expect(value.rsv3):is(false)
        expect(value.opcode):is(frame.opcode.binary)
        expect(value.mask):is(true)
        expect(value.payloadData):is(hexToBytes("07 02 02 15"))

        local generator = frame.generateMaskingKey
        frame.generateMaskingKey = function()
            return 0x01010101
        end

        local data = value:toBytes()

        expect(data):is(hexToBytes("82 84 01 01 01 01 06 03 03 14"))

        frame.generateMaskingKey = generator
    end),

    it "returns ${result} when masking ${data} with ${key}"
    :doing(function(this)
        local dataBytes = hexToBytes(this.data)
        local value = frame.new(true, frame.opcode.binary, true, dataBytes)

        local generator = frame.generateMaskingKey
        frame.generateMaskingKey = function()
            return this.key
        end

        local data = value:toBytes()

        local resultBytes = hexToBytes(this.result)

        local expected = bytes(uint8(0x82), uint8(0x80 | #resultBytes), uint32be(this.key), resultBytes)
        expect(data):is(expected:bytes())

        frame.generateMaskingKey = generator
    end)
    :where {
        { "data", "key", "result" },
        { "48656c6c6f", 0x37fa213d, "7f9f4d5158" }, -- "Hello"
        { "07020215", 0x01010101, "06030314" },
        { "9bce62d5", 0x12345678, "89fa34ad" },
        { "9bce62d5 21ed7dc6", 0x12345678, "89fa34ad 33d92bbe" },
        { "9bce62d5 21ed7dc6 675e2082 4af61729", 0x12345678, "89fa34ad 33d92bbe 756a76fa 58c24151" },
    },

    it "reads an unmasked text message"
    :doing(function()
        local buff = buffer.fromHex("81 05 48 65 6c 6c 6f") -- "Hello"

        expect(buff:len()):is(7)

        local outcome = frame.fromBuffer(buff)
        expect(outcome.value.bytes):is(7)

        local value = outcome.value.frame

        expect(value.final):is(true)
        expect(value.rsv1):is(false)
        expect(value.rsv3):is(false)
        expect(value.rsv3):is(false)
        expect(value.opcode):is(frame.opcode.text)
        expect(value.mask):is(false)
        expect(value.payloadData):is("Hello")

        expect(buff:len()):is(0)
    end),

    it "reads a masked text message"
    :doing(function()
        local buff = buffer.fromHex("81 85 37 fa 21 3d 7f 9f 4d 51 58") -- "Hello"

        expect(buff:len()):is(11)

        local outcome = frame.fromBuffer(buff)
        expect(outcome.value.bytes):is(11)

        local value = outcome.value.frame

        expect(value.final):is(true)
        expect(value.rsv1):is(false)
        expect(value.rsv3):is(false)
        expect(value.rsv3):is(false)
        expect(value.opcode):is(frame.opcode.text)
        expect(value.mask):is(true)
        expect(value.payloadData):is("Hello")

        expect(buff:len()):is(0)
    end),

    it "doesn't read an incomplete frame"
    :doing(function()
        local buff = buffer.fromHex("81 05 48 65 6c 6c") -- "Hell"
        local outcome = frame.fromBuffer(buff)

        expect(outcome.failure):is(true)
    end),

    it "doesn't consume unused bytes"
    :doing(function()
        local buff = buffer.fromHex("81 05 48 65 6c 6c 6f FF") -- "Hello" + 0xFF
        local outcome = frame.fromBuffer(buff)

        expect(outcome.success):is(true)

        expect(outcome.value.bytes):is(7)
        expect(outcome.value.frame.payloadData):is("Hello")
        expect(buff:len()):is(1)
    end),

    it "reads a string of bytes"
    :doing(function()
        local data = hexToBytes("81 05 48 65 6c 6c 6f FF") -- "Hello" + 0xFF

        expect(data:len()):is(8)

        local outcome = frame.fromBytes(data)
        expect(outcome.value.bytes):is(7)

        local value = outcome.value.frame

        expect(value.final):is(true)
        expect(value.rsv1):is(false)
        expect(value.rsv3):is(false)
        expect(value.rsv3):is(false)
        expect(value.opcode):is(frame.opcode.text)
        expect(value.mask):is(false)
        expect(value.payloadData):is("Hello")

        expect(data:len()):is(8)
    end),
}