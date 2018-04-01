--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                T A N G E N T    M A N A G E R    P L U G I N               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.tangent.manager.group ===
---
--- Represents a Tangent Group
local prop              = require("cp.prop")
local x                 = require("cp.web.xml")
local is                = require("cp.is")

local action            = require("action")
local parameter         = require("parameter")
local menu              = require("menu")
local binding           = require("binding")

local insert            = table.insert
local format            = string.format

local group = {}

group.mt = {}

--- plugins.core.tangent.manager.group.new(name, controls)
--- Constructor
--- Creates a new `Group` instance.
---
--- Parameters:
--- * name      - The name of the group.
--- * controls  - The `controls` instance
function group.new(name, controls)
    if is.blank(name) then
        error("Group names cannot be empty")
    end
    local o = prop.extend({
        name = name,
        controls = controls,

        --- plugins.core.tanget.group.enabled <cp.prop: boolean>
        --- Field
        --- Indicates if the group is enabled.
        enabled = prop.FALSE(),
    }, group.mt)

    return o
end

--- plugins.core.tangent.manager.group:group(name) -> group
--- Method
--- Adds a subgroup to this group.
---
--- Parameters
--- * name  - the name of the new sub-group
---
--- Returns:
--- * The new `group`
function group.mt:group(name)
    local groups = self._groups
    if not groups then
        groups = {}
        self._groups = groups
    end

    local g = group.new(name, self.controls)
    insert(groups, g)

    return g
end

--- plugins.core.tangent.manager.group:action(id[, name]) -> action
--- Method
--- Adds an `action` to this group.
---
--- Parameters
--- * id    - The ID number of the new action
--- * name  - The name of the action.
---
--- Returns:
--- * The new `action`
function group.mt:action(id, name)
    local actions = self._actions
    if not actions then
        actions = {}
        self._actions = actions
    end

    local a = action.new(id, name)
    insert(actions, a)
    if self.controls then
        self.controls:register(a)
    end

    return a
end

--- plugins.core.tangent.manager.group:parameter(id[, name]) -> parameter
--- Method
--- Adds an `parameter` to this group.
---
--- Parameters
--- * id    - The ID number of the new parameter
--- * name  - The name of the parameter.
---
--- Returns:
--- * The new `parameter`
function group.mt:parameter(id, name)
    local parameters = self._parameters
    if not parameters then
        parameters = {}
        self._parameters = parameters
    end

    local a = parameter.new(id, name)
    insert(parameters, a)
    if self.controls then
        self.controls:register(a)
    end

    return a
end

--- plugins.core.tangent.manager.group:menu(id[, name]) -> menu
--- Method
--- Adds an `menu` to this group.
---
--- Parameters
--- * id    - The ID number of the new menu
--- * name  - The name of the menu.
---
--- Returns:
--- * The new `menu`
function group.mt:menu(id, name)
    local menus = self._menus
    if not menus then
        menus = {}
        self._menus = menus
    end

    local a = menu.new(id, name)
    insert(menus, a)
    if self.controls then
        self.controls:register(a)
    end

    return a
end

--- plugins.core.tangent.manager.group:binding(id[, name]) -> binding
--- Method
--- Adds an `binding` to this group.
---
--- Parameters
--- * id    - The ID number of the new binding
--- * name  - The name of the binding.
---
--- Returns:
--- * The new `binding`
function group.mt:binding(name)
    local bindings = self._bindings
    if not bindings then
        bindings = {}
        self._bindings = bindings
    end

    local a = binding.new(name)
    insert(bindings, a)

    return a
end

--- plugins.core.tangent.manager.group:xml() -> cp.web.xml
--- Method
--- Returns the `xml` configuration for the Group.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `xml` for the Group.
function group.mt:xml()
    return x.Group { name=self.name } (
        function()
            local result = x()

            if self._groups then
                for _,v in ipairs(self._groups) do
                    result = result .. v:xml()
                end
            end
            if self._actions then
                for _,v in ipairs(self._actions) do
                    result = result .. v:xml()
                end
            end
            if self._parameters then
                for _,v in ipairs(self._parameters) do
                    result = result .. v:xml()
                end
            end
            if self._menus then
                for _,v in ipairs(self._menus) do
                    result = result .. v:xml()
                end
            end
            if self._bindings then
                for _,v in ipairs(self._bindings) do
                    result = result .. v:xml()
                end
            end

            return result
        end
    )
end

function group.mt:__tostring()
    return format("group: %s", self.name)
end

return group
