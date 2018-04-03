--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.cmd.CommandEditor ===
---
--- Command Editor Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                           = require("hs.logger").new("PrefsDlg")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
--local inspect                       = require("hs.inspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                       = require("cp.ui.axutils")
local Button                        = require("cp.ui.Button")
local id                            = require("cp.apple.finalcutpro.ids") "CommandEditor"
local just                          = require("cp.just")
local prop                          = require("cp.prop")
local WindowWatcher                 = require("cp.apple.finalcutpro.WindowWatcher")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local CommandEditor = {}

--- cp.apple.finalcutpro.cmd.CommandEditor.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function CommandEditor.matches(element)
    if element then
        return element:attributeValue("AXSubrole") == "AXDialog"
           and element:attributeValue("AXModal")
           and axutils.childWithRole(element, "AXPopUpButton") ~= nil
           and #axutils.childrenWithRole(element, "AXGroup") == 4
    end
    return false
end

--- cp.apple.finalcutpro.cmd.CommandEditor:new(app) -> CommandEditor
--- Function
--- Creates a new Command Editor object.
---
--- Parameters:
---  * app - The `cp.apple.finalcutpro` object.
---
--- Returns:
---  * A new CommandEditor object.
-- TODO: Use a function instead of a method.
function CommandEditor:new(app) -- luacheck: ignore
    local o = {_app = app}
    return prop.extend(o, CommandEditor)
end

--- cp.apple.finalcutpro.cmd.CommandEditor:app() -> App
--- Method
--- Returns the app instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function CommandEditor:app()
    return self._app
end

--- cp.apple.finalcutpro.cmd.CommandEditor:UI() -> axuielementObject
--- Method
--- Returns the Command Editor Accessibility Object
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `axuielementObject` or `nil`
function CommandEditor:UI()
    return axutils.cache(self, "_ui", function()
        local windowsUI = self:app():windowsUI()
        return windowsUI and self:_findWindowUI(windowsUI)
    end,
    CommandEditor.matches)
end

-- cp.apple.finalcutpro.cmd.CommandEditor:_findWindowUI(windows) -> window | nil
-- Method
-- Gets the Window UI.
--
-- Parameters:
--  * windows - Table of windows.
--
-- Returns:
--  * An `axuielementObject` or `nil`
-- TODO: Use a function instead of a method.
function CommandEditor:_findWindowUI(windows) -- luacheck: ignore
    for _,window in ipairs(windows) do
        if CommandEditor.matches(window) then return window end
    end
    return nil
end

--- cp.apple.finalcutpro.cmd.CommandEditor.isShowing <cp.prop: boolean; read-only>
--- Field
--- Is the Command Editor showing?
CommandEditor.isShowing = prop.new(function(self)
    return self:UI() ~= nil
end):bind(CommandEditor)

--- cp.apple.finalcutpro.cmd.CommandEditor:show() -> cp.apple.finalcutpro.cmd.CommandEditor
--- Method
--- Shows the Command Editor.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.cmd.CommandEditor` object for method chaining.
function CommandEditor:show()
    if not self:isShowing() then
        -- open the window
        if self:app():menuBar():isEnabled({"Final Cut Pro", "Commands", "Customize…"}) then
            self:app():menuBar():selectMenu({"Final Cut Pro", "Commands", "Customize…"})
            just.doUntil(function() return self:UI() end)
        end
    end
    return self
end

--- cp.apple.finalcutpro.cmd.CommandEditor:hide() -> cp.apple.finalcutpro.cmd.CommandEditor
--- Method
--- Hides the Command Editor.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.cmd.CommandEditor` object for method chaining.
function CommandEditor:hide()
    local ui = self:UI()
    if ui then
        local closeBtn = axutils.childWith(ui, "AXSubrole", "AXCloseButton")
        if closeBtn then
            closeBtn:doPress()
        end
    end
    return self
end

--- cp.apple.finalcutpro.cmd.CommandEditor:saveButton() -> axuielementObject | nil
--- Method
--- Gets the Command Editor Save Button AX item.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `axuielementObject` of the Save Button or nil.
function CommandEditor:saveButton()
    if not self._saveButton then
        self._saveButton = Button.new(self, function()
            return axutils.childWithID(self:UI(), id "SaveButton")
        end)
    end
    return self._saveButton
end

--- cp.apple.finalcutpro.cmd.CommandEditor:save() -> cp.apple.finalcutpro.cmd.CommandEditor
--- Method
--- Triggers the Save button in the Command Editor.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.cmd.CommandEditor` object for method chaining.
function CommandEditor:save()
    local ui = self:UI()
    if ui then
        local saveBtn = axutils.childWith(ui, "AXIdentifier", id "SaveButton")
        if saveBtn and saveBtn:enabled() then
            saveBtn:doPress()
        end
    end
    return self
end

--- cp.apple.finalcutpro.cmd.CommandEditor:getTitle() -> string | nil
--- Method
--- The title of the Command Editor window or `nil`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The title of the Command Editor window as a string or `nil`.
function CommandEditor:getTitle()
    local ui = self:UI()
    return ui and ui:title()
end

--- cp.apple.finalcutpro.cmd.CommandEditor:watch() -> table
--- Method
--- Watch for events that happen in the command editor. The optional functions will be called when the window is shown or hidden, respectively.
---
--- Parameters:
---  * `events` - A table of functions with to watch. These may be:
---    * `open(window)` - Triggered when the window is shown.
---    * `close(window)` - Triggered when the window is hidden.
---    * `move(window)` - Triggered when the window is moved.
---
--- Returns:
---  * A table which contains an ID which can be passed to `unwatch` to stop watching.
function CommandEditor:watch(events)
    if not self._watcher then
        self._watcher = WindowWatcher:new(self)
    end
    return self._watcher:watch(events)
end

--- cp.apple.finalcutpro.cmd.CommandEditor:unwatch(id) -> none
--- Method
--- Unwatches an event.
---
--- Parameters:
---  * id - An ID as a string of the event you want to unwatch.
---
--- Returns:
---  * None
function CommandEditor:unwatch(theID)
    if self._watcher then
        self._watcher:unwatch(theID)
    end
end

return CommandEditor
