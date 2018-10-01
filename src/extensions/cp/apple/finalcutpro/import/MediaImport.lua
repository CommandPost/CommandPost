--- === cp.apple.finalcutpro.import.MediaImport ===
---
--- Media Import

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log                           = require("hs.logger").new("PrefsDlg")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils                       = require("cp.ui.axutils")
local just                          = require("cp.just")
local prop                          = require("cp.prop")
local strings                       = require("cp.apple.finalcutpro.strings")
local Window                        = require("cp.ui.Window")

--------------------------------------------------------------------------------
-- Local Lua Functions:
--------------------------------------------------------------------------------
local cache                         = axutils.cache
local childWith                     = axutils.childWith

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local MediaImport = {}

-- _findWindowUI(windows) -> hs._asm.axuielementObject | nil
-- Method
-- Finds a matching window UI.
--
-- Parameters:
--  * windows - A table of `hs.window` objects
--
-- Returns:
--  * An `axuielement` or `nil`
local function _findWindowUI(windows)
    for _,window in ipairs(windows) do
        if MediaImport.matches(window) then return window end
    end
    return nil
end

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
    local importAll = strings:find("PEImportAll_NoEllipsis")
    return element
       and element:attributeValue("AXSubrole") == "AXDialog"
       and element:attributeValue("AXMain")
       and element:attributeValue("AXModal")
       and importAll
       and childWith(element, "AXTitle", importAll) ~= nil
end

--- cp.apple.finalcutpro.import.MediaImport.new(app) -> MediaImport
--- Constructor
--- Creates a new Media Import object.
---
--- Parameters:
---  * app - The `cp.apple.finalcutpro` object.
---
--- Returns:
---  * A new MediaImport object.
function MediaImport.new(app)
    local o = prop.extend({_app = app}, MediaImport)

--- cp.apple.finalcutpro.import.MediaImport:UI() -> axuielementObject
--- Method
--- Returns the Media Import Accessibility Object
---
--- Parameters:
---  * None
---
--- Returns:
---  * An `axuielementObject` or `nil`
    local UI = app.windowsUI:mutate(function(original, self)
        return cache(self, "_ui", function()
            local windowsUI = original()
            return windowsUI and _findWindowUI(windowsUI)
        end,
        MediaImport.matches)
    end)

    local window = Window(app.app, UI)
    o._window = window

    prop.bind(o) {
        UI = UI,

--- cp.apple.finalcutpro.import.MediaImport.hsWindow <cp.prop: hs.window; read-only>
--- Field
--- The `hs.window` instance for the window, or `nil` if it can't be found.
        hsWindow = window.hsWindow,

--- cp.apple.finalcutpro.import.MediaImport.isShowing <cp.prop: boolean>
--- Field
--- Is `true` if the window is visible.
        isShowing = window.visible,

--- cp.apple.finalcutpro.import.MediaImport.isFullScreen <cp.prop: boolean>
--- Field
--- Is `true` if the window is full-screen.
        isFullScreen = window.fullScreen,

--- cp.apple.finalcutpro.import.MediaImport.frame <cp.prop: frame>
--- Field
--- The current position (x, y, width, height) of the window.
        frame = window.frame,
    }

    return o
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

function MediaImport:window()
    return self._window
end

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
        if self:app():menu():isEnabled({"File", "Import", "Media…"}) then
            self:app():menu():selectMenu({"File", "Import", "Media…"})
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

return MediaImport
