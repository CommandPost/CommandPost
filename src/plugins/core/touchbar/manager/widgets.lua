--- === plugins.core.touchbar.manager.widgets ===
---
--- Touch Bar Widgets Manager

local require = require

local tools                                     = require("cp.tools")

local insert                                    = table.insert
local tableContains                             = tools.tableContains


local mod = {}

-- plugins.core.touchbar.manager.widgets._items -> table
-- Variable
-- Touch Bar Widget Items
mod._items = {}

--- plugins.core.touchbar.manager.widgets:new(id, params) -> table
--- Method
--- Creates a new Touch Bar Widget.
---
--- Parameters:
--- * `id`      - The unique ID for this widget.
---
--- Returns:
---  * table that has been created
function mod:new(id, params)
    if mod._items[id] ~= nil then
        error("Duplicate Widget ID: " .. id)
    end
    local o = {
        _id = id,
        _params = params,
    }
    setmetatable(o, self)
    self.__index = self
    mod._items[id] = o
    return o
end

--- plugins.core.touchbar.manager.widgets:get(id) -> table
--- Method
--- Gets a Touch Bar widget
---
--- Parameters:
--- * `id`      - The unique ID for the widget you want to return.
---
--- Returns:
---  * table containing the widget
function mod:get(id)
    return self._items[id]
end

--- plugins.core.touchbar.manager.widgets:getAll() -> table
--- Method
--- Returns all of the created widgets
---
--- Parameters:
--- * None
---
--- Returns:
---  * table containing all of the created callbacks
function mod:getAll()
    return self._items
end

--- plugins.core.touchbar.manager.widgets:id() -> string
--- Method
--- Returns the ID of the widget
---
--- Parameters:
--- * None
---
--- Returns:
---  * The ID of the widget as a `string`
function mod:id()
    return self._id
end

--- plugins.core.touchbar.manager.widgets:params() -> function
--- Method
--- Returns the paramaters of the widget
---
--- Parameters:
--- * None
---
--- Returns:
---  * The paramaters of the widget
function mod:params()
    return self._params
end

--- plugins.core.touchbar.manager.widgets.allGroups() -> table
--- Function
--- Returns a table containing all of the widget groups.
---
--- Parameters:
--- * None
---
--- Returns:
---  * Table
function mod.allGroups()
    local result = {}
    local theWidgets = mod:getAll()
    for _, widget in pairs(theWidgets) do
        local params = widget:params()
        if params and params.group then
            if not tableContains(result, params.group) then
                insert(result, params.group)
            end
        end
    end
    return result
end

return mod
