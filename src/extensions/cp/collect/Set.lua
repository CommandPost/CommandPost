--- === cp.collect.Set ===
---
--- TODO: Write something here.

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Set = {}

local DATA = {}
local LEN = {}

-- retrieves the actual set data
local function getdata(set)
    local data = set[DATA]
    if not data then
        error "Expected to receive a Set"
    end
    return data
end

local function getlen(set)
    return rawget(set, LEN) or 0
end

local function inclen(set)
    rawset(set, LEN, getlen(set) + 1)
end

local function declen(set)
    rawset(set, LEN, getlen(set) - 1)
end

--- cp.collect.Set.is(thing) -> boolean
--- Function
--- Checks if the `thing` is a `Set`.
---
--- Parameters:
--- * thing     - The thing to check.
---
--- Returns:
--- * `true` if it is a `Set`.
function Set.is(thing)
    return type(thing) == "table" and thing == Set.mt or Set.is(getmetatable(thing))
end

--- cp.collect.Set.new(...) -> cp.collect.Set
--- Constructor
--- Creates a new `Set` instance, containing the items in the parameter list.
---
--- Parameters:
--- * The set items.
---
--- Returns:
--- * The new `Set` instance.
function Set.new(...)
    local data = {}
    local count = select("#", ...)
    local len = 0
    for i = 1,count do
        local value = select(i, ...)
        if not data[value] then
            len = len + 1
            data[value] = true
        end
    end

    return setmetatable({
        [LEN] = len,
        [DATA] = data,
    }, Set.mt)
end

--- cp.collect.Set.has(set, value) -> boolean
--- Function
--- Checks if the set has the specified value.
---
--- Parameters:
--- * set   - The `Set` to check.
--- * value - The value to check for.
---
--- Parameters:
--- * `true` if the value is contained in the `Set`.
function Set.has(set, value)
    return getdata(set)[value] == true
end

--- cp.collect.Set.union(...) -> cp.collect.Set
--- Function
---
--- Parameters:
--- * ...       - a list of `Set`s to create a union from.
---
--- Returns:
--- * A new `Set` which contains a union of all listed `Set`s.
function Set.union(...)
    local count = select("#", ...)

    local result = Set.new()
    local data = getdata(result)

    for i = 1,count do
        local input = select(i, ...)
        assert(Set.is(input), "All values must be Sets.")
        for k,v in pairs(input) do
            if v == true and not data[k] then
                inclen(result)
                data[k] = true
            end
        end
    end

    return result
end

--- cp.collect.Set.intersection(...) -> cp.collect.Set
--- Function
---
--- Parameters:
--- * ...       - a list of `Set`s to create an intersection from.
---
--- Returns:
--- * A new `Set` which contains an intersection of all listed `Set`s.
function Set.intersection(...)
    local count = select("#", ...)

    if count == 0 then
        error "Expected at least 1 Set"
    end

    local first = select(1, ...)
    -- copy the first Set via `union`
    local result = Set.union(first)
    local data = getdata(result)

    for i = 2,count do
        local input = select(i, ...)
        assert(Set.is(input), "All values must be Sets.")
        for k,v in pairs(data) do
            if v == true and not input[k] then
                declen(result)
                data[k] = nil
            end
        end
    end

    return result
end

Set.mt = {
    --- cp.collect.Set:has(value) -> boolean
    --- Method
    --- Checks if this set has the specified value.
    ---
    --- Parameters:
    --- * value     - The value to check for.
    ---
    --- Returns:
    --- * `true` if the `Set` contains the `value`.
    has = Set.has,

    --- cp.collect.Set:union(...) -> cp.collect.Set
    --- Method
    --- Creates a new set which is a union of the current set plus other `Set`s passed in.
    ---
    --- Parameters:
    --- * ...       - The list of `Set`s to create a union from.
    ---
    --- Returns:
    --- * The new `Set` which is a union.
    union = Set.union,

    --- cp.collect.Set:intersection(...) -> cp.collect.Set
    --- Method
    --- Creates a new `Set` which is an intersection of the current values plus other `Set`s passed in.
    ---
    --- Parameters:
    --- * ...       - The list of `Set`s to create an intersection from.
    ---
    --- Returns:
    --- * The new `Set`.
    intersection = Set.intersection,

    __index = function(self, key)
        return Set.mt[key] or getdata(self)[key]
    end,

    __newindex = function()
        error "Sets are immutible."
    end,

    __pairs = function(self)
        return pairs(getdata(self))
    end,

    __len = function(self)
        return getlen(self)
    end,
}

setmetatable(Set, {
    __call = function(_, ...)
        return Set.new(...)
    end
})

return Set
