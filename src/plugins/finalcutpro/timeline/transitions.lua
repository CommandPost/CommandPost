--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.transitions ===
---
--- Controls Final Cut Pro's Transitions.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("transitions")

local timer				= require("hs.timer")

local dialog			= require("cp.dialog")
local fcp				= require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.timeline.transitions.init() -> none
--- Function
--- Initialise the Module
---
--- Parameters:
---  * None
---
--- Returns:
---  * The Module
function mod.init(touchbar)
	mod.touchbar = touchbar
	return mod
end

--- plugins.finalcutpro.timeline.transitions(action) -> boolean
--- Function
--- Applies the specified action as a transition. Expects action to be a table with the following structure:
---
--- ```lua
--- { name = "XXX", category = "YYY", theme = "ZZZ" }
--- ```
---
--- ...where `"XXX"`, `"YYY"` and `"ZZZ"` are in the current FCPX language. The `category` and `theme` are optional,
--- but if they are known it's recommended to use them, or it will simply execute the first matching transition with that name.
---
--- Alternatively, you can also supply a string with just the name.
---
--- Parameters:
--- * `action`		- A table with the name/category/theme for the transition to apply, or a string with just the name.
---
--- Returns:
--- * `true` if a matching transition was found and applied to the timeline.
function mod.apply(action)

	--------------------------------------------------------------------------------
	-- Get settings:
	--------------------------------------------------------------------------------
	local currentLanguage = fcp:currentLanguage()

	if type(shortcut) == "string" then
		action = { name = action }
	end

	local name, category = action.name, action.category

	if name == nil then
		dialog.displayMessage(i18n("noPluginShortcut", {plugin = i18n("transition_group")}))
		return false
	end

	--------------------------------------------------------------------------------
	-- Save the Effects Browser layout:
	--------------------------------------------------------------------------------
	local effects = fcp:effects()
	local effectsLayout = effects:saveLayout()

	--------------------------------------------------------------------------------
	-- Get Transitions Browser:
	--------------------------------------------------------------------------------
	local transitions = fcp:transitions()
	local transitionsShowing = transitions:isShowing()
	local transitionsLayout = transitions:saveLayout()
	
	--------------------------------------------------------------------------------
	-- Make sure FCPX is at the front.
	--------------------------------------------------------------------------------
	fcp:launch()
	
	--------------------------------------------------------------------------------
	-- Make sure panel is open:
	--------------------------------------------------------------------------------
	transitions:show()

	--------------------------------------------------------------------------------
	-- Make sure "Installed Transitions" is selected:
	--------------------------------------------------------------------------------
	local group = transitions:group():UI()		
	local groupValue = group:attributeValue("AXValue")	
	if groupValue ~= fcp:string("PEMediaBrowserInstalledTransitionsMenuItem") then
		transitions:showInstalledTransitions()
	end

	--------------------------------------------------------------------------------
	-- Make sure there's nothing in the search box:
	--------------------------------------------------------------------------------
	transitions:search():clear()

	--------------------------------------------------------------------------------
	-- Click 'All':
	--------------------------------------------------------------------------------
	if category then
		transitions:showTransitionsCategory(category)
	else
		transitions:showAllTransitions()
	end

	--------------------------------------------------------------------------------
	-- Perform Search:
	--------------------------------------------------------------------------------
	transitions:search():setValue(name)

	--------------------------------------------------------------------------------
	-- Get the list of matching transitions
	--------------------------------------------------------------------------------
	local matches = transitions:currentItemsUI()
	if not matches or #matches == 0 then
		dialog.displayErrorMessage(i18n("noPluginFound", {plugin=i18n("transition_group"), name=name}))
		return false
	end

	local transition = matches[1]

	--------------------------------------------------------------------------------
	-- Apply the selected Transition:
	--------------------------------------------------------------------------------
	mod.touchbar.hide()

	transitions:applyItem(transition)

	-- TODO: HACK: This timer exists to  work around a mouse bug in Hammerspoon Sierra
	timer.doAfter(0.1, function()
		mod.touchbar.show()

		transitions:loadLayout(transitionsLayout)
		if effectsLayout then effects:loadLayout(effectsLayout) end
		if not transitionsShowing then transitions:hide() end
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
	id = "finalcutpro.timeline.transitions",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.os.virtualtouchbar"]						= "touchbar",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	return mod
end

function plugin.postInit(deps)
	return mod.init(deps.touchbar)
end

return plugin