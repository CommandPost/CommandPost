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

local id								= require("cp.finalcutpro.ids") "ImportPanel"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local ImportPanel = {}

ImportPanel.ID = 4

ImportPanel.CREATE_PROXY_MEDIA 			= id "CreateProxyMedia"
ImportPanel.CREATE_OPTIMIZED_MEDIA 		= id "CreateOptimizedMedia"
ImportPanel.COPY_TO_MEDIA_FOLDER 		= id "CopyToMediaFolder"

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
		return toolbarUI and toolbarUI[ImportPanel.ID]
	end)
end

-- TODO: Add documentation
function ImportPanel:isShowing()
	if self:parent():isShowing() then
		local toolbar = self:parent():toolbarUI()
		if toolbar then
			local selected = toolbar:selectedChildren()
			return #selected == 1 and selected[1] == toolbar[ImportPanel.ID]
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

-- TODO: Add documentation
function ImportPanel:toggleCheckBox(identifier)
	if self:show() then
		local group = self:parent():groupUI()
		if group then
			local checkbox = axutils.childWith(group, "AXIdentifier", identifier)
			if checkbox then
				checkbox:doPress()
				return true
			end
		end
	end
	return false
end

-- TODO: Add documentation
function ImportPanel:toggleCreateProxyMedia()
	return self:toggleCheckBox(ImportPanel.CREATE_PROXY_MEDIA)
end

-- TODO: Add documentation
function ImportPanel:toggleCreateOptimizedMedia()
	return self:toggleCheckBox(ImportPanel.CREATE_OPTIMIZED_MEDIA)
end

-- TODO: Add documentation
function ImportPanel:toggleCopyToMediaFolder()
	if self:show() then
		local group = self:parent():groupUI()
		if group then
			local radioGroup = axutils.childWith(group, "AXIdentifier", ImportPanel.COPY_TO_MEDIA_FOLDER)
			if radioGroup then
				for i,button in ipairs(radioGroup) do
					if button:value() == 0 then
						button:doPress()
						return true
					end
				end
			end
		end
	end
	return false
end

return ImportPanel