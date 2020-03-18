--- === cp.blackmagic.resolve.main.PrimaryWindow ===
---
--- Primary Window Module.

local require               = require

--local log                 = require "hs.logger".new "primaryWindow"

local axutils               = require "cp.ui.axutils"

local Window                = require "cp.ui.Window"

local Do                    = require "cp.rx.go.Do"
local If                    = require "cp.rx.go.If"

local class                 = require "middleclass"
local lazy                  = require "cp.lazy"

local childrenWithRole      = axutils.childrenWithRole

local PrimaryWindow = class("PrimaryWindow"):include(lazy)

--- cp.blackmagic.resolve.main.PrimaryWindow.matches(w) -> boolean
--- Function
--- Checks to see if a window matches the PrimaryWindow requirements
---
--- Parameters:
---  * w - The window to check
---
--- Returns:
---  * `true` if matched otherwise `false`
function PrimaryWindow.static.matches(element)
    local children = element and childrenWithRole(element, "AXCheckBox")
    return children and #children >= 6
end

--- cp.blackmagic.resolve.main.PrimaryWindow(app) -> PrimaryWindow object
--- Constructor
--- Creates a new PrimaryWindow.
---
--- Parameters:
---  * None
---
--- Returns:
---  * PrimaryWindow
function PrimaryWindow:initialize(app)
    self._app = app
end

--- cp.blackmagic.resolve.main.PrimaryWindow:app() -> cp.blackmagic.resolve
--- Method
--- Returns the application the display belongs to.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The app instance.
function PrimaryWindow:app()
    return self._app
end

--- cp.blackmagic.resolve.main.PrimaryWindow:window() -> cp.ui.Window
--- Method
--- Returns the `Window` instance.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Window` instance.
function PrimaryWindow.lazy.method:window()
    return Window(self:app().app, self.UI)
end

--- cp.blackmagic.resolve.main.PrimaryWindow.UI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- The main `axuielement` for the window. May be `nil` if not currently available.
function PrimaryWindow.lazy.prop:UI()
    return self:app().windowsUI:mutate(function(original)
        return axutils.cache(self, "_ui", function()
            return axutils.childMatching(original(), PrimaryWindow.matches)
        end,
        PrimaryWindow.matches)
    end)
end

--- cp.blackmagic.resolve.main.PrimaryWindow.hsWindow <cp.prop: hs.window; read-only>
--- Field
--- The `hs.window` instance for the window, or `nil` if it can't be found.
function PrimaryWindow.lazy.prop:hsWindow()
    return self:window().hsWindow
end

--- cp.blackmagic.resolve.main.PrimaryWindow.isShowing <cp.prop: boolean>
--- Field
--- Is `true` if the window is visible.
function PrimaryWindow.lazy.prop:isShowing()
    return self:window().visible
end

--- cp.blackmagic.resolve.main.PrimaryWindow.isFullScreen <cp.prop: boolean>
--- Field
--- Is `true` if the window is full-screen.
function PrimaryWindow.lazy.prop:isFullScreen()
    return self:window().fullScreen
end

--- cp.blackmagic.resolve.main.PrimaryWindow.frame <cp.prop: frame>
--- Field
--- The current position (x, y, width, height) of the window.
function PrimaryWindow.lazy.prop:frame()
    return self:window().frame
end

--- cp.blackmagic.resolve.main.PrimaryWindow:show() -> PrimaryWindow
--- Method
--- Shows the Primary Window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `PrimaryWindow` instance.
function PrimaryWindow:show()
    self:app():show()
    if not self:isShowing() then
        return self:window():focus()
    end
    return self
end

--- cp.blackmagic.resolve.main.PrimaryWindow:doShow() -> PrimaryWindow
--- Field
--- A [Statement](cp.rx.go.Statement.md) that attempts to show the Primary Window.
---
--- Returns:
--- * The `Statement`, which resolves as either `true` or sends an error.
function PrimaryWindow.lazy.method:doShow()
    return Do(self:app():doShow())
    :Then(
        If(self.isShowing):Is(false)
        :Then(self:window():doFocus())
    )
    :Label("PrimaryWindow:doShow")
end

return PrimaryWindow
