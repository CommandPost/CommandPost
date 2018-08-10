--- === cp.collect.Set ===
---
--- An implementation of a logical `set`, which contains a single unique
--- reference of each item in it. For example:
---
--- ```lua
--- Set(1,2,2,3) == Set(1,1,2,3,3) == Set(1,2,3)
--- ```
---
--- You can combine sets in a couple of ways. For example, a `union`:
---
--- ```lua
--- Set(1,2):union(Set(2,3)) == Set(1,2,3)
--- Set(1,2) | Set(2,3) == Set(1,2,3)
--- ```
---
--- ...or an `intersection`:
---
--- ```lua
--- Set(1,2):intersection(Set(2,3)) == Set(2)
--- Set(1,2) & Set(2,3) == Set(2)
--- ```
---
--- As indicated above, you can use operators for common set operations. Specifically:
---
--- * [union](#union) (A ⋃ B):                          `a | b` or `a + b`
--- * [intersection](#intersection) (A ∩ B):            `a & b`
--- * [complement](#complement) (A<sup>c</sup>):        `-a`
--- * [difference](#diference) (A - B):                 `a - b`
--- * [symetric diference](#symetricDiference) (A ⊕ B)  `a ~ b`
---
--- Keep in mind that Lua's operator precedence may be different to that of standard set operations, so it's probably best to group operations in brackets if you combine more than one in a single statement. For example:
---
--- ```lua
--- a + b | c ~= a + (b | c)
--- ```

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local insert, concat        = table.insert, table.concat

local Set = {}

local DATA = {}
local SIZE = {}
local COMPLEMENT = {}

local function clone(org)
    local size = 0
    local result = {}
    for k,v in pairs(org) do
        result[k] = v
        size = size + 1
    end
    return result, size
end

local function isComplement(set)
    return rawget(set, COMPLEMENT) == true
end

local function makeComplement(set)
    rawset(set, COMPLEMENT, true)
end

local function getSize(set)
    local size = rawget(set, SIZE) or 0
    if isComplement(set) then
        if size == 0 then
            return nil
        else
            return -1 * size
        end
    else
        return size
    end
end

local function setSize(set, size)
    rawset(set, SIZE, size)
end

-- retrieves the actual set data
local function getData(set)
    local data = rawget(set, DATA)
    if not data then
        error "Expected to receive a Set"
    end
    return data
end

-- setData(set, data[, size]) -> nil
-- Function
-- Sets the data table for the specified Set.
--
-- Parameters:
-- * set    - The Set to update the data table for.
-- * data   - The data table.
-- * size    - The number of values in the data table.
local function setData(set, data, size)
    rawset(set, DATA, data)
    if size ~= nil then
        setSize(set, size)
    end
end

local function hasValue(set, value)
    local required = not isComplement(set) or nil
    local data = getData(set)
    return data[value] == required
end

-- union(left, right) -> table, number
-- Function
-- Performs a simple union of the keys with a value of `true` in the left and right table into a new table.
--
-- Parameters:
-- * left   - The left table.
-- * right  - The right table.
--
-- Returns:
-- * table - The united table
-- * number - The number of items in the united table
local function union(left, right)
    local result = {}
    local size = 0

    for k,v in pairs(left) do
        if v == true then
            result[k] = true
            size = size + 1
        end
    end

    for k,v in pairs(right) do
        if v == true and not result[k] then
            result[k] = true
            size = size + 1
        end
    end

    return result, size
end

-- intersection(left, right) -> table, number
-- Function
-- Performs a simple intersection of the keys with a value of `true` in the left and right table into a new table.
--
-- Parameters:
-- * left   - The left table.
-- * right  - The right table.
--
-- Returns:
-- * table - The intersection table
-- * number - The number of items in the intersection table
local function intersection(left, right)
    local result = {}
    local size = 0

    for k,v in pairs(left) do
        if v == true and right[k] == true then
            result[k] = true
            size = size + 1
        end
    end

    return result, size
end

-- difference(left, right) -> table, number
-- Function
-- Performs a simple difference of the keys with a value of `true` in the left and right table into a new table.
-- The resulting table will contain items in `left` which do not occur in `right`.
--
-- Parameters:
-- * left   - The left table.
-- * right  - The right table.
--
-- Returns:
-- * table - The difference table
-- * number - The number of items in the united table
local function difference(left, right)
    local result = {}
    local size = 0

    for k,v in pairs(left) do
        if v == true and right[k] == nil then
            result[k] = true
            size = size + 1
        end
    end

    return result, size
end

-- symetricDifference(left, right) -> table, number
-- Function
-- Performs a symetric difference of keys with a value of `true` in the left and right table into a new table.
-- The resulting table will contain items that only occur in the `left` or `right` set, but not both.
--
-- Parameters:
-- * left       - the left `Set`.
-- * right      - the right `Set`.
--
-- Returns:
-- * The new `Set`.
local function symetricDifference(left, right)
    local diffLeft = difference(left, right)
    local diffRight = difference(right, left)

    return union(diffLeft, diffRight)
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

--- cp.collect.Set.of(...) -> cp.collect.Set
--- Constructor
--- Creates a new `Set` instance, containing the items in the parameter list.
---
--- Parameters:
--- * The set items.
---
--- Returns:
--- * The new `Set` instance.
function Set.of(...)
    return Set.fromList(table.pack(...))
end

--- cp.collect.Set.fromList(list) -> cp.collect.Set
--- Constructor
--- Creates a new `Set` instance, containing the unique items in the table collected as a list from `1` to `n`.
--- Any duplicate items will only occur in the `Set` once.
---
--- Parameters:
--- * list      - The table that contains items as a list to add to the `Set`. E.g. `{"foo", "bar"}
---
--- Returns:
--- * The new `Set`.
function Set.fromList(list)
    local data = {}
    local size = 0
    for _,value in ipairs(list) do
        if not data[value] then
            size = size + 1
            data[value] = true
        end
    end
    return setmetatable({
        [SIZE] = size,
        [DATA] = data,
    }, Set.mt)
end

--- cp.collect.Set.fromMap(map) -> cp.collect.Set
--- Constructor
--- Creates a new `Set` instance, containing the items in the provided `table` who's key value is `true`.
--- Keys with values other than `true` will be ignored.
---
--- Parameters:
--- * map      - The table that contains key/value items to add to the set. E.g. `{foo = true, bar = true}`
---
--- Returns:
--- * The new `Set`.
function Set.fromMap(map)
    local data = {}
    local size = 0
    for key,value in pairs(map) do
        if value == true then
            size = size + 1
            data[key] = true
        end
    end
    return setmetatable({
        [SIZE] = size,
        [DATA] = data,
    }, Set.mt)
end

--- cp.collect.Set.clone(set) -> cp.collect.Set
--- Constructor
--- Creates a new `Set` which is a clone of the provided `Set`.
---
--- Parameters:
--- * set       - The set to clone.
---
--- Returns:
--- * The new `Set` instance.
function Set.clone(set)
    assert(Set.is(set), "Parameter #1 must be a cp.collect.Set.")
    return setmetatable({
        [SIZE] = set[SIZE],
        [COMPLEMENT] = set[COMPLEMENT],
        [DATA] = clone(set[DATA]),
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
--- Returns:
--- * `true` if the value is contained in the `Set`.
function Set.has(set, value)
    return hasValue(set, value)
end

--- cp.collect.Set.union(left, right) -> cp.collect.Set
--- Function
--- Returns a new `Set` which is a union of the `left` and `right`
---
--- Parameters:
--- * left      - The left `Set`.
--- * right     - The right `Set`.
---
--- Returns:
--- * A new `Set` which contains a union of the `left` and `right` `Set`s.
function Set.union(left, right)
    assert(Set.is(left), "left must be a Set.")
    assert(Set.is(right), "right must be a Set.")

    local result = Set.of()
    local leftData, rightData = getData(left), getData(right)

    if isComplement(left) then
        makeComplement(result)
        if isComplement(right) then
            makeComplement(result)
            setData(result, intersection(leftData, rightData))
        else
            setData(result, difference(leftData, rightData))
        end
    elseif isComplement(right) then
        makeComplement(result)
        local diff, size = difference(rightData, leftData)
        setData(result, diff, size)
    else
        setData(result, union(leftData, rightData))
    end

    return result
end

--- cp.collect.Set.intersection(left, right) -> cp.collect.Set
--- Function
---
--- Parameters:
--- * left      - The left `Set`
--- * right     - The right `Set`.
---
--- Returns:
--- * A new `Set` which contains an intersection `left` and `right`.
function Set.intersection(left, right)
    assert(Set.is(left), "left must be a Set.")
    assert(Set.is(right), "right must be a Set.")

    local result = Set.of()
    local leftData, rightData = getData(left), getData(right)

    if isComplement(left) then
        if isComplement(right) then
            makeComplement(result)
            setData(result, union(leftData, rightData))
        else
            setData(result, difference(rightData, leftData))
        end
    elseif isComplement(right) then
        setData(result, difference(leftData, rightData))
    else
        setData(result, intersection(leftData, rightData))
    end

    return result
end

--- cp.collect.Set.difference(left, right) -> cp.collect.Set
--- Function
--- Returns a new `Set` which is the set of values in `left` that are not in `right`.
---
--- Parameters:
--- * left      - The left `Set`.
--- * right     - The right `Set`.
---
--- Returns:
--- * The new `Set`.
function Set.difference(left, right)
    assert(Set.is(left), "left must be a Set.")
    assert(Set.is(right), "right must be a Set.")

    local result = Set.of()
    local leftData, rightData = getData(left), getData(right)

    if isComplement(left) then
        if isComplement(right) then
            setData(result, difference(rightData, leftData))
        else
            makeComplement(result)
            setData(result, union(leftData, rightData))
        end
    elseif isComplement(right) then
        setData(result, intersection(leftData, rightData))
    else
        setData(result, difference(leftData, rightData))
    end

    return result
end

--- cp.collect.Set.symetricDifference(left, right) -> cp.collect.Set
--- Function
--- Performs a symetric difference of keys with a value of `true` in the left and right table into a new table.
--- The resulting table will contain items that only occur in the `left` or `right` set, but not both.
---
--- Parameters:
--- * left      - The left `Set`.
--- * right     - The right `Set`.
---
--- Returns:
--- * The new `Set`.
function Set.symetricDifference(left, right)
    assert(Set.is(left), "left must be a Set.")
    assert(Set.is(right), "right must be a Set.")

    local result = Set.of()
    local leftData, rightData = getData(left), getData(right)
    local leftComplement, rightComplement = isComplement(left), isComplement(right)

    if leftComplement == rightComplement then
        setData(result, symetricDifference(leftData, rightData))
    else
        if leftComplement or rightComplement then
            makeComplement(result)
        end
        setData(result, symetricDifference(leftData, rightData))
    end

    return result
end

--- cp.collect.Set.complement(set) -> cp.collect.Set
--- Function
--- Returns a `Set` which is the complement of the provided set.
---
--- Parameters:
--- * set       - The `Set` to complement.
---
--- Returns:
--- * The new `Set`.
function Set.complement(set)
    assert(Set.is(set), "parameter #1 must be a Set.")

    local result = Set.of()
    setData(result, clone(getData(set)))
    if not isComplement(set) then
        makeComplement(result)
    end

    return result
end

--- cp.collect.Set.size(set) -> number
--- Function
--- Returns the size of the set.
---
--- Parameters:
--- * set   - The set to find the size of.
---
--- Returns:
--- * the number of values in the set, or the number of values removed from a complement set.
---
--- Notes:
--- * If the set is empty, `0` is returned.
--- * If the set is a complement, this will return a negative number indicating how many values have been removed from the universal set of all things.
--- * If the set is a complement of an empty set, `nil` is returned to indicate the size is infinite.
function Set.size(set)
    assert(Set.is(set), "parameter #1 must be a Set.")

    return getSize(set)
end

--- cp.collect.Set.isComplement(set) -> boolean
--- Function
--- Checks if the set is a complement set.
---
--- Parameters:
--- * set       - The set to check.
---
--- Returns:
--- * `true` if the set is a complement.
function Set.isComplement(set)
    assert(Set.is(set), "parameter #1 must be a Set.")
    return isComplement(set)
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
---
--- Notes:
--- * You can also check for specific values via `mySet['key']` or `mySet.key`.
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
---
--- Notes:
--- * You can also use the `\|` or `+` operator. E.g. `a \| b` or `a + b`.
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
---
--- Notes:
--- * You can also use the `&` operator. E.g. `a & b`.
    intersection = Set.intersection,

--- cp.collect.Set:difference(right) -> cp.collect.Set
--- Method
--- Returns a new `Set` which is the set of values in this `Set` that are not in `right`.
---
--- Parameters:
--- * right     - The right `Set`.
---
--- Returns:
--- * The new `Set`.
---
--- Notes:
--- * You can also use the `-` operator. E.g. `a - b`.
    difference = Set.difference,

--- cp.collect.Set:complement() -> cp.collect.Set
--- Method
--- Returns a new `Set` which is the complement of the current `Set`.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The new `Set`.
---
--- Notes:
--- * You can also use the `-` or `~` prefix operators. E.g. `-a` or `~a`.
    complement = Set.complement,

--- cp.collect.Set:symetricDifference(right) -> cp.collect.Set
--- Method
--- Performs a symetric difference of keys with a value of `true` in the left and right table into a new table.
--- The resulting table will contain items that only occur in the `left` or `right` set, but not both.
---
--- Parameters:
--- * right     - The right `Set`.
---
--- Returns:
--- * The new `Set`.
---
--- Notes:
--- * You can also use the `~` operator. E.g. `a ~ b`.
    symetricDifference = Set.symetricDifference,

--- cp.collect.Set:isComplement() -> boolean
--- Method
--- Checks if the set is a complement set.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if the set is a complement.
    isComplement = isComplement,

--- cp.collect.Set:size() -> number
--- Method
--- Returns the size of the `Set`. If the set is a complement, this will return a negative number indicating
--- how many values have been removed from the universal set of all things.
---
--- Parameters:
--- * None
---
--- Returns:
--- * the number of values in the set, or the number of values removed from a complement set.
---
--- Notes:
--- * If the set is empty, `0` is returned.
--- * If the set is a complement, this will return a negative number indicating how many values have been removed from the universal set of all things.
--- * If the set is a complement of an empty set, `nil` is returned to indicate the size is infinite.
    size = Set.size,

    -- `-foo`
    __unm = Set.complement,

    -- `~foo`
    __bnot = Set.complement,

    -- `foo & bar`
    __band = Set.intersection,

    -- `foo | bar`
    __bor = Set.union,

    -- `foo + bar`
    __add = Set.union,

    -- `foo - bar`
    __sub = Set.difference,

    -- `foo ~ bar`
    __bxor = Set.symetricDifference,

    __index = function(self, key)
        return Set.mt[key] or getData(self)[key]
    end,

    __newindex = function()
        error "Sets are immutible."
    end,

    __pairs = function(self)
        return pairs(getData(self))
    end,

    __eq = function(self, other)
        if #self ~= #other then
            return false
        end
        for k,v in pairs(self) do
            if other[k] ~= v then
                return false
            end
        end
        return true
    end,

    __tostring = function(self)
        local str = {}
        local first = true
        insert(str, "cp.collect.Set: ")
        if isComplement(self) then
            insert(str, "-")
        end

        insert(str, "{")
        for k,_ in pairs(getData(self)) do
            if not first then
                insert(str, ", ")
            else
                first = false
            end
            insert(str, tostring(k))
        end
        insert(str, "}")
        return concat(str)
    end,
}

--- cp.collect.Set.nothing <cp.collect.Set>
--- Constant
--- An empty `Set`.
Set.nothing = Set.of()

--- cp.collect.Set.everything <cp.collect.Set>
--- Constant
--- A `Set` which contains the whole universe.
Set.everything = Set.of():complement()

Set.__getData = getData

setmetatable(Set, {
    __call = function(_, ...)
        return Set.of(...)
    end
})

return Set
