-- local log           = require("hs.logger").new("rxgotils")
-- local inspect       = require("hs.inspect")

local test          = require("cp.test")

local prop          = require("cp.prop")
local Statement     = require("cp.rx.go.Statement")
local SetProp       = require("cp.rx.go.SetProp")

local insert = table.insert

return test.suite("cp.rx.go.SetProp"):with {

    test("SetProp.To", function()
        ok(Statement.Definition.is(SetProp), "SetProp is not a Statement Definition")
        ok(Statement.Modifier.Definition.is(SetProp.To), "SetProp.To is not a Statment.Modifier")

        local aProp = prop.THIS("foo")
        local result = SetProp(aProp):To("bar")

        ok(SetProp.To.is(result), "result is not a SetProp.To")
        ok(Statement.is(result), "result is not a Statement")

        ok(eq(aProp(), "foo"))

        result:Now(function(value)
            ok(eq(value, "bar"))
        end)

        ok(eq(aProp(), "bar"))
    end),

    test("SetProp.To.Then", function()
        ok(Statement.Modifier.Definition.is(SetProp.To.Then))

        local aProp = prop.THIS("foo")
        local result = SetProp(aProp):To("bar")
        :Then(function(value)
            ok(eq(value, "bar"))
            return "yada"
        end)

        ok(Statement.Modifier.is(result), "SetProp.To:Then is not a Statement.Modifier")

        ok(eq(aProp(), "foo"))

        result:Now(function(value)
            ok(eq(value, "yada"))
        end)

        ok(eq(aProp(), "bar"))
    end),

    test("SetProp.To.Then.ThenReset", function()
        ok(Statement.Modifier.Definition.is(SetProp.To.Then))

        local thenValue = nil

        local aProp = prop.THIS("foo")
        local result = SetProp(aProp):To("bar")
        :Then(function(value)
            ok(eq(value, "bar"))
            thenValue = value
            return "yada"
        end)
        :ThenReset()

        ok(Statement.Modifier.is(result), "SetProp.To:Then is not a Statement.Modifier")

        ok(eq(aProp(), "foo"))
        ok(eq(thenValue, nil))

        result:Now(function(value)
            ok(eq(value, "yada"))
        end)

        ok(eq(aProp(), "foo"))
        ok(eq(thenValue, "bar"))
    end),

    test("SetProp.To.Then Error", function()
        local results = {}
        local message = nil
        local completed = false

        local aProp = prop.THIS("foo")
        SetProp(aProp):To("bar")
        :Then(function()
            error "message"
        end)
        :Now(
            function(value)
                insert(results, value)
            end,
            function(msg)
                message = msg
            end,
            function()
                completed = true
            end
        )

        ok(eq(results, {}))
        ok(neq(message, nil))
        ok(eq(completed, false))
    end),
}