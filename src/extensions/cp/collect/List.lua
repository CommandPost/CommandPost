--- === cp.collect.List ===
---
--- Lists are similar `tables` which can contain `nil` items without shortening the length.
--- They also have a few additional methods to assist with managing the size.
local List = {}
List.mt = setmetatable({}, table)
List.mt.__index = List.mt

--- cp.collect.List.sized([size[, defaultValue]]) -> cp.collect.List
--- Constructor
--- Creates a new `List` with the specified size.
---
--- Parameters:
--- * size          - The size of the list. Defaults to `0`.
--- * defaultValue  - If specified, all items in the list will be initialised to the default value.
---
--- Returns:
--- * The new `List` instance.
function List.sized(size, defaultValue)
    size = size or 0
    assert(type(size) == "number", "parameter #1 must be a number.")
    if size < 0 then
        error(string.format("parameter #1 must be at least 0, but was %d.", size))
    end
    local result = setmetatable({n = size}, List.mt)

    if defaultValue and size > 0 then
        for i = 1,size do
            result[i] = defaultValue
        end
    end
    return result
end

--- cp.collect.List.of(...) -> cp.collect.List
--- Constructor
--- Creates a new `List` with the specified items init.
---
--- Parameters:
--- * ...       - The items to put in the list, in order.
---
--- Returns:
--- * The new `List` instance.
function List.of(...)
    local size = select("#", ...)
    local result = List.sized(size)

    for i = 1,size do
        result[i] = select(i, ...)
    end

    return result
end

function List.mt:__len()
    return self.n
end

function List.mt:__newindex(key, value)
    rawset(self, key, value)
    if type(key) == "number" and key > self.n then
        self.n = key
    end
end

--- cp.collect.List:trim([minSize]) -> cp.collect.List
--- Method
--- Trims the current `List` to only contain trailing values that are not `nil`.
---
--- Parameters:
--- * minSize   - If provided, the minimum size to trim down to. Defaults to `0`.
---
--- Returns:
--- * The same `List` instance.
function List.mt:trim(minSize)
    minSize = minSize or 0
    local len = self.n
    for i = len,minSize+1,-1 do
        if self[i] == nil then
            self.n = i - 1
        else
            break
        end
    end
    return self
end

--- cp.collect.List:size([newSize]) -> number
--- Method
--- Returns and/or sets the current size of the list.
---
--- Parameters:
--- * newSize       - if provided, sets the new size of the list. Any values contained above the new size are set to `nil`.
---
--- Returns:
--- * The size of the list.
function List.mt:size(newSize)
    local len = self.n
    if newSize ~= nil then
        if newSize < 0 then
            error(string.format("Parameter #1 must be at least 0 but was %d.", newSize))
        end
        if newSize < len then
            for i = len,newSize+1,-1 do
                self[i] = nil
            end
        end
        self.n = newSize
    end
    return self.n
end

setmetatable(List, {
    __call = function(_, ...)
        return List.of(...)
    end,
})

return List
