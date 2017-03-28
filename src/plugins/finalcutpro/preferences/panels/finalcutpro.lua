--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--      F I N A L    C U T    P R O    P R E F E R E N C E S    P A N E L     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === finalcutpro.preferences.panels.finalcutpro ===
---
--- Final Cut Pro Preferences Panel

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefsGeneral")

local image										= require("hs.image")
local timer										= require("hs.timer")
local toolbar                  					= require("hs.webview.toolbar")
local webview									= require("hs.webview")

local fcp										= require("cp.finalcutpro")
local generate									= require("cp.web.generate")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local DEFAULT_PRIORITY 							= 0

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

mod._uiItems 								= {}

--------------------------------------------------------------------------------
-- CONTROLLER CALLBACK:
--------------------------------------------------------------------------------
local function controllerCallback(message)

	--log.df("Callback Result: %s", hs.inspect(message))

	local title = message["body"][1]
	local result = message["body"][2]

	for i, v in ipairs(mod._uiItems) do
		--------------------------------------------------------------------------------
		-- Dropdown Items:
		--------------------------------------------------------------------------------
		if v["uiType"] == generate.UI_DROPDOWN then
			if v["title"] == title then
				local data = v["itemFn"]()
				for a, b in ipairs(data) do
					if b["title"] == result then
						if type(b["fn"]) == "function" then
							--------------------------------------------------------------------------------
							-- Trigger Function:
							--------------------------------------------------------------------------------
							b["fn"]()
							return
						else
							log.df("Failed to trigger Dropdown Callback Function.")
							return
						end
					end
				end
			end
		else
		--------------------------------------------------------------------------------
		-- Everything Else:
		--------------------------------------------------------------------------------
			local data = v["itemFn"]()
			if data["title"] == title or title == v["customTrigger"] then
				if type(data["fn"]) == "function" then
					--------------------------------------------------------------------------------
					-- Trigger Function:
					--------------------------------------------------------------------------------
					data["fn"]()
					return
				else
					log.df("Failed to trigger Callback Function.")
					return
				end
			end
		end
	end

end

--------------------------------------------------------------------------------
-- GENERATE CONTENT:
--------------------------------------------------------------------------------
local function generateContent()

	generate.setWebviewLabel(mod._webviewLabel)

	local result = ""

	table.sort(mod._uiItems, function(a, b) return a.priority < b.priority end)
	for i, v in ipairs(mod._uiItems) do

		local data = v["itemFn"]()

		local uiType = v["uiType"]

		if uiType == generate.UI_CHECKBOX then
			result = result .. "\n" .. generate.checkbox(data, v["customTrigger"], v["customID"])
		elseif uiType == generate.UI_HEADING then
			result = result .. "\n" .. generate.heading(data)
		elseif uiType == generate.UI_BUTTON then
			result = result .. "\n" .. generate.button(data)
		elseif uiType == generate.UI_DROPDOWN then
			result = result .. "\n" .. generate.dropdown(v["title"], data)

		end

	end

	return result
end

--------------------------------------------------------------------------------
-- INITIALISE MODULE:
--------------------------------------------------------------------------------
function mod.init(deps)

	mod._webviewLabel = deps.manager.getLabel()

	local id 			= "finalcutpro"
	local label 		= "Final Cut Pro"
	local image			= image.imageFromPath(fcp:getPath() .. "/Contents/Resources/Final Cut.icns")
	local priority		= 2040
	local tooltip		= "Final Cut Pro"
	local contentFn		= generateContent
	local callbackFn 	= controllerCallback

	deps.manager.addPanel(id, label, image, priority, tooltip, contentFn, callbackFn)

	return mod

end

--------------------------------------------------------------------------------
-- ADD CHECKBOX:
--------------------------------------------------------------------------------
function mod:addCheckbox(priority, itemFn, customTrigger, customID)

	--log.df("Adding Checkbox to General Preferences Panel: %s", itemFn)

	priority = priority or DEFAULT_PRIORITY

	mod._uiItems[#mod._uiItems + 1] = {
		priority = priority,
		itemFn = itemFn,
		uiType = generate.UI_CHECKBOX,
		customTrigger = customTrigger,
		customID = customID,
	}

	return self

end

--------------------------------------------------------------------------------
-- ADD HEADING:
--------------------------------------------------------------------------------
function mod:addHeading(priority, itemFn)

	priority = priority or DEFAULT_PRIORITY

	mod._uiItems[#mod._uiItems + 1] = {
		priority = priority,
		itemFn = itemFn,
		uiType = generate.UI_HEADING,
	}

	return self

end

--------------------------------------------------------------------------------
-- ADD BUTTON:
--------------------------------------------------------------------------------
function mod:addButton(priority, itemFn)

	priority = priority or DEFAULT_PRIORITY

	mod._uiItems[#mod._uiItems + 1] = {
		priority = priority,
		itemFn = itemFn,
		uiType = generate.UI_BUTTON,
	}

	return self

end

--------------------------------------------------------------------------------
-- ADD DROPDOWN:
--------------------------------------------------------------------------------
function mod:addDropdown(priority, title, itemFn)

	priority = priority or DEFAULT_PRIORITY

	mod._uiItems[#mod._uiItems + 1] = {
		title = title,
		priority = priority,
		itemFn = itemFn,
		uiType = generate.UI_DROPDOWN,
	}

	return self

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "finalcutpro.preferences.panels.finalcutpro",
	group			= "finalcutpro",
	dependencies	= {
		["core.preferences.manager"]	= "manager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	return mod.init(deps)
end

return plugin