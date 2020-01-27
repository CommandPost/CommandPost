-- it cases for `hs.bytes`
local spec                  = require "cp.spec"
local expect                = require "cp.spec.expect"
local bytes                    = require "hs.bytes"

local describe, it, context = spec.describe, spec.it, spec.context

return describe "hs.bytes" {
    context "bytesToHex" {
        it "returns ${output:q} when given ${data:q} with lowerCase of ${lowerCase} and spacer of ${spacer:q}"
        :doing(function(this)
            expect(bytes.bytesToHex(this.data, this.lowerCase, this.spacer)):is(this.output)
        end)
        :where {
            { "data",       "lowerCase",    "spacer",   "output",   },
            { "\0\1\255",   nil,            nil,        "0001FF"    },
            { "\0\1\255",   true,           nil,        "0001ff"    },
            { "\0\1\255",   nil,            "-",        "00-01-FF"  },
            { "\0\1\255",   true,           ":",        "00:01:ff"  },
        }
    },

    context "int8" {
        it "returns ${output:q} when given `${value:02X}`"
        :doing(function(this)
            local output = bytes.int8(this.value)
            expect(output):is(this.output)
        end)
        :where {
            { "value",  "output"    },
            { 0x00,     "\0"        },
            { 0xFF,     "\255"      },
        },

        it "fails when given a number larger than 0xFF"
        :doing(function(this)
            this:expectAbort("value is larger than 8 bits: 0x0FFF")
            bytes.int8(0xFFF)
        end),

        it "returns ${output}, ${offset}, when given ${value:q} and an index of ${index}"
        :doing(function(this)
            local output, offset = bytes.int8(this.value, this.index)
            expect(output):is(this.output)
            expect(offset):is(this.offset)
        end)
        :where {
            { "value",      "index",    "output",   "offset",   },
            { "\1",         nil,        0x01,       2,          },
            { "\255",       nil,        0xFF,       2,          },
            { "\1\2\3",     nil,        0x01,       2,          },
            { "\1\2\3",     1,          0x01,       2,          },
            { "\1\2\3",     2,          0x02,       3,          },
            { "\1\2\3",     2,          0x02,       3,          },
            { "\1\2\3",     3,          0x03,       4,          },
        },

        it "fails when the index is larger than the length of the data"
        :doing(function(this)
            this:expectAbort("need 1 bytes but only 0 are available from index 2")
            bytes.int8("1", 2)
        end),
    },

    context "int16be" {
        it "returns ${output:q} when given `${value:02X}`"
        :doing(function(this)
            local output = bytes.int16be(this.value)
            expect(output):is(this.output)
        end)
        :where {
            { "value",  "output"    },
            { 0x00,     "\0\0"      },
            { 0xFF,     "\0\255"    },
            { 0x12,     "\0\18"     },
            { 0xFFFF,   "\255\255"  },
        },

        it "fails when given a number larger than 0xFF"
        :doing(function(this)
            this:expectAbort("value is larger than 16 bits: 0xFFFFF")
            bytes.int16be(0xFFFFF)
        end),

        it "returns ${output}, ${offset}, when given ${value:q} and an index of ${index}"
        :doing(function(this)
            local output, offset = bytes.int16be(this.value, this.index)
            expect(output):is(this.output)
            expect(offset):is(this.offset)
        end)
        :where {
            { "value",      "index",    "output",   "offset",   },
            { "\0\1",       nil,        0x01,       3,          },
            { "\255\255",   nil,        0xFFFF,     3,          },
            { "\1\2\3",     nil,        0x0102,     3,          },
            { "\1\2\3",     1,          0x0102,     3,          },
            { "\1\2\3",     2,          0x0203,     4,          },
        },

        it "fails when the index is larger than the length of the data"
        :doing(function(this)
            this:expectAbort("need 1 bytes but only 0 are available from index 2")
            bytes.int16be("12", 2)
        end),
    },

    context "bytes:write" {
        it "doesn't concatenate until bytes are retrieved"
        :doing(function()
            local data = bytes()

            data:write("one", "two", "three")

            expect(data._data):is({"one", "two", "three"})
        end)
    },
}