--- === cp.commands.command ===
---
--- Commands Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log					= require("hs.logger").new("command")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local shortcut		  = require("cp.commands.shortcut")
local prop					= require("cp.prop")
local i18n          = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local command = {}
command.mt = {}
command.mt.__index = command.mt

--- cp.commands.command.new() -> command
--- Method
--- Creates a new command, which can have keyboard shortcuts assigned to it.
---
--- Parameters:
---  * `id`		- the unique identifier for the command. E.g. 'cpCustomCommand'
---  * `parent`	- The parent group.
---
--- Returns:
---  * command - The command that was created.
---
function command.new(id, parent)
    local o = prop.extend({
        _id = id,
        _parent = parent,
        _shortcuts = {},
    }, command.mt)

--- cp.commands.command.isEnabled <cp.prop: boolean>
--- Field
--- If set to `true`, the command is enabled.
    local isEnabled = prop.TRUE()

--- cp.commands.command.isActive <cp.prop: boolean; read-only>
--- Field
--- Indicates if the command is active. To be active, both the command and the group it belongs to must be enabled.
    local isActive = isEnabled:AND(parent.isEnabled):watch(function(active)
        for _,sc in ipairs(o._shortcuts) do
            sc:isEnabled(active)
        end
    end, true)

    prop.bind(o) {
        isEnabled = isEnabled,
        isActive = isActive,
    }

    return o
end

--- cp.commands.command:id() -> string
--- Method
--- Returns the ID for this command.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The ID.
function command.mt:id()
    return self._id
end

--- cp.commands.command:parent() -> cp.commands
--- Method
--- Returns the parent command group.
---
--- Parameters:
--- * None
---
--- Returns
--- * The parent `cp.commands`.
function command.mt:parent()
    return self._parent
end

--- cp.commands.command:titled(title) -> command
--- Method
--- Applies the provided human-readable title to the command.
---
--- Parameters:
---  * id - the unique identifier for the command (i.e. 'CPCustomCommand').
---
--- Returns:
---  * command - The command that was created.
function command.mt:titled(title)
    self._title = title
    return self
end

--- cp.commands.command:action(getFn, setFn) -> command
--- Method
--- Sets the action get and set callbacks for a specific command.
---
--- Parameters:
---  * getFn - The function that gets the action.
---  * setFn - The function that sets the action.
---
--- Returns:
---  * command - The command that was created.
---
--- Notes:
---  * The `getFn` function should have no arguments.
---  * The `setFn` function can have two optional arguments:
---    * `clear` - A boolean that defines whether or not the value should be cleared.
---    * `completionFn` - An optional completion function callback.
function command.mt:action(getFn, setFn)
    self._actionGetFn = getFn
    self._actionSetFn = setFn
    return self
end

--- cp.commands.command:getAction() -> function, function
--- Method
--- Gets the action get and set callbacks for a specific command.
---
--- Parameters:
---  * None
---
--- Returns:
---  * getFn - The function that gets the action.
---  * setFn - The function that sets the action.
function command.mt:getAction()
    return self._actionGetFn, self._actionSetFn
end

