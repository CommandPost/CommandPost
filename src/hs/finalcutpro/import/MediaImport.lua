local log							= require("hs.logger").new("PrefsDlg")
local inspect						= require("hs.inspect")

local axutils						= require("hs.finalcutpro.axutils")
local just							= require("hs.just")
local windowfilter					= require("hs.window.filter")

local MediaImport = {}

function MediaImport.matches(element)
	if element then
		return element:attributeValue("AXSubrole") == "AXDialog"
		   and element:attributeValue("AXMain")
		   and element:attributeValue("AXModal")
		   and axutils.childWith(element, "AXIdentifier", "_NS:39") ~= nil
	end
	return false
end

function MediaImport:new(app)
	o = {_app = app}
	setmetatable(o, self)
	self.__index = self
	return o
end

function MediaImport:app()
	return self._app
end

function MediaImport:UI()
	return axutils.cache(self, "_ui", function()
		local windowsUI = self:app():windowsUI()
		return windowsUI and self:_findWindowUI(windowsUI)
	end,
	MediaImport.matches)
end

function MediaImport:_findWindowUI(windows)
	for i,window in ipairs(windows) do
		if MediaImport.matches(window) then return window end
	end
	return nil
end

function MediaImport:isShowing()
	return self:UI() ~= nil
end

--- Ensures the MediaImport is showing
function MediaImport:show()
	if not self:isShowing() then
		-- open the window
		if self:app():menuBar():isEnabled("File", "Import", "Media…") then
			self:app():menuBar():selectMenu("File", "Import", "Media…")
			local ui = just.doUntil(function() return self:isShowing() end)
		end
	end
	return self
end

function MediaImport:hide()
	local ui = self:UI()
	if ui then
		local closeBtn = ui:closeButton()
		if closeBtn then
			closeBtn:doPress()
		end
	end
	return self
end

function MediaImport:importAll()
	local ui = self:UI()
	if ui then
		local btn = ui:defaultButton()
		if btn and btn:enabled() then
			btn:doPress()
		end
	end
	return self
end

function MediaImport:getTitle()
	local ui = self:UI()
	return ui and ui:title()
end

--- Watch for events that happen in the command editor
--- The optional functions will be called when the window
--- is shown or hidden, respectively.
---
--- Parameters:
--- * `events` - A table of functions with to watch. These may be:
--- 	* `show(MediaImport)` - Triggered when the window is shown.
--- 	* `hide(MediaImport)` - Triggered when the window is hidden.
---
--- Returns:
--- * An ID which can be passed to `unwatch` to stop watching.
function MediaImport:watch(events)
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
				debugMessage("Media Import Opened.")
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
				debugMessage("Media Import Closed.")

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
function MediaImport:unwatch(id)
	local watchers = self._watchers
	if id and id.id and watchers and watchers[id.id] then
		table.remove(watchers, id.id)
	end
end

return MediaImport