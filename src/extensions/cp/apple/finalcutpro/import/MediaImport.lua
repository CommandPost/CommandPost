--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.import.MediaImport ===
---
--- Media Import

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
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                       = require("cp.ui.axutils")
local id                            = require("cp.apple.finalcutpro.ids") "MediaImporter"
local just                          = require("cp.just")
local prop                          = require("cp.prop")
local WindowWatcher                 = require("cp.apple.finalcutpro.WindowWatcher")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local MediaImport = {}

--- cp.apple.finalcutpro.import.MediaImport.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function MediaImport.matches(element)
    if element then
        return element:attributeValue("AXSubrole") == "AXDialog"
           and element:attributeValue("AXMain")
           and element:attributeValue("AXModal")
           and axutils.childWith(element, "AXIdentifier", id "MainPanel") ~= nil
    end
    return false
end

--- cp.apple.finalcutpro.import.MediaImport:new(app) -> MediaImport
--- Function
--- Creates a new Media Import object.
---
--- Parameters:
---  * app - The `cp.apple.finalcutpro` object.
---
--- Returns:
---  * A new MediaImport object.
-- TODO: Use a function instead of a method.
function MediaImport:new(app) -- luacheck: ignore
    local o = {_app = app}
    return prop.extend(o, MediaImport)
end

--- cp.apple.finalcutpro.import.MediaImport:app() -> App
--- Method
--- Returns the App instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function MediaImport:app()
    return self._app
end

--- cp.apple.finalcutpro.export.MediaImport:UI() -> axuielementObject
--- Method
--- Returns the Media Import Accessibility Object
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `axuielementObject` or `nil`
function MediaImport:UI()
    return axutils.cache(self, "_ui", function()
        local windowsUI = self:app():windowsUI()
        return windowsUI and self:_findWindowUI(windowsUI)
    end,
    MediaImport.matches)
end

-- cp.apple.finalcutpro.export.MediaImport:_findWindowUI(windows) -> axuielementObject | nil
-- Method
-- Finds a matching window UI.
--
-- Parameters:
--  * windows - A table of `hs.window` objects
--
-- Returns:
--  * An `axuielementObject` or `nil`
-- TODO: Use a function instead of a method.
function MediaImport:_findWindowUI(windows) -- luacheck: ignore
    for _,window in ipairs(windows) do
        if MediaImport.matches(window) then return window end
    end
    return nil
end

--- cp.apple.finalcutpro.import.MediaImport.isShowing <cp.prop: boolean; read-only>
--- Field
--- Is the Media Import window showing?
MediaImport.isShowing = prop.new(function(self)
    return self:UI() ~= nil
end):bind(MediaImport)

--- cp.apple.finalcutpro.import.MediaImport:show() -> cp.apple.finalcutpro.import.MediaImport
--- Method
--- Shows the Media Import window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.import.MediaImport` object for method chaining.
function MediaImport:show()
    if not self:isShowing() then
        -- open the window
        if self:app():menuBar():isEnabled({"File", "Import", "Media…"}) then
            self:app():menuBar():selectMenu({"File", "Import", "Media…"})
            just.doUntil(function() return self:isShowing() end)
        end
    end
    return self
end

--- cp.apple.finalcutpro.import.MediaImport:hide() -> cp.apple.finalcutpro.import.MediaImport
--- Method
--- Hides the Media Import window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.import.MediaImport` object for method chaining.
function MediaImport:hide()
    local ui = self:UI()
    if ui then
        local closeBtn = ui:closeButton()
        if closeBtn then
            closeBtn:doPress()
        end
    end
    return self
end

--- cp.apple.finalcutpro.import.MediaImport:show() -> cp.apple.finalcutpro.import.MediaImport
--- Method
--- Triggers the Import All button.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `cp.apple.finalcutpro.import.MediaImport` object for method chaining.
function MediaImport:importAll()
    local ui = self:UI()
    if ui then
        local btn = ui:defaultButton()
        if btn and btn:enabled() then
            btn:doPress()
        end
    end
    return self
end

--- cp.apple.finalcutpro.import.MediaImport:getTitle() -> string | nil
--- Method
--- The title of the Media Import window or `nil`.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The title of the Media Import window as a string or `nil`.
function MediaImport:getTitle()
    local ui = self:UI()
    return ui and ui:title()
end

-----------------------------------------------------------------------
--
-- WATCHERS
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.import.MediaImport:watch() -> table
--- Method
--- Watch for events that happen in the Media Import window. The optional functions will be called when the window is shown or hidden, respectively.
---
--- Parameters:
---  * `events` - A table of functions with to watch. These may be:
---    * `show(window)` - Triggered when the window is shown.
---    * `hide(window)` - Triggered when the window is hidden.
---
--- Returns:
---  * An ID which can be passed to `unwatch` to stop watching.
function MediaImport:watch(events)
    if not self._watcher then
        self._watcher = WindowWatcher:new(self)
    end
    return self._watcher:watch(events)
end

--- cp.apple.finalcutpro.import.MediaImport:unwatch() -> none
--- Method
--- Removes the watch with the specified ID.
---
--- Parameters:
---  * `id` - The ID returned from `watch` that wants to be removed.
---
--- Returns:
---  * None
function MediaImport:unwatch(theID)
    if self._watcher then
        self._watcher:unwatch(theID)
    end
end

return MediaImport
