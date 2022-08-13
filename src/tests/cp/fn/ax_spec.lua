-- Test cases for `cp.fn.ax`.
local require               = require
local spec                  = require "cp.spec"
local expect                = require "cp.spec.expect"

local describe, context, it = spec.describe, spec.context, spec.it

local ax                    = require "cp.fn.ax"

-- a mock definition for `axuielement` for testing.
local axuielementMock = {}
axuielementMock.__index = axuielementMock

function axuielementMock:attributeValue(attribute)
    return self[attribute]
end

function axuielementMock:setAttributeValue(attribute, value)
    self[attribute] = value
end

local function new_axuielementMock(attributes)
    return setmetatable(attributes, axuielementMock)
end

return describe "cp.fn.ax" {
    context "areAligned" {
        it "returns true if the intersection of the first and second element is 100%"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 10, y = 0, w = 10, h = 10}}
            expect(ax.areAligned(first, second)):is(true)
        end),

        it "returns false if the intersection of the first and second element is 0%"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 10, w = 10, h = 10}}
            expect(ax.areAligned(first, second)):is(false)
        end),

        it "returns true if the intersection of the first and second element is 50% of both"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 5, w = 10, h = 10}}
            expect(ax.areAligned(first, second)):is(true)
        end),

        it "return false if the intersection of the first and second element is <50% for both"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 8, w = 10, h = 10}}
            expect(ax.areAligned(first, second)):is(false)
        end),

        it "returns true if the intersection of the first and second element is >50% for the first and <50% for the second"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 5, w = 10, h = 20}}
            expect(ax.areAligned(first, second)):is(false)
        end),
    },

    context "leftToRight" {
        it "returns false when both elements have the same x value"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            expect(ax.leftToRight(first, second)):is(false)
            expect(ax.leftToRight(second, first)):is(false)
        end),

        it "returns true when the first element is left of the right, no matter what y value"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 10, y = 0, w = 10, h = 10}}
            expect(ax.leftToRight(first, second)):is(true)
            expect(ax.leftToRight(second, first)):is(false)
        end),

        it "isn't affected by differences in y, width, or height"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 10, w = 100, h = 100}}
            local second = new_axuielementMock {AXFrame = {x = 10, y = 0, w = 10, h = 10}}
            expect(ax.leftToRight(first, second)):is(true)
            expect(ax.leftToRight(second, first)):is(false)
        end),
    },

    context "rightToLeft" {
        it "returns false when both elements have the same x value"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            expect(ax.rightToLeft(first, second)):is(false)
            expect(ax.rightToLeft(second, first)):is(false)
        end),

        it "returns true when the first element is right of the left, accounting for width"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = -10, y = 0, w = 10, h = 10}}
            expect(ax.rightToLeft(first, second)):is(true)
            expect(ax.rightToLeft(second, first)):is(false)
        end),

        it "returns false if both elements have an equal right edge, even though their widths are different"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = -10, y = 0, w = 20, h = 10}}
            expect(ax.rightToLeft(first, second)):is(false)
        end),
    },

    context "topToBottom" {
        it "returns false when both elements have the same y value"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            expect(ax.topToBottom(first, second)):is(false)
        end),

        it "returns true when the first element is above the second, no matter what x value"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 10, w = 10, h = 10}}
            expect(ax.topToBottom(first, second)):is(true)
            expect(ax.topToBottom(second, first)):is(false)
        end),

        it "isn't affected by differences in x, width, or height"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 10, y = 0, w = 100, h = 100}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            expect(ax.topToBottom(first, second)):is(false)
            expect(ax.topToBottom(second, first)):is(false)
        end),
    },

    context "bottomToTop" {
        it "returns false when both elements have the same bottom edge"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            expect(ax.bottomToTop(first, second)):is(false)
            expect(ax.bottomToTop(second, first)):is(false)
        end),

        it "returns true when the first element has a lower bottom edge"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = -10, w = 10, h = 10}}
            expect(ax.bottomToTop(first, second)):is(true)
            expect(ax.bottomToTop(second, first)):is(false)
        end),

        it "isn't affected by differences in x or width"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 10, y = 0, w = 100, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            expect(ax.bottomToTop(first, second)):is(false)
            expect(ax.bottomToTop(second, first)):is(false)
        end),

        it "returns false when both elements have the same bottom edge but different top edges"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = -10, w = 20, h = 20}}
            expect(ax.bottomToTop(first, second)):is(false)
            expect(ax.bottomToTop(second, first)):is(false)
        end),
    },

    context "narrowToWide" {
        it "returns false when both elements have the same width"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            expect(ax.narrowToWide(first, second)):is(false)
            expect(ax.narrowToWide(second, first)):is(false)
        end),

        it "returns true when the first element is narrower than the second"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 20, h = 10}}
            expect(ax.narrowToWide(first, second)):is(true)
            expect(ax.narrowToWide(second, first)):is(false)
        end),

        it "returns false when the first element is wider than the second"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 20, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            expect(ax.narrowToWide(first, second)):is(false)
            expect(ax.narrowToWide(second, first)):is(true)
        end),

        it "isn't affected by differences in x, y, or height"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 10, y = 0, w = 10, h = 100}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 10, w = 10, h = 10}}
            expect(ax.narrowToWide(first, second)):is(false)
            expect(ax.narrowToWide(second, first)):is(false)
        end),
    },

    context "shortToTall" {
        it "returns false when both elements have the same height"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            expect(ax.shortToTall(first, second)):is(false)
            expect(ax.shortToTall(second, first)):is(false)
        end),

        it "returns true when the first element is shorter than the second"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 20}}
            expect(ax.shortToTall(first, second)):is(true)
            expect(ax.shortToTall(second, first)):is(false)
        end),

        it "returns false when the first element is taller than the second"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 20}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            expect(ax.shortToTall(first, second)):is(false)
            expect(ax.shortToTall(second, first)):is(true)
        end),

        it "isn't affected by differences in x, y, or width"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 10, y = 0, w = 100, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 10, w = 10, h = 10}}
            expect(ax.shortToTall(first, second)):is(false)
            expect(ax.shortToTall(second, first)):is(false)
        end),
    },

    context "topToBottomBaseAligned" {
        it "returns false when both elements have the same bottom edge"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            expect(ax.topToBottomBaseAligned(first, second)):is(false)
            expect(ax.topToBottomBaseAligned(second, first)):is(false)
        end),

        it "returns true when the first element is more than 50% of the height above the second"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 8, w = 10, h = 10}}
            expect(ax.topToBottomBaseAligned(first, second)):is(true)
            expect(ax.topToBottomBaseAligned(second, first)):is(false)
        end),

        it "returns false when the first element is less than 50% of the height above the second"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 2, w = 10, h = 10}}
            expect(ax.topToBottomBaseAligned(first, second)):is(false)
            expect(ax.topToBottomBaseAligned(second, first)):is(false)
        end),

        it "isn't affected by differences in x or width"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 10, y = 0, w = 100, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            expect(ax.topToBottomBaseAligned(first, second)):is(false)
            expect(ax.topToBottomBaseAligned(second, first)):is(false)
        end),
    },

    context "topDown" {
        it "returns false if both elements are exactly the same"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            expect(ax.topDown(first, second)):is(false)
            expect(ax.topDown(second, first)):is(false)
        end),

        it "returns true if the both elements are aligned but the first is left of the second"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 10, y = 0, w = 10, h = 10}}
            expect(ax.topDown(first, second)):is(true)
            expect(ax.topDown(second, first)):is(false)
        end),

        it "returns true if the first element is right of the second element, but more than 50% of the height higher"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = -8, y = 10, w = 10, h = 10}}
            expect(ax.topDown(first, second)):is(true)
            expect(ax.topDown(second, first)):is(false)
        end),

        it "returns true if the elements are aligned, have the same left position, and the first is shorter"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 10, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 20}}
            expect(ax.topDown(first, second)):is(true)
            expect(ax.topDown(second, first)):is(false)
        end),

        it "returns true if the elements are aligned, have the same left position, and the first is shorter, even if the second is narrower"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 10, w = 20, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 20}}
            expect(ax.topDown(first, second)):is(true)
            expect(ax.topDown(second, first)):is(false)
        end),

        it "returns true if the elements are aligned, have the same left position, are equal height, but the first is narrower"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 20, h = 10}}
            expect(ax.topDown(first, second)):is(true)
            expect(ax.topDown(second, first)):is(false)
        end),

        it "returns false if both elements have the same x value, but the first is taller"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 20}}
            local second = new_axuielementMock {AXFrame = {x = 0, y = 10, w = 10, h = 10}}
            expect(ax.topDown(first, second)):is(false)
            expect(ax.topDown(second, first)):is(true)
        end),

        it "returns true if the first element is left of the second element, even if the second is 20% higher"
        :doing(function()
            local first = new_axuielementMock {AXFrame = {x = 0, y = 0, w = 10, h = 10}}
            local second = new_axuielementMock {AXFrame = {x = -2, y = 10, w = 10, h = 10}}
            expect(ax.topDown(first, second)):is(true)
            expect(ax.topDown(second, first)):is(false)
        end),
    },
}