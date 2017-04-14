--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

-- Libraries List

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local axutils							= require("cp.finalcutpro.axutils")
local Table								= require("cp.finalcutpro.ui.Table")
local Playhead							= require("cp.finalcutpro.main.Playhead")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local List = {}

-- TODO: Add documentation
function List.matches(element)
	return element and element:attributeValue("AXRole") == "AXSplitGroup"
end

-- TODO: Add documentation
function List:new(parent)
	o = {_parent = parent}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- TODO: Add documentation
function List:parent()
	return self._parent
end

-- TODO: Add documentation
function List:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
--
-- UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
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

-- TODO: Add documentation
function List:isShowing()
	return self:UI() ~= nil
end

-----------------------------------------------------------------------
--
-- PREVIEW PLAYER:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function List:playerUI()
	return axutils.cache(self, "_player", function()
		local ui = self:UI()
		return ui and axutils.childWithID(ui, "_NS:590")
	end)
end

-- TODO: Add documentation
function List:playhead()
	if not self._playhead then
		self._playhead = Playhead:new(self, false, function()
			return self:playerUI()
		end)
	end
	return self._playhead
end

-- TODO: Add documentation
function List:skimmingPlayhead()
	if not self._skimmingPlayhead then
		self._skimmingPlayhead = Playhead:new(self, true, function()
			return self:playerUI()
		end)
	end
	return self._skimmingPlayhead
end

-----------------------------------------------------------------------
--
-- LIBRARY CONTENT:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function List:contents()
	if not self._content then
		self._content = Table:new(self, function()
			return axutils.childWithID(self:UI(), "_NS:9")
		end)
	end
	return self._content
end

-- TODO: Add documentation
function List:clipsUI()
	local rowsUI = self:contents():rowsUI()
	if rowsUI then
		local level = 0
		-- if the first row has no icon (_NS:11), it's a group
		local firstCell = self:contents():findCellUI(1, "filmlist name col")
		if firstCell and axutils.childWithID(firstCell, "_NS:11") == nil then
			level = 1
		end
		return axutils.childrenWith(rowsUI, "AXDisclosureLevel", level)
	end
	return nil
end

-- TODO: Add documentation
function List:selectedClipsUI()
	return self:contents():selectedRowsUI()
end

-- TODO: Add documentation
function List:showClip(clipUI)
	self:contents():showRow(clipUI)
	return self
end

-- TODO: Add documentation
function List:selectClip(clipUI)
	self:contents():selectRow(clipUI)
	return self
end

-- TODO: Add documentation
function List:selectClipAt(index)
	self:contents():selectRowAt(index)
	return self
end

-- TODO: Add documentation
function List:selectAll(clipsUI)
	self:contents():selectAll(clipsUI)
	return self
end

-- TODO: Add documentation
function List:deselectAll(clipsUI)
	self:contents():deselectAll(clipsUI)
	return self
end

-- TODO: Add documentation
function List:isFocused()
	local player = self:playerUI()
	return self:contents():isFocused() or player and player:focused()
end

return List