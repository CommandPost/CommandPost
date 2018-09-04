--- === cp.apple.finalcutpro.main.PrimaryWindow ===
---
--- Primary Window Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log							= require("hs.logger").new("primaryWindow")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils						= require("cp.ui.axutils")
local prop							= require("cp.prop")

local Window						= require("cp.ui.Window")

local Inspector						= require("cp.apple.finalcutpro.inspector.Inspector")
local PrimaryToolbar				= require("cp.apple.finalcutpro.main.PrimaryToolbar")

local Do                            = require("cp.rx.go.Do")
local If                            = require("cp.rx.go.If")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local PrimaryWindow = {}

--- cp.apple.finalcutpro.main.PrimaryWindow.matches(w) -> boolean
--- Function
--- Checks to see if a window matches the PrimaryWindow requirements
---
--- Parameters:
---  * w - The window to check
---
--- Returns:
---  * `true` if matched otherwise `false`
function PrimaryWindow.matches(w)
    local subrole = w:attributeValue("AXSubrole")
    return w and w:attributeValue("AXTitle") == "Final Cut Pro" and (subrole == "AXStandardWindow" or subrole == "AXDialog")
end

--- cp.apple.finalcutpro.main.PrimaryWindow.new(app) -> PrimaryWindow object
--- Method
--- Creates a new PrimaryWindow.
---
--- Parameters:
---  * None
---
--- Returns:
---  * PrimaryWindow
function PrimaryWindow.new(app)
    local o = prop.extend({
        _app = app,
    }, PrimaryWindow)

    -- provides access to common AXWindow properties.
    local window = Window.new(app.app, app.windowsUI:mutate(function(original)
        return axutils.cache(o, "_ui", function()
            return axutils.childMatching(original(), PrimaryWindow.matches)
        end,
        PrimaryWindow.matches)
    end))
    o._window = window

    prop.bind(o) {
--- cp.apple.finalcutpro.main.PrimaryWindow.UI <cp.prop: axuielement; read-only>
--- Field
--- The `axuielement` for the window.
        UI = window.UI,

--- cp.apple.finalcutpro.main.PrimaryWindow.hsWindow <cp.prop: hs.window; read-only>
--- Field
--- The `hs.window` instance for the window, or `nil` if it can't be found.
        hsWindow = window.hsWindow,

--- cp.apple.finalcutpro.main.PrimaryWindow.isShowing <cp.prop: boolean>
--- Field
--- Is `true` if the window is visible.
        isShowing = window.visible,

--- cp.apple.finalcutpro.main.PrimaryWindow.isFullScreen <cp.prop: boolean>
--- Field
--- Is `true` if the window is full-screen.
        isFullScreen = window.fullScreen,

--- cp.apple.finalcutpro.main.PrimaryWindow.frame <cp.prop: frame>
--- Field
--- The current position (x, y, width, height) of the window.
        frame = window.frame,
    }

--- cp.apple.finalcutpro.main.PrimaryWindow.rootGroupUI() <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the top AXSplitGroup as a `hs._asm.axuielement` object
    local rootGroupUI = window.UI:mutate(function(original, self)
        return axutils.cache(self, "_rootGroup", function()
            local ui = original()
            return ui and axutils.childWith(ui, "AXRole", "AXSplitGroup")
        end)
    end)

--- cp.apple.finalcutpro.main.PrimaryWindow.leftGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the left group UI as a `hs._asm.axuielement` object
    local leftGroupUI = rootGroupUI:mutate(function(original)
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

--- cp.apple.finalcutpro.main.PrimaryWindow.rightGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the right group UI as a `hs._asm.axuielement` object.
    local rightGroupUI = rootGroupUI:mutate(function(original)
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

--- cp.apple.finalcutpro.main.PrimaryWindow.topGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the top group UI as a `hs._asm.axuielement` object.
    local topGroupUI = leftGroupUI:mutate(function(original)
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

--- cp.apple.finalcutpro.main.PrimaryWindow:bottomGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the bottom group UI as a `hs._asm.axuielement` object.
    local bottomGroupUI = leftGroupUI:mutate(function(original)
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

--- cp.apple.finalcutpro.main.PrimaryWindow.viewerGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the UI that contains the `Viewer`.
    local viewerGroupUI = topGroupUI

--- cp.apple.finalcutpro.main.PrimaryWindow.timelineGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the UI that contains the `Timeline`.
    local timelineGroupUI = bottomGroupUI

--- cp.apple.finalcutpro.main.PrimaryWindow.browserGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- Returns the UI which contains the Browser.
    local browserGroupUI = topGroupUI

    prop.bind(o) {
        rootGroupUI = rootGroupUI,
        leftGroupUI = leftGroupUI,
        rightGroupUI = rightGroupUI,
        topGroupUI = topGroupUI,
        bottomGroupUI = bottomGroupUI,
        viewerGroupUI = viewerGroupUI,
        timelineGroupUI = timelineGroupUI,
        browserGroupUI = browserGroupUI,
    }

    return o
end

--- cp.apple.finalcutpro.main.PrimaryWindow:app() -> hs.application
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

--- cp.apple.finalcutpro.main.PrimaryWindow:window() -> cp.ui.Window
--- Method
--- Returns the `Window` instance.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Window` instance.
function PrimaryWindow:window()
    return self._window
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
        return self:window():focus()
    end
    return self
end

function PrimaryWindow:doShow()
    return Do(self:app():doShow())
    :Then(
        If(self.isShowing):Is(false)
        :Then(self:window():doFocus())
    )
    :Label("PrimaryWindow:doShow")
end

-----------------------------------------------------------------------
--
-- INSPECTOR:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.PrimaryWindow:inspector() -> Inspector
--- Method
--- Gets the Inspector object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * Inspector
function PrimaryWindow:inspector()
    if not self._inspector then
        self._inspector = Inspector(self)
    end
    return self._inspector
end

-----------------------------------------------------------------------
--
-- COLOR BOARD:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.PrimaryWindow:colorBoard() -> ColorBoard
--- Method
--- Gets the ColorBoard object.
---
--- Parameters:
---  * None
---
--- Returns:
---  * ColorBoard
function PrimaryWindow:colorBoard()
    return self:inspector():color():colorBoard()
end

-----------------------------------------------------------------------
--
-- VIEWER:
--
-----------------------------------------------------------------------


--- cp.apple.finalcutpro.main.PrimaryWindow:toolbar() -> PrimaryToolbar
--- Method
--- Returns the PrimaryToolbar element.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `PrimaryToolbar`.
function PrimaryWindow:toolbar()
    if not self._toolbar then
        self._toolbar = PrimaryToolbar.new(self)
    end
    return self._toolbar
end

-----------------------------------------------------------------------
--
-- BROWSER:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.PrimaryWindow:alert() -> cp.ui.Alert
--- Method
--- Provides access to any 'Alert' windows on the PrimaryWindow.
---
--- Parameters:
---  * None
---
--- Returns:
---  * A `cp.ui.Alert` object
function PrimaryWindow:alert()
    return self:window():alert()
end

return PrimaryWindow
