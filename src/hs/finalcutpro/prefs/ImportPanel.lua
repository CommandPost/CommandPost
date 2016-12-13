local log								= require("hs.logger").new("playback")
local inspect							= require("hs.inspect")

local just								= require("hs.just")

local ImportPanel = {}

ImportPanel.ID = 4

ImportPanel.CREATE_PROXY_MEDIA 			= "_NS:177"
ImportPanel.CREATE_OPTIMIZED_MEDIA 		= "_NS:15"
ImportPanel.COPY_TO_MEDIA_FOLDER 		= "_NS:84"

function ImportPanel:new(preferencesDialog)
	o = {_parent = preferencesDialog}
	setmetatable(o, self)
	self.__index = self
	return o
end

function ImportPanel:parent()
	return self._parent
end

function ImportPanel:UI()
	local toolbarUI = self:parent():toolbarUI()
	if toolbarUI then
		return toolbarUI:childAt(ImportPanel.ID)
	end
	return nil
end

-- Returns the UI for the AXGroup containing this panels's elements
function ImportPanel:groupUI()
	local parentUI = self:parent():UI()
	if parentUI then
		-- AXIdentifier = "_NS:9"
		return parentUI:childWith("AXIdentifier", "_NS:9")
	end
	return nil
end

function ImportPanel:isShowing()
	if self:parent():isShowing() then
		local toolbar = self:parent():toolbarUI()
		if toolbar then
			local selected = toolbar:attribute("AXSelectedChildren", true)
			return #selected == 1 and selected[1] == toolbar[ImportPanel.ID]
		end
	end
	return false
end

function ImportPanel:show()
	local parent = self:parent()
	-- show the parent.
	if parent:show() then
		-- get the toolbar UI
		local panel = just.doUntil(function() return self:UI() end)
		if panel then
			panel:press()
			return true
		end
	end
	return false
end

function ImportPanel:toggleCheckBox(identifier)
	if self:show() then
		local group = self:groupUI()
		if group then
			local checkbox = group:childWith("AXIdentifier", identifier)
			checkbox:press()
			return true
		end
	end
	return false
end

function ImportPanel:toggleCreateProxyMedia()
	return self:toggleCheckBox(ImportPanel.CREATE_PROXY_MEDIA)
end

function ImportPanel:toggleCreateOptimizedMedia()
	return self:toggleCheckBox(ImportPanel.CREATE_OPTIMIZED_MEDIA)
end

function ImportPanel:toggleCopyToMediaFolder()
	if self:show() then
		local group = self:groupUI()
		if group then
			local radioGroup = group:childWith("AXIdentifier", ImportPanel.COPY_TO_MEDIA_FOLDER)
			if radioGroup then
				for i=1,radioGroup:childCount() do
					local button = radioGroup:childAt(i)
					if button:attribute("AXValue") == 0 then
						button:press()
						return true
					end
				end
			end
		end
	end
	return false
end


return ImportPanel