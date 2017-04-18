--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.finalcutpro.prefs.PlaybackPanel ===
---
--- Playback Panel Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("playbackPanel")
local inspect							= require("hs.inspect")

local axutils							= require("cp.finalcutpro.axutils")
local just								= require("cp.just")
local CheckBox							= require("cp.finalcutpro.ui.CheckBox")

local id								= require("cp.finalcutpro.ids") "PlaybackPanel"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local PlaybackPanel = {}

PlaybackPanel.ID = 3

PlaybackPanel.CREATE_OPTIMIZED_MEDIA_FOR_MULTICAM_CLIPS = id "CreateMulticamOptimizedMedia"
PlaybackPanel.AUTO_START_BG_RENDER = id "BackgroundRender"

-- TODO: Add documentation
function PlaybackPanel:new(preferencesDialog)
	o = {_parent = preferencesDialog}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- TODO: Add documentation
function PlaybackPanel:parent()
	return self._parent
end

-- TODO: Add documentation
function PlaybackPanel:UI()
	return axutils.cache(self, "_ui", function()
		local toolbarUI = self:parent():toolbarUI()
		return toolbarUI and toolbarUI[PlaybackPanel.ID]
	end)
end

-- TODO: Add documentation
function PlaybackPanel:isShowing()
	if self:parent():isShowing() then
		local toolbar = self:parent():toolbarUI()
		if toolbar then
			local selected = toolbar:selectedChildren()
			return #selected == 1 and selected[1] == toolbar[PlaybackPanel.ID]
		end
	end
	return false
end

-- TODO: Add documentation
function PlaybackPanel:show()
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

function PlaybackPanel:hide()
	return self:parent():hide()
end

-- TODO: Add documentation
function PlaybackPanel:toggleCheckBox(identifier)
	if self:show() then
		local group = self:parent():groupUI()
		if group then
			local checkbox = axutils.childWith(group, "AXIdentifier", identifier)
			checkbox:doPress()
			return true
		end
	end
	return false
end

function PlaybackPanel:createOptimizedMediaForMulticamClips()
	if not self._createOptimizedMedia then
		self._createOptimizedMedia = CheckBox:new(self, function()
			return axutils.childWith(self:parent():groupUI(), id "CreateMulticamOptimizedMedia")
		end)
	end
	return self._createOptimizedMedia
end

-- TODO: Add documentation
function PlaybackPanel:toggleCreateOptimizedMediaForMulticamClips()
	local checkBox = self:createOptimizedMediaForMulticamClips()
	if self:show() and checkBox:isShowing() then
		checkBox:toggle()
		return true
	end
	return false
end

function PlaybackPanel:autoStartBGRender()
	if not self._autoStartBGRender then
		self._autoStartBGRender = CheckBox:new(self, function()
			return axutils.childWith(self:parent():groupUI(), id "BackgroundRender")
		end)
	end
	return self._autoStartBGRender
end

-- TODO: Add documentation
function PlaybackPanel:toggleAutoStartBGRender()
	local checkBox = self:autoStartBGRender()
	if self:show() and checkBox:isShowing() then
		checkBox:toggle()
		return true
	end
	return false
end

return PlaybackPanel