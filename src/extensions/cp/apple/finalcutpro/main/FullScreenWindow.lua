--- === cp.apple.finalcutpro.main.FullScreenWindow ===
---
--- Full Screen Window Player.
---
--- Triggered by the "View > Playback > Play Full Screen" menubar item.

-- TODO: This needs to be updated to use middleclass.
--       Maybe also rename this to FullScreenPlayer?

local require       = require

local axutils       = require "cp.ui.axutils"
local prop          = require "cp.prop"
local Window        = require "cp.ui.Window"

local FullScreenWindow = {}

-- _findWindowUI(windows) -> window | nil
-- Function
-- Gets the Window UI.
--
-- Parameters:
--  * windows - Table of windows.
--
-- Returns:
--  * An `axuielementObject` or `nil`
local function _findWindowUI(windows)
    for _,w in ipairs(windows) do
        if FullScreenWindow.matches(w) then return w end
    end
    return nil
end

--- cp.apple.finalcutpro.main.FullScreenWindow.matches(element) -> boolean
--- Function
--- Checks to see if an element matches what we think it should be.
---
--- Parameters:
---  * element - An `axuielementObject` to check.
---
--- Returns:
---  * `true` if matches otherwise `false`
function FullScreenWindow.matches(element)
    if element and element:attributeValue("AXSubrole") == "AXUnknown"
    and element:attributeValue("AXTitle") == "" then
        local children = element:attributeValue("AXChildren")
        return children and #children == 1 and children[1]:attributeValue("AXRole") == "AXSplitGroup"
    end
    return false
end

--- cp.apple.finalcutpro.main.FullScreenWindow.new(app) -> FullScreenWindow
--- Constructor
--- Creates a new FCPX `FullScreenWindow` instance.
---
--- Parameters:
--- * app       - The FCP app instance.
---
--- Returns:
--- * The new `FullScreenWindow`.
function FullScreenWindow.new(app)
    local o = prop.extend({
        _app = app,
    }, FullScreenWindow)

    local UI = app.windowsUI:mutate(function(original, self)
        return axutils.cache(self, "_ui", function()
            local windowsUI = original()
            return windowsUI and _findWindowUI(windowsUI)
        end,
        FullScreenWindow.matches)
    end)

    -- provides access to common AXWindow properties.
    local window = Window(app.app, UI)
    o._window = window

    local rootGroupUI = UI:mutate(function(original, self)
        return axutils.cache(self, "_rootGroup", function()
            local ui = original()
            return ui and axutils.childWithRole(ui, "AXSplitGroup")
        end)
    end)

    local viewerGroupUI = rootGroupUI:mutate(function(original)
        local ui = original()
        if ui then
            local group
            if #ui == 1 then
                group = ui[1]
            else
                group = axutils.childMatching(ui, function(element) return #element == 2 end)
            end
            if #group == 2 and axutils.childWithRole(group, "AXImage") ~= nil then
                return group
            end
        end
        return nil
    end)

    local isFullScreen = rootGroupUI:mutate(
        function(original)
            local ui = original()
            if ui then
                -- In full-screen, it can either be a single group, or a sub-group containing the event viewer.
                local group
                if #ui == 1 then
                    group = ui[1]
                else
                    group = axutils.childMatching(ui, function(element) return #element == 2 end)
                end
                if #group == 2 then
                    local image = axutils.childWithRole(group, "AXImage")
                    return image ~= nil
                end
            end
            return false
        end,
        function(fullScreen, original)
            local ui = original:UI()
            if ui then ui:setFullScreen(fullScreen) end
        end
    )

    prop.bind(o) {
--- cp.apple.finalcutpro.main.FullScreenWindow.UI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- The core `axuielement` for the window.
        UI = UI,

--- cp.apple.finalcutpro.main.FullScreenWindow.rootGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- The root `AXGroup`.
        rootGroupUI = rootGroupUI,

--- cp.apple.finalcutpro.main.FullScreenWindow.viewerGroupUI <cp.prop: hs._asm.axuielement; read-only; live>
--- Field
--- The Viewer's group UI element.
        viewerGroupUI = viewerGroupUI,

--- cp.apple.finalcutpro.main.FullScreenWindow.isShowing <cp.prop; boolean; read-only; live>
--- Field
--- Checks if the window is currently showing.
        isShowing = window.visible,

--- cp.apple.finalcutpro.main.FullScreenWindow.isFullScreen <cp.prop; boolean; read-only; live>
--- Field
--- Checks if the window is full-screen.
        isFullScreen = isFullScreen,
    }

    return o
end

--- cp.apple.finalcutpro.main.FullScreenWindow:app() -> cp.apple.finalcutpro
--- Method
--- Returns the FCPX app.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The FCPX app.
function FullScreenWindow:app()
    return self._app
end

--- cp.apple.finalcutpro.main.FullScreenWindow:window() -> cp.ui.Window
--- Method
--- Returns the `Window` instance for the full-screen window.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `Window` instance.
function FullScreenWindow:window()
    return self._window
end

--- cp.apple.finalcutpro.main.FullScreenWindow:show() -> cp.apple.finalcutpro
--- Method
--- Attempts to show the full screen window.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The window instance.
function FullScreenWindow:show()
    self:app():selectMenu({"View", "Playback", "Play Full Screen"})
    return self
end

return FullScreenWindow
