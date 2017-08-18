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
local log							= require("hs.logger").new("secondaryWindow")
local inspect						= require("hs.inspect")

local axutils						= require("cp.ui.axutils")
local just							= require("cp.just")
local prop							= require("cp.prop")

local Button						= require("cp.ui.Button")
local WindowWatcher					= require("cp.apple.finalcutpro.WindowWatcher")

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
function SecondaryWindow:new(app)
	local o = {
		_app = app
	}
	prop.extend(o, SecondaryWindow)

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
		local group = nil
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
	-- Currently a null-op. Determin if there are any scenarios where we need to force this.
	return true
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
				return windowsUI and self:_findWindowUI(windowsUI)
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
function SecondaryWindow:_findWindowUI(windows)
	for i,w in ipairs(windows) do
		if SecondaryWindow.matches(w) then return w end
	end
	return nil
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