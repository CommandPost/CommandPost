--- === cp.slice ===
---
--- A slice of a table, from the provided `start` index to the end, or the optional `count` if provided.
---

--local log               = require "hs.logger" .new "slice"

local format            = string.format
local max               = math.max

local mod = {}
mod.mt = {}

-- __len(t) -> number
-- Function
-- Returns the length of the table, shifted by the slice start index (retrieved from the metatable).
-- If the slice size (also from the metatable) is specified, and the requested index exceeds it, returns `nil`.
--
-- Parameters:
--  * t - The table to get the length of.
--
-- Returns:
--  * The length of the table.
--
-- Notes:
--  * This is a private function.
local function __len(t)
    local mt = getmetatable(t)
    local sliceLen = rawget(mt, "__sliceLen")

    if sliceLen then
        return sliceLen
    end

    local original = rawget(mt,"__sliceTable")
    local sliceShift = rawget(mt, "__sliceShift")

    return max((original.n or #original) - sliceShift + 1, 0)
end

-- __index(t, i) -> any
-- Function
-- Returns the value at the specified index in the table, shifted by the slice start index (retrieved from the metatable).
-- If the slice size (also from the metatable) is specified, and the requested index exceeds it, returns `nil`.
--
-- Parameters:
--  * t - The table to get the value from.
--  * i - The index to get the value at.
--
-- Returns:
--  * The value at the specified index.
--
-- Notes:
--  * This is a private function.
local function __index(t, i)
    local mtValue = mod.mt[i]
    if mtValue then
        return mtValue
    end

    local mt = getmetatable(t)
    local original = rawget(mt,"__sliceTable")
    local sliceShift = rawget(mt, "__sliceShift")
    local sliceLen = __len(t)

    if i == "n" then
        return sliceLen
    elseif type(i) ~= "number" then
        return original[i]
    elseif i < 1 or i > sliceLen then
        return nil
    end

    local sliceIndex = i + sliceShift

    return original[sliceIndex]
end

-- __newindex(t, i, v)
-- Function
-- Sets the value at the specified index in the table, shifted by the slice start index (retrieved from the metatable).
-- If the slice size (also from the metatable) is specified, and the requested index exceeds it, returns `nil`.
--
-- Parameters:
--  * t - The table to set the value in.
--  * i - The index to set the value at.
--  * v - The value to set.
--
-- Returns:
--  * Nothing
--
-- Notes:
--  * This is a private function.
local function __newindex(t, i, v)
    if i == "n" then
        return
    elseif type(i) ~= "number" then
        return rawset(t, i, v)
    end

    local mt = getmetatable(t)
    local original = rawget(mt,"__sliceTable")
    local sliceShift = rawget(mt, "__sliceShift")
    local sliceLen = __len(t)

    local sliceIndex = i + sliceShift

    if sliceLen and sliceIndex >= sliceLen then
        error(format("index out of bounds: %d", i), 2)
    end

    rawset(original, sliceIndex, v)
end

--- cp.slice.is(other) -> boolean
--- Function
--- Checks if the other value is a `cp.slice`.
---
--- Parameters:
---  * other - The other value to check.
---
--- Returns:
---  * `true` if the other value is a `cp.slice`, otherwise `false`.
function mod.is(other)
    if type(other) ~= "table" then return false end
    local mt = getmetatable(other)
    return mt ~= nil and rawget(mt, "__sliceTable") ~= nil
end

--- cp.slice.new(t, start, [count]) -> cp.slice
--- Constructor
--- Creates a new `cp.slice` over the provided `table`.
---
--- Parameters:
---  * `t`       - The table to slice.
---  * `start`   - The starting index.
---  * `count`   - The number of items to slice. If not provided, then the slice will go to the end of the table.
---
--- Returns:
---  * The new `cp.slice` instance.
function mod.new(t, start, count)
    if type(t) ~= "table" then
        error(format("expected table, got %s", type(t)), 2)
    end
    if start < 1 then
        error(format("start index must be 1 or higher, but was %d", start), 2)
    end
    if count and count < 0 then
        error(format("invalid count: %d", count), 2)
    end
    local shift = start - 1
    count = count or max(#t - shift, 0)
    return setmetatable({}, {
        __index = __index,
        __newindex = __newindex,
        __len = __len,
        __sliceTable = t,
        __sliceShift = shift,
        __sliceLen = count,
    })
end

--- cp.slice.from(value) -> cp.slice
--- Constructor
--- Creates a new `cp.slice` from the provided `value`.
--- If it is already a `slice`, it is returned unmodified. If it's a table, then a new `slice` is created from it, starting at index 1.
--- Any other value generates an error.
---
--- Parameters:
---  * `value` - The value to create a `slice` from.
---
--- Returns:
---  * The new `cp.slice` instance.
function mod.from(value)
    if mod.is(value) then
        return value
    elseif type(value) == "table" then
        return mod.new(value, 1)
    end
    error(format("expected table or slice, got %s", type(value)), 2)
end

--- cp.slice:shift(n) -> cp.slice
--- Method
--- Returns a new slice which is shifted by the specified number of items, without changing the length.
---
--- Parameters:
---  * `n` - The number of items to shift the slice by.
---
--- Returns:
---  * The new `cp.slice` instance.
---
--- Notes:
---  * The original slice is not modified.
function mod.mt:shift(n)
    if n < 0 then
        error(format("invalid shift: %d", n), 2)
    end
    local mt = getmetatable(self)
    local original = rawget(mt,"__sliceTable")
    local sliceShift = rawget(mt, "__sliceShift")
    local sliceLen = __len(self)

    return mod.new(original, 1 + sliceShift + n, sliceLen)
end

--- cp.slice:drop(n) -> cp.slice
--- Method
--- Returns a new slice which is shifted by the specified number of items, and the length is reduced by the specified number of items.
---
--- Parameters:
---  * `n` - The number of items to drop.
---
--- Returns:
---  * The new `cp.slice` instance.
---
--- Notes:
---  * The original slice is not modified.
function mod.mt:drop(n)
    if n < 0 then
        error(format("invalid drop: %d", n), 2)
    end
    local mt = getmetatable(self)
    local original = rawget(mt,"__sliceTable")
    local sliceShift = rawget(mt, "__sliceShift")
    local sliceLen = __len(self)

    if sliceLen < n then
        error(format("dropping %d but only %d are available", n, sliceLen), 2)
    else
        return mod.new(original, 1 + sliceShift + n, sliceLen - n)
    end
end

--- cp.slice:pop() -> any, cp.slice
--- Method
--- Returns the first element of the slice, returning a new `slice` with the first element removed.
---
--- Parameters:
---  * None.
---
--- Returns:
---  * The the popped element, and a new `cp.slice` instance.
---
--- Notes:
---  * The original slice is not modified.
function mod.mt:pop()
    local mt = getmetatable(self)
    local original = rawget(mt,"__sliceTable")
    local sliceShift = rawget(mt, "__sliceShift")
    local sliceLen = __len(self)

    if sliceLen == 0 then
        error("pop from empty slice", 2)
    else
        -- get the first item
        local item = original[1+sliceShift]
        -- return the item, plus a new slice of the original, incremented by 1
        return item, mod.new(original, 2+sliceShift, sliceLen - 1)
    end
end

--- cp.slice:split(n) -> cp.slice, cp.slice
--- Method
--- Splits the slice into two new slices, where the first slice contains the first `n` items,
--- and the second slice contains the remaining items.
---
--- Parameters:
---  * `n` - The number of items to include in the first slice.
---
--- Returns:
---  * The first slice, and the second slice.
---
--- Notes:
---  * The original slice is not modified.
function mod.mt:split(n)
    if n < 0 then
        error(format("invalid split: %d", n), 2)
    end
    local mt = getmetatable(self)
    local original = rawget(mt,"__sliceTable")
    local sliceShift = rawget(mt, "__sliceShift")
    local sliceLen = __len(self)

    if sliceLen < n then
        error(format("split size (%d) is greater than slice size (%d)", n, sliceLen), 2)
    end

    local firstLen = n
    local secondLen = sliceLen - firstLen

    local first = mod.new(original, sliceShift + 1, firstLen)
    local second = mod.new(original, sliceShift + firstLen + 1, secondLen)

    return first, second
end

--- cp.slice:clone() -> cp.slice
--- Method
--- Creates a new slice that is a copy of the original.
--- It will be pointing at the original table, and will have the same length and shift.
---
--- Parameters:
---  * None.
---
--- Returns:
---  * The new slice.
function mod.mt:clone()
    local mt = getmetatable(self)
    local original = rawget(mt,"__sliceTable")
    local sliceShift = rawget(mt, "__sliceShift")
    local sliceLen = __len(self)

    return mod.new(original, sliceShift + 1, sliceLen)
end

return mod