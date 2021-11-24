local spec                  = require "cp.spec"
local expect                = require "cp.spec.expect"
local describe, context, it = spec.describe, spec.context, spec.it

local LazyList              = require "cp.collect.LazyList"

return describe "cp.collect.LazyList" {
    context "construction" {
        it "can be an empty list"
        :doing(function()
            local list = LazyList.new(function() return 0 end, function() return nil end)
            expect(#list):is(0)
            expect(list[1]):is(nil)
        end),

        it "can be a list of values"
        :doing(function()
            local list = LazyList.new(function() return 3 end, function(index) return index * 2 end)
            expect(#list):is(3)
            expect(list[1]):is(2)
            expect(list[2]):is(4)
            expect(list[3]):is(6)
        end)
    },

    context "iteration" {
        it "can be iterated with ipairs"
        :doing(function()
            local list = LazyList.new(function() return 3 end, function(index) if index <=3 then return index * 2 end end)
            local count = 0
            for _ in ipairs(list) do
                count = count + 1
                expect(count <= 3):is(true)
            end
            expect(count):is(3)
        end),

        it "can be iterated with pairs"
        :doing(function()
            local list = LazyList.new(function() return 3 end, function(index) if index <= 3 then return index * 2 end end)
            local count = 0
            for _ in pairs(list) do
                count = count + 1
                expect(count <= 3):is(true)
            end
            expect(count):is(3)
        end),
    },

    context "caching" {
        it "can be cached"
        :doing(function()
            local callCount = 0
            local list = LazyList.new(function() return 3 end, function(index)
                callCount = callCount + 1
                if index <= 3 then return index * 2 end
            end, {cached = true})

            -- uncached
            local itemCount = 0
            for _ in ipairs(list) do
                itemCount = itemCount + 1
            end
            -- extra call to `4` that returns nil
            expect(callCount):is(4)

            -- cached
            for _ in ipairs(list) do
                itemCount = itemCount + 1
            end
            -- another uncached call to `4` that returns nil
            expect(callCount):is(5)
            expect(itemCount):is(6)
        end),

        it "can be uncached"
        :doing(function()
            local callCount = 0
            local list = LazyList.new(function() return 3 end, function(index)
                callCount = callCount + 1
                if index <= 3 then return index * 2 end
            end)

            -- uncached
            local itemCount = 0
            for _ in ipairs(list) do
                itemCount = itemCount + 1
            end
            expect(callCount):is(4)

            -- uncached
            for _ in ipairs(list) do
                itemCount = itemCount + 1
            end
            expect(callCount):is(8)
            expect(itemCount):is(6)
        end),
    },
}