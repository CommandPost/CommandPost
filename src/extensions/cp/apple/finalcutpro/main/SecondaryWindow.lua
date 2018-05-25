--- === cp.apple.finalcutpro.main.SecondaryWindow ===
---
--- Secondary Window Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log							= require("hs.logger").new("secondaryWindow")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils						= require("cp.ui.axutils")
local prop							= require("cp.prop")
local Window						= require("cp.ui.Window")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local SecondaryWindow = {}

-- TODO: Add documentation
function SecondaryWindow.matches(element)
    if element and element:attributeValue("AXModal") == false then
        local children = element:attributeValue("AXChildren")
        return children and #children == 1 and children[1]:attributeValue("AXRole") == "AXSplitGroup"
    end
    return false
end

-- TODO: Add documentation
function SecondaryWindow.new(app)
    local o = prop.extend({
        _app = app
    }, SecondaryWindow)

    local window = Window.new(app.windowsUI:mutate(function(original)
        return axutils.cache(o, "_ui", function()
            return axutils.childMatching(original(), SecondaryWindow.matches)
        end,
        SecondaryWindow.matches)
    end))
    o._window = window

    prop.bind(o) {

--- cp.apple.finalcutpro.main.SecondaryWindow.UI <cp.prop: axuielement; read-only; live>
--- Field
--- The `axuielement` for the window.
        UI = window.UI,

--- cp.apple.finalcutpro.main.SecondaryWindow.hsWindow <cp.prop: hs.window; read-only; live>
--- Field
--- The `hs.window` instance for the window, or `nil` if it can't be found.
        hsWindow = window.hsWindow,

--- cp.apple.finalcutpro.main.SecondaryWindow.isShowing <cp.prop: boolean; read-only; live>
--- Field
--- Is `true` if the window is visible.
        isShowing = window.visible,

--- cp.apple.finalcutpro.main.SecondaryWindow.isFullScreen <cp.prop: boolean; live>
--- Field
--- Is `true` if the window is full-screen.
        isFullScreen = window.fullScreen,

--- cp.apple.finalcutpro.main.SecondaryWindow.frame <cp.prop: frame>
--- Field
--- The current position (x, y, width, height) of the window.
        frame = window.frame,
    }

--- cp.apple.finalcutpro.main.SecondaryWindow.rootGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- The root UI element on the window.
    local rootGroupUI = window.UI:mutate(function(original, self)
        return axutils.cache(self, "_rootGroup", function()
            local ui = original()
            return ui and axutils.childWithRole(ui, "AXSplitGroup")
        end)
    end):bind(o, "rootGroupUI")

    prop.bind(o) {
--- cp.apple.finalcutpro.main.SecondaryWindow.viewerGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- The UI element that will contain the `Viewer` if it's on the Secondary Window.
        viewerGroupUI = rootGroupUI,

--- cp.apple.finalcutpro.main.SecondaryWindow.browserGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- The UI element that will contain the `Browser` if it's on the Secondary Window.
        browserGroupUI = rootGroupUI,

--- cp.apple.finalcutpro.main.SecondaryWindow.timelineGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- The UI element that will contain the `Timeline` if it's on the Secondary Window.
        timelineGroupUI = rootGroupUI:mutate(function(original, self)
            return axutils.cache(self, "_timelineGroup", function()
                -- for some reason, the Timeline is burried under three levels
                local root = original()
                if root and root[1] and root[1][1] then
                    return root[1][1]
                end
            end)
        end),
    }

    return o
end

-- TODO: Add documentation
function SecondaryWindow:app()
    return self._app
end

--- cp.apple.finalcutpro.main.SecondaryWindow:window() -> cp.ui.Window
--- Method
--- Returns the `Window` instance.
---
--- Parameters:
---  * None
---
--- Returns:
---  * The `Window` instance.
function SecondaryWindow:window()
    return self._window
end

-- TODO: Add documentation
function SecondaryWindow:show()
    -- Currently just ensures the app is running. Determine if there are any scenarios where we need to force this.
    self:app():show()
    return self
end

return SecondaryWindow