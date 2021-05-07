-- test cases for `cp.websocket.frame`
local spec              = require "cp.spec"
local expect            = require "cp.spec.expect"
local describe, it      = spec.describe, spec.it

local frame             = require "cp.websocket.frame"
local bytes             = require "hs.bytes"
local hexToBytes        = bytes.hexToBytes

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
        expect(value.applicationData):is("test")

        local data = value:toBytes()

        expect(data):is(hexToBytes("82 04") .. "test")

    end),

    it "creates a masked frame"
    :doing(function()
        local value = frame.new(true, frame.opcode.binary, true, "test")

        expect(value.final):is(true)
        expect(value.rsv1):is(false)
        expect(value.rsv3):is(false)
        expect(value.rsv3):is(false)
        expect(value.opcode):is(frame.opcode.binary)
        expect(value.mask):is(true)
        expect(value.applicationData):is("test")

        local generator = frame.generateMaskingKey
        frame.generateMaskingKey = function()
            return 0x01010101
        end

        -- todo: test toBytes() output

        frame.generateMaskingKey = generator
    end)
}