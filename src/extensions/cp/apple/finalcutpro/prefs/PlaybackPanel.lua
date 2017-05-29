--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.prefs.PlaybackPanel ===
---
--- Playback Panel Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("playbackPanel")
local inspect							= require("hs.inspect")

local axutils							= require("cp.ui.axutils")
local just								= require("cp.just")
local prop								= require("cp.prop")
local CheckBox							= require("cp.ui.CheckBox")

local id								= require("cp.apple.finalcutpro.ids") "PlaybackPanel"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local PlaybackPanel = {}

-- TODO: Add documentation
function PlaybackPanel:new(preferencesDialog)
	local o = {_parent = preferencesDialog}
	
	return prop.extend(o, PlaybackPanel)
end

-- TODO: Add documentation
function PlaybackPanel:parent()
	return self._parent
end

-- TODO: Add documentation
function PlaybackPanel:UI()
	return axutils.cache(self, "_ui", function()
		return axutils.childFromLeft(self:parent():toolbarUI(), id "ID")
	end)
end

-- TODO: Add documentation
PlaybackPanel.isShowing = prop.new(function(self)
	local toolbar = self:parent():toolbarUI()
	if toolbar then
		local selected = toolbar:selectedChildren()
		return #selected == 1 and selected[1] == self:UI()
	end
	return false
end):bind(PlaybackPanel)

function PlaybackPanel:contentsUI()
	return self:isShowing() and self:parent():groupUI() or nil
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

function PlaybackPanel:createMulticamOptimizedMedia()
	if not self._createOptimizedMedia then
		self._createOptimizedMedia = CheckBox:new(self, function()
			return axutils.childFromTop(axutils.childrenWithRole(self:contentsUI(), "AXCheckBox"), id "CreateMulticamOptimizedMedia")
		end)
	end
	return self._createOptimizedMedia
end

function PlaybackPanel:backgroundRender()
	if not self._backgroundRender then
		self._backgroundRender = CheckBox:new(self, function()
			return axutils.childFromTop(axutils.childrenWithRole(self:contentsUI(), "AXCheckBox"), id "BackgroundRender")
		end)
	end
	return self._backgroundRender
end

return PlaybackPanel