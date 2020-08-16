--- === cp.apple.finalcutpro.main.SecondaryWindow ===
---
--- Secondary Window Module.

local require = require

-- local log							= require("hs.logger").new("secondaryWindow")

local axutils						= require "cp.ui.axutils"
local Window						= require "cp.ui.Window"

local go                            = require "cp.rx.go"
local Do, If                        = go.Do, go.If

local class                         = require "middleclass"
local lazy                          = require "cp.lazy"


local SecondaryWindow = class("cp.apple.finalcutpro.main.SecondaryWindow"):include(lazy)

--- cp.apple.finalcutpro.main.SecondaryWindow.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function SecondaryWindow.static.matches(element)
    if element ~= nil and element:attributeValue("AXModal") == false then
        local children = element:attributeValue("AXChildren")
        return children and #children == 1 and children[1]:attributeValue("AXRole") == "AXSplitGroup"
    end
    return false
end

--- cp.apple.finalcutpro.main.SecondaryWindow(app) -> SecondaryWindow
--- Constructor
--- Creates a new `SecondaryWindow` instance.
---
--- Parameters:
---  * app - The `cp.apple.finalcutpro` object.
---
--- Returns:
---  * A new `SecondaryWindow` object.
function SecondaryWindow:initialize(app)
    self._app = app
end

function SecondaryWindow:app()
    return self._app
end

function SecondaryWindow.lazy.value:window()
    return Window(self:app().app, self.UI)
end

function SecondaryWindow.lazy.prop:UI()
    return self:app().windowsUI:mutate(function(original)
        return axutils.cache(self, "_ui", function()
            return axutils.childMatching(original(), SecondaryWindow.matches)
        end,
        SecondaryWindow.matches)
    end)
end

--- cp.apple.finalcutpro.main.SecondaryWindow.hsWindow <cp.prop: hs.window; read-only; live>
--- Field
--- The `hs.window` instance for the window, or `nil` if it can't be found.
function SecondaryWindow.lazy.prop:hsWindow()
    return self.window.hsWindow
end

--- cp.apple.finalcutpro.main.SecondaryWindow.isShowing <cp.prop: boolean; read-only; live>
--- Field
--- Is `true` if the window is visible.
function SecondaryWindow.lazy.prop:isShowing()
    return self.window.visible
end

--- cp.apple.finalcutpro.main.SecondaryWindow.isFullScreen <cp.prop: boolean; live>
--- Field
--- Is `true` if the window is full-screen.
function SecondaryWindow.lazy.prop:isFullScreen()
    return self.window.isFullScreen
end

--- cp.apple.finalcutpro.main.SecondaryWindow.frame <cp.prop: frame>
--- Field
--- The current position (x, y, width, height) of the window.
function SecondaryWindow.lazy.prop:frame()
    return self.window.frame
end

--- cp.apple.finalcutpro.main.SecondaryWindow.rootGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- The root UI element on the window.
function SecondaryWindow.lazy.prop:rootGroupUI()
    return self.UI:mutate(function(original)
        return axutils.cache(self, "_rootGroup", function()
            local ui = original()
            return ui and axutils.childWithRole(ui, "AXSplitGroup")
        end)
    end)
end

--- cp.apple.finalcutpro.main.SecondaryWindow.viewerGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- The UI element that will contain the `Viewer` if it's on the Secondary Window.
function SecondaryWindow.lazy.prop:viewerGroupUI()
    return self.rootGroupUI
end

--- cp.apple.finalcutpro.main.SecondaryWindow.browserGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- The UI element that will contain the `Browser` if it's on the Secondary Window.
function SecondaryWindow.lazy.prop:browserGroupUI()
    return self.rootGroupUI
end

--- cp.apple.finalcutpro.main.SecondaryWindow.timelineGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- The UI element that will contain the `Timeline` if it's on the Secondary Window.
function SecondaryWindow.lazy.prop:timelineGroupUI()
    return self.rootGroupUI:mutate(function(original)
        return axutils.cache(self, "_timelineGroup", function()
            -- for some reason, the Timeline is burried under three levels
            local root = original()
            if root and root[1] and root[1][1] then
                return root[1][1]
            end
        end)
    end)
end

--- cp.apple.finalcutpro.main.SecondaryWindow:app() -> App
--- Method
--- Returns the app instance representing Final Cut Pro.
---
--- Parameters:
---  * None
---
--- Returns:
---  * App
function SecondaryWindow:app()
    return self._app
end

--- cp.apple.finalcutpro.main.SecondaryWindow:show() -> SecondaryWindow
--- Method
--- Show the Secondary Window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `SecondaryWindow` object.
function SecondaryWindow:show()
    --------------------------------------------------------------------------------
    -- Currently just ensures the app is running.
    -- Determine if there are any scenarios where we need to force this.
    --------------------------------------------------------------------------------
    self:app():show()
    return self
end

--- cp.apple.finalcutpro.main.SecondaryWindow:doShow() -> cp.rx.go.Statement
--- Method
--- A [Statement](cp.rx.go.Statement) that shows the Secondary Window.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `SecondaryWindow` object.
function SecondaryWindow.lazy.method:doShow()
    return Do(self:app():doShow())
    :Then(
        If(self.isShowing):Is(false)
        :Then(self.window:doFocus())
        :TimeoutAfter(1000, "Unable to focus on Secondary Window.")
    )
    :Label("SecondaryWindow:doShow")
end

-- This just returns the same element when it is called as a method. (eg. `fcp.viewer == fcp:viewer()`)
-- This is a bridge while we migrate to using `lazy.value` instead of `lazy.method` (or methods)
-- in the FCPX API.
function SecondaryWindow:__call()
    return self
end

return SecondaryWindow
