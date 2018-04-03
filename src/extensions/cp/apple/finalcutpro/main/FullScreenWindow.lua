--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.FullScreenWindow ===
---
--- Full Screen Window

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local axutils						= require("cp.ui.axutils")
local prop							= require("cp.prop")
local WindowWatcher					= require("cp.apple.finalcutpro.WindowWatcher")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local FullScreenWindow = {}

-- TODO: Add documentation
local function _findWindowUI(windows)
    for _,w in ipairs(windows) do
        if FullScreenWindow.matches(w) then return w end
    end
    return nil
end

-- TODO: Add documentation
function FullScreenWindow.matches(element)
    if element and element:attributeValue("AXSubrole") == "AXUnknown"
    and element:attributeValue("AXTitle") == "" then
        local children = element:attributeValue("AXChildren")
        return children and #children == 1 and children[1]:attributeValue("AXRole") == "AXSplitGroup"
    end
    return false
end

-- TODO: Add documentation
-- TODO: Convert to a Constructor Function
function FullScreenWindow:new(app) --luacheck:ignore
    local o = {
        _app = app
    }
    return prop.extend(o, FullScreenWindow)
end

-- TODO: Add documentation
function FullScreenWindow:app()
    return self._app
end

-- TODO: Add documentation
function FullScreenWindow:show() -- luacheck:ignore
    -- Currently a null-op. Determine if there are any scenarios where we need to force this.
    return true
end

-- TODO: Add documentation
function FullScreenWindow:UI()
    return axutils.cache(self, "_ui", function()
        local ui = self:app():UI()
        if ui then
            if FullScreenWindow.matches(ui:mainWindow()) then
                return ui:mainWindow()
            else
                local windowsUI = self:app():windowsUI()
                return windowsUI and _findWindowUI(windowsUI)
            end
        end
        return nil
    end,
    FullScreenWindow.matches)
end

-- TODO: Add documentation
FullScreenWindow.isShowing = prop.new(function(self)
    return self:UI() ~= nil
end):bind(FullScreenWindow)

-- TODO: Add documentation
FullScreenWindow.isFullScreen = prop.new(function(self)
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
end):bind(FullScreenWindow)

-- TODO: Add documentation
function FullScreenWindow:setFullScreen(isFullScreen)
    local ui = self:UI()
    if ui then ui:setFullScreen(isFullScreen) end
    return self
end

-- TODO: Add documentation
function FullScreenWindow:toggleFullScreen()
    local ui = self:UI()
    if ui then ui:setFullScreen(not self:isFullScreen()) end
    return self
end

-----------------------------------------------------------------------
--
-- UI STRUCTURE:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
-- The top AXSplitGroup contains the
function FullScreenWindow:rootGroupUI()
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
function FullScreenWindow:viewerGroupUI()
    local ui = self:rootGroupUI()
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
end

-----------------------------------------------------------------------
--
-- WATCHERS:
--
-----------------------------------------------------------------------

--- cp.apple.finalcutpro.main.FullScreenWindow:watch() -> table
--- Method
--- Watch for events that happen in the command editor
--- The optional functions will be called when the window
--- is shown or hidden, respectively.
---
--- Parameters:
---  * `events` - A table of functions with to watch. These may be:
---    * `show(CommandEditor)` - Triggered when the window is shown.
---    * `hide(CommandEditor)` - Triggered when the window is hidden.
---
--- Returns:
---  * A table containing an ID which can be passed to `unwatch` to stop watching.
function FullScreenWindow:watch(events)
    if not self._watcher then
        self._watcher = WindowWatcher:new(self)
    end
    return self._watcher:watch(events)
end

--- cp.apple.finalcutpro.main.FullScreenWindow:unwatch(id) -> none
--- Method
--- Unwatches an event.
---
--- Parameters:
---  * id - The ID that would have been previously returned by the `watch()` function.
---
--- Returns:
---  * None
function FullScreenWindow:unwatch(id)
    if self._watcher then
        self._watcher:unwatch(id)
    end
end

return FullScreenWindow