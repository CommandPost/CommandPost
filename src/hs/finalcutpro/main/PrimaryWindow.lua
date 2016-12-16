local log							= require("hs.logger").new("PrefsDlg")
local inspect						= require("hs.inspect")

local axutils						= require("hs.finalcutpro.axutils")
local just							= require("hs.just")

local Button						= require("hs.finalcutpro.ui.Button")

local Browser						= require("hs.finalcutpro.main.Browser")
local Inspector						= require("hs.finalcutpro.main.Inspector")
local Viewer						= require("hs.finalcutpro.main.Viewer")

local PrimaryWindow = {}

function PrimaryWindow:new(app)
	o = {
		_app = app
	}
	setmetatable(o, self)
	self.__index = self
	
	return o
end

function PrimaryWindow:app()
	return self._app
end

function PrimaryWindow:show()
	-- Currently a null-op. Determin if there are any scenarios where we need to force this.
	return true
end

function PrimaryWindow:UI()
	local ui = self:app():UI():mainWindow()
	if not self:_isPrimaryWindow(ui) then
		local windowsUI = self:app():windowsUI()
		ui = windowsUI and self:_findWindowUI(windowsUI)
	end
	return ui
end

function PrimaryWindow:_findWindowUI(windows)
	for i,w in ipairs(windows) do
		if self:isPrimaryWindow(w) then	return w end
	end
	return nil
end

function PrimaryWindow:_isPrimaryWindow(w)
	return w and w:attributeValue("AXSubrole") == "AXStandardWindow"
end

function PrimaryWindow:isFullScreen()
	local ui = self:UI()
	return ui and ui:fullScreen()
end

function PrimaryWindow:setFullScreen(isFullScreen)
	local ui = self:UI()
	if ui then ui:setFullScreen(isFullScreen) end
	return self
end

function PrimaryWindow:toggleFullScreen()
	local ui = self:UI()
	if ui then ui:setFullScreen(not self:isFullScreen()) end
	return self
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- UI STRUCTURE
-----------------------------------------------------------------------
-----------------------------------------------------------------------

-- The top AXSplitGroup contains the 
function PrimaryWindow:rootGroupUI()
	local ui = self:UI()
	return ui and axutils.childWith(ui, "AXRole", "AXSplitGroup")
end

function PrimaryWindow:leftGroupUI()
	local root = self:rootGroupUI()
	if root then
		for i,child in ipairs(root) do
			-- the left group has only one child
			if #child == 1 then
				return child[1]
			end
		end
	end
	return nil
end

function PrimaryWindow:rightGroupUI()
	local root = self:rootGroupUI()
	if root and #root == 2 then
		if #(root[1]) == 3 then
			return root[1]
		else
			return root[2]
		end
	end
	return nil
end

function PrimaryWindow:topGroupUI()
	local left = self:leftGroupUI()
	if left and #left == 3 then
		for i,child in ipairs(left) do
			if #child == 1 and #(child[1]) > 1 then
				return child[1]
			end
		end
	end
	return nil	
end

function PrimaryWindow:bottomGroupUI()
	local left = self:leftGroupUI()
	if left and #left == 3 then
		for i,child in ipairs(left) do
			if #child == 1 and #(child[1]) == 1 then
				return child[1]
			end
		end
	end
	return nil	
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- INSPECTOR
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function PrimaryWindow:inspectorUI()
	local ui = self:rightGroupUI()
	if ui then
		-- it's in the right panel (full-height)
		if self:_isInspector(ui) then
			return ui
		end
	else
		-- it's in the top-left panel (half-height)
		local top = self:topGroupUI()
		for i,child in ipairs(top) do
			if self:_isInspector(child) then
				return child
			end
		end
	end
	return nil
end

function PrimaryWindow:_isInspector(element)
	return axutils.childWith(element, "AXIdentifier", "_NS:112") ~= nil -- is inspecting
		or axutils.childWith(element, "AXIdentifier", "_NS:53") ~= nil 	-- nothing to inspect
end

function PrimaryWindow:inspector()
	if not self._inspector then
		self._inspector = Inspector:new(self)
	end
	return self._inspector
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- VIEWER UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function PrimaryWindow:viewerUI()
	local top = self:topGroupUI()
	local ui = nil
	for i,child in ipairs(top) do
		-- There can be two viwers enabled
		if self:_isViewer(child) then
			-- Both the event viewer and standard viewer have the ID, so pick the right-most one
			if ui == nil or ui:position().x < child:position().x then
				ui = child
			end
		end
	end
	return ui
end

function PrimaryWindow:_isViewer(element)
	-- Viewers contain an AXSplitGroup with an ID of "_NS:523"
	return axutils.childWith(element, "AXIdentifier", "_NS:523") ~= nil
end

function PrimaryWindow:viewer()
	if not self._viewer then
		self._viewer = Viewer:new(self, false)
	end
	return self._viewer
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- EVENT VIEWER UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function PrimaryWindow:eventViewerUI()
	local top = self:topGroupUI()
	local ui = nil
	local viewerCount = 0
	for i,child in ipairs(top) do
		-- There can be two viwers enabled
		if self:_isViewer(child) then
			viewerCount = viewerCount + 1
			-- Both the event viewer and standard viewer have the ID, so pick the left-most one
			if ui == nil or ui:position().x > child:position().x then
				ui = child
			end
		end
	end
	-- Can only be the event viewer if there are two viewers.
	if viewerCount == 2 then
		return ui
	else
		return nil
	end
end

function PrimaryWindow:eventViewer()
	if not self._eventViewer then
		self._eventViewer = Viewer:new(self, true)
	end
	return self._eventViewer
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- TIMELINE UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------

function PrimaryWindow:timelineUI()
	return self:bottomGroupUI()
end

function PrimaryWindow:timelineToolbarUI()
	local timeline = self:timelineUI()
	return timeline and timeline[1][2]
end

function PrimaryWindow:timelineScrollAreaUI()
	local timeline = self:timelineUI()
	return timeline and timeline[1][1][1]
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- BROWSER
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function PrimaryWindow:browserUI()
	local top = self:topGroupUI()
	local ui = nil
	for i,child in ipairs(top) do
		if self:_isBrowser(child) then
			return child
		end
	end
	return ui
end

function PrimaryWindow:_isBrowser(element)
	return axutils.childWith(element, "AXIdentifier", "_NS:82") ~= nil
end

function PrimaryWindow:browser()
	if not self._browser then
		self._browser = Browser:new(self)
	end
	return self._browser
end

return PrimaryWindow
