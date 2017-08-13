--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.videoeffects ===
---
--- Controls Final Cut Pro's Effects.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("effects")

local chooser			= require("hs.chooser")
local screen			= require("hs.screen")
local drawing			= require("hs.drawing")
local timer				= require("hs.timer")
local inspect			= require("hs.inspect")

local choices			= require("cp.choices")
local fcp				= require("cp.apple.finalcutpro")
local dialog			= require("cp.dialog")
local tools				= require("cp.tools")
local config			= require("cp.config")
local prop				= require("cp.prop")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

function mod.init(touchbar)
	mod.touchbar = touchbar
end


--------------------------------------------------------------------------------
-- SHORTCUT PRESSED:
-- The shortcut may be a number from 1-5, in which case the 'assigned' shortcut is applied,
-- or it may be the name of the effect to apply in the current FCPX language.
--------------------------------------------------------------------------------
function mod.apply(shortcut)

	--------------------------------------------------------------------------------
	-- Get settings:
	--------------------------------------------------------------------------------
	local currentLanguage = fcp:currentLanguage()

	if type(shortcut) == "number" then
		shortcut = mod.getShortcuts()[shortcut]
	end

	if shortcut == nil then
		dialog.displayMessage(i18n("noEffectShortcut"))
		return false
	end

	--------------------------------------------------------------------------------
	-- Save the Transitions Browser layout:
	--------------------------------------------------------------------------------
	local transitions = fcp:transitions()
	local transitionsLayout = transitions:saveLayout()

	--------------------------------------------------------------------------------
	-- Get Effects Browser:
	--------------------------------------------------------------------------------
	local effects = fcp:effects()
	local effectsShowing = effects:isShowing()
	local effectsLayout = effects:saveLayout()

	fcp:launch()

	--------------------------------------------------------------------------------
	-- Make sure panel is open:
	--------------------------------------------------------------------------------
	effects:show()

	--------------------------------------------------------------------------------
	-- Make sure "Installed Effects" is selected:
	--------------------------------------------------------------------------------
	effects:showInstalledEffects()

	--------------------------------------------------------------------------------
	-- Make sure there's nothing in the search box:
	--------------------------------------------------------------------------------
	effects:search():clear()

	--------------------------------------------------------------------------------
	-- Click 'All':
	--------------------------------------------------------------------------------
	effects:showAllTransitions()

	--------------------------------------------------------------------------------
	-- Perform Search:
	--------------------------------------------------------------------------------
	effects:search():setValue(shortcut)

	--------------------------------------------------------------------------------
	-- Get the list of matching effects
	--------------------------------------------------------------------------------
	local matches = effects:currentItemsUI()
	if not matches or #matches == 0 then
		--------------------------------------------------------------------------------
		-- If Needed, Search Again Without Text Before First Dash:
		--------------------------------------------------------------------------------
		local index = string.find(shortcut, "-")
		if index ~= nil then
			local trimmedShortcut = string.sub(shortcut, index + 2)
			effects:search():setValue(trimmedShortcut)

			matches = effects:currentItemsUI()
			if not matches or #matches == 0 then
				dialog.displayErrorMessage("Unable to find a transition called '"..shortcut.."'.")
				return false
			end
		end
	end

	local effect = matches[1]

	--------------------------------------------------------------------------------
	-- Apply the selected Transition:
	--------------------------------------------------------------------------------
	mod.touchbar.hide()

	effects:applyItem(effect)

	-- TODO: HACK: This timer exists to  work around a mouse bug in Hammerspoon Sierra
	timer.doAfter(0.1, function()
		mod.touchbar.show()

		effects:loadLayout(effectsLayout)
		if transitionsLayout then transitions:loadLayout(transitionsLayout) end
		if not effectsShowing then effects:hide() end
	end)

	-- Success!
	return true
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id = "finalcutpro.timeline.videoeffects",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.os.touchbar"]						= "touchbar",
	}
}

function plugin.init(deps)
	return mod.init(deps.touchbar)
end

return plugin