--- === cp.fn.args ===
---
--- Functions for working with function arguments.

local pack, unpack, insert      = table.pack, table.unpack, table.insert

local mod = {}

--- cp.fn.args.only(index, ...) -> function(...) -> any
--- Function
--- Returns a function that only returns the argument at the specified index.
---
--- Parameters:
---  * index - The index of the argument to return.
---  * ... - The other indexes to include as well.
---
--- Returns:
---  * A function that returns the arguments at the specified indecies.
function mod.only(index, ...)
    local indexes = pack(index, ...)
    return function(...)
        local args = {}
        for _, i in ipairs(indexes) do
            local value = select(i, ...)
            insert(args, value)
        end
        return unpack(args)
    end
end


--- cp.fn.args.from(index) -> function(...) -> ...
--- Function
--- Returns a function that selects the arguments from the provided index.
---
--- Parameters:
---  * index - The index of the argument to select.
---
--- Returns:
---  * A function that selects the argument at the specified index.
function mod.from(index)
    return function(...)
        return select(index, ...)
    end
end

--- cp.fn.args.pack(...) -> table, boolean
--- Function
--- Packs the arguments into a table.
--- If the number of arguments is 1 and the first argument is a table,
--- and the table has a size of 1 or more, it will be returned.
--- Otherwise, the arguments are packed into a table.
---
--- Parameters:
---  * ... - The arguments to pack.
---
--- Returns:
---  * A table containing the arguments.
---  * A boolean indicating whether the arguments were packed into a table.
function mod.pack(...)
    local argCount = select("#", ...)
    if argCount == 1 then
        local first = select(1, ...)
        if type(first) == "table" and #first > 0 then
            return first, false
        end
    end
    return pack(...), true
end

--- cp.fn.args.unpack(args, packed) -> ... | table
--- Function
--- Unpacks the arguments from a table.
--- If the arguments were packed, the table is unpacked first.
--- Otherwise, the arguments are returned unchanged.
---
--- Parameters:
---  * args - The arguments to unpack.
---  * packed - A boolean indicating whether the arguments were packed.
---
--- Returns:
---  * The arguments, unpacked if necessary.
function mod.unpack(args, packed)
    if packed then
        return unpack(args)
    end
    return args
end

--- cp.fn.args.hasNone(...) -> boolean
--- Function
--- Returns `true` if all the arguments are `nil`.
---
--- Parameters:
---  * ... - The arguments to check.
---
--- Returns:
---  * `true` if all the arguments are `nil`, `false` if not.
function mod.hasNone(...)
    local count = select("#", ...)
    for i = 1, count do
        if select(i, ...) ~= nil then
            return false
        end
    end
    return true
end

--- cp.fn.args.hasAny(...) -> boolean
--- Function
--- Returns `true` if any of the arguments are not `nil`.
---
--- Parameters:
---  * ... - The arguments to check.
---
--- Returns:
---  * `true` if any of the arguments are not `nil`, `false` if not.
function mod.hasAny(...)
    return not mod.hasNone(...)
end

return mod