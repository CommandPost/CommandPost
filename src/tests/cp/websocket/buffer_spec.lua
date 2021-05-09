local spec              = require "cp.spec"
local expect            = require "cp.spec.expect"
local describe, it      = spec.describe, spec.it

local buffer            = require "cp.websocket.buffer"

-- local log               = require "hs.logger" .new "ws_buff_spec"

return describe "cp.websocket.buffer" {
    it "creates an empty buffer"
    :doing(function()
        local value = buffer.new()

        expect(value:len()):is(0)
        expect(value:peek(1)):is(nil)
        expect(value:pop(1)):is(nil)
    end),

    it "creates a buffer with data"
    :doing(function()
        local value = buffer.new("Hello", " ", "world", "!")

        expect(value:len()):is(12)
        expect(value:peek(3)):is("Hel")
        expect(value:peek(10)):is("Hello worl")

        expect(value:pop(3)):is("Hel")

        expect(value:len()):is(9)

        expect(value:peek(10)):is(nil)
        expect(value:pop(10)):is(nil)

        expect(value:peek(9)):is("lo world!")
        expect(value:pop(9)):is("lo world!")
        expect(value:len()):is(0)
    end),

    it("cycles to the beginning when running out of indexes")
    :doing(function()
        local maxChunks = buffer.maxChunks
        buffer.maxChunks = 5

        -- fill the chunk buffer
        local value = buffer.new("A", "B", "C", "D", "E")

        expect(value:len()):is(5)
        expect(value:peek(5)):is("ABCDE")

        expect(value:pop(2)):is("AB")
        expect(value:len()):is(3)
        expect(value:peek(3)):is("CDE")

        -- add a new chunk, should be at the beginning
        value:push("F")
        expect(value:len()):is(4)
        expect(value:peek(4)):is("CDEF")
        expect(value[0]):is("F")
        expect(value:push("G"):len()):is(5)

        buffer.maxChunks = maxChunks
    end),
}