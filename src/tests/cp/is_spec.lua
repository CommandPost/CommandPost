-- it cases for `cp.is`
local spec                  = require("cp.spec")
local expect                = require("cp.spec.expect")
local is                    = require("cp.is")

local describe, it, context = spec.describe, spec.it, spec.context

local callable = {}
local mt = {
    __call = function() end,
}
setmetatable(callable, mt)

local subcallable = {}
setmetatable(subcallable, callable)

-- an example of a `userdata` value.
local function newUserdata()
    return require("hs.canvas").new({x=0,y=0,w=1,h=1})
end

return describe "cp.is" {
    context "calling `nothing`" {
        it "returns ${result} when given ${input}"
        :doing(function(this)
            expect(is.nothing(this.input)):is(this.result)
        end)
        :where {
            { "input",  "result"    },
            { nil,      true        },
            { 0,        false       },
            { false,    false       },
            { "",       false       },
        },
    },

    context "calling `string`" {
        it "returns ${result} when given ${input}"
        :doing(function(this)
            assert(is.string(this.input) == this.result)
        end)
        :where {
            {   "input",    "result"},
            {   "foobar",   true    },
            {   "",         true    },
            {   nil,        false   },
            {   {},         false   }
        },
    },

    context "calling `fn`" {
        it "returns ${result} when given ${type}"
        :doing(function(this)
            assert(is.fn(this.input) == this.result)
        end)
        :where {
            { "type",           "input",          "result"    },
            { "tostring",       tostring,         true        },
            { "closure",        function() end,   true        },
            { "nil",            nil,              false       },
            { "empty table",    {},               false       },
            { "callable table", callable,         false       },
        },
    },

    context "calling `number`" {
        it "returns ${result} when given ${input}"
        :doing(function(this)
            assert(is.number(this.input) == this.result)
        end)
        :where {
            { "input",      "result"    },
            { 1,            true        },
            { 0.1,          true        },
            { "1",          false       },
            { true,         false       },
        },
    },

    context "calling `boolean`" {
        it "returns ${result} when given ${input}"
        :doing(function(this)
            assert(is.boolean(this.input) == this.result)
        end)
        :where {
            { "input",      "result"    },
            { true,         true        },
            { false,        true        },
            { "true",       false       },
            { nil,          false       },
        },
    },

    context "calling `table`" {
        it "returns ${result} when given ${input}"
        :doing(function(this)
            assert(is.table(this.input) == this.result)
        end)
        :where {
            { "type",       "input",        "result"    },
            { "table",      {},             true        },
            { "callable",   callable,       true        },
            { "string",     "table",        false       },
        },
    },

    context "calling `userdata`" {
        it "returns ${result} when given ${type}"
        :doing(function(this)
            assert(is.userdata(this.input) == this.result)
        end)
        :where {
            { "type",           "input",          "result"    },
            { "userdata",       newUserdata(),    true        },
            { "table",          {},               false       },
            { "callable",       callable,         false       },
        },
    },


    context "calling `instance`" {
        it "returns true when given a class or subclass"
        :doing(function()
            local alpha = {}
            local beta = setmetatable({}, {__index = alpha})
            local gamma = setmetatable({}, {__class = alpha, __index = function(_, key) return alpha[key] end})

            local a = setmetatable({}, {__index = alpha})
            local b = setmetatable({}, {__index = beta})
            local g = setmetatable({}, {__index = gamma})

            assert(is.instance(beta, alpha) == true)
            assert(is.instance(gamma, alpha) == true)
            assert(is.instance(beta, gamma) == false)
            assert(is.instance(alpha, beta) == false)
            assert(is.instance(alpha, gamma) == false)

            assert(is.instance(a, alpha) == true)
            assert(is.instance(a, beta) == false)
            assert(is.instance(a, gamma) == false)

            assert(is.instance(b, alpha) == true)
            assert(is.instance(b, beta) == true)
            assert(is.instance(b, gamma) == false)

            assert(is.instance(g, alpha) == true)
            assert(is.instance(g, beta) == false)
            assert(is.instance(g, gamma) == true)
        end),
    },

    context "calling `object`" {
        it "returns ${result} when given ${type}"
        :doing(function(this)
            assert(is.object(this.input) == this.result)
        end)
        :where {
            { "type",       "input",        "result"    },
            { "table",      {},             true        },
            { "userdata",   newUserdata(),  true        },
            { "string",     "string",       false       },
            { "nil",        nil,            false       },
        },
    },

    it("list", function()
        local list = {1,2}
        assert(is.list({}) == false)
        assert(is.list(list) == true)
    end),

    it("truthy", function()
        expect(is.truthy(true)):is(true)
        expect(is.truthy(callable)):is(true)
        expect(is.truthy(nil)):is(false)
        expect(is.truthy(false)):is(false)
        expect(is.truthy(0)):is(true)
        expect(is.truthy(1)):is(true)
    end),

    it("falsey", function()
        expect(is.falsey(true)):is(false)
        expect(is.falsey(callable)):is(false)
        expect(is.falsey(nil)):is(true)
        expect(is.falsey(false)):is(true)
        expect(is.falsey(0)):is(false)
        expect(is.falsey(1)):is(false)
    end),

    it("callable", function()
        expect(is.callable(function() end)):is(true)
        expect(is.callable(callable)):is(true)
        expect(is.callable(subcallable)):is(true)
        expect(is.callable({})):is(false)
        expect(is.callable("string")):is(false)
    end),

    it("blank", function()
        expect(is.blank(nil)):is(true)
        expect(is.blank("")):is(true)
        expect(is.blank(" ")):is(false)
        expect(is.blank(0)):is(false)
    end),

    it("is.nt", function()
        expect(is.nt.blank(nil)):is(false)
        expect(is.nt.blank("Hello World!")):is(true)
    end)
}