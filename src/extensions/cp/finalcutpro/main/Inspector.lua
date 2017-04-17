--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.finalcutpro.main.Inspector ===
---
--- Inspector

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("timline")
local inspect							= require("hs.inspect")

local just								= require("cp.just")
local axutils							= require("cp.finalcutpro.axutils")

local id								= require("cp.finalcutpro.ids") "Inspector"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local Inspector = {}

-- TODO: Add documentation
function Inspector.matches(element)
	return axutils.childWith(element, "AXIdentifier", id "DetailsPanel") ~= nil -- is inspecting
		or axutils.childWith(element, "AXIdentifier", id "NothingToInspect") ~= nil 	-- nothing to inspect
end

-- TODO: Add documentation
function Inspector:new(parent)
	o = {_parent = parent}
	setmetatable(o, self)
	self.__index = self
	return o
end

-- TODO: Add documentation
function Inspector:parent()
	return self._parent
end

-- TODO: Add documentation
function Inspector:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
--
-- INSPECTOR UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function Inspector:UI()
	return axutils.cache(self, "_ui",
	function()
		local parent = self:parent()
		local ui = parent:rightGroupUI()
		if ui then
			-- it's in the right panel (full-height)
			if Inspector.matches(ui) then
				return ui
			end
		else
			-- it's in the top-left panel (half-height)
			local top = parent:topGroupUI()
			for i,child in ipairs(top) do
				if Inspector.matches(child) then
					return child
				end
			end
		end
		return nil
	end,
	Inspector.matches)
end

-- TODO: Add documentation
function Inspector:isShowing()
	return self:app():menuBar():isChecked("Window", "Show in Workspace", "Inspector")
end

-- TODO: Add documentation
function Inspector:show()
	local parent = self:parent()
	-- show the parent.
	if parent:show() then
		local menuBar = self:app():menuBar()
		-- Enable it in the primary
		menuBar:checkMenu("Window", "Show in Workspace", "Inspector")
	end
	return self
end

-- TODO: Add documentation
function Inspector:hide()
	local menuBar = self:app():menuBar()
	-- Uncheck it from the primary workspace
	menuBar:uncheckMenu("Window", "Show in Workspace", "Inspector")
	return self
end

return Inspector