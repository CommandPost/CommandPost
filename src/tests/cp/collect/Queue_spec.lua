local spec          = require "cp.spec"
local expect        = require "cp.spec.expect"
local describe, it  = spec.describe, spec.it

local Queue          = require("cp.collect.Queue")

return describe "cp.collect.Queue" {
    it "can be created by calling `new`"
    :doing(function()
        -- the `new` method directly
        local q = Queue.new()
        expect(#q):is(0)

        -- alternate method, with default items
        q = Queue(1, 2, 3)
        expect(#q):is(3)
        expect(q[1]):is(1)
        expect(q[2]):is(2)
        expect(q[3]):is(3)
    end),

    it "can have an item pushed on the right end of the queue."
    :doing(function()
        local q = Queue.new()

        q:pushRight(true)
        expect(q[1]):is(true)
        expect(#q):is(1)
    end),

    it "can have an item pushed on the left end of the queue"
    :doing(function()
        local q = Queue.new()

        q:pushLeft(true)
        expect(q[1]):is(true)
        expect(#q):is(1)
    end),

    it "can peek at the left or right-most item without removing it"
    :doing(function()
        local q = Queue.new(1, 2)

        expect(q:peekRight()):is(2)
        expect(#q):is(2)
        expect(q:peekLeft()):is(1)
        expect(#q):is(2)
    end),

    it "can pop the right-most item off the queue"
    :doing(function()
        local q = Queue(1, 2, 3)

        expect(q:popRight()):is(3)
        expect(#q):is(2)
        expect(q:popRight()):is(2)
        expect(#q):is(1)
        expect(q:popRight()):is(1)
        expect(#q):is(0)
    end),

    it "can pop the left-most item off the queue"
    :doing(function()
        local q = Queue(1, 2, 3)

        expect(q:popLeft()):is(1)
        expect(#q):is(2)
        expect(q[1]):is(2)
        expect(q:popLeft()):is(2)
        expect(#q):is(1)
        expect(q[1]):is(3)
        expect(q:popLeft()):is(3)
        expect(#q):is(0)
        expect(q[1]):is(nil)
    end),

    it "can check if the queue contains a value"
    :doing(function()
        local q = Queue(1, 2, 3)

        expect(q:contains(1)):is(true)
        expect(q:contains(2)):is(true)
        expect(q:contains(3)):is(true)
        expect(q:contains(0)):is(false)
        expect(q:contains(4)):is(false)

        q:popLeft()
        expect(q:contains(1)):is(false)
    end),

    it "can remove an arbitrary value from the queue"
    :doing(function()
        local q = Queue(1, 2, 3)

        -- simple queue
        -- non-existent item
        expect(q:removeItem(4)):is(nil)
        -- the middle item
        expect(q:removeItem(2)):is(2)
        expect(#q):is(2)
        expect(q[1]):is(1)
        expect(q[2]):is(3)
        expect(q[3]):is(nil)

        -- queue with items below `1`
        q = Queue(1):pushLeft(-2,-1,0)

        expect(#q):is(4)
        expect(q[1]):is(-2)
        expect(q:removeItem(-1)):is(2)
        expect(#q):is(3)
        expect(q[1]):is(-2)
        expect(q[2]):is(0)
        expect(q[3]):is(1)
    end)
}