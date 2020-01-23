--- === plugins.core.tangent.manager.binding ===
---
--- Represents a Tangent Binding

local require = require

local class             = require "middleclass"
local x                 = require "cp.web.xml"
local parameter         = require "parameter"

local format            = string.format
local insert            = table.insert


local binding = class "core.tangent.manager.binding"

--- plugins.core.tangent.manager.binding(id[, name]) -> binding
--- Constructor
--- Creates a new `Binding` instance.
---
--- Parameters:
--- * id        - The ID number of the binding.
--- * name      - The name of the binding.
---
--- Returns:
--- * the new `binding`.
function binding:initialize(name)
    self.name = name
    self._members = {}
end

--- plugins.core.tangent.manager.binding:member(parameter) -> self
--- Method
--- Adds a `parameter` as a member of the Binding group. The order is significant
--- - it will determine the order the parameters are applied to group controls in the Mapper.
---
--- Parameters:
--- * param     - The `parameter` to add to the binding.
---
--- Returns:
--- * The `binding` instance.
function binding:member(param)
    assert(parameter.is(param))
    insert(self._members, param)
    return self
end

--- plugins.core.tangent.manager.binding:members(...) -> self
--- Method
--- Adds the list of parameters to this binding.
---
--- Parameters:
--- * ...   - the list of parameters to bind.
---
--- Returns:
--- * The `binding` instance.
function binding:members(...)
    for i = 1,select("#", ...) do
        self:member(select(i, ...))
    end
    return self
end

--- plugins.core.tangent.manager.binding:xml() -> cp.web.xml
--- Method
--- Returns the `xml` configuration for the Binding.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `xml` for the Binding.
function binding:xml()
    return x.Binding { name=self.name } (
        function()
            local result = x()
            for _,member in ipairs(self._members) do
                result( x.Member {id = format("%#010x", member.id)} )
            end
            return result
        end
    )
end

return binding
