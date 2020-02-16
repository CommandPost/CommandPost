-- it cases for `hs.bytes`
local spec                  = require "cp.spec"
local expect                = require "cp.spec.expect"
local bytes                 = require "hs.bytes"

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
        it "returns ${output:q} when given `0x${value:02X}`"
        :doing(function(this)
            local output = bytes.int8(this.value)
            expect(output):is(this.output)
        end)
        :where {
            { "value",  "output"    },
            { 0,        "\0"        },
            { -1,       "\255"      },
            { 1,        "\1"        },
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
            { "\1",         nil,        1,          2,          },
            { "\255",       nil,        -1,         2,          },
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

    context "uint8" {
        it "returns ${output:q} when given `0x${value:02X}`"
        :doing(function(this)
            local output = bytes.uint8(this.value)
            expect(output):is(this.output)
        end)
        :where {
            { "value",  "output"    },
            { 0,        "\0"        },
            { 1,        "\1"        },
            { 255,      "\255"      },
        },
        it "returns ${output}, ${offset}, when given ${value:q} and an index of ${index}"
        :doing(function(this)
            local output, offset = bytes.uint8(this.value, this.index)
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
    },

    context "int16be" {
        it "returns ${output:q} when given `0x${value:02X}`"
        :doing(function(this)
            local output = bytes.int16be(this.value)
            expect(output):is(this.output)
        end)
        :where {
            { "value",  "output"    },
            { 0x0000,   "\0\0"      },
            { 0x00FF,   "\0\255"    },
            { 0x0102,   "\01\02"    },
            { -1,       "\255\255"  },
        },

        it "fails when given a number larger than 0xFFFF"
        :doing(function(this)
            this:expectAbort("value is larger than 16 bits: 0xFFFFF")
            bytes.int16be(0xFFFF)
        end),

        it "returns ${output}, ${offset}, when given ${value:q} and an index of ${index}"
        :doing(function(this)
            local output, offset = bytes.int16be(this.value, this.index)
            expect(output):is(this.output)
            expect(offset):is(this.offset)
        end)
        :where {
            { "value",      "index",    "output",   "offset",   },
            { "\0\1",       nil,        1,          3,          },
            { "\255\255",   nil,        -1,         3,          },
            { "\1\2\3",     nil,        0x0102,     3,          },
            { "\1\2\3",     1,          0x0102,     3,          },
            { "\1\2\3",     2,          0x0203,     4,          },
        },

        it "fails when the index is larger than the length of the data"
        :doing(function(this)
            this:expectAbort("need 1 bytes but only 0 are available from index 2")
            -- NOTE: this currently fails due to a bug in cp.spec, not bytes
            -- bytes.int16be("12", 2)
        end),
    },

    context "int16le" {
        it "returns ${output:q} when given `0x${value:02X}`"
        :doing(function(this)
            local output = bytes.int16le(this.value)
            expect(output):is(this.output)
        end)
        :where {
            { "value",  "output"    },
            { 0x0000,   "\0\0"      },
            { 0x00FF,   "\255\0"    },
            { 0x0102,   "\02\01"    },
            { -1,       "\255\255"  },
        },

        it "fails when given a number larger than 0xFFFF"
        :doing(function(this)
            this:expectAbort("value is larger than 16 bits: 0xFFFFF")
            bytes.int16le(0xFFFFF)
        end),

        it "returns ${output}, ${offset}, when given ${value:q} and an index of ${index}"
        :doing(function(this)
            local output, offset = bytes.int16le(this.value, this.index)
            expect(output):is(this.output)
            expect(offset):is(this.offset)
        end)
        :where {
            { "value",      "index",    "output",   "offset",   },
            { "\1\0",       nil,        1,          3,          },
            { "\255\255",   nil,        -1,         3,          },
            { "\1\2\3",     nil,        0x0201,     3,          },
            { "\1\2\3",     1,          0x0201,     3,          },
            { "\1\2\3",     2,          0x0302,     4,          },
        },

        it "fails when the index is larger than the length of the data"
        :doing(function(this)
            this:expectAbort("need 1 bytes but only 0 are available from index 2")
            -- NOTE: this currently fails due to a bug in cp.spec, not bytes
            -- bytes.int16le("12", 2)
        end),
    },

    context "int32be" {
        it "returns ${output:q} when given `0x${value:04X}`"
        :doing(function(this)
            local output = bytes.int32be(this.value)
            expect(output):is(this.output)
        end)
        :where {
            { "value",      "output"            },
            { 0x00,         "\0\0\0\0"          },
            { 0xFF,         "\0\0\0\255"        },
            { 0x0102,       "\0\0\1\2"          },
            { -1,           "\255\255\255\255"  },
        },

        it "fails when given a number larger than 0xFFFFFFFF"
        :doing(function(this)
            this:expectAbort("value is larger than 32 bits: 0xFFFFFFFFF")
            bytes.int32be(0xFFFFFFFFF)
        end),

        it "returns ${output}, ${offset}, when given ${value:q} and an index of ${index}"
        :doing(function(this)
            local output, offset = bytes.int32be(this.value, this.index)
            expect(output):is(this.output)
            expect(offset):is(this.offset)
        end)
        :where {
            { "value",              "index",    "output",       "offset",   },
            { "\0\0\0\0",           nil,        0x00,           5,          },
            { "\0\0\0\1",           nil,        0x01,           5,          },
            { "\255\255\255\255",   nil,        -1,             5,          },
            { "\1\2\3\4\5\6",       nil,        0x01020304,     5,          },
            { "\1\2\3\4\5\6",       1,          0x01020304,     5,          },
            { "\1\2\3\4\5\6",       3,          0x03040506,     7,          },
        },

        it "fails when the index is larger than the length of the data"
        :doing(function(this)
            this:expectAbort("need 1 bytes but only 0 are available from index 2")
            -- NOTE: this currently fails due to a bug in cp.spec, not bytes
            -- bytes.int32be("1234", 2)
        end),
    },

    context "int32le" {
        it "returns ${output:q} when given `0x${value:04X}`"
        :doing(function(this)
            local output = bytes.int32le(this.value)
            expect(output):is(this.output)
        end)
        :where {
            { "value",      "output"            },
            { 0x00,         "\0\0\0\0"          },
            { 0xFF,         "\255\0\0\0"        },
            { 0x0102,       "\2\1\0\0"          },
            { -1,           "\255\255\255\255"  },
        },

        it "fails when given a number larger than 0xFFFFFFFF"
        :doing(function(this)
            this:expectAbort("value is larger than 32 bits: 0xFFFFFFFFF")
            bytes.int32le(0xFFFFFFFFF)
        end),

        it "returns ${output}, ${offset}, when given ${value:q} and an index of ${index}"
        :doing(function(this)
            local output, offset = bytes.int32le(this.value, this.index)
            expect(output):is(this.output)
            expect(offset):is(this.offset)
        end)
        :where {
            { "value",              "index",    "output",       "offset",   },
            { "\0\0\0\0",           nil,        0x00000000,     5,          },
            { "\0\0\0\1",           nil,        0x01000000,     5,          },
            { "\255\255\255\255",   nil,        -1,             5,          },
            { "\1\2\3\4\5\6",       nil,        0x04030201,     5,          },
            { "\1\2\3\4\5\6",       1,          0x04030201,     5,          },
            { "\1\2\3\4\5\6",       3,          0x06050403,     7,          },
        },

        it "fails when the index is larger than the length of the data"
        :doing(function(this)
            this:expectAbort("need 4 bytes but only 3 are available from index 2")
            -- NOTE: this currently fails due to a bug in cp.spec, not bytes
            -- bytes.int32le("1234", 2)
        end),
    },

    context "uint32be" {
        it "returns ${output:q} when given `0x${value:04X}`"
        :doing(function(this)
            local output = bytes.uint32be(this.value)
            expect(output):is(this.output)
        end)
        :where {
            { "value",      "output"            },
            { 0x00,         "\0\0\0\0"          },
            { 0xFF,         "\0\0\0\255"        },
            { 0x0102,       "\0\0\1\2"          },
            { 0xFFFFFFFF,   "\255\255\255\255"  },
        },

        it "fails when given a number larger than 0xFFFFFFFF"
        :doing(function(this)
            this:expectAbort("value is larger than 32 bits: 0xFFFFFFFFF")
            bytes.int32be(0xFFFFFFFFF)
        end),

        it "returns ${output}, ${offset}, when given ${value:q} and an index of ${index}"
        :doing(function(this)
            local output, offset = bytes.uint32be(this.value, this.index)
            expect(output):is(this.output)
            expect(offset):is(this.offset)
        end)
        :where {
            { "value",              "index",    "output",       "offset",   },
            { "\0\0\0\0",           nil,        0x00,           5,          },
            { "\0\0\0\1",           nil,        0x01,           5,          },
            { "\255\255\255\255",   nil,        0xFFFFFFFF,     5,          },
            { "\1\2\3\4\5\6",       nil,        0x01020304,     5,          },
            { "\1\2\3\4\5\6",       1,          0x01020304,     5,          },
            { "\1\2\3\4\5\6",       3,          0x03040506,     7,          },
        },

        it "fails when the index is larger than the length of the data"
        :doing(function(this)
            this:expectAbort("need 1 bytes but only 0 are available from index 2")
            -- NOTE: this currently fails due to a bug in cp.spec, not bytes
            -- bytes.int32be("1234", 2)
        end),
    },

    context "int64be" {
        it "returns ${output:q} when given `${value:04X}`"
        :doing(function(this)
            local output = bytes.int64be(this.value)
            expect(output):is(this.output)
        end)
        :where {
            { "value",              "output"                            },
            { 0x00,                 "\0\0\0\0\0\0\0\0"                  },
            { 0x00FF00FF,           "\0\0\0\0\0\255\0\255"              },
            { 0x0102,               "\0\0\0\0\0\0\1\2"                  },
            { 0xFFFFFFFFFFFFFFFF,   "\255\255\255\255\255\255\255\255"  },
        },

        it "returns ${output}, ${offset}, when given ${value:q} and an index of ${index}"
        :doing(function(this)
            local output, offset = bytes.int64be(this.value, this.index)
            expect(output):is(this.output)
            expect(offset):is(this.offset)
        end)
        :where {
            { "value",                              "index",    "output",           "offset",   },
            { "\0\0\0\0\0\0\0\0",                   nil,        0x00,               9,          },
            { "\0\0\0\0\0\0\0\1",                   nil,        0x01,               9,          },
            { "\255\255\255\255\255\255\255\255",   nil,        0xFFFFFFFFFFFFFFFF, 9,          },
            { "\1\2\3\4\5\6\7\8\9\10",              nil,        0x0102030405060708, 9,          },
            { "\1\2\3\4\5\6\7\8\9\10",              1,          0x0102030405060708, 9,          },
            { "\1\2\3\4\5\6\7\8\9\10",              3,          0x030405060708090A, 11,         },
        },

        it "fails when the index is larger than the length of the data"
        :doing(function(this)
            this:expectAbort("need 8 bytes but only 3 are available from index 2")
            -- NOTE: this currently fails due to a bug in cp.spec, not bytes
            -- bytes.int64be("12345678", 2)
        end),
    },

    context "int64le" {
        it "returns ${output:q} when given `${value:08X}`"
        :doing(function(this)
            local output = bytes.int64le(this.value)
            expect(output):is(this.output)
        end)
        :where {
            { "value",              "output"                            },
            { 0x00,                 "\0\0\0\0\0\0\0\0"                  },
            { 0x0000000000FF00FF,   "\255\0\255\0\0\0\0\0"              },
            { 0x0000000000000102,   "\2\1\0\0\0\0\0\0"                  },
            { 0xFFFFFFFFFFFFFFFF,   "\255\255\255\255\255\255\255\255"  },
        },

        it "returns ${output}, ${offset}, when given ${value:q} and an index of ${index}"
        :doing(function(this)
            local output, offset = bytes.int64le(this.value, this.index)
            expect(output):is(this.output)
            expect(offset):is(this.offset)
        end)
        :where {
            { "value",                              "index",    "output",           "offset",   },
            { "\0\0\0\0\0\0\0\0",                   nil,        0x00,               9,          },
            { "\1\0\0\0\0\0\0\0",                   nil,        0x01,               9,          },
            { "\255\255\255\255\255\255\255\255",   nil,        0xFFFFFFFFFFFFFFFF, 9,          },
            { "\1\2\3\4\5\6\7\8\9\10",              nil,        0x0807060504030201, 9,          },
            { "\1\2\3\4\5\6\7\8\9\10",              1,          0x0807060504030201, 9,          },
            { "\1\2\3\4\5\6\7\8\9\10",              3,          0x0A09080706050403, 11,         },
        },

        it "fails when the index is larger than the length of the data"
        :doing(function(this)
            this:expectAbort("need 8 bytes but only 3 are available from index 2")
            -- NOTE: this currently fails due to a bug in cp.spec, not bytes
            -- bytes.int64le("12345678", 2)
        end),
    },

    context "bytes:write" {
        it "doesn't concatenate until bytes are retrieved"
        :doing(function()
            local data = bytes()
            data:write("one", "two", "three")
            expect(data._data):is({"one", "two", "three"})
        end),

        it "adds all values passed to the constructor"
        :doing(function()
            local data = bytes("one", "two", "three")
            expect(data._data):is({"one", "two", "three"})
        end),

        it "concatenates when retrieving bytes"
        :doing(function()
            local data = bytes("one", "two", "three")
            expect(data:bytes()):is("onetwothree")
            expect(#data._data):is(1)
            expect(data._data[1]):is("onetwothree")
        end),
    },

    context "bytes.read" {
        it "reads a single int8 value from a string"
        :doing(function()
            local x, y = bytes.read("\1\2\3", bytes.int8)
            expect(x):is(1)
            expect(y):is(nil)
        end),

        it "reads multiple int8 values from a string"
        :doing(function()
            local x, y, z = bytes.read("\1\2\3", bytes.int8, bytes.int8, bytes.int8)
            expect(x):is(1)
            expect(y):is(2)
            expect(z):is(3)
        end),

        it "reads multiple types of values from a string"
        :doing(function()
            local a, b, c, d, e, f, g, exactly, remainder = bytes.read(
                "\1\0\2\3\0\0\0\0\4\5\0\0\0\0\0\0\0\0\0\0\6\7\0\0\0\0\0\0\0exactlyremainder",
                bytes.int8, bytes.int16be, bytes.int16le, bytes.int32be, bytes.int32le, bytes.int64be, bytes.int64le,
                bytes.exactly(7), bytes.remainder
            )

            expect(a):is(1)
            expect(b):is(2)
            expect(c):is(3)
            expect(d):is(4)
            expect(e):is(5)
            expect(f):is(6)
            expect(g):is(7)
            expect(exactly):is("exactly")
            expect(remainder):is("remainder")
        end)
    }
}