--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--           S H O R T C U T S    P R E F E R E N C E S    P A N E L          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.plugins.core.preferences.panels.shortcuts ===
---
--- Shortcuts Preferences Panel

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefsShortcuts")

local image										= require("hs.image")
local keycodes									= require("hs.keycodes")
local timer										= require("hs.timer")
local toolbar                  					= require("hs.webview.toolbar")
local webview									= require("hs.webview")

local config									= require("cp.config")

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

--------------------------------------------------------------------------------
-- SPLIT STRING:
--------------------------------------------------------------------------------
local function split(str, pat)
	local t = {}  -- NOTE: use {n = 0} in Lua-5.0
	local fpat = "(.-)" .. pat
	local last_end = 1
	local s, e, cap = str:find(fpat, 1)
	while s do
	  if s ~= 1 or cap ~= "" then
		 table.insert(t,cap)
	  end
	  last_end = e+1
	  s, e, cap = str:find(fpat, last_end)
	end
	if last_end <= #str then
	  cap = str:sub(last_end)
	  table.insert(t, cap)
	end
	return t
end

--------------------------------------------------------------------------------
-- CONTROLLER CALLBACK:
--------------------------------------------------------------------------------
local function controllerCallback(message)

	local action = message["body"][1]

	if action == "updateShortcut" then

		--------------------------------------------------------------------------------
		-- Values from Callback:
		--------------------------------------------------------------------------------
		local commandFunction 	= message["body"][2]
		local commandModifier 	= message["body"][3]
		local commandShortcut 	= message["body"][4]
		local commandGroup 		= message["body"][5]

		local modifiers = split(commandModifier, ":")

		--------------------------------------------------------------------------------
		-- Setup Controller:
		--------------------------------------------------------------------------------
		local controller = nil
		if commandGroup == "fcpx" then
			controller = mod._fcpx
		elseif commandGroup == "global" then
			controller = mod._global
		end

		--------------------------------------------------------------------------------
		-- Get the correct Command:
		--------------------------------------------------------------------------------
		local theCommand = controller:get(commandFunction)

		log.df("Title: %s", theCommand:getTitle())

		--------------------------------------------------------------------------------
		-- Clear Previous Shortcuts:
		--------------------------------------------------------------------------------
		theCommand:deleteShortcuts()

		--------------------------------------------------------------------------------
		-- Setup New Shortcut:
		--------------------------------------------------------------------------------
		local id = string.gsub(commandModifier, ":", "") .. commandShortcut
		if commandShortcut ~= "" then
			theCommand:activatedBy(modifiers, commandShortcut)
		end

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
-- GENERATE LIST OF SHORTCUTS:
--------------------------------------------------------------------------------
function generateListOfShortcuts()

	local shortcuts = {}

	for i, v in pairs(keycodes.map) do
	  if type(v) == "number" then
	  	if v <= 9 then
	  		local alreadyExists = false
	  		for x, y in pairs(shortcuts) do
	  			if shortcuts[x] == tostring(v) then
	  				alreadyExists = true
	  			end
	  		end
	  		if not alreadyExists then
		  		shortcuts[#shortcuts + 1] = tostring(v)
		  	end
	  	end
	  else
	  	shortcuts[#shortcuts + 1] = v
	  end
	end

	table.sort(shortcuts, function(a, b) return a < b end)

	return shortcuts

end

--------------------------------------------------------------------------------
-- SHORTCUT GROUP:
--------------------------------------------------------------------------------
local function shortcutGroup(group)
	return i18n("shortcut_group_" .. group, {default = group})
end

--------------------------------------------------------------------------------
-- GENERATE CONTENT:
--------------------------------------------------------------------------------
local function generateContent()

	local result = ""

	local choices = mod._commandaction.choices()["_choices"]

	table.sort(choices, function(a, b) return a.text < b.text end)
	table.sort(choices, function(a, b) return a.params.group < b.params.group end)

	local shortcutRows = ""
	for i, v in ipairs(mod.availiableShortcuts) do
		shortcutRows = shortcutRows .. [[<option value="]] .. v .. [[">]] .. v .. [[</option>]]
	end

	local globalCommands = mod._global["_commands"]
	local fcpxCommands = mod._fcpx["_commands"]

	local lastGroup = "nothing"

	local rows = ""
	for i, v in pairs(choices) do

		local commandID = v["params"]["id"] or nil
		local commandGroup = v["params"]["group"] or "Unknown"
		local commandFunction = v["text"] or "Unknown"
		local commandModifier = ""
		local commandShortcut = ""

		if commandID then
			if commandGroup == "global" then
				if globalCommands[commandID] then
					if globalCommands[commandID]["_shortcuts"][1] then
						commandShortcut = globalCommands[commandID]["_shortcuts"][1]["_keyCode"] or ""
						commandModifier = globalCommands[commandID]["_shortcuts"][1]["_modifiers"]
					end
				end
			end
			if commandGroup == "fcpx" then
				if fcpxCommands[commandID] then
					if fcpxCommands[commandID]["_shortcuts"][1] then
						commandShortcut = fcpxCommands[commandID]["_shortcuts"][1]["_keyCode"] or ""
						commandModifier = fcpxCommands[commandID]["_shortcuts"][1]["_modifiers"]
					end
				end
			end
		end

		local originalGroup = shortcutGroup(commandGroup)
		if originalGroup == lastGroup then
			currentGroup = ""
		else
			currentGroup = originalGroup
		end
		lastGroup = originalGroup

		rows = rows .. [[
			<tr>
				<td class="rowGroup">]] .. currentGroup .. [[</td>
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
					<select id="shortcut]] .. commandID .. [[" style="width: 50px;">
						]] .. shortcutRows .. [[
					</select>
					<script>
						document.getElementById("shortcut]] .. commandID .. [[").value = "]] .. commandShortcut .. [[";
					</script>
				</td>
			</tr>
			<script>
				var modifier]] .. commandID .. [[=document.getElementById("modifier]] .. commandID .. [[");
				modifier]] .. commandID .. [[.onchange = function (){
					try {
						var modifierValue = document.getElementById("modifier]] .. commandID .. [[").value;
						var shortcutValue = document.getElementById("shortcut]] .. commandID .. [[").value;
						var result = ["updateShortcut", "]] .. commandID .. [[", modifierValue, shortcutValue, "]] .. commandGroup .. [["];
						webkit.messageHandlers.]] .. mod._webviewLabel .. [[.postMessage(result);
					} catch(err) {
						alert('An error has occurred. Does the controller exist yet?');
					}
				}

				var shortcut]] .. commandID .. [[=document.getElementById("shortcut]] .. commandID .. [[");
				shortcut]] .. commandID .. [[.onchange = function (){
					try {
						var modifierValue = document.getElementById("modifier]] .. commandID .. [[").value;
						var shortcutValue = document.getElementById("shortcut]] .. commandID .. [[").value;
						var result = ["updateShortcut", "]] .. commandID .. [[", modifierValue, shortcutValue, "]] .. commandGroup .. [["];
						webkit.messageHandlers.]] .. mod._webviewLabel .. [[.postMessage(result);
					} catch(err) {
						alert('An error has occurred. Does the controller exist yet?');
					}
				}
			</script>
			]]

	end

	local enableHacksShortcutsInFinalCutPro = config.get("enableHacksShortcutsInFinalCutPro", false)
	local customShortcutsEnabled = ""
	if enableHacksShortcutsInFinalCutPro then
		customShortcutsEnabled = [[ style="pointer-events: none; opacity: 0.4;" ]]
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
				width:10%;
				font-weight: bold;
			}

			.rowLabel {
				width:45%;
			}

			.rowModifier {
				width:25%;
			}

			.rowShortcut {
				width:20%;
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
		<div id="customiseShortcuts" ]] .. customShortcutsEnabled .. [[>
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
-- UPDATE CUSTOM SHORTCUTS SECTION:
--------------------------------------------------------------------------------
function mod.updateCustomShortcutsVisibility()

	local enableHacksShortcutsInFinalCutPro = config.get("enableHacksShortcutsInFinalCutPro", false)

	if enableHacksShortcutsInFinalCutPro then
		mod._manager.injectScript([[
			document.getElementById("customiseShortcuts").style.opacity = 0.4;
			document.getElementById("customiseShortcuts").style.pointerEvents = "none";
			document.getElementById("keyboardShortcuts").children[0].children[0].checked = true;
		]])
	else
		mod._manager.injectScript([[
			document.getElementById("customiseShortcuts").style.opacity = 1;
			document.getElementById("customiseShortcuts").style.pointerEvents = "auto";
			document.getElementById("keyboardShortcuts").children[0].children[0].checked = false;
		]])
	end

	mod._manager.show()

end

--------------------------------------------------------------------------------
-- INITIALISE MODULE:
--------------------------------------------------------------------------------
function mod.init(deps)

	mod.availiableShortcuts = generateListOfShortcuts()

	mod._commandaction = deps.commandaction
	mod._global = deps.global
	mod._fcpx = deps.fcpx
	mod._manager = deps.manager

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
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.preferences.panels.shortcuts",
	group			= "core",
	dependencies	= {
		["core.preferences.manager"]		= "manager",
		["core.commands.commandaction"]		= "commandaction",
		["core.commands.global"]			= "global",
		["finalcutpro.commands"]			= "fcpx",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
	return mod.init(deps)
end

return plugin