--- === cp.slice ===
---
--- A slice of a table, from the provided `start` index to the end, or the optional `count` if provided.
---

local format            = string.format
local max               = math.max

local mod = {}

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
--  * The value at the specified index.
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
        error(format("Index out of bounds: %d", i), 2)
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
    return type(other) == "table" and rawget(getmetatable(other), "__index") == __index
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
        error("expected table, got " .. type(t), 2)
    end
    if start < 1 then
        error(format("start index must be 1 or higher, but was %d", start), 2)
    end
    if count and count < 0 then
        error(format("invalid count: %d", count), 2)
    end
    return setmetatable({}, {
        __index = __index,
        __newindex = __newindex,
        __len = __len,
        __sliceTable = t,
        __sliceShift = start - 1,
        __sliceLen = count
    })
end

return mod