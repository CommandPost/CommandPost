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

		--log.df("Callback Result: %s", hs.inspect(message))

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

		if result == "modifier" then
			local commandFunction = message["body"][1]
			local commandModifier = message["body"][3]
			log.df("We should change the modifier for %s to %s.", commandFunction, commandModifier)

			-- TO DO: We need to work out where we actually save these "custom" shortcuts (as opposed to the default shortcuts hardcoded into each
			--        plugin, and also the "Hacks Shortcuts" which are loaded from the Final Cut Pro plist files.

		elseif result == "shortcut" then
			local commandFunction = message["body"][1]
			local commandShortcut = message["body"][3]
			log.df("We should change the shortcut for %s to %s.", commandFunction, commandShortcut)

			-- TO DO: We need to work out where we actually save these "custom" shortcuts (as opposed to the default shortcuts hardcoded into each
			--        plugin, and also the "Hacks Shortcuts" which are loaded from the Final Cut Pro plist files.

		end

	end

	--------------------------------------------------------------------------------
	-- COMPARE TABLES:
	--------------------------------------------------------------------------------
	function compareTables(t1, t2)
		if #t1 ~= #t2 then return false end
		for i=1,#t1 do
			local matchValue = false
			for v=1,#t2 do
				if t1[i] == t2[v] then matchValue = true end
			end
			if not matchValue then return false end
	  	end
	  	return true
	end

	--------------------------------------------------------------------------------
	-- CHECK MODIFIER:
	--------------------------------------------------------------------------------
	local function checkModifier(actual, expected)
		if compareTables(actual, expected) then
			return " selected"
		else
			return ""
		end
	end

	--------------------------------------------------------------------------------
	-- GENERATE CONTENT:
	--------------------------------------------------------------------------------
	local function generateContent()

		--------------------------------------------------------------------------------
		-- Keyboard Shortcuts:
		--------------------------------------------------------------------------------
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

		--------------------------------------------------------------------------------
		-- Customise Shortcuts:
		--------------------------------------------------------------------------------
		local choices = mod._commandaction.choices()["_choices"]
		table.sort(choices, function(a, b) return a.text < b.text end)

		local rows = ""
		for i, v in pairs(choices) do

			local commandID = v["params"]["id"] or nil
      		local commandApplication = v["params"]["group"] or "Unknown"
      		local commandFunction = v["text"] or "Unknown"
      		local commandModifier = ""
      		local commandShortcut = ""

			local globalCommands = mod._global["_commands"]
			local fcpxCommands = mod._fcpx["_commands"]

      		if commandID then
				if commandApplication == "global" then
					if globalCommands[commandID] then
						if globalCommands[commandID]["_shortcuts"][1] then
							commandShortcut = globalCommands[commandID]["_shortcuts"][1]["_keyCode"] or ""
							commandModifier = globalCommands[commandID]["_shortcuts"][1]["_modifiers"]
						end
					end
				end
				if commandApplication == "fcpx" then
					if fcpxCommands[commandID] then
						if fcpxCommands[commandID]["_shortcuts"][1] then
							commandShortcut = fcpxCommands[commandID]["_shortcuts"][1]["_keyCode"] or ""
							commandModifier = fcpxCommands[commandID]["_shortcuts"][1]["_modifiers"]
						end
					end
				end
			end

      		rows = rows .. [[
      			<tr>
					<td class="rowGroup">]] .. commandApplication .. [[</td>
					<td class="rowLabel">]] .. commandFunction .. [[</td>
					<td class="rowModifier" style="text-align: center;">
						<select id="modifier]] .. commandID .. [[" style="width: 90px;">
							<option value="none" ]] .. checkModifier(commandModifier, "") .. [[>None</option>
							<option value="control" ]] .. checkModifier(commandModifier, {"control"}) .. [[>Control</option>
							<option value="option" ]] .. checkModifier(commandModifier, {"option"}) .. [[>Option</option>
							<option value="command" ]] .. checkModifier(commandModifier, {"command"}) .. [[>Command</option>
							<option value="shift" ]] .. checkModifier(commandModifier, {"shift"}) .. [[>Shift</option>
							<option value="control:option" ]] .. checkModifier(commandModifier, {"control", "option"}) .. [[>Control + Option</option>
							<option value="control:command" ]] .. checkModifier(commandModifier, {"control", "command"}) .. [[>Control + Command</option>
							<option value="control:shift" ]] .. checkModifier(commandModifier, {"control", "shift"}) .. [[>Control + Shift</option>
							<option value="control:option:command" ]] .. checkModifier(commandModifier, {"control", "option", "command"}) .. [[>Control + Option + Command</option>
							<option value="control:option:command:shift" ]] .. checkModifier(commandModifier, {"control", "option", "command", "shift"}) .. [[>Control + Option + Command + Shift</option>
							<option value="option:command" ]] .. checkModifier(commandModifier, {"option", "command"}) .. [[>Option + Command</option>
							<option value="option:shift" ]] .. checkModifier(commandModifier, {"option", "shift"}) .. [[>Option + Shift</option>
							<option value="command:shift" ]] .. checkModifier(commandModifier, {"command", "shift"}) .. [[>Command + Shift</option>
						</select>
					</td>
					<td class="rowShortcut" style="text-align: center;">
						<input id="shortcut]] .. commandID.. [[" maxlength="1" style="width: 30px; text-align: center;" type="text" name="shortcut" value="]] .. commandShortcut .. [[">
					</td>
				</tr>
				<script>
					var modifier]] .. commandID .. [[=document.getElementById("modifier]] .. commandID .. [[");
					modifier]] .. commandID .. [[.onchange = function (){
						try {
							var value = document.getElementById("modifier]] .. commandID .. [[").value;
							var result = ["]] .. commandID .. [[", "modifier", value];
							webkit.messageHandlers.]] .. mod._webviewLabel .. [[.postMessage(result);
						} catch(err) {
							alert('An error has occurred. Does the controller exist yet?');
						}
					}

					var shortcut]] .. commandID .. [[=document.getElementById("shortcut]] .. commandID .. [[");
					shortcut]] .. commandID .. [[.onchange = function (){
						try {
							var value = document.getElementById("shortcut]] .. commandID .. [[").value;
							var result = ["]] .. commandID .. [[", "shortcut", value];
							webkit.messageHandlers.]] .. mod._webviewLabel .. [[.postMessage(result);
						} catch(err) {
							alert('An error has occurred. Does the controller exist yet?');
						}
					}
				</script>
				]]

    	end

		result = result .. [[
			<style>
				.shortcuts {
					table-layout: fixed;
					width: 100%;
					white-space: nowrap;

					border: 1px solid #cccccc;
					padding: 8px;
					background-color: #ffffff;
					text-align: left;
				}

				.shortcuts td {
				  white-space: nowrap;
				  overflow: hidden;
				  text-overflow: ellipsis;
				}

				.rowGroup {
					width:15%;
					font-weight: bold;
				}

				.rowLabel {
					width:45%;
				}

				.rowModifier {
					width:25%;
				}

				.rowShortcut {
					width:15%;
				}

				.shortcuts thead, .shortcuts tbody tr {
					display:table;
					table-layout:fixed;
					width: calc( 100% - 1.5em );
				}

				.shortcuts tbody {
					display:block;
					height: 250px;
					font-weight: normal;
					font-size: 10px;

					overflow-x: hidden;
					overflow-y: auto;
				}

				.shortcuts tbody tr {
					display:table;
					width:100%;
					table-layout:fixed;
				}

				.shortcuts thead {
					font-weight: bold;
					font-size: 12px;
				}

				.shortcuts tbody {
					font-weight: normal;
					font-size: 10px;
				}

				.shortcuts tbody tr:nth-child(even) {
					background-color: #f5f5f5
				}

				.shortcuts tbody tr:hover {
					background-color: #006dd4;
					color: white;
				}
			</style>
			<h3>Customise Shortcuts:</h3>
			<div id="customiseShortcuts" >
				<table class="shortcuts">
					<thead>
						<tr>
							<th class="rowGroup">Group</th>
							<th class="rowLabel">Label</th>
							<th class="rowModifier">Modifier</th>
							<th class="rowShortcut">Shortcut</th>
						</tr>
					</thead>
					<tbody>
					]] .. rows .. [[
					</tbody>
				</table>
			</div>
		]]

		return result

	end

	--------------------------------------------------------------------------------
	-- INITIALISE MODULE:
	--------------------------------------------------------------------------------
	function mod.init(deps)

		mod._commandaction = deps.commandaction
		mod._global = deps.global
		mod._fcpx = deps.fcpx

		generate.setWebviewLabel(deps.manager.getLabel())
		mod._webviewLabel = deps.manager.getLabel()

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
		["cp.plugins.core.commands.commandaction"]		= "commandaction",
		["cp.plugins.core.commands.global"]				= "global",
		["cp.plugins.finalcutpro.commands.fcpx"]		= "fcpx",
	}

	--------------------------------------------------------------------------------
	-- INITIALISE PLUGIN:
	--------------------------------------------------------------------------------
	function plugin.init(deps)
		return mod.init(deps)
	end

return plugin