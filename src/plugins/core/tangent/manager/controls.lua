--- === plugins.core.tangent.manager.controls ===
---
--- Represents a Tangent Group

local require = require

local prop              = require("cp.prop")
local tools             = require("cp.tools")
local x                 = require("cp.web.xml")

local action            = require("action")
local group             = require("group")
local menu              = require("menu")
local parameter         = require("parameter")

local insert            = table.insert

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local controls = {}
controls.mt = {}

--- plugins.core.tangent.manager.controls.new(id, name)
--- Constructor
--- Creates a new `Group` instance.
---
--- Parameters:
--- * name      - The name of the controls.
function controls.new()
    local o = prop.extend({
        ids = {},

        --- plugins.core.tangent.controls.enabled <cp.prop: boolean>
        --- Field
        --- Indicates if the controls are enabled.
        enabled = prop.TRUE(),
    }, controls.mt)

    prop.bind(o) {
        --- plugins.core.tangent.controls.active <cp.prop: boolean; read-only>
        --- Field
        --- Indicates if the controls are active. They will be active if `enabled` is `true`.
        active = o.enabled:IMMUTABLE()
    }

    return o
end

--- plugins.core.tangent.manager.controls:parent() -> nil
--- Method
--- Always returns `nil`, sinces `controls` have no parent.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `nil`.
function controls.mt.parent()
    return nil
end

--- plugins.core.tangent.manager.controls:controls() -> controls
--- Method
--- Returns this `controls` instance.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `controls instance.
function controls.mt:controls()
    return self
end

--- plugins.core.tangent.manager.controls:register(control) -> self
--- Method
--- Registers a control (Action/Parameter/Menu) with it's ID
--- This allows efficient retrieval via the `findById(...)` method, as well
--- as checking that ID is unique.
---
--- Parameters:
--- * control       - The Action/Parameter/Menu to register
---
--- Returns:
--- * self
function controls.mt:register(control)
    if control.id == nil then
        error("The control must have an ID")
    end
    if self.ids[control.id] ~= nil then
        error("There is already a control with the same ID: %s", control.id)
    end
    self.ids[control.id] = control
    return self
end

--- plugins.core.tangent.manager.controls:unregister(control) -> self
--- Method
--- Unregisters a control (Action/Parameter/Menu) with it's ID
---
--- Parameters:
--- * control       - The Action/Parameter/Menu to unregister
---
--- Returns:
--- * self
function controls.mt:unregister(control)
    if control.id == nil then
        error("The control must have an ID")
    end
    if self.ids[control.id] ~= nil then
        self.ids[control.id] = nil
    end
    return self
end

--- plugins.core.tangent.manager.controls:findByID(id) -> table
--- Method
--- Finds a control (Action/Parameter/Mode) by its unique ID.
---
--- Parameters:
--- * id        - the ID to search by
---
--- Returns:
--- * The control, or `nil` if not found.
function controls.mt:findByID(id)
    return self.ids[id]
end

--- plugins.core.tangent.manager.controls:group(name) -> group
--- Method
--- Adds a subgroup to this group.
---
--- Parameters
--- * name  - the name of the new sub-group
---
--- Returns:
--- * The new `group`
function controls.mt:group(name)
    local groups = self._groups
    if not groups then
        groups = {}
        self._groups = groups
    end

    local g = group.new(name, self)
    insert(groups, g)

    return g
end

--- plugins.core.tangent.manager.controls:action(id[, name]) -> action
--- Method
--- Adds an `action` to this controls.
---
--- Parameters
--- * id    - The ID number of the new action
--- * name  - The name of the action.
---
--- Returns:
--- * The new `action`
function controls.mt:action(id, name)
    local actions = self._actions
    if not actions then
        actions = {}
        self._actions = actions
    end

    local a = action.new(id, name, self)
    insert(actions, a)
    self:register(a)

    return a
end

--- plugins.core.tangent.manager.controls:parameter(id[, name]) -> parameter
--- Method
--- Adds an `parameter` to this controls.
---
--- Parameters
--- * id    - The ID number of the new parameter
--- * name  - The name of the parameter.
---
--- Returns:
--- * The new `parameter`
function controls.mt:parameter(id, name)
    local parameters = self._parameters
    if not parameters then
        parameters = {}
        self._parameters = parameters
    end

    local a = parameter.new(id, name, self)
    insert(parameters, a)
    self:register(a)

    return a
end

--- plugins.core.tangent.manager.controls:menu(id[, name]) -> menu
--- Method
--- Adds an `menu` to this controls.
---
--- Parameters
--- * id    - The ID number of the new menu
--- * name  - The name of the menu.
---
--- Returns:
--- * The new `menu`
function controls.mt:menu(id, name)
    local menus = self._menus
    if not menus then
        menus = {}
        self._menus = menus
    end

    local a = menu.new(id, name, self)
    insert(menus, a)
    self:register(a)

    return a
end

--- plugins.core.tangent.manager.controls:xml() -> cp.web.xml
--- Method
--- Returns the `xml` configuration for the Group.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `xml` for the Group.
function controls.mt:xml()
    return x.Controls (
        function()
            local result = x()

            if self._groups then
                for _,v in tools.spairs(self._groups, function(t,a,b) return t[b].name > t[a].name end) do
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

            return result
        end
    )
end

return controls
