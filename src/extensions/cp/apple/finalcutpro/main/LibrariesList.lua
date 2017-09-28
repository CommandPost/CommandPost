--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.LibrariesList ===
---
--- Libraries List Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local _									= require("moses")

local axutils							= require("cp.ui.axutils")
local Table								= require("cp.ui.Table")

local Clip								= require("cp.apple.finalcutpro.content.Clip")
local Playhead							= require("cp.apple.finalcutpro.main.Playhead")

local id								= require("cp.apple.finalcutpro.ids") "LibrariesList"

local prop								= require("cp.prop")

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
	local o = {_parent = parent}
	return prop.extend(o, List)
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
List.isShowing = prop.new(function(self)
	return self:UI() ~= nil and self:parent():isShowing()
end):bind(List)

-- TODO: Add documentation
List.isFocused = prop.new(function(self)
	local player = self:playerUI()
	return self:contents():isFocused() or player and player:focused()
end):bind(List)

function List:show()
	if not self:isShowing() and self:parent():show():isShowing() then
		self:parent():toggleViewMode():press()
	end
end

-----------------------------------------------------------------------
--
-- PREVIEW PLAYER:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function List:playerUI()
	return axutils.cache(self, "_player", function()
		return axutils.childFromTop(self:UI(), id "Player")
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
		self._content = Table.new(self, function()
			return axutils.childWithRole(self:UI(), "AXScrollArea")
		end)
	end
	return self._content
end

-- TODO: Add documentation
function List:clipsUI(filterFn)
	local rowsUI = self:contents():rowsUI()
	if rowsUI then
		local level = 0
		-- if the first row has no icon, it's a group
		local firstCell = self:contents():findCellUI(1, "filmlist name col")
		if firstCell and axutils.childWithID(firstCell, id "RowIcon") == nil then
			level = 1
		end
		return axutils.childrenMatching(rowsUI, function(row)
			return row:attributeValue("AXDisclosureLevel") == level
			   and (filterFn == nil or filterFn(row))
		end)
	end
	return nil
end

function List:_uiToClips(clipsUI)
	local columnIndex = self:contents():findColumnIndex("filmlist name col")
	local options = {columnIndex = columnIndex}
	return _.map(clipsUI, function(_,clipUI)
		return Clip.new(clipUI, options)
	end)
end

function List:_clipsToUI(clips)
	return _.map(clips, function(_,clip) return clip:UI() end)
end

function List:clips(filterFn)
	local clips = self:_uiToClips(self:clipsUI())
	if filterFn then
		clips = _.filter(clips, function(_,clip) return filterFn(clip) end)
	end
	return clips

end

-- TODO: Add documentation
function List:selectedClipsUI()
	return self:contents():selectedRowsUI()
end

function List:selectedClips()
	return self:_uiToClips(self:contents():selectedRowsUI())
end

-- TODO: Add documentation
function List:showClip(clip)
	if clip then
		local clipUI = clip:UI()
		if axutils.isValid(clipUI) then
			self:contents():showRow(clipUI)
			return true
		end
	end
	return false
end

-- TODO: Add documentation
function List:selectClip(clip)
	if clip then
		local clipUI = clip:UI()
		if axutils.isValid(clipUI) then
			self:contents():selectRow(clip:UI())
			return true
		end
	end
	return false
end

-- TODO: Add documentation
function List:selectClipAt(index)
	local clips = self:clipsUI()
	if clips and #clips <= index then
		self:contents():selectRow(clips[index])
		return true
	end
	return false
end

function List:selectClipTitled(title)
	local clips = self:clips()
	for _,clip in ipairs(clips) do
		if clip:getTitle() == title then
			return self:selectClip(clip)
		end
	end
	return false
end

-- TODO: Add documentation
function List:selectAll(clips)
	clips = clips or self:clips()
	if clips then
		self:contents():selectAll(self:_clipsToUI(clips))
		return true
	end
	return false
end

-- TODO: Add documentation
function List:deselectAll(clips)
	clips = clips or self:clips()
	if clips then
		self:contents():deselectAll(self:_clipsToUI(clips))
		return true
	end
	return false
end

return List