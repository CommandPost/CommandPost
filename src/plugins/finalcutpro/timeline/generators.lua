--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.generators ===
---
--- Controls Final Cut Pro's Generators.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log				= require("hs.logger").new("generators")

local timer				= require("hs.timer")

local fcp				= require("cp.apple.finalcutpro")
local dialog			= require("cp.dialog")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

function mod.init(touchbar)
	mod.touchbar = touchbar
	return mod
end

--- plugins.finalcutpro.timeline.generators.apply(action) -> boolean
--- Function
--- Applies the specified action as a generator. Expects action to be a table with the following structure:
---
--- ```lua
--- { name = "XXX", category = "YYY", theme = "ZZZ" }
--- ```
---
--- ...where `"XXX"`, `"YYY"` and `"ZZZ"` are in the current FCPX language. The `category` and `theme` are optional,
--- but if they are known it's recommended to use them, or it will simply execute the first matching generator with that name.
---
--- Parameters:
--- * `action`		- A table with the name/category/theme for the generator to apply.
---
--- Returns:
--- * `true` if a matching generator was found and applied to the timeline.
function mod.apply(action)

	-- is it a simple string?
	if type(action) == "string" then
		action = { name = tostring(params) }
	end

	local shortcut, category = action.name, action.category

	if shortcut == nil then
		dialog.displayMessage(i18n("noGeneratorShortcut"))
		return false
	end

	--------------------------------------------------------------------------------
	-- Save the main Browser layout:
	--------------------------------------------------------------------------------
	local browser = fcp:browser()
	local browserLayout = browser:saveLayout()

	--------------------------------------------------------------------------------
	-- Get Generators Browser:
	--------------------------------------------------------------------------------
	local generators = fcp:generators()
	local generatorsLayout = generators:saveLayout()


	--------------------------------------------------------------------------------
	-- Make sure FCPX is at the front.
	--------------------------------------------------------------------------------
	fcp:launch()

	--------------------------------------------------------------------------------
	-- Make sure the panel is open:
	--------------------------------------------------------------------------------
	generators:show()

	if not generators:isShowing() then
		dialog.displayErrorMessage("Unable to display the Generators panel.")
		return false
	end

	--------------------------------------------------------------------------------
	-- Make sure there's nothing in the search box:
	--------------------------------------------------------------------------------
	generators:search():clear()

	--------------------------------------------------------------------------------
	-- Click 'All':
	--------------------------------------------------------------------------------
	if category then
		generators:showGeneratorsCategory(category)
	else
		generators:showAllGenerators()
	end
	--------------------------------------------------------------------------------
	-- Make sure "Installed Generators" is selected:
	--------------------------------------------------------------------------------
	generators:showInstalledGenerators()

	--------------------------------------------------------------------------------
	-- Perform Search:
	--------------------------------------------------------------------------------
	generators:search():setValue(shortcut)

	--------------------------------------------------------------------------------
	-- Get the list of matching effects
	--------------------------------------------------------------------------------
	local matches = generators:currentItemsUI()
	if not matches or #matches == 0 then
		--------------------------------------------------------------------------------
		-- If Needed, Search Again Without Text Before First Dash:
		--------------------------------------------------------------------------------
		local index = string.find(shortcut, "-")
		if index ~= nil then
			local trimmedShortcut = string.sub(shortcut, index + 2)
			generators:search():setValue(trimmedShortcut)

			matches = generators:currentItemsUI()
			if not matches or #matches == 0 then
				dialog.displayErrorMessage("Unable to find a generator called '"..shortcut.."'")
				return false
			end
		end
	end

	local generator = matches[1]

	--------------------------------------------------------------------------------
	-- Apply the selected Transition:
	--------------------------------------------------------------------------------
	mod.touchbar.hide()

	generators:applyItem(generator)

	-- TODO: HACK: This timer exists to  work around a mouse bug in Hammerspoon Sierra
	timer.doAfter(0.1, function()
		mod.touchbar.show()

		generators:loadLayout(generatorsLayout)
		if browserLayout then browser:loadLayout(browserLayout) end
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
	id = "finalcutpro.timeline.generators",
	group = "finalcutpro",
	dependencies = {
		["finalcutpro.os.touchbar"]						= "touchbar",
	}
}

function plugin.init(deps)
	return mod
end

function plugin.postInit(deps)
	-- Add the action
	mod.init(deps.touchbar)
	return mod
end

return plugin