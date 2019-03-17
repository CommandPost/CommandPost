-- it cases for `cp.is`
local spec                  = require("cp.spec")
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
            assert(is.nothing(this.input) == this.result)
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
        :where( "input",    "result")
        :is(
            {   "foobar",   true    },
            {   "",         true    },
            {   nil,        false   },
            {   {},         false   }
        ),
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
        ok(eq(is.truthy(true), true))
        ok(eq(is.truthy(callable), true))
        ok(eq(is.truthy(nil), false))
        ok(eq(is.truthy(false), false))
        ok(eq(is.truthy(0), true))
        ok(eq(is.truthy(1), true))
    end),

    it("falsey", function()
        ok(eq(is.falsey(true), false))
        ok(eq(is.falsey(callable), false))
        ok(eq(is.falsey(nil), true))
        ok(eq(is.falsey(false), true))
        ok(eq(is.falsey(0), false))
        ok(eq(is.falsey(1), false))
    end),

    it("callable", function()
        ok(eq(is.callable(function() end), true))
        ok(eq(is.callable(callable), true))
        ok(eq(is.callable(subcallable), true))
        ok(eq(is.callable({}), false))
        ok(eq(is.callable("string"), false))
    end),

    it("blank", function()
        ok(eq(is.blank(nil), true))
        ok(eq(is.blank(""), true))
        ok(eq(is.blank(" "), false))
        ok(eq(is.blank(0), false))
    end),

    it("is.nt", function()
        ok(eq(is.nt.blank(nil), false))
        ok(eq(is.nt.blank("Hello World!"), true))
    end)
}