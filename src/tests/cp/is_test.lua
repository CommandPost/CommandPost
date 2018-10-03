-- test cases for `cp.is`
local test      = require("cp.test")
local is        = require("cp.is")

local callable = {}
local mt = {
    __call = function() end,
}
setmetatable(callable, mt)

local subcallable = {}
setmetatable(subcallable, callable)

local function newUserdata()
    return require("hs.canvas").new({x=0,y=0,w=1,h=1})
end

return test.suite("cp.is"):with(
    test("nothing", function()
        ok(eq(is.nothing(nil), true))
        ok(eq(is.nothing(0), false))
        ok(eq(is.nothing(false), false))
        ok(eq(is.nothing(""), false))
    end),

    test("string", function()
        ok(eq(is.string("foobar"), true))
        ok(eq(is.string(""), true))
        ok(eq(is.string(nil), false))
        ok(eq(is.string({}), false))
    end),

    test("fn", function()
        ok(eq(is.fn(tostring), true))
        ok(eq(is.fn(function() end), true))
        ok(eq(is.fn(nil), false))
        ok(eq(is.fn(callable), false))
    end),

    test("number", function()
        ok(eq(is.number(1), true))
        ok(eq(is.number(0.1), true))
        ok(eq(is.number("1"), false))
        ok(eq(is.number(true), false))
    end),

    test("boolean", function()
        ok(eq(is.boolean(true), true))
        ok(eq(is.boolean(false), true))
        ok(eq(is.boolean("true"), false))
        ok(eq(is.boolean(nil), false))
    end),

    test("table", function()
        ok(eq(is.table({}), true))
        ok(eq(is.table(callable), true))
        ok(eq(is.table("table"), false))
    end),

    test("userdata", function()
        local c = newUserdata()
        ok(eq(is.userdata(c), true))
        ok(eq(is.userdata(callable), false))
    end),

    test("instance", function()
        local alpha = {}
        local beta = setmetatable({}, {__index = alpha})
        local gamma = setmetatable({}, {__class = alpha, __index = function(_, key) return alpha[key] end})

        local a = setmetatable({}, {__index = alpha})
        local b = setmetatable({}, {__index = beta})
        local g = setmetatable({}, {__index = gamma})

        ok(eq(is.instance(beta, alpha), true))
        ok(eq(is.instance(gamma, alpha), true))
        ok(eq(is.instance(beta, gamma), false))
        ok(eq(is.instance(alpha, beta), false))
        ok(eq(is.instance(alpha, gamma), false))

        ok(eq(is.instance(a, alpha), true))
        ok(eq(is.instance(a, beta), false))
        ok(eq(is.instance(a, gamma), false))

        ok(eq(is.instance(b, alpha), true))
        ok(eq(is.instance(b, beta), true))
        ok(eq(is.instance(b, gamma), false))

        ok(eq(is.instance(g, alpha), true))
        ok(eq(is.instance(g, beta), false))
        ok(eq(is.instance(g, gamma), true))
    end),

    test("object", function()
        ok(eq(is.object({}), true))
        ok(eq(is.object(newUserdata()), true))
        ok(eq(is.object("string"), false))
        ok(eq(is.object(nil), false))
    end),

    test("list", function()
        local list = {1,2}
        ok(eq(is.list({}), false))
        ok(eq(is.list(list), true))
    end),

    test("truthy", function()
        ok(eq(is.truthy(true), true))
        ok(eq(is.truthy(callable), true))
        ok(eq(is.truthy(nil), false))
        ok(eq(is.truthy(false), false))
        ok(eq(is.truthy(0), true))
        ok(eq(is.truthy(1), true))
    end),

    test("falsey", function()
        ok(eq(is.falsey(true), false))
        ok(eq(is.falsey(callable), false))
        ok(eq(is.falsey(nil), true))
        ok(eq(is.falsey(false), true))
        ok(eq(is.falsey(0), false))
        ok(eq(is.falsey(1), false))
    end),

    test("callable", function()
        ok(eq(is.callable(function() end), true))
        ok(eq(is.callable(callable), true))
        ok(eq(is.callable(subcallable), true))
        ok(eq(is.callable({}), false))
        ok(eq(is.callable("string"), false))
    end),

    test("blank", function()
        ok(eq(is.blank(nil), true))
        ok(eq(is.blank(""), true))
        ok(eq(is.blank(" "), false))
        ok(eq(is.blank(0), false))
    end),

    test("is.nt", function()
        ok(eq(is.nt.blank(nil), false))
        ok(eq(is.nt.blank("Hello World!"), true))
    end)
)