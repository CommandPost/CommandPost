--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.export.ExportDialog ===
---
--- Export Dialog Module.

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
local id                            = require("cp.apple.finalcutpro.ids") "ExportDialog"
local just                          = require("cp.just")
local prop                          = require("cp.prop")
local SaveSheet                     = require("cp.apple.finalcutpro.export.SaveSheet")
local WindowWatcher                 = require("cp.apple.finalcutpro.WindowWatcher")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ExportDialog = {}

--- cp.apple.finalcutpro.export.ExportDialog.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function ExportDialog.matches(element)
    if element then
        return element:attributeValue("AXSubrole") == "AXDialog"
           and element:attributeValue("AXModal")
           and axutils.childWithID(element, id "BackgroundImage") ~= nil
    end
    return false
end

--- cp.apple.finalcutpro.export.ExportDialog.new(app) -> ExportDialog
--- Constructor
--- Creates a new Export Dialog object.
---
--- Parameters:
---  * app - The `cp.apple.finalcutpro` object.
---
--- Returns:
---  * A new ExportDialog object.
function ExportDialog.new(app)
    local o = {_app = app}
    return prop.extend(o, ExportDialog)
end

--- cp.apple.finalcutpro.export.ExportDialog:app() -> App
--- Method
--- Returns the app instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function ExportDialog:app()
    return self._app
end

--- cp.apple.finalcutpro.export.ExportDialog:UI() -> axuielementObject
--- Method
--- Returns the Export Dialog Accessibility Object
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `axuielementObject` or `nil`
function ExportDialog:UI()
    return axutils.cache(self, "_ui", function()
        local windowsUI = self:app():windowsUI()
        return windowsUI and self._findWindowUI(windowsUI)
    end,
    ExportDialog.matches)
end

-- cp.apple.finalcutpro.export.ExportDialog:_findWindowUI(windows) -> window | nil
-- Method
-- Gets the Window UI.
--
-- Parameters:
--  * windows - Table of windows.
--
-- Returns:
--  * An `axuielementObject` or `nil`
function ExportDialog._findWindowUI(windows)
    for _,window in ipairs(windows) do
        if ExportDialog.matches(window) then return window end
    end
    return nil
end

--- cp.apple.finalcutpro.export.ExportDialog.isShowing <cp.prop: boolean; read-only>
--- Field
--- Is the window showing?
ExportDialog.isShowing = prop.new(function(self)
    return self:UI() ~= nil
end):bind(ExportDialog)

--- cp.apple.finalcutpro.export.ExportDialog:show() -> cp.apple.finalcutpro.export.ExportDialog
--- Method
--- Shows the Export Dialog
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.ExportDialog` object for method chaining.
function ExportDialog:show()
    if not self:isShowing() then
        --------------------------------------------------------------------------------
        -- Open the window:
        --------------------------------------------------------------------------------
        if self:app():menu():isEnabled({"File", "Share", 1}) then
            self:app():menu():selectMenu({"File", "Share", 1})
            just.doUntil(function() return self:UI() end)
        end
    end
    return self
end

--- cp.apple.finalcutpro.export.ExportDialog:hide() -> cp.apple.finalcutpro.export.ExportDialog
--- Method
--- Hides the Export Dialog
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.ExportDialog` object for method chaining.
function ExportDialog:hide()
    self:pressCancel()
    return self
end

--- cp.apple.finalcutpro.export.ExportDialog:pressCancel() -> cp.apple.finalcutpro.export.ExportDialog
--- Method
--- Presses the Cancel Button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.ExportDialog` object for method chaining.
function ExportDialog:pressCancel()
    local ui = self:UI()
    if ui then
        local btn = ui:cancelButton()
        if btn then
            btn:doPress()
        end
    end
    return self
end

--- cp.apple.finalcutpro.export.ExportDialog:getTitle() -> string | nil
--- Method
--- The title of the Export Dialog window or `nil`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The title of the Export Dialog window as a string or `nil`.
function ExportDialog:getTitle()
    local ui = self:UI()
    return ui and ui:title()
end

--- cp.apple.finalcutpro.export.ExportDialog:pressNext() -> cp.apple.finalcutpro.export.ExportDialog
--- Method
--- Presses the Next Button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.export.ExportDialog` object for method chaining.
function ExportDialog:pressNext()
    local ui = self:UI()
    if ui then
        local nextBtn = ui:defaultButton()
        if nextBtn then
            nextBtn:doPress()
        end
    end
    return self
end

--- cp.apple.finalcutpro.export.ExportDialog:saveSheet() -> SaveSheet
--- Method
--- Creates a new Save Sheet.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The SaveSheet.
function ExportDialog:saveSheet()
    if not self._saveSheet then
        self._saveSheet = SaveSheet.new(self)
    end
    return self._saveSheet
end

-----------------------------------------------------------------------
--
-- WATCHERS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.export.ExportDialog:watch() -> table
--- Method
--- Watch for events that happen in the command editor. The optional functions will be called when the window is shown or hidden, respectively.
---
--- Parameters:
---  * `events` - A table of functions with to watch. These may be:
---    * `show(CommandEditor)` - Triggered when the window is shown.
---    * `hide(CommandEditor)` - Triggered when the window is hidden.
---
--- Returns:
---  * An ID which can be passed to `unwatch` to stop watching.
function ExportDialog:watch(events)
    if not self._watcher then
        self._watcher = WindowWatcher:new(self)
    end
    return self._watcher:watch(events)
end

--- cp.apple.finalcutpro.export.ExportDialog:unwatch(id) -> none
--- Method
--- Unwatches an event.
---
--- Parameters:
---  * id - An ID as a string of the event you want to unwatch.
---
--- Returns:
---  * None
function ExportDialog:unwatch(theID)
    if self._watcher then
        self._watcher:unwatch(theID)
    end
end

return ExportDialog
