local log							= require("hs.logger").new("PrefsDlg")
local inspect						= require("hs.inspect")

local axutils						= require("hs.finalcutpro.axutils")
local just							= require("hs.just")
local windowfilter					= require("hs.window.filter")

local CommandEditor = {}

CommandEditor.GROUP					= "_NS:9"

function CommandEditor.matches(element)
	if element then
		return element:attributeValue("AXSubrole") == "AXDialog"
		   and element:attributeValue("AXModal")
		   and axutils.childWith(element, "AXIdentifier", "_NS:273") ~= nil
	end
	return false
end

function CommandEditor:new(app)
	o = {_app = app}
	setmetatable(o, self)
	self.__index = self
	return o
end

function CommandEditor:app()
	return self._app
end

function CommandEditor:UI()
	return axutils.cache(self, "_ui", function()
		local windowsUI = self:app():windowsUI()
		return windowsUI and self:_findWindowUI(windowsUI)
	end,
	CommandEditor.matches)
end

function CommandEditor:_findWindowUI(windows)
	for i,window in ipairs(windows) do
		if CommandEditor.matches(window) then return window end
	end
	return nil
end

function CommandEditor:isShowing()
	return self:UI() ~= nil
end

--- Ensures the CommandEditor is showing
function CommandEditor:show()
	if not self:isShowing() then
		-- open the window
		if self:app():menuBar():isEnabled("Final Cut Pro", "Commands", "Customize…") then
			self:app():menuBar():selectMenu("Final Cut Pro", "Commands", "Customize…")
			local ui = just.doUntil(function() return self:UI() end)
		end
	end
	return self
end

function CommandEditor:hide()
	local ui = self:UI()
	if ui then
		local closeBtn = axutils.childWith(ui, "AXSubrole", "AXCloseButton")
		if closeBtn then
			closeBtn:doPress()
		end
	end
	return self
end

function CommandEditor:save()
	local ui = self:UI()
	if ui then
		local saveBtn = axutils.childWith(ui, "AXIdentifier", "_NS:50")
		if saveBtn and saveBtn:enabled() then
			saveBtn:doPress()
		end
	end
	return self
end

function CommandEditor:getTitle()
	local ui = self:UI()
	return ui and ui:title()
end

--- Watch for events that happen in the command editor
--- The optional functions will be called when the window
--- is shown or hidden, respectively.
---
--- Parameters:
--- * `events` - A table of functions with to watch. These may be:
--- 	* `show(CommandEditor)` - Triggered when the window is shown.
--- 	* `hide(CommandEditor)` - Triggered when the window is hidden.
---
--- Returns:
--- * An ID which can be passed to `unwatch` to stop watching.
function CommandEditor:watch(events)
	local startWatching = false
	if not self._watchers then
		self._watchers = {}
		startWatching = true
	end
	self._watchers[#(self._watchers)+1] = {show = events.show, hide = events.hide}
	local id = {id=#(self._watchers)}

	if startWatching then
		--------------------------------------------------------------------------------
		-- Final Cut Pro Window Filter:
		--------------------------------------------------------------------------------
		local filter = windowfilter.new{"Final Cut Pro"}

		--------------------------------------------------------------------------------
		-- Final Cut Pro Window Created:
		--------------------------------------------------------------------------------
		filter:subscribe(windowfilter.windowCreated,(function(window, applicationName)
			if (window:title() == self:getTitle()) and self:isShowing() then
				--------------------------------------------------------------------------------
				-- Command Editor is Open:
				--------------------------------------------------------------------------------
				self.windowID = window:id()
				debugMessage("Command Editor Opened.")
				--------------------------------------------------------------------------------

				for i,watcher in ipairs(self._watchers) do
					if watcher.show then
						watcher.show(self)
					end
				end
			end
		end), true)

		--------------------------------------------------------------------------------
		-- Final Cut Pro Window Destroyed:
		--------------------------------------------------------------------------------
		filter:subscribe(windowfilter.windowDestroyed,(function(window, applicationName)

			--------------------------------------------------------------------------------
			-- Command Editor Window Closed:
			--------------------------------------------------------------------------------
			if (window:id() == self.windowID) then
				self.windowID = nil
				debugMessage("Command Editor Closed.")

				for i,watcher in ipairs(self._watchers) do
					if watcher.hide then
						watcher.hide(self)
					end
				end
			end
		end), true)
		self.windowFilter = filter
	end

	return id
end

--- Removes the watch with the specified ID
---
--- Parameters:
--- * `id` - The ID returned from `watch` that wants to be removed.
---
--- Returns:
--- * N/A
function CommandEditor:unwatch(id)
	local watchers = self._watchers
	if id and id.id and watchers and watchers[id.id] then
		table.remove(watchers, id.id)
	end
end

return CommandEditor