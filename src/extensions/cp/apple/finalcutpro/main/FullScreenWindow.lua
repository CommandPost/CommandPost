--- === cp.apple.finalcutpro.main.FullScreenWindow ===
---
--- Full Screen Window Player.
---
--- Triggered by the "View > Playback > Play Full Screen" menubar item.

-- TODO: This needs to be updated to use middleclass.
--       Maybe also rename this to FullScreenPlayer?

local require       = require

local axutils       = require "cp.ui.axutils"
local SplitGroup    = require "cp.ui.SplitGroup"
local Window        = require "cp.ui.Window"

local cache         = axutils.cache
local children      = axutils.children
local childMatching = axutils.childMatching
local childWithRole = axutils.childWithRole

local FullScreenWindow = Window:subclass("cp.apple.finalcutpro.main.FullScreenWindow")

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
function FullScreenWindow.static.matches(element)
    return Window.matches(element)
    and element:attributeValue("AXSubrole") == "AXUnknown"
    and element:attributeValue("AXTitle") == ""
    and SplitGroup.matches(children(element)[1])
end

--- cp.apple.finalcutpro.main.FullScreenWindow(app) -> FullScreenWindow
--- Constructor
--- Creates a new FCPX `FullScreenWindow` instance.
---
--- Parameters:
--- * app       - The FCP app instance.
---
--- Returns:
--- * The new `FullScreenWindow`.
function FullScreenWindow:initialize(app)
    local UI = app.windowsUI:mutate(function(original)
        return cache(self, "_ui", function()
            local windowsUI = original()
            return windowsUI and _findWindowUI(windowsUI)
        end,
        FullScreenWindow.matches)
    end)

    Window.initialize(self, app.app, UI)
end

--- cp.apple.finalcutpro.main.FullScreenWindow.rootGroupUI <cp.prop: hs.axuielement; read-only; live>
--- Field
--- The root `AXGroup`.
function FullScreenWindow.lazy.prop:rootGroupUI()
    return self.UI:mutate(function(original)
        return cache(self, "_rootGroup", function()
            local ui = original()
            return ui and childWithRole(ui, "AXSplitGroup")
        end)
    end)
end

--- cp.apple.finalcutpro.main.FullScreenWindow.viewerGroupUI <cp.prop: hs.axuielement; read-only; live>
--- Field
--- The Viewer's group UI element.
function FullScreenWindow.lazy.prop:viewerGroupUI()
    return self.rootGroupUI:mutate(function(original)
        local ui = original()
        if ui then
            local group
            if #ui == 1 then
                group = ui[1]
            else
                group = childMatching(ui, function(element) return #element == 2 end)
            end
            if #group == 2 and childWithRole(group, "AXImage") ~= nil then
                return group
            end
        end
        return nil
    end)
end

--- cp.apple.finalcutpro.main.FullScreenWindow.isFullScreen <cp.prop; boolean; read-only; live>
--- Field
--- Checks if the window is full-screen.
function FullScreenWindow.lazy.prop:isFullScreen()
    return self.rootGroupUI:mutate(
        function(original)
            local ui = original()
            if ui then
                -- In full-screen, it can either be a single group, or a sub-group containing the event viewer.
                local group
                if #ui == 1 then
                    group = ui[1]
                else
                    group = childMatching(ui, function(element) return #element == 2 end)
                end
                if #group == 2 then
                    local image = childWithRole(group, "AXImage")
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
    self:app().menu:selectMenu({"View", "Playback", "Play Full Screen"})
    return self
end

--- cp.apple.finalcutpro.main.FullScreenWindow:doShow() -> <cp.rx.go.Statement>
--- Method
--- A `Statement` that attempts to show the full screen window.
---
--- Parameters:
--- * None
---
--- Returns:
--- * The `Statement` to execute.
function FullScreenWindow.lazy.method:doShow()
    return self:app().menu:doSelectMenu({"View", "Playback", "Play Full Screen"})
    :Label("FullScreenWindow:doShow")
end

return FullScreenWindow
