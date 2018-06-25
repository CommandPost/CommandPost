
local Set = {}

local DATA = {}

local function getdata(set)
    local data = set[DATA]
    if not data then
        error "Expected to receive a Queue"
    end
    return data
end

function Set.is(thing)
    return type(thing) == "table" and thing == Set.mt or Set.is(getmetatable(thing))
end

function Set.new(...)
    local data = {}
    local count = select("#", ...)
    for i = 1,count do
        local value = select(i, ...)
        data[i] = value
        data[value] = true
    end

    return setmetatable({
        [DATA] = data,
    }, Set.mt)
end

--- cp.collect.Set.contains
function Set.has(set, value)
    return getdata(set)[value] == true
end

function Set.union(...)
    local count = select("#", ...)

    local result = Set.new()
    local data = getdata(result)

    for i = 1,count do
        local input = select(i, ...)
        assert(Set.is(input), "All values in a union must be Sets.")
        for k,v in pairs(input) do
            if v == true then
                table.insert(data, k)
                data[k] = true
            end
        end
    end

    return result
end

Set.mt = {
    has = Set.has,
    union = Set.union,

    __index = function(self, key)
        return Set.mt[key] or getdata(self)[key]
    end,

    __newindex = function()
        error "Sets are immutible."
    end,

    __pairs = function(self)
        return pairs(getdata(self))
    end,
}

setmetatable(Set, {
    __call = function(_, ...)
        return Set.new(...)
    end
})

return Set
