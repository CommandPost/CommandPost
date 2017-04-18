--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.finalcutpro.prefs.ImportPanel ===
---
--- Import Panel Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("importPanel")
local inspect							= require("hs.inspect")

local just								= require("cp.just")
local axutils							= require("cp.finalcutpro.axutils")
local CheckBox							= require("cp.finalcutpro.ui.CheckBox")
local RadioButton						= require("cp.finalcutpro.ui.RadioButton")

local id								= require("cp.finalcutpro.ids") "ImportPanel"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ImportPanel = {}

-- TODO: Add documentation
function ImportPanel:new(preferencesDialog)
	o = {_parent = preferencesDialog}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- TODO: Add documentation
function ImportPanel:parent()
	return self._parent
end

-- TODO: Add documentation
function ImportPanel:UI()
	return axutils.cache(self, "_ui", function()
		local toolbarUI = self:parent():toolbarUI()
		return toolbarUI and toolbarUI[id "ID"]
	end)
end

-- TODO: Add documentation
function ImportPanel:isShowing()
	if self:parent():isShowing() then
		local toolbar = self:parent():toolbarUI()
		if toolbar then
			local selected = toolbar:selectedChildren()
			return #selected == 1 and selected[1] == toolbar[id "ID"]
		end
	end
	return false
end

-- TODO: Add documentation
function ImportPanel:show()
	local parent = self:parent()
	-- show the parent.
	if parent:show() then
		-- get the toolbar UI
		local panel = just.doUntil(function() return self:UI() end)
		if panel then
			panel:doPress()
			return true
		end
	end
	return false
end

function ImportPanel:hide()
	return self:parent():hide()
end

function ImportPanel:createProxyMedia()
	if not self._createProxyMedia then
		self._createProxyMedia = CheckBox:new(self, function()
			return axutils.childWith(self:parent():groupUI(), id "CreateProxyMedia")
		end)
	end
	return self._createProxyMedia
end

-- TODO: Add documentation
function ImportPanel:toggleCreateProxyMedia()
	if self:show() and self:createProxyMedia():isShowing() then
		self:createProxyMedia():toggle()
		return true
	end
	return false
end

function ImportPanel:createOptimizedMedia()
	if not self._createOptimizedMedia then
		self._createOptimizedMedia = CheckBox:new(self, function()
			return axutils.childWith(self:parent():groupUI(), id "CreateOptimizedMedia")
		end)
	end
	return self._createOptimizedMedia
end

-- TODO: Add documentation
function ImportPanel:toggleCreateOptimizedMedia()
	if self:show() and self:createOptimizedMedia():isShowing() then
		self:createOptimizedMedia():toggle()
		return true
	end
	return false
end

function ImportPanel:mediaLocationGroupUI()
	return axutils.cache(self, "_mediaLocationGroup", function()
		return axutils.childWithID(self:parent():groupUI(), id "MediaLocationGroup")
	end)
end

function ImportPanel:copyToMediaFolder()
	if not self._copyToMediaFolder then
		self._copyToMediaFolder = RadioButton:new(self, function()
			return self:mediaLocationGroupUI()[id "CopyToMediaFolder"]
		end)
	end
	return self._copyToMediaFolder
end

function ImportPanel:leaveInPlace()
	if not self._leaveInPlace then
		self._leaveInPlace = RadioButton:new(self, function()
			return self:mediaLocationGroupUI()[id "LeaveInPlace"]
		end)
	end
	return self._leaveInPlace
end

-- TODO: Add documentation
function ImportPanel:toggleMediaLocation()
	if self:show() then
		if self:copyToMediaFolder():isChecked() then
			self:leaveInPlace():check()
		else
			self:copyToMediaFolder():check()
		end
		return true
	end
	return false
end

return ImportPanel