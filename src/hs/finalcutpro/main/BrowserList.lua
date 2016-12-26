local axutils							= require("hs.finalcutpro.axutils")

local Table								= require("hs.finalcutpro.ui.Table")

local List = {}

function List.matches(element)
	return element and element:attributeValue("AXIdentifier") == "_NS:658"
end

function List:new(parent)
	o = {_parent = parent}
	setmetatable(o, self)
	self.__index = self
	return o
end

function List:parent()
	return self._parent
end

function List:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
--- TIMELINE CONTENT UI
-----------------------------------------------------------------------
-----------------------------------------------------------------------
function List:UI()
	return axutils.cache(self, "_ui", function()
		local main = self:parent():mainGroupUI()
		if main then
			for i,child in ipairs(main) do
				if child:attributeValue("AXRole") == "AXGroup" and #child == 1 then
					if List.matches(child[1]) then
						return child[1]
					end
				end
			end
		end
		return nil
	end,
	List.matches)
end

function List:isShowing()
	return self:UI() ~= nil
end

function List:playerUI()
	return axutils.cache(self, "_player", function()
		local ui = self:UI()
		return ui and axutils.childWithID(ui, "_NS:590")
	end)
end

function List:content()
	if not self._content then
		self._content = Table:new(self, "_NS:9")
	end
	return self._content
end

function List:selectedClipsUI()
	return self:content():selectedRowsUI()
end

function List:showClip(clipUI)
	self:content():showRow(clipUI)
	return self
end

function List:selectClip(clipUI)
	self:content():selectRow(clipUI)
	return self
end

function List:selectClipAt(index)
	self:content():selectRowAt(index)
	return self
end

return List