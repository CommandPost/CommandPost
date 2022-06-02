--- === cp.ui.Window ===
---
--- A Window UI element.

local require = require

local hswindow          = require "hs.window"
local class             = require "middleclass"

local delegator         = require "cp.delegator"
local lazy              = require "cp.lazy"
local prop              = require "cp.prop"

local ax                = require "cp.fn.ax"
local axutils           = require "cp.ui.axutils"
local notifier          = require "cp.ui.notifier"
local Alert             = require "cp.ui.Alert"
local Button            = require "cp.ui.Button"

local If                = require "cp.rx.go.If"
local WaitUntil         = require "cp.rx.go.WaitUntil"

local format            = string.format

local Window = class("cp.ui.Window"):include(lazy):include(delegator)

--- cp.ui.Window.matches(element) -> boolean
--- Function
--- Checks if the provided element is a valid window.
---
--- Parameters:
---  * element - An element to check
---
--- Returns:
---  * A boolean
function Window.static.matches(element)
    return element ~= nil and element:attributeValue("AXRole") == "AXWindow"
end

-- utility function to help set up watchers
local function notifyWatch(cpProp, notifications)
    cpProp:preWatch(function(self)
        self:notifier():watchFor(
            notifications,
            function() cpProp:update() end
        )
    end)
    return cpProp
end

--- cp.ui.Window(cpApp, uiProp) -> Window
--- Constructor
--- Creates a new Window
---
--- Parameters:
---  * `cpApp`    - a `cp.app` for the application the Window belongs to.
---  * `uiProp`   - a `cp.prop` that returns the `hs.axuielement` for the window.
---
--- Returns:
---  * A new `Window` instance.
function Window:initialize(cpApp, uiProp)
    assert(prop.is(uiProp), "Parameter #2 must be a cp.prop")

    self._app = cpApp

--- cp.ui.Window.UI <cp.prop: hs.axuielement: read-only; live?>
--- Field
--- The UI `axuielement` for the Window.
    prop.bind(self) {
        UI = uiProp
    }
end

--- cp.ui.Window.isShowing <cp.prop: boolean; read-only; live?>
--- Field
--- Indicates if the `Window` is currently showing on screen.
function Window.lazy.prop:isShowing()
    return self.UI:ISNOT(nil)
end

--- cp.ui.Window.hsWindow <cp.prop: hs.window; read-only>
--- Field
--- The `hs.window` instance for the window, or `nil` if it can't be found.
function Window.lazy.prop:hsWindow()
    return notifyWatch(
        self.UI:mutate(
            function(original)
                local ui = original()
                return ui and ui:asHSWindow()
            end
        ),
        {"AXWindowCreated", "AXUIElementDestroyed"}
    )
end

--- cp.ui.Window.id <cp.prop: number; read-only>
--- Field
--- The unique ID for the window.
function Window.lazy.prop:id()
    return self.hsWindow:mutate(
        function(original)
            local window = original()
            return window ~= nil and window:id()
        end
    )
end

--- cp.ui.Window.id <cp.prop: string; read-only>
--- Field
--- The window title, or `nil` if the window is not currently visible.
function Window.lazy.prop:title()
    return self.hsWindow:mutate(
        function(original)
            local window = original()
            return window and window:title()
        end
    )
end

--- cp.ui.Window.visible <cp.prop: boolean; read-only>
--- Field
--- Returns `true` if the window is visible on a screen.
function Window.lazy.prop:visible()
    return notifyWatch(
        self.hsWindow:mutate(
            function(original)
                local window = original()
                return window ~= nil and window:isVisible()
            end
        ),
        {"AXWindowMiniaturized", "AXWindowDeminiaturized",  "AXApplicationHidden", "AXApplicationShown"}
    )
end