--- cp.commands.command:hasAction() -> boolean
--- Method
--- Gets whether or not any action callbacks have been assigned.
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` if action callbacks have been assigned, otherwise `false`.
function command.mt:hasAction()
    return (self._actionGetFn ~= nil and self._actionSetFn ~= nil) or false
end

--- cp.commands.command:getTitle() -> string
--- Method
--- Returns the command title in the current language, if availalbe. If not, the ID is returned.
---
--- Parameters:
--- * None
---
--- Returns
--- * The human-readable command title.
function command.mt:getTitle()
    if self._title then
        return self._title
    else
        return i18n(self:id() .. "_title", {default = self:id()})
    end
end

--- cp.commands.command:subtitled(subtitle) -> cp.commands.command
--- Method
--- Sets the specified subtitle and returns the `cp.commands.command` instance.
---
--- Note: By default, it will look up the `<ID>_subtitle` value.
--- Anything set here will override it in all langauges.
---
--- Parameters:
--- * `subtitle`	- The new subtitle.
function command.mt:subtitled(subtitle)
    self._subtitle = subtitle
    return self
end

--- cp.commands.command:getSubtitle() -> string
--- Method
--- Returns the current subtitle, based on either the set subtitle, or the "<ID>_subtitle" value in the I18N files.
--- If nothing is available, it will return `nil`.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The subtitle value or `nil`.
function command.mt:getSubtitle()
    if self._subtitle then
        return self._subtitle
    else
        return i18n(self:id() .. "_subtitle")
    end
end

--- cp.commands.command:groupedBy(group) -> cp.commands.command
--- Method
--- Specifies that the command is grouped by a specific value.
--- Note: This is different to the command group/parent value.
---
--- Parameters:
--- * `group`	- The group ID.
---
--- Returns:
--- * The `cp.commands.command` instance.
function command.mt:groupedBy(group)
    self._group = group
    return self
end

--- cp.commands.command:getGroup() -> string
--- Method
--- Returns the group ID for the command.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The group ID.
function command.mt:getGroup()
    return self._group
end

--- cp.commands.command:activatedBy([modifiers,] [keyCode]) -> command/modifier
--- Method
--- Specifies that the command is activated by pressing a key combination.
--- This method can be called multiple times, and multiple key combinations will be registered for the command.
--- To remove existing key combinations, call the `command:deleteShortcuts()` method.
---
--- * If the `keyCode` is provided, no modifiers need to be pressed to activate and the `command` is returned.
--- * If the `modifiers` and `keyCode` are provided, the combination is created and the `command` is returned.
--- * If no `keyCode` is provided, a `modifier` is returned, which lets you specify keyboard combinations.
---
--- For example:
---
--- ```
--- local global    	= commands.collection("global")
--- local pressA 		= global:add("commandA"):activatedBy("a")
--- local pressShiftA	= global:add("commandShiftA"):activatedBy({"shift"}, "a")
--- local pressCmdA		= global:add("commandCmdA"):activatedBy():command("a")
--- local pressOptCmdA	= global:add("commandOptCmdA"):activatedBy():option():command("a")
--- global:enable()
--- ```
---
--- Parameters:
---  * `modifiers`	- (optional) The table containing names of required modifiers.
---  * `keyCode`	- (optional) The key code that will activate the command, with no modifiers.
---
--- Returns:
---  * `command` if a `keyCode` was provided, or `modifier` if not.
function command.mt:activatedBy(modifiers, keyCode)
    if keyCode and not modifiers then
        modifiers = {}
    elseif modifiers and not keyCode then
        keyCode = modifiers
        modifiers = {}
    end

    if keyCode then
        self:addShortcut(shortcut.new(modifiers, keyCode))
        return self
    else
        return shortcut.build(
            function(newShortcut)
                return self:addShortcut(newShortcut)
            end
        )
    end
end

--- cp.commands.command:deleteShortcuts() -> command
--- Method
--- Sets the function that will be called when the command key combo is pressed.
---
--- Parameters:
---  * None
---
--- Returns:
---  * command - The current command
---
function command.mt:deleteShortcuts()
    for _,sc in ipairs(self._shortcuts) do
        sc:delete()
    end
    self._shortcuts = {}
    return self
end

--- cp.commands.command:setShortcuts(shortcuts) -> command
--- Method
--- Deletes any existing shortcuts and applies the new set of shortcuts in the table.
---
--- Parameters:
--- * shortcuts		- The set of `cp.commands.shortcuts` to apply to this command.
---
--- Returns:
--- * The `cp.commands.command` instance.
function command.mt:setShortcuts(shortcuts)
    self:deleteShortcuts()
    for _,newShortcut in ipairs(shortcuts) do
        self:addShortcut(newShortcut)
    end
    return self
end

--- cp.commands.command:addShortcut(newShortcut) -> command
--- Method
--- Adds the specified shortcut to the command.
--- If the command is enabled, the shortcut will also be enabled.
---
--- Parameters:
---  * `newShortcut`	- the shortcut to add.
---
--- Returns:
---  * `self`
function command.mt:addShortcut(newShortcut)
    newShortcut:bind(
        function() return self:pressed() end,
        function() return self:released() end,
        function() return self:repeated() end
    )

    --------------------------------------------------------------------------------
    -- Mark it as a 'command' hotkey:
    --------------------------------------------------------------------------------
    local shortcuts = self._shortcuts
    shortcuts[#shortcuts + 1] = newShortcut
    newShortcut:isEnabled(self:isActive())
    return self
end

--- cp.commands.command:getShortcuts() -> command
--- Method
--- Returns the set of shortcuts assigned to this command.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The associated shortcuts.
function command.mt:getShortcuts()
    return self._shortcuts
end

--- cp.commands.command:getFirstShortcut() -> command
--- Method
--- Returns the first shortcut, or `nil` if none have been registered.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The first shortcut, or `nil`.
function command.mt:getFirstShortcut()
    return self._shortcuts and #self._shortcuts > 0 and self._shortcuts[1] or nil
end

--- cp.commands.command:whenActivated(activatedFn) -> command
--- Method
--- Sets the function that will be called when the command is activated.
---
--- NOTE: This is a shortcut for calling `whenPressed(...)`
---
--- Parameters:
---  * `activatedFn`	- the function to call when activated.
---
--- Returns:
---  * command - The current command
---
function command.mt:whenActivated(activatedFn)
    return self:whenPressed(activatedFn)
end

--- cp.commands.command:whenPressed(pressedFn) -> command
--- Method
--- Sets the function that will be called when the command key combo is pressed.
---
--- Parameters:
---  * `pressedFn`	- the function to call when pressed.
---
--- Returns:
---  * command - The current command
---
function command.mt:whenPressed(pressedFn)
    self.pressedFn = pressedFn
    return self
end

--- cp.commands.command:whenReleased(releasedFn) -> command
--- Method
--- Sets the function that will be called when the command key combo is released.
---
--- Parameters:
---  * `releasedFn`	- the function to call when released.
---
--- Returns:
---  * command - The current command
---
function command.mt:whenReleased(releasedFn)
    self.releasedFn = releasedFn
    return self
end

--- cp.commands.command:whenRepeated(repeatedFn) -> command
--- Method
--- Sets the function that will be called when the command key combo is repeated.
---
--- Parameters:
---  * `repeatedFn`	- the function to call when repeated.
---
--- Returns:
---  * command - The current command
---
function command.mt:whenRepeated(repeatedFn)
    self.repeatedFn = repeatedFn
    return self
end

--- cp.commands.command:pressed() -> command
--- Method
--- Executes the 'pressed' function, if present.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the result of the function, or `nil` if none is present.
---
function command.mt:pressed()
    if self:isActive() and self.pressedFn then return self.pressedFn() end
    return nil
end

--- cp.commands.command:released() -> command
--- Method
--- Executes the 'released' function, if present.
---
--- Parameters:
---  * None
---
--- Returns:
---  * the result of the function, or `nil` if none is present.
---
function command.mt:released()
    if self:isActive() and self.releasedFn then return self.releasedFn() end
    return nil
end

--- cp.commands.command:repeated(repeats) -> command
--- Method
--- Executes the 'repeated' function, if present.
---
--- Parameters:
---  * `repeats`	- the number of times to repeat. Defaults to 1.
---
--- Returns:
---  * the last result.
---
function command.mt:repeated(repeats)
    if not self:isActive() then return nil end

    repeats = repeats or 1
    local result = nil
    if self.repeatedFn then
        for _ = 1,repeats do
            result = self.repeatedFn()
        end
    end
    return result
end

--- cp.commands.command:activated(repeats) -> command
--- Method
--- Executes the 'pressed', then 'repeated', then 'released' functions, if present.
---
--- Parameters:
---  * `repeats`	- the number of times to repeat the 'repeated' function. Defaults to 1.
---
--- Returns:
---  * the last 'truthy' result (non-nil/false).
---
function command.mt:activated(repeats)
    if not self:isActive() then return nil end

    local result
    result = self:pressed()
    result = self:repeated(repeats) or result
    result = self:released() or result
    return result
end

--- cp.commands.command:enable() -> cp.commands.command
--- Method
--- Enables the command.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `cp.commands.command` instance.
function command.mt:enable()
    self:isEnabled(true)
    return self
end

--- cp.commands.command:disable() -> cp.commands.command
--- Method
--- Disables the command.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `cp.commands.command` instance.
function command.mt:disable()
    self:isEnabled(false)
    return self
end

function command.mt:__tostring()
    return string.format("command: %s (enabled: %s; active: %s)", self:id(), self:isEnabled(), self:isActive())
end

return command
