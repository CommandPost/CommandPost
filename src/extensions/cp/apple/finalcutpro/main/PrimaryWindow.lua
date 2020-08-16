--- === cp.apple.finalcutpro.main.PrimaryWindow ===
---
--- Primary Window Module.

local require           = require

--local log               = require "hs.logger".new "primaryWindow"

local axutils           = require "cp.ui.axutils"

local Window            = require "cp.ui.Window"

local Inspector         = require "cp.apple.finalcutpro.inspector.Inspector"
local PrimaryToolbar    = require "cp.apple.finalcutpro.main.PrimaryToolbar"

local Do                = require "cp.rx.go.Do"
local If                = require "cp.rx.go.If"

local class             = require "middleclass"
local lazy              = require "cp.lazy"

local PrimaryWindow = class("cp.apple.finalcutpro.main.PrimaryWindow"):include(lazy)

--- cp.apple.finalcutpro.main.PrimaryWindow.matches(w) -> boolean
--- Function
--- Checks to see if a window matches the PrimaryWindow requirements
---
--- Parameters:
---  * w - The window to check
---
--- Returns:
---  * `true` if matched otherwise `false`
function PrimaryWindow.static.matches(w)
    if w ~= nil then
        local subrole = w:attributeValue("AXSubrole")
        return w:attributeValue("AXTitle") == "Final Cut Pro" and (subrole == "AXStandardWindow" or subrole == "AXDialog")
    end
    return false
end

--- cp.apple.finalcutpro.main.PrimaryWindow(app) -> PrimaryWindow object
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

--- cp.apple.finalcutpro.main.PrimaryWindow:app() -> cp.apple.finalcutpro
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

--- cp.apple.finalcutpro.main.PrimaryWindow.window <cp.ui.Window>
--- Field
--- The `Window` instance.
function PrimaryWindow.lazy.value:window()
    return Window(self:app().app, self.UI)
end

--- cp.apple.finalcutpro.main.PrimaryWindow.UI <cp.prop: hs._asm.axuielement; read-only; live>
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

--- cp.apple.finalcutpro.main.PrimaryWindow.hsWindow <cp.prop: hs.window; read-only>
--- Field
--- The `hs.window` instance for the window, or `nil` if it can't be found.
function PrimaryWindow.lazy.prop:hsWindow()
    return self.window.hsWindow
end

--- cp.apple.finalcutpro.main.PrimaryWindow.isShowing <cp.prop: boolean>
--- Field
--- Is `true` if the window is visible.
function PrimaryWindow.lazy.prop:isShowing()
    return self.window.visible
end

--- cp.apple.finalcutpro.main.PrimaryWindow.isFullScreen <cp.prop: boolean>
--- Field
--- Is `true` if the window is full-screen.
function PrimaryWindow.lazy.prop:isFullScreen()
    return self.window.fullScreen
end

--- cp.apple.finalcutpro.main.PrimaryWindow.frame <cp.prop: frame>
--- Field
--- The current position (x, y, width, height) of the window.
function PrimaryWindow.lazy.prop:frame()
    return self.window.frame
end

--- cp.apple.finalcutpro.main.PrimaryWindow.rootGroupUI() <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the top AXSplitGroup as a `hs._asm.axuielement` object
function PrimaryWindow.lazy.prop:rootGroupUI()
    return self.UI:mutate(function(original)
        return axutils.cache(self, "_rootGroup", function()
            return axutils.childWith(original(), "AXRole", "AXSplitGroup")
        end)
    end)
end

--- cp.apple.finalcutpro.main.PrimaryWindow.leftGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the left group UI as a `hs._asm.axuielement` object
function PrimaryWindow.lazy.prop:leftGroupUI()
    return self.rootGroupUI:mutate(function(original)
        local root = original()
        if root then
            for _,child in ipairs(root) do
                -----------------------------------------------------------------------
                -- The left group has only one child:
                -----------------------------------------------------------------------
                if #child == 1 then
                    return child[1]
                end
            end
        end
        return nil
    end)
end

--- cp.apple.finalcutpro.main.PrimaryWindow.rightGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the right group UI as a `hs._asm.axuielement` object.
function PrimaryWindow.lazy.prop:rightGroupUI()
    return self.rootGroupUI:mutate(function(original)
        local root = original()
        if root and #root >= 3 then -- NOTE: Chris changed from "== 3" to ">= 3" because this wasn't working with FCPX 10.4 as there seems to be two AXSplitters.
            if #(root[1]) >= 3 then
                return root[1]
            else
                return root[2]
            end
        end
        return nil
    end)
end

