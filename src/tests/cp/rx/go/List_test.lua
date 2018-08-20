local test          = require("cp.test")

local List          = require("cp.rx.go.List")
local prop          = require("cp.prop")

local insert        = table.insert


return test.suite("cp.rx.go.List"):with {
    test("List", function()
        local results = {}
        local error = nil
        local completed = true

        List({1,2,3})
        :Now(
            function(value)
                insert(results, value)
            end,
            function(message)
                error = message
            end,
            function()
                completed = true
            end
        )

        ok(eq(results, {1,2,3}))
        ok(eq(error, nil))
        ok(eq(completed, true))
    end),

    test("Empty List", function()
        local results = {}
        local error = nil
        local completed = true

        List({})
        :Now(
            function(value)
                insert(results, value)
            end,
            function(message)
                error = message
            end,
            function()
                completed = true
            end
        )

        ok(eq(results, {}))
        ok(eq(error, nil))
        ok(eq(completed, true))
    end),

    test("List from function", function()
        local results = {}
        local error = nil
        local completed = true

        List(function() return {1,2,3} end)
        :Now(
            function(value)
                insert(results, value)
            end,
            function(message)
                error = message
            end,
            function()
                completed = true
            end
        )

        ok(eq(results, {1,2,3}))
        ok(eq(error, nil))
        ok(eq(completed, true))
    end),

    test("List from prop", function()
        local results = {}
        local error = nil
        local completed = true

        local source = prop.THIS({1,2,3})
        ok(source(), {1,2,3})

        List(source)
        :Now(
            function(value)
                insert(results, value)
            end,
            function(message)
                error = message
            end,
            function()
                completed = true
            end
        )

        ok(eq(results, {1,2,3}))
        ok(eq(error, nil))
        ok(eq(completed, true))
    end)
}