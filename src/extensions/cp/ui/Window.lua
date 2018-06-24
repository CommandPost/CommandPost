--- === cp.ui.Window ===
---
--- A Window UI element.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log                         = require("hs.logger").new("button")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local hswindow                      = require("hs.window")
--local inspect                     = require("hs.inspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local app                           = require("cp.app")
local axutils                       = require("cp.ui.axutils")
local notifier                      = require("cp.ui.notifier")
local prop                          = require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Window = {}

--- cp.ui.Window.matches(element) -> boolean
--- Function
--- Checks if the provided element is a valid window.
function Window.matches(element)
    return element and element:attributeValue("AXRole") == "AXWindow"
end


-- utility function to help set up watchers
local function notifyWatch(cpProp, notifications)
    cpProp:preWatch(function(self)
        self:notifier():watchFor(
            notifications,
            function() cpProp:update() end
        )
    end)
end

--- cp.ui.Window.new(cpApp, uiProp) -> Window
--- Constructor
--- Creates a new Window
---
--- Parameters:
---  * `cpApp`    - a `cp.app` for the application the Window belongs to.
---  * `uiProp`   - a `cp.prop` that returns the `hs._asm.axuielement` for the window.
---
--- Returns:
---  * A new `Window` instance.
function Window.new(cpApp, uiProp)
    assert(app.is(cpApp), "Parameter #1 must be a cp.app")
    assert(prop.is(uiProp), "Parameter #2 must be a cp.prop")
    local o = prop.extend({
        _app = cpApp,
    }, Window)

--- cp.ui.Window.UI <cp.prop: hs._asm.axuielement: read-only; live?>
--- Field
--- The UI `axuielement` for the Window.
    local UI = uiProp

--- cp.ui.Window.hsWindow <cp.prop: hs.window; read-only>
--- Field
--- The `hs.window` instance for the window, or `nil` if it can't be found.
    local hsWindow = UI:mutate(
        function(original)
            local ui = original()
            return ui and ui:asHSWindow()
        end
    )

--- cp.ui.Window.id <cp.prop: number; read-only>
--- Field
--- The unique ID for the window.
    local id = hsWindow:mutate(
        function(original)
            local window = original()
            return window ~= nil and window:id()
        end
    )

--- cp.ui.Window.visible <cp.prop: boolean; read-only>
--- Field
--- Returns `true` if the window is visible on a screen.
    local visible = hsWindow:mutate(
        function(original)
            local window = original()
            return window ~= nil and window:isVisible()
        end
    )

--- cp.ui.Window.focused <cp.prop: boolean>
--- Field
--- Is `true` if the window has mouse/keyboard focused.
--- Note: Setting to `false` has no effect, since 'defocusing' isn't definable.
    local focused = hsWindow:mutate(
        function(original)
            return original() == hswindow.focusedWindow()
        end,
        function(focused, original)
            local window = original()
            if window and focused then
                window:focus()
            end
        end
    )
    :monitor(visible)

--- cp.ui.Window.exists <cp.prop: boolean; read-only>
--- Field
--- Returns `true` if the window exists. It may not be visible.
    local exists = UI:ISNOT(nil)

--- cp.ui.Window.minimized <cp.prop: boolean>
--- Field
--- Returns `true` if the window exists and is minimised.
    local minimized = hsWindow:mutate(
        function(original)
            local window = original()
            return window ~= nil and window:isMinimized()
        end,
        function(minimized, original)
            local window = original()
            if window then
                if minimized then
                    window:minimize()
                else
                    window:unminimize()
                end
            end
        end
    )

--- cp.ui.Window.frame <cp.prop: hs.geometry rect>
--- Field
--- The `hs.geometry` rect value describing the window's position.
    local frame = hsWindow:mutate(
        function(original)
            local window = original()
            return window and window:frame()
        end,
        function(frame, original)
            local window = original()
            if window then
                window:move(frame)
            end
            return window
        end
    )
    :monitor(visible)

--- cp.ui.Window.fullScreen <cp.prop: boolean>
--- Field
--- Returns `true` if the window is full-screen.
    local fullScreen = hsWindow:mutate(
        function(original)
            local window = original()
            return window ~= nil and window:isFullScreen()
        end,
        function(window, fullScreen)
            if window then
                window:setFullScreen(fullScreen)
            end
            return window
        end
    )
    :monitor(visible)

    prop.bind(o) {
        UI = UI,
        hsWindow = hsWindow,
        id = id,
        visible = visible,
        focused = focused,
        exists = exists,
        minimized = minimized,
        frame = frame,
        fullScreen = fullScreen,
    }

    notifyWatch(hsWindow, {"AXWindowCreated", "AXUIElementDestroyed"})
    notifyWatch(visible, {"AXWindowMiniaturized", "AXWindowDeminiaturized",  "AXApplicationHidden", "AXApplicationShown"})
    notifyWatch(focused, {"AXFocusedWindowChanged", "AXApplicationActivated", "AXApplicationDeactivated"})
    notifyWatch(minimized, {"AXWindowMiniaturized", "AXWindowDeminiaturized"})
    notifyWatch(frame, {"AXWindowResized", "AXWindowMoved"})
    notifyWatch(fullScreen, {"AXWindowResized", "AXWindowMoved"})

    return o
end

function Window:app()
    return self._app
end

--- cp.ui.Window.close() -> boolean
--- Method
--- Attempts to close the window.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if the window was successfully closed.
function Window:close()
    local hsWindow = self:hsWindow()
    return hsWindow ~= nil and hsWindow:close()
end

--- cp.ui.Window.focus() -> boolean
--- Method
--- Attempts to focus the window.
---
--- Parameters:
--- * None
---
--- Returns:
--- * `true` if the window was successfully focused.
function Window:focus()
    local hsWindow = self:hsWindow()
    return hsWindow ~= nil and hsWindow:focus()
end

--- cp.app:notifier() -> cp.ui.notifier
--- Method
--- Returns a `notifier` that is tracking the application UI element. It has already been started.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The notifier.
function Window:notifier()
    if not self._notifier then
        local theApp = self:app()
        local bundleID = theApp:bundleID()
        self._notifier = notifier.new(bundleID, function() return self:UI() end):start()
    end
    return self._notifier
end

--- cp.ui.Window:snapshot([path]) -> hs.image | nil
--- Method
--- Takes a snapshot of the UI in its current state as a PNG and returns it.
--- If the `path` is provided, the image will be saved at the specified location.
---
--- Parameters:
--- * path		- (optional) The path to save the file. Should include the extension (should be `.png`).
---
--- Return:
--- * The `hs.image` that was created, or `nil` if the UI is not available.
function Window:snapshot(path)
    local ui = self:UI()
    if ui then
        return axutils.snapshot(ui, path)
    end
    return nil
end

return Window
