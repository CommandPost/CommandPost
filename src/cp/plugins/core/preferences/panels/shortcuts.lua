--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--           S H O R T C U T S    P R E F E R E N C E S    P A N E L          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.plugins.core.preferences.panels.shortcuts ===
---
--- Shortcuts Preferences Panel

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefsShortcuts")

local image										= require("hs.image")
local timer										= require("hs.timer")
local toolbar                  					= require("hs.webview.toolbar")
local webview									= require("hs.webview")

local generate									= require("cp.plugins.core.preferences.generate")

--------------------------------------------------------------------------------
-- CONSTANTS:
--------------------------------------------------------------------------------
local DEFAULT_PRIORITY 							= 0

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	mod._uiItems = {}

	--------------------------------------------------------------------------------
	-- CONTROLLER CALLBACK:
	--------------------------------------------------------------------------------
	local function controllerCallback(message)

		log.df("Callback Result: %s", hs.inspect(message))

		local title = message["body"][1]
		local result = message["body"][2]

		for i, v in ipairs(mod._uiItems) do
			local data = v["itemFn"]()
			if data["title"] == title then
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

	--------------------------------------------------------------------------------
	-- GENERATE CONTENT:
	--------------------------------------------------------------------------------
	function generateContent()

		local result = "<h3>Keyboard Shortcuts:</h3>\n"

		table.sort(mod._uiItems, function(a, b) return a.priority < b.priority end)
		for i, v in ipairs(mod._uiItems) do

			local data = v["itemFn"]()

			local uiType = v["uiType"]

			if uiType == generate.UI_CHECKBOX then
				result = result .. "\n" .. generate.checkbox(data)
			elseif uiType == generate.UI_HEADING then
				result = result .. "\n" .. generate.heading(data)
			elseif uiType == generate.UI_BUTTON then
				result = result .. "\n" .. generate.button(data)
			elseif uiType == generate.UI_DROPDOWN then
				result = result .. "\n" .. generate.dropdown(v["title"], data)

			end

		end

		result = result .. [[
			<h3>Customise Shortcuts:</h3>
			<table class="plugins">
				<thead>
					<tr>
						<th class="rowCategory">Application</th>
						<th class="rowName">Function</th>
						<th class="rowStatus">Modifier</th>
						<th class="rowOption">Shortcut</th>
					</tr>
				</thead>
				<tbody>
					<tr>
						<td class="rowCategory">TBC</td>
						<td class="rowName">TBC</td>
						<td class="rowStatus">TBC</td>
						<td class="rowOption">TBC</td>
					</tr>
					<tr>
						<td class="rowCategory">TBC</td>
						<td class="rowName">TBC</td>
						<td class="rowStatus">TBC</td>
						<td class="rowOption">TBC</td>
					</tr>
				</tbody>
			</table>
		]]

		return result

	end

	--------------------------------------------------------------------------------
	-- INITIALISE MODULE:
	--------------------------------------------------------------------------------
	function mod.init(deps)

		generate.setWebviewLabel(deps.manager.getLabel())

		local id 		= "shorcuts"
		local label 	= "Shortcuts"
		local image		= image.imageFromPath("/System/Library/PreferencePanes/Keyboard.prefPane/Contents/Resources/Keyboard.icns")
		local priority	= 2
		local tooltip	= "Shortcuts Panel"
		local contentFn	= generateContent
		local callbackFn 	= controllerCallback

		deps.manager.addPanel(id, label, image, priority, tooltip, contentFn, callbackFn)

		return mod

	end

	--------------------------------------------------------------------------------
	-- ADD CHECKBOX:
	--------------------------------------------------------------------------------
	function mod:addCheckbox(priority, itemFn)

		priority = priority or DEFAULT_PRIORITY

		mod._uiItems[#mod._uiItems + 1] = {
			priority = priority,
			itemFn = itemFn,
			uiType = generate.UI_CHECKBOX,
		}

		return self

	end

--------------------------------------------------------------------------------
-- THE PLUGIN:
--------------------------------------------------------------------------------
local plugin = {}

	--------------------------------------------------------------------------------
	-- DEPENDENCIES:
	--------------------------------------------------------------------------------
	plugin.dependencies = {
		["cp.plugins.core.preferences.manager"]			= "manager",
	}

	--------------------------------------------------------------------------------
	-- INITIALISE PLUGIN:
	--------------------------------------------------------------------------------
	function plugin.init(deps)
		return mod.init(deps)
	end

return plugin