--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   F I N A L    C U T    P R O    A P I                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.apple.finalcutpro.main.PrimaryToolbar ===
---
--- Timeline Toolbar

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log								= require("hs.logger").new("PrimaryToolbar")

local axutils							= require("cp.ui.axutils")
local prop								= require("cp.prop")

local Button							= require("cp.ui.Button")
local CheckBox							= require("cp.ui.CheckBox")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local PrimaryToolbar = {}

-- TODO: Add documentation
function PrimaryToolbar.matches(element)
	return element and element:attributeValue("AXRole") == "AXToolbar"
end

local function getParent(element)
	return element and element:attributeValue("AXParent")
end

-- TODO: Add documentation
function PrimaryToolbar:new(parent)
	local o = prop.extend({_parent = parent}, PrimaryToolbar)

	-- a CheckBox instance to access the browser button.
	o._browserShowing = CheckBox:new(o, function()
		local group = axutils.childFromRight(o:UI(), 4)
		if group and group:attributeValue("AXRole") == "AXGroup" then
			return axutils.childWithRole(group, "AXCheckBox")
		end
		return nil
	end)

--- cp.apple.finalcutpro.main.PrimaryToolbar.browserShowing <cp.prop: boolean>
--- Field
--- If `true`, the browser panel is showing. Can be modified or watched.
	o.browserShowing = o._browserShowing.checked:wrap(o)

	-- watch for AXValueChanged notifications in the app for this CheckBox
	o:app():notifier():addWatcher("AXValueChanged", function(element)
		if element:attributeValue("AXRole") == "AXImage" then
			local eParent = getParent(element)
			if eParent then
				-- browser showing check
				local bsParent = getParent(o._browserShowing:UI())
				if eParent == bsParent then -- update the checked status for any watchers.
					-- log.df("value changed: parent: %s", _inspect(eParent))
					o._browserShowing.checked:update()
				end
			end
		end
	end)

	return o
end

-- TODO: Add documentation
function PrimaryToolbar:parent()
	return self._parent
end

-- TODO: Add documentation
function PrimaryToolbar:app()
	return self:parent():app()
end

-----------------------------------------------------------------------
--
-- TIMELINE UI:
--
-----------------------------------------------------------------------

-- TODO: Add documentation
function PrimaryToolbar:UI()
	return axutils.cache(self, "_ui", function()
		return axutils.childMatching(self:parent():UI(), PrimaryToolbar.matches)
	end,
	PrimaryToolbar.matches)
end

-- TODO: Add documentation
PrimaryToolbar.isShowing = prop.new(function(self)
	return self:UI() ~= nil
end):bind(PrimaryToolbar)

-----------------------------------------------------------------------
--
-- THE BUTTONS:
--
-----------------------------------------------------------------------

function PrimaryToolbar:shareButton()
	if not self._shareButton then
		self._shareButton = Button:new(self, function() return axutils.childFromRight(self:UI(), 1) end)
	end
	return self._shareButton
end

function PrimaryToolbar:browserButton()
	if not self._browserButton then
		self._browserButton = CheckBox:new(self, function()
			local group = axutils.childFromRight(self:UI(), 4)
			if group and group:attributeValue("AXRole") == "AXGroup" then
				return axutils.childWithRole(group, "AXCheckBox")
			end
			return nil
		end)
	end
	return self._browserButton
end

return PrimaryToolbar