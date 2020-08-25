--- === plugins.core.tangent.manager.group ===
---
--- Represents a Tangent Group. Groups can also be used to enable/disable multiple
--- Parameters/Actions/Menus by enabling/disabling the containing group.

-- local log               = require "hs.logger" .new "group"

local require = require

local class             = require "middleclass"
local lazy              = require "cp.lazy"
local is                = require "cp.is"
local prop              = require "cp.prop"
local tools             = require "cp.tools"
local x                 = require "cp.web.xml"

local action            = require "action"
local parameter         = require "parameter"
local menu              = require "menu"
local binding           = require "binding"

local insert            = table.insert
local format            = string.format


local group = class "core.tangent.manager.group" :include(lazy)

--- plugins.core.tangent.manager.group(name[, parent[, localActive]])
--- Constructor
--- Creates a new `Group` instance.
---
--- Parameters:
---  * name      - The name of the group.
---  * parent    - The parent group.
---  * localActive - If `true`, this group will ignore the parent's `active` status when determining its own `active` status. Defaults to `false`.
function group:initialize(name, parent, localActive)
    if is.blank(name) then
        error("Group names cannot be empty")
    end

    self._name = name
    self._parent = parent
    self._localActive = localActive
end

--- plugins.core.tangent.manager.group.enabled <cp.prop: boolean>
--- Field
--- Indicates if the group is enabled.
function group.lazy.prop.enabled()
    return prop.TRUE()
end

--- plugins.core.tangent.manager.group.localActive <cp.prop: boolean>
--- Field
--- Indicates if the group should ignore the parent's `enabled` state when determining if the group is active.
function group.lazy.prop:localActive()
    return prop.THIS(self._localActive == true)
end

--- plugins.core.tangent.manager.group.active <cp.prop: boolean; read-only>
--- Field
--- Indicates if the group is active. It will only be active if
--- the current group is `enabled` and if the parent group (if present) is `active`.
function group.lazy.prop:active()
    local parent = self:parent()
    return parent and prop.AND(self.localActive:OR(parent.active), self.enabled) or self.enabled:IMMUTABLE()
end

--- plugins.core.tangent.manager.group.is(thing) -> boolean
--- Function
--- Checks if the `thing` is a `group`.
---
--- Parameters:
---  * thing    - The thing to check.
---
--- Returns:
---  * `true` if it is a `group`, `false` otherwise.
function group.static.is(thing)
    return type(thing) == "table" and thing.isInstanceOf ~= nil and thing:isInstanceOf(group)
end

--- plugins.core.tangent.manager.group:name() -> string
--- Method
--- Returns the `name` given to the group.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The name.
function group:name()
    return self._name
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
function group:parent()
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
function group:controls()
    local parent = self:parent()
    if group.is(parent) then
        return parent:controls()
    else
        return parent
    end
end

--- plugins.core.tangent.manager.group:group(name[, localActive]) -> group
--- Method
--- Adds a subgroup to this group.
---
--- Parameters
---  * name  - the name of the new sub-group
---  * localActive - If `true`, this group will ignore the parent's `active` status when determining its own `active` status. Defaults to `false`.
---
--- Returns:
---  * The new `group`
function group:group(name, localActive)
    local groups = self._groups
    if not groups then
        groups = {}
        self._groups = groups
    end

    local g = group(name, self, localActive)
    insert(groups, g)

    return g
end

function group:_register(control)
    local controls = self:controls()
    if controls then
        controls:register(control)
    end
end

function group:_unregister(control)
    local controls = self:controls()
    if controls then
        controls:unregister(control)
    end
end

function group:_unregisterAll(controlList)
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
function group:action(id, name, localActive)
    local actions = self._actions
    if not actions then
        actions = {}
        self._actions = actions
    end

    local a = action(id, name, self, localActive)
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
function group:parameter(id, name)
    local parameters = self._parameters
    if not parameters then
        parameters = {}
        self._parameters = parameters
    end

    local a = parameter(id, name, self)
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
function group:menu(id, name)
    local menus = self._menus
    if not menus then
        menus = {}
        self._menus = menus
    end

    local a = menu(id, name, self)
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
function group:binding(name)
    local bindings = self._bindings
    if not bindings then
        bindings = {}
        self._bindings = bindings
    end

    local a = binding(name, self)
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
function group:reset()
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
function group:xml()
    return x.Group { name=self:name() } (
        function()
            local result = x()

            if self._groups then
                for _,v in tools.spairs(self._groups, function(t,a,b) return t[b]:name() > t[a]:name() end) do
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
                for _,v in tools.spairs(self._bindings, function(t,a,b) return t[b]:name() > t[a]:name() end) do
                    result = result .. v:xml()
                end
            end

            return result
        end
    )
end

function group:__tostring()
    return format("group: %s", self._name)
end

return group
