--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.SecondaryWindow ===
---
--- Secondary Window Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
-- local log							= require("hs.logger").new("secondaryWindow")

local prop							= require("cp.prop")

local axutils						= require("cp.ui.axutils")
local Window						= require("cp.ui.Window")

local WindowWatcher					= require("cp.apple.finalcutpro.WindowWatcher")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local SecondaryWindow = {}

-- TODO: Add documentation
local function _findWindowUI(windows)
    for _,w in ipairs(windows) do
        if SecondaryWindow.matches(w) then return w end
    end
    return nil
end

-- TODO: Add documentation
function SecondaryWindow.matches(element)
    if element and element:attributeValue("AXModal") == false then
        local children = element:attributeValue("AXChildren")
        return children and #children == 1 and children[1]:attributeValue("AXRole") == "AXSplitGroup"
    end
    return false
end

-- TODO: Add documentation
function SecondaryWindow:new(app)
    local o = prop.extend({
        _app = app
    }, SecondaryWindow)

    local window = Window:new(function()
        return axutils.cache(self, "_ui", function()
            return axutils.childMatching(app:windowsUI(), SecondaryWindow.matches)
        end,
        SecondaryWindow.matches)
    end)
    o._window = window

--- cp.apple.finalcutpro.main.PrimaryWindow.UI <cp.prop: axuielement; read-only>
--- Field
--- The `axuielement` for the window.
    o.UI = window.UI:wrap(o)

--- cp.apple.finalcutpro.main.PrimaryWindow.hsWindow <cp.prop: hs.window; read-only>
--- Field
--- The `hs.window` instance for the window, or `nil` if it can't be found.
    o.hsWindow = window.hsWindow:wrap(o)

--- cp.apple.finalcutpro.main.PrimaryWindow.isShowing <cp.prop: boolean>
--- Field
--- Is `true` if the window is visible.
    o.isShowing = window.visible:wrap(o)

--- cp.apple.finalcutpro.main.PrimaryWindow.isFullScreen <cp.prop: boolean>
--- Field
--- Is `true` if the window is full-screen.
    o.isFullScreen = window.fullScreen:wrap(o)

--- cp.apple.finalcutpro.main.PrimaryWindow.frame <cp.prop: frame>
--- Field
--- The current position (x, y, width, height) of the window.
    o.frame = window.frame:wrap(o)

    o:watch({
        show	= function() o.isShowing:update() end,
        hide	= function() o.isShowing:update() end,
        open	= function() o.isShowing:update() end,
        close	= function() o.isShowing:update() end,
        move	= function() o.frame:update() end,
    })

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
SecondaryWindow.isShowing = prop.new(function(self)
    local ui = self:UI()
    return ui ~= nil and ui:asHSWindow():isVisible()
end):bind(SecondaryWindow)

-- TODO: Add documentation
SecondaryWindow.isFullScreen = prop.new(function(self)
    local ui = self:rootGroupUI()
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
end):bind(SecondaryWindow)

-- TODO: Add documentation
function SecondaryWindow:show()
    -- Currently just ensures the app is running. Determine if there are any scenarios where we need to force this.
    self:app():show()
    return self
end

-- TODO: Add documentation
function SecondaryWindow:UI()
    return axutils.cache(self, "_ui", function()
        local ui = self:app():UI()
        if ui then
            if SecondaryWindow.matches(ui:mainWindow()) then
                return ui:mainWindow()
            else
                local windowsUI = self:app():windowsUI()
                return windowsUI and _findWindowUI(windowsUI)
            end
        end
        return nil
    end,
    SecondaryWindow.matches)
end

function SecondaryWindow:window()
    local ui = self:UI()
    return ui and ui:asHSWindow()
end

-- TODO: Add documentation
function SecondaryWindow:setFullScreen(isFullScreen)
    local ui = self:UI()
    if ui then ui:setFullScreen(isFullScreen) end
    return self
end

-- TODO: Add documentation
function SecondaryWindow:toggleFullScreen()
    local ui = self:UI()
    if ui then ui:setFullScreen(not self:isFullScreen()) end
    return self
end

--- cp.apple.finalcutpro.main.SecondaryWindow.frame <cp.prop: frame>
--- Field
--- The current position (x, y, width, height) of the window.
SecondaryWindow.frame = prop(
    function(self)
        local ui = self:UI()
        return ui and ui:frame()
    end,
    function(frame, self)
        local ui = self:UI()
        if ui then ui:setAttributeValue("AXFrame", frame) end
    end
):bind(SecondaryWindow)

-----------------------------------------------------------------------
--
-- UI STRUCTURE:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
-- The top AXSplitGroup contains the
function SecondaryWindow:rootGroupUI()
    return axutils.cache(self, "_rootGroup", function()
        local ui = self:UI()
        return ui and axutils.childWithRole(ui, "AXSplitGroup")
    end)
end

-----------------------------------------------------------------------
--
-- VIEWER UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function SecondaryWindow:viewerGroupUI()
    return self:rootGroupUI()
end

-----------------------------------------------------------------------
--
-- TIMELINE UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function SecondaryWindow:timelineGroupUI()
    return axutils.cache(self, "_timelineGroup", function()
        -- for some reason, the Timeline is burried under three levels
        local root = self:rootGroupUI()
        if root and root[1] and root[1][1] then
            return root[1][1]
        end
    end)
end

-----------------------------------------------------------------------
--
-- BROWSER:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function SecondaryWindow:browserGroupUI()
    return self:rootGroupUI()
end

-----------------------------------------------------------------------
--
-- WATCHERS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.SecondaryWindow:watch() -> bool
--- Method
--- Watch for events that happen in the command editor
--- The optional functions will be called when the window
--- is shown or hidden, respectively.
---
--- Parameters:
---  * `events` - A table of functions with to watch. These may be:
---    * `show(window)` - Triggered when the window is shown.
---    * `hide(window)` - Triggered when the window is hidden.
---    * `move(window)` - Triggered when the window is moved.
---
--- Returns:
---  * An ID which can be passed to `unwatch` to stop watching.
function SecondaryWindow:watch(events)
    if not self._watcher then
        self._watcher = WindowWatcher:new(self)
    end

    self._watcher:watch(events)
end

-- TODO: Add documentation
function SecondaryWindow:unwatch(id)
    if self._watcher then
        self._watcher:unwatch(id)
    end
end

return SecondaryWindow