--- cp.ui.Window.focused <cp.prop: boolean>
--- Field
--- Is `true` if the window has mouse/keyboard focused.
--- Note: Setting to `false` has no effect, since 'defocusing' isn't definable.
function Window.lazy.prop:focused()
    return notifyWatch(
        self.hsWindow:mutate(
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
        :monitor(self.visible),
        {"AXFocusedWindowChanged", "AXApplicationActivated", "AXApplicationDeactivated"}
    )
end

function Window.lazy.prop:modal()
    return axutils.prop(self.UI, "AXModal")
end

function Window.lazy.value:closeButton()
    return Button(self, ax.prop(self.UI, "AXCloseButton"))
end

function Window.lazy.value:minimizeButton()
    return Button(self, ax.prop(self.UI, "AXMinimizeButton"))
end

function Window.lazy.value:fullScreenButton()
    return Button(self, ax.prop(self.UI, "AXFullScreenButton"))
end

function Window.lazy.value:zoomButton()
    return Button(self, ax.prop(self.UI, "AXZoomButton"))
end

--- cp.ui.Window.exists <cp.prop: boolean; read-only>
--- Field
--- Returns `true` if the window exists. It may not be visible.
function Window.lazy.prop:exists()
    return self.UI:ISNOT(nil)
end

--- cp.ui.Window.minimized <cp.prop: boolean>
--- Field
--- Returns `true` if the window exists and is minimised.
function Window.lazy.prop:minimized()
    return notifyWatch(
        self.hsWindow:mutate(
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
        ),
        {"AXWindowMiniaturized", "AXWindowDeminiaturized"}
    )
end

--- cp.ui.Window.frame <cp.prop: hs.geometry rect>
--- Field
--- The `hs.geometry` rect value describing the window's position.
function Window.lazy.prop:frame()
    return notifyWatch(
        self.hsWindow:mutate(
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
        :monitor(self.visible),
        {"AXWindowResized", "AXWindowMoved"}
    )
end

--- cp.ui.Window.isFullScreen <cp.prop: boolean>
--- Field
--- Returns `true` if the window is full-screen.
function Window.lazy.prop:isFullScreen()
    return notifyWatch(
        self.hsWindow:mutate(
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
        :monitor(self.visible),
        {"AXWindowResized", "AXWindowMoved"}
    )
end

function Window:app()
    return self._app
end

--- cp.ui.Window:close() -> boolean
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

--- cp.ui.Window:doClose() -> cp.rx.go.Statement <boolean>
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) that will attempt to close the window, if it is visible.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `Statement` to execute, resolving to `true` if the window is closed successfully, or `false` if not.
function Window.lazy.method:doClose()
    return If(self.hsWindow):Then(function(hsWindow)
        return hsWindow:close()
    end)
    :Then(WaitUntil(self.visible:NOT())
    ):Otherwise(true)
    :ThenYield()
end

--- cp.ui.Window:focus() -> boolean
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

--- cp.ui.Window:doFocus() -> cp.rx.go.Statement
--- Method
--- Returns a [Statement](cp.rx.go.Statement.md) will attempt to focus on the window, if it is visible.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `Statement` to execute, which resolves to `true` if the window was successfully focused, or `false` if not.
function Window.lazy.method:doFocus()
    return If(self.hsWindow):Then(function(hsWindow)
        return hsWindow:focus()
    end)
    :Then(WaitUntil(self.focused))
    :Otherwise(false)
    :TimeoutAfter(10000)
    :ThenYield()
end

function Window.lazy.method:doRaise()
    return If(self.hsWindow)
    :Then(function()
        self:UI():doRaise()
        return true
    end)
    :Otherwise(false)
    :ThenYield()
end

--- cp.ui.Window.alert <cp.ui.Alert>
--- Field
--- Provides access to any 'Alert' windows on the Window.
function Window.lazy.value:alert()
    return Alert(self)
end

--- cp.ui.Window.findSectionUI(windowUI, sectionID) -> hs.axuielement
--- Function
--- Finds the `axuielement` for the specified `sectionID`, if present in the provided `axuielement` `windowUI`.
---
--- Parameters:
--- * windowUI - The `AXWindow` `axuielement` to search in.
--- * sectionID - The string value for the `SectionUniqueID`.
---
--- Returns:
--- * The matching `axuielement`, or `nil`.
function Window.static.findSectionUI(windowUI, sectionID)
    if windowUI then
        local sections = windowUI:attributeValue("AXSections")
        if sections then
            for _,section in ipairs(sections) do
                if section.SectionUniqueID == sectionID then
                    return section.SectionObject
                end
            end
        end
    end
end

--- cp.ui.Window:findSectionUI(sectionID) -> hs.axuielement
--- Method
--- Looks for th section with the specified `SectionUniqueID` value and returns the matching `axuielement` value.
---
--- Parameters:
--- * sectionID - The string for the section ID.
---
--- Returns:
--- * The matching `axuielement`, or `nil`.
function Window:findSectionUI(sectionID)
    return Window.findSectionUI(self:UI(), sectionID)
end

--- cp.ui.Window:notifier() -> cp.ui.notifier
--- Method
--- Returns a `notifier` that is tracking the application UI element. It has already been started.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The notifier.
function Window.lazy.method:notifier()
    return notifier.new(self:app():bundleID(), self.UI):start()
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

function Window:__tostring()
    local title = self:title()
    local label = title or "[Untitled]"
    return format("%s: %s (%s)", self.class.name, label, self:app())
end


-- This just returns the same element when it is called as a method. (eg. `fcp.viewer == fcp:viewer()`)
-- This is a bridge while we migrate to using `lazy.value` instead of `lazy.method` (or methods)
-- in the FCPX API.
function Window:__call()
    return self
end


return Window
