--- === plugins.core.tangent.manager.group ===
---
--- Represents a Tangent Group. Groups can also be used to enable/disable multiple
--- Parameters/Actions/Menus by enabling/disabling the containing group.

local require = require

local is                = require("cp.is")
local prop              = require("cp.prop")
local tools             = require("cp.tools")
local x                 = require("cp.web.xml")

local action            = require("action")
local parameter         = require("parameter")
local menu              = require("menu")
local binding           = require("binding")

local insert            = table.insert
local format            = string.format

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local group = {}
group.mt = {}

--- plugins.core.tangent.manager.group.new(name, parent, controls)
--- Constructor
--- Creates a new `Group` instance.
---
--- Parameters:
---  * name      - The name of the group.
---  * parent    - The parent group.
function group.new(name, parent)
    if is.blank(name) then
        error("Group names cannot be empty")
    end
    local o = prop.extend({
        name = name,
        _parent = parent,

        --- plugins.core.tangent.manager.group.enabled <cp.prop: boolean>
        --- Field
        --- Indicates if the group is enabled.
        enabled = prop.TRUE(),
    }, group.mt)

    prop.bind(o) {
        --- plugin.core.tangent.manager.group.active <cp.prop: boolean; read-only>
        --- Field
        --- Indicates if the group is active. It will only be active if
        --- the current group is `enabled` and if the parent group (if present) is `active`.
        active = parent and parent.active:AND(o.enabled) or o.enabled:IMMUTABLE(),
    }

    return o
end

--- plugins.core.tangent.manager.group.is(otherThing) -> boolean
--- Function
--- Checks if the `otherThing` is a `group`.
---
--- Parameters:
---  * otherThing    - The thing to check.
---
--- Returns:
---  * `true` if it is a `group`, `false` otherwise.
function group.is(otherThing)
    return is.table(otherThing) and getmetatable(otherThing) == group.mt
end

--- plugins.core.tangent.manager.group:parent() -> group | controls
--- Method
--- Returns the parent of the group, which should be either a `group`, `controls` or `nil`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The group's parents.
function group.mt:parent()
    return self._parent
end

--- plugins.core.tangent.manager.group:controls() -> controls
--- Method
--- Retrieves the `controls` for this group. May be `nil` if the group was created independently.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `controls`, or `nil`.
function group.mt:controls()
    local parent = self:parent()
    if group.is(parent) then
        return parent:controls()
    else
        return parent
    end
end

--- plugins.core.tangent.manager.group:group(name) -> group
--- Method
--- Adds a subgroup to this group.
---
--- Parameters
---  * name  - the name of the new sub-group
---
--- Returns:
---  * The new `group`
function group.mt:group(name)
    local groups = self._groups
    if not groups then
        groups = {}
        self._groups = groups
    end

    local g = group.new(name, self)
    insert(groups, g)

    return g
end

function group.mt:_register(control)
    local controls = self:controls()
    if controls then
        controls:register(control)
    end
end

function group.mt:_unregister(control)
    local controls = self:controls()
    if controls then
        controls:unregister(control)
    end
end

function group.mt:_unregisterAll(controlList)
    if controlList then
        for _,c in ipairs(controlList) do
            self:_unregister(c)
        end
    end
end

--- plugins.core.tangent.manager.group:action(id[, name[, localActive]]) -> action
--- Method
--- Adds an `action` to this group.
---
--- Parameters
---  * id    - The ID number of the new action
---  * name  - The name of the action.
---  * localActive - If true, the parent group's `active` state is ignored when determining if this action is active.
---
--- Returns:
---  * The new `action`
function group.mt:action(id, name, localActive)
    local actions = self._actions
    if not actions then
        actions = {}
        self._actions = actions
    end

    local a = action.new(id, name, self, localActive)
    insert(actions, a)

    self:_register(a)

    return a
end

--- plugins.core.tangent.manager.group:parameter(id[, name]) -> parameter
--- Method
--- Adds an `parameter` to this group.
---
--- Parameters
---  * id    - The ID number of the new parameter
---  * name  - The name of the parameter.
---
--- Returns:
---  * The new `parameter`
function group.mt:parameter(id, name)
    local parameters = self._parameters
    if not parameters then
        parameters = {}
        self._parameters = parameters
    end

    local a = parameter.new(id, name, self)
    insert(parameters, a)

    self:_register(a)

    return a
end

--- plugins.core.tangent.manager.group:menu(id[, name]) -> menu
--- Method
--- Adds an `menu` to this group.
---
--- Parameters
---  * id    - The ID number of the new menu
---  * name  - The name of the menu.
---
--- Returns:
---  * The new `menu`
function group.mt:menu(id, name)
    local menus = self._menus
    if not menus then
        menus = {}
        self._menus = menus
    end

    local a = menu.new(id, name, self)
    insert(menus, a)

    self:_register(a)

    return a
end

--- plugins.core.tangent.manager.group:binding(id[, name]) -> binding
--- Method
--- Adds an `binding` to this group.
---
--- Parameters
---  * id    - The ID number of the new binding
---  * name  - The name of the binding.
---
--- Returns:
---  * The new `binding`
function group.mt:binding(name)
    local bindings = self._bindings
    if not bindings then
        bindings = {}
        self._bindings = bindings
    end

    local a = binding.new(name, self)
    insert(bindings, a)

    return a
end

--- plugins.core.tangent.manager.group:reset() -> self
--- Method
--- This will remove all parameters, actions, menus and bindings from
--- the group. It does not remove sub-groups. Use with care!
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `group` instance.
function group.mt:reset()
    self:_unregisterAll(self._actions)
    self:_unregisterAll(self._parameters)
    self:_unregisterAll(self._menus)

    self._actions = nil
    self._parameters = nil
    self._menus = nil
end

--- plugins.core.tangent.manager.group:xml() -> cp.web.xml
--- Method
--- Returns the `xml` configuration for the Group, sorted alphabetically.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `xml` for the Group.
function group.mt:xml()
    return x.Group { name=self.name } (
        function()
            local result = x()

            if self._groups then
                for _,v in tools.spairs(self._groups, function(t,a,b) return t[b].name > t[a].name end) do
                    result = result .. v:xml()
                end
            end
            if self._actions then
                for _,v in tools.spairs(self._actions, function(t,a,b) return t[b]:name() > t[a]:name() end) do
                    result = result .. v:xml()
                end
            end
            if self._parameters then
                for _,v in tools.spairs(self._parameters, function(t,a,b) return t[b]:name() > t[a]:name() end) do
                    result = result .. v:xml()
                end
            end
            if self._menus then
                for _,v in tools.spairs(self._menus, function(t,a,b) return t[b]:name() > t[a]:name() end) do
                    result = result .. v:xml()
                end
            end
            if self._bindings then
                for _,v in tools.spairs(self._bindings, function(t,a,b) return t[b].name > t[a].name end) do
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
