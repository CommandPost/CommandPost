--- === plugins.core.touchbar.location ===
---
--- Virtual Touch Bar Update Location Callback


local mod = {}

-- plugins.core.touchbar.location._items -> table
-- Variable
-- Items
mod._items = {}

--- plugins.core.touchbar.location:new(id, callbackFn) -> table
--- Method
--- Creates a new Update Location Callback
---
--- Parameters:
--- * `id`      - The unique ID for this callback.
---
--- Returns:
---  * table that has been created
function mod:new(id, callbackFn)

    if mod._items[id] ~= nil then
        error("Duplicate Update Location Callback: " .. id)
    end
    local o = {
        _id = id,
        _callbackFn = callbackFn,
    }
    setmetatable(o, self)
    self.__index = self

    mod._items[id] = o
    return o

end

--- plugins.core.touchbar.location:get(id) -> table
--- Method
--- Gets an Update Location Callback based on an ID.
---
--- Parameters:
--- * `id`      - The unique ID for the callback you want to return.
---
--- Returns:
---  * table containing the callback
function mod:get(id)
    return self._items[id]
end

--- plugins.core.touchbar.location:getAll() -> table
--- Method
--- Returns all of the created Update Location Callbacks
---
--- Parameters:
--- * None
---
--- Returns:
---  * table containing all of the created callbacks
function mod:getAll()
    return self._items
end

--- plugins.core.touchbar.location:id() -> string
--- Method
--- Returns the ID of the current Update Location Callback
---
--- Parameters:
--- * None
---
--- Returns:
---  * The ID of the current File Dropped to Dock Icon Callback as a `string`
function mod:id()
    return self._id
end

--- plugins.core.touchbar.location:callbackFn() -> function
--- Method
--- Returns the callbackFn of the current Update Location Callback
---
--- Parameters:
--- * None
---
--- Returns:
---  * The callbackFn of the current Shutdown Callback
function mod:callbackFn()
    return self._callbackFn
end

--- plugins.core.touchbar.location:delete() -> none
--- Method
--- Deletes a Update Location Callback based on an ID.
---
--- Parameters:
--- * None
---
--- Returns:
---  * None
function mod:delete()
    mod._items[self._id] = nil
end

return mod
