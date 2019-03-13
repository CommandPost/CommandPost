--- === plugins.core.midi.manager.controls ===
---
--- MIDI Manager Controls.

local require = require

local tools = require("cp.tools")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

-- plugins.core.midi.manager.controls._items -> table
-- Variable
-- Table of MIDI Controls
mod._items = {}

--- plugins.core.midi.manager.controls:new(id, params) -> table
--- Method
--- Creates a new MIDI control.
---
--- Parameters:
---  * id       - The unique ID for this widget.
---  * params   - A table of parameters for the MIDI control.
---
--- Returns:
---  * table that has been created
---
--- Notes:
---  * The parameters table should include:
---    * group      - The group as a string (i.e. "fcpx")
---    * text       - The name of the control as it will appear in the Console
---    * subText    - The subtext of the control as it will appear in the Console
---    * fn         - The callback function. This functions should accept one parameter
---                   which contains all the MIDI callback metadata.
function mod:new(id, params)
    if mod._items[id] ~= nil then
        error("Duplicate Control ID: " .. id)
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

--- plugins.core.midi.manager.controls:get(id) -> table
--- Method
--- Gets a MIDI control.
---
--- Parameters:
---  * `id`      - The unique ID for the widget you want to return.
---
--- Returns:
---  * table containing the widget
function mod:get(id)
    return self._items[id]
end

--- plugins.core.midi.manager.controls:getAll() -> table
--- Method
--- Returns all of the created controls.
---
--- Parameters:
---  * None
---
--- Returns:
---  * table containing all of the created callbacks
function mod:getAll()
    return self._items
end

--- plugins.core.midi.manager.controls:id() -> string
--- Method
--- Returns the ID of the control.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The ID of the widget as a `string`
function mod:id()
    return self._id
end

--- plugins.core.midi.manager.controls:params() -> function
--- Method
--- Returns the paramaters of the control.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The paramaters of the widget
function mod:params()
    return self._params
end

--- plugins.core.midi.manager.controls.allGroups() -> table
--- Function
--- Returns a table containing all of the control groups.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Table
function mod.allGroups()
    local result = {}
    local allControls = mod:getAll()
    for _, widget in pairs(allControls) do
        local params = widget:params()
        if params and params.group then
            if not tools.tableContains(result, params.group) then
                table.insert(result, params.group)
            end
        end
    end
    return result
end

return mod