--- cp.apple.finalcutpro.main.PrimaryWindow.topGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the top group UI as a `hs._asm.axuielement` object.
function PrimaryWindow.lazy.prop:topGroupUI()
    return self.leftGroupUI:mutate(function(original)
        local left = original()
        if left then
            if #left < 3 then
                -----------------------------------------------------------------------
                -- Either top or bottom is visible.
                -- It's impossible to determine which it at this level,
                -- so just return the non-empty one:
                -----------------------------------------------------------------------
                for _,child in ipairs(left) do
                    if #child > 0 then
                        return child[1]
                    end
                end
            elseif #left >= 3 then
                -----------------------------------------------------------------------
                -- Both top and bottom are visible. Grab the highest AXGroup:
                -----------------------------------------------------------------------
                local top = nil
                for _,child in ipairs(left) do
                    if child:attributeValue("AXRole") == "AXGroup" then
                        local topFrame = top and top:frame()
                        local childFrame = child and child:frame()
                        if top == nil or (topFrame and childFrame and topFrame.y > childFrame.y) then
                            top = child
                        end
                    end
                end
                if top then return top[1] end
            end
        end
        return nil
    end)
end

--- cp.apple.finalcutpro.main.PrimaryWindow:bottomGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the bottom group UI as a `hs._asm.axuielement` object.
function PrimaryWindow.lazy.prop:bottomGroupUI()
    return self.leftGroupUI:mutate(function(original)
        local left = original()
        if left then
            if #left < 3 then
                -----------------------------------------------------------------------
                -- Either top or bottom is visible.
                -- It's impossible to determine which it at this level,
                -- so just return the non-empty one:
                -----------------------------------------------------------------------
                for _,child in ipairs(left) do
                    if #child > 0 then
                        return child[1]
                    end
                end
            elseif #left >= 3 then
                -----------------------------------------------------------------------
                -- Both top and bottom are visible. Grab the lowest AXGroup:
                -----------------------------------------------------------------------
                local top = nil
                for _,child in ipairs(left) do
                    if child:attributeValue("AXRole") == "AXGroup" then
                        if top == nil or top:frame().y < child:frame().y then
                            top = child
                        end
                    end
                end
                if top then return top[1] end
            end
        end
        return nil
    end)
end

--- cp.apple.finalcutpro.main.PrimaryWindow.viewerGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the UI that contains the `Viewer`.
function PrimaryWindow.lazy.prop:viewerGroupUI()
    return self.topGroupUI
end

--- cp.apple.finalcutpro.main.PrimaryWindow.timelineGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the UI that contains the `Timeline`.
function PrimaryWindow.lazy.prop:timelineGroupUI()
    return self.bottomGroupUI
end

--- cp.apple.finalcutpro.main.PrimaryWindow.browserGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the UI which contains the Browser.
function PrimaryWindow.lazy.prop:browserGroupUI()
    return self.topGroupUI
end

--- cp.apple.finalcutpro.main.PrimaryWindow:show() -> PrimaryWindow
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
        return self.window:focus()
    end
    return self
end

--- cp.apple.finalcutpro.main.PrimaryWindow:doShow() -> PrimaryWindow
--- Field
--- A [Statement](cp.rx.go.Statement.md) that attempts to show the Primary Window.
---
--- Returns:
--- * The `Statement`, which resolves as either `true` or sends an error.
function PrimaryWindow.lazy.method:doShow()
    return Do(self:app():doShow())
    :Then(
        If(self.isShowing):Is(false)
        :Then(self.window:doFocus())
    )
    :Label("PrimaryWindow:doShow")
end

-----------------------------------------------------------------------
--
-- INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.PrimaryWindow.inspector <Inspector>
--- Field
--- The Inspector object.
function PrimaryWindow.lazy.value:inspector()
    return Inspector(self)
end

-----------------------------------------------------------------------
--
-- COLOR BOARD:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.PrimaryWindow.colorBoard <ColorBoard>
--- Field
--- The ColorBoard object.
function PrimaryWindow.lazy.value:colorBoard()
    return self.inspector.color.colorBoard
end

-----------------------------------------------------------------------
--
-- VIEWER:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.PrimaryWindow.toolbar <cp.ui.PrimaryToolbar>
--- Field
--- The PrimaryToolbar element.
function PrimaryWindow.lazy.value:toolbar()
    return PrimaryToolbar(self)
end

-----------------------------------------------------------------------
--
-- BROWSER:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.PrimaryWindow.alert <cp.ui.Alert>
--- Field
--- Provides access to any 'Alert' windows on the PrimaryWindow.
function PrimaryWindow.lazy.value:alert()
    return self.window.alert
end

-- This just returns the same element when it is called as a method. (eg. `fcp.viewer == fcp.viewer`)
-- This is a bridge while we migrate to using `lazy.value` instead of `lazy.method` (or methods)
-- in the FCPX API.
function PrimaryWindow:__call()
    return self
end

return PrimaryWindow
