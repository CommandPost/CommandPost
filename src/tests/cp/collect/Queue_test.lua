local test          = require("cp.test")
local Queue          = require("cp.collect.Queue")

return test.suite("cp.collect.Queue"):with {
    test("new", function()
        -- the `new` method directly
        local q = Queue.new()
        ok(eq(#q, 0))

        -- alternate method, with default items
        q = Queue(1, 2, 3)
        ok(eq(#q, 3))
        ok(eq(q[1], 1))
        ok(eq(q[2], 2))
        ok(eq(q[3], 3))
    end),

    test("pushRight", function()
        local q = Queue.new()

        q:pushRight(true)
        ok(eq(q[1], true))
        ok(eq(#q, 1))
    end),

    test("pushLeft", function()
        local q = Queue.new()

        q:pushLeft(true)
        ok(eq(q[1], true))
        ok(eq(#q, 1))
    end),

    test("peek", function()
        local q = Queue.new(1, 2)

        ok(eq(q:peekRight(), 2))
        ok(eq(#q, 2))
        ok(eq(q:peekLeft(), 1))
        ok(eq(#q, 2))
    end),

    test("popRight", function()
        local q = Queue(1, 2, 3)

        ok(eq(q:popRight(), 3))
        ok(eq(#q, 2))
        ok(eq(q:popRight(), 2))
        ok(eq(#q, 1))
        ok(eq(q:popRight(), 1))
        ok(eq(#q, 0))
    end),

    test("popLeft", function()
        local q = Queue(1, 2, 3)

        ok(eq(q:popLeft(), 1))
        ok(eq(#q, 2))
        ok(eq(q[1], 2))
        ok(eq(q:popLeft(), 2))
        ok(eq(#q, 1))
        ok(eq(q[1], 3))
        ok(eq(q:popLeft(), 3))
        ok(eq(#q, 0))
        ok(eq(q[1], nil))
    end),

    test("contains", function()
        local q = Queue(1, 2, 3)

        ok(eq(q:contains(1), true))
        ok(eq(q:contains(2), true))
        ok(eq(q:contains(3), true))
        ok(eq(q:contains(0), false))
        ok(eq(q:contains(4), false))

        q:popLeft()
        ok(eq(q:contains(1), false))
    end),

    test("removeItem", function()
        local q = Queue(1, 2, 3)

        -- simple queue
        -- non-existent item
        ok(eq(q:removeItem(4), nil))
        -- the middle item
        ok(eq(q:removeItem(2), 2))
        ok(eq(#q, 2))
        ok(eq(q[1], 1))
        ok(eq(q[2], 3))
        ok(eq(q[3], nil))

        -- queue with items below `1`
        q = Queue(1):pushLeft(-2,-1,0)

        ok(eq(#q, 4))
        ok(eq(q[1], -2))
        ok(eq(q:removeItem(-1), 2))
        ok(eq(#q, 3))
        ok(eq(q[1], -2))
        ok(eq(q[2], 0))
        ok(eq(q[3], 1))
    end)

}