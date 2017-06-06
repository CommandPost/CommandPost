--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.LibrariesFilmstrip ===
---
--- Libraries Filmstrip Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local _									= require("moses")

local axutils							= require("cp.ui.axutils")

local tools								= require("cp.tools")
local Clip								= require("cp.apple.finalcutpro.content.Clip")
local Playhead							= require("cp.apple.finalcutpro.main.Playhead")

local id								= require("cp.apple.finalcutpro.ids") "LibrariesFilmstrip"

local prop								= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Filmstrip = {}

-- TODO: Add documentation
function Filmstrip.matches(element)
	return element and element:attributeValue("AXIdentifier") == id("Content")
end

-- TODO: Add documentation
function Filmstrip:new(parent)
	local o = {_parent = parent}
	return prop.extend(o, Filmstrip)
end

-- TODO: Add documentation
function Filmstrip:parent()
	return self._parent
end

-- TODO: Add documentation
function Filmstrip:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
--
-- TIMELINE CONTENT UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function Filmstrip:UI()
	return axutils.cache(self, "_ui", function()
		local main = self:parent():mainGroupUI()
		if main then
			for i,child in ipairs(main) do
				if child:attributeValue("AXRole") == "AXGroup" and #child == 1 then
					if Filmstrip.matches(child[1]) then
						return child[1]
					end
				end
			end
		end
		return nil
	end,
	Filmstrip.matches)
end

-- TODO: Add documentation
function Filmstrip:verticalScrollBarUI()
	local ui = self:UI()
	return ui and ui:attributeValue("AXVerticalScrollBar")
end

-- TODO: Add documentation
Filmstrip.isShowing = prop.new(function(self)
	return self:UI() ~= nil and self:parent():isShowing()
end):bind(Filmstrip)

function Filmstrip:show()
	if not self:isShowing() and self:parent():show():isShowing() then
		self:parent():toggleViewMode():press()
	end
end

-- TODO: Add documentation
function Filmstrip:contentsUI()
	local ui = self:UI()
	return ui and ui:contents()[1]
end

-----------------------------------------------------------------------
--
-- PLAYHEADS:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function Filmstrip:playhead()
	if not self._playhead then
		self._playhead = Playhead:new(self, false, function()
			return self:contentsUI()
		end)
	end
	return self._playhead
end

-- TODO: Add documentation
function Filmstrip:skimmingPlayhead()
	if not self._skimmingPlayhead then
		self._skimmingPlayhead = Playhead:new(self, true, function()
			return self:contentsUI()
		end)
	end
	return self._skimmingPlayhead
end

-----------------------------------------------------------------------
--
-- CLIPS:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function Filmstrip.sortClips(a, b)
	local aFrame = a:frame()
	local bFrame = b:frame()
	if aFrame.y < bFrame.y then -- a is above b
		return true
	elseif aFrame.y == bFrame.y then
		if aFrame.x < bFrame.x then -- a is left of b
			return true
		elseif aFrame.x == bFrame.x
		   and aFrame.w < bFrame.w then -- a starts with but finishes before b, so b must be multi-line
			return true
		end
	end
	return false -- b is first
end

function Filmstrip:_uiToClips(clipsUI)
	return _.map(clipsUI, function(_,clipUI) return Clip.new(clipUI) end)
end

function Filmstrip:_clipsToUI(clips)
	return _.map(clips, function(_,clip) return clip:UI() end)
end

-- TODO: Add documentation
function Filmstrip:clipsUI(filterFn)
	local ui = self:contentsUI()
	if ui then
		local clips = axutils.childrenMatching(ui, function(child)
			return child:attributeValue("AXRole") == "AXGroup"
			   and (filterFn == nil or filterFn(child))
		end)
		if clips then
			table.sort(clips, Filmstrip.sortClips)
			return clips
		end
	end
	return nil
end

function Filmstrip:clips(filterFn)
	local clips = self:_uiToClips(self:clipsUI())
	if filterFn then
		clips = _.filter(clips, function(_,clip) return filterFn(clip) end)
	end
	return clips
end

-- TODO: Add documentation
function Filmstrip:selectedClipsUI()
	local ui = self:contentsUI()
	if ui then
		local children = ui:selectedChildren()
		local clips = {}
		for i,child in ipairs(children) do
			clips[i] = child
		end
		table.sort(clips, Filmstrip.sortClips)
		return clips
	end
	return nil
end

function Filmstrip:selectedClips()
	return self:_uiToClips(self:selectedClipsUI())
end

-- TODO: Add documentation
function Filmstrip:showClip(clip)
	local clipUI = clip:UI()
	local ui = self:UI()
	if ui then
		local vScroll = self:verticalScrollBarUI()
		local vFrame = vScroll:frame()
		local clipFrame = clipUI:frame()

		local top = vFrame.y
		local bottom = vFrame.y + vFrame.h

		local clipTop = clipFrame.y
		local clipBottom = clipFrame.y + clipFrame.h

		if clipTop < top or clipBottom > bottom then
			-- we need to scroll
			local oFrame = self:contentsUI():frame()
			local scrollHeight = oFrame.h - vFrame.h

			local vValue = nil
			if clipTop < top or clipFrame.h > vFrame.h then
				vValue = (clipTop-oFrame.y)/scrollHeight
			else
				vValue = 1.0 - (oFrame.y + oFrame.h - clipBottom)/scrollHeight
			end
			vScroll:setAttributeValue("AXValue", vValue)
		end
		return true
	end
	return false
end

-- TODO: Add documentation
function Filmstrip:showClipAt(index)
	local ui = self:clips()
	if ui and #ui >= index then
		return self:showClip(ui[index])
	end
	return false
end

-- TODO: Add documentation
function Filmstrip:selectClip(clip)
	local clipUI = clip:UI()
	if axutils.isValid(clipUI) then
		clipUI:parent():setSelectedChildren( { clipUI } )
		return true
	end
	return false
end

-- TODO: Add documentation
function Filmstrip:selectClipAt(index)
	local ui = self:clips()
	if ui and #ui >= index then
		return self:selectClip(ui[index])
	end
	return false
end

function Filmstrip:selectClipTitled(title)
	local clips = self:clips()
	for _,clip in ipairs(clips) do
		if clip:getTitle() == title then
			return self:selectClip(clip)
		end
	end
	return false
end

-- TODO: Add documentation
function Filmstrip:selectAll(clips)
	clips = clips or self:clips()
	if clips then
		for i,clip in ipairs(clips) do
			return self:selectClip(clip)
		end
	end
	return false
end

-- TODO: Add documentation
function Filmstrip:deselectAll()
	local contents = self:contentsUI()
	if contents then
		contents:setSelectedChildren({})
		return true
	end
	return false
end

return Filmstrip