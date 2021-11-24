--- === cp.collect.LazyList ===
---
--- A LazyList is a list that is lazily evaluated. It will dynamically create items on demand,
--- and may cache the results if configured to do so.
---
--- It works by requiring two functions which provide information about the length and item at a given index.
--- The `len` function is called when the length of the list is required, and the `get` function is called when
--- an item is required.
---
--- This allows the list to be created lazily, and the items to be created on demand. That is useful for
--- lists that are expensive to create, but are only required when they are actually used.

-- local log                       = require("hs.logger").new("LazyList")

local mod = {}

--- cp.collect.LazyList.new(lenFn, getFn[, options]) -> cp.collect.LazyList
--- Constructor
--- Creates a new `LazyList` with the provided `lenFn` and `getFn`, and a table with options.
---
--- Parameters:
---  * lenFn - A function that returns the length of the list.
---  * getFn - A function that returns the item at the specified index.
---  * options - A table of options.
---
--- Returns:
---  * A new `LazyList` instance.
---
--- Notes:
---  * The `lenFn` function has the signature `function() -> number`.
---  * The `getFn` function has the signature `function(index) -> item`.
---  * The `options` table has the following keys:
---   * `cached` - A boolean indicating whether the list should cache the results of the `getFn`. Defaults to `false`.
function mod.new(lenFn, getFn, options)
    options = options or {}

    local mt = {
        -- retrieves items from the list.
        __index = function(t, k)
            -- if it's a number, fetch it
            if type(k) == "number" then
                local result = getFn(k)
                if options.cached then
                    rawset(t, k, result)
                end
                return result
            end
        end,
        -- sets items to the list
        __newindex = function(_, _, _)
            -- read-only. do nothing.
            error("Unable to set values in a LazyList.", 2)
        end,
        -- returns the length of the list.
        __len = function(_)
            return lenFn()
        end,
        -- iterates through the list, returning non-nil key/value pairs.
        __pairs = function(self)
            return function(t, k)
                k = k or 0
                local len = #t
                while k < len do
                    k = k + 1
                    local result = t[k]
                    if result ~= nil then
                        return k, result
                    end
                end
            end, self, nil
        end,
        -- weak references to cached values.
        __mode = "v",
        -- describes the object.
        __tostring = function(_)
            return "cp.collect.LazyList"
        end,
    }

    return setmetatable({}, mt)
end

return setmetatable(mod, {
    __call = function(_, ...) return mod.new(...) end,
})