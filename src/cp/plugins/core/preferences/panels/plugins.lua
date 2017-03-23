--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--            P L U G I N S    P R E F E R E N C E S    P A N E L            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === cp.plugins.core.preferences.panels.plugins ===
---
--- Plugins Preferences Panel

--------------------------------------------------------------------------------
-- EXTENSIONS:
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefsPlugin")

local fnutils									= require("hs.fnutils")
local fs										= require("hs.fs")
local image										= require("hs.image")
local timer										= require("hs.timer")
local toolbar                  					= require("hs.webview.toolbar")
local webview									= require("hs.webview")

local dialog									= require("cp.dialog")
local metadata									= require("cp.metadata")
local tools										= require("cp.tools")

--------------------------------------------------------------------------------
-- THE MODULE:
--------------------------------------------------------------------------------
local mod = {}

	mod.SETTINGS_DISABLED = "plugins.disabled"
	mod.SETTINGS_CUSTOM_PATH = "plugins.custompath"

	--------------------------------------------------------------------------------
	-- DISABLE PLUGIN:
	--------------------------------------------------------------------------------
	local function disablePlugin(path)

		local result = dialog.displayMessage("Are you sure you want to disable this plugin?\n\nIf you continue, CommandPost will need to restart.", {"Yes", "No"})
		if result == "Yes" then
			local disabled = metadata.get(mod.SETTINGS_DISABLED, {})
			disabled[path] = true
			metadata.set(mod.SETTINGS_DISABLED, disabled)
			hs.reload()
		end

	end

	--------------------------------------------------------------------------------
	-- ENABLE PLUGIN:
	--------------------------------------------------------------------------------
	local function enablePlugin(path)

		local result = dialog.displayMessage("Are you sure you want to enable this plugin?\n\nIf you continue, CommandPost will need to restart.", {"Yes", "No"})
		if result == "Yes" then
			local disabled = metadata.get(mod.SETTINGS_DISABLED, {})
			disabled[path] = false
			metadata.set(mod.SETTINGS_DISABLED, disabled)
			hs.reload()
		end

	end

	--------------------------------------------------------------------------------
	-- CONTROLLER CALLBACK:
	--------------------------------------------------------------------------------
	local function controllerCallback(message)

		if message["body"][1] == "openErrorLog" then
			hs.openConsole()
		elseif message["body"][2] == "Disable" then
			disablePlugin(message["body"][1])
		elseif message["body"][2] == "Enable" then
			enablePlugin(message["body"][1])
		end

	end

	--------------------------------------------------------------------------------
	-- FIND PLUGINS:
	--------------------------------------------------------------------------------
	local function findPlugins(package)

		local plugins = {}
		local path = fs.pathToAbsolute(metadata.scriptPath .. "/" .. package:gsub("%.", "/"))

		local files = tools.dirFiles(path)
		for i,file in ipairs(files) do
			if file ~= "." and file ~= ".." and file ~= "init.lua" then
				local filePath = path .. "/" .. file
				if fs.attributes(filePath).mode == "directory" then
					local attrs, err = fs.attributes(filePath .. "/init.lua")
					if attrs and attrs.mode == "file" then
						--------------------------------------------------------------------------------
						-- It's a plugin:
						--------------------------------------------------------------------------------
						plugins[#plugins+1] = package .. "." .. file
					else
						--------------------------------------------------------------------------------
						-- It's a plain folder. Load it as a sub-package:
						--------------------------------------------------------------------------------
						local subPackages = findPlugins(package .. "." .. file)
						for i, v in ipairs(subPackages) do
							plugins[#plugins+1] = v
					    end
					end
				else
					local name = file:match("(.+)%.lua$")
					if name then
						plugins[#plugins+1] = package .. "." .. name
					end
				end
			end
		end

		return plugins

	end

	--------------------------------------------------------------------------------
	-- FIND CUSTOM PLUGINS:
	--------------------------------------------------------------------------------
	local function findCustomPlugins(path)

		local plugins = {}

		local files = tools.dirFiles(path)
		if files then
			for i,file in ipairs(files) do
				if file ~= "." and file ~= ".." and file ~= "init.lua" then
					local filePath = path .. "/" .. file
					if fs.attributes(filePath).mode == "directory" then
						local attrs, err = fs.attributes(filePath .. "/init.lua")
						if attrs and attrs.mode == "file" then
							--------------------------------------------------------------------------------
							-- It's a plugin:
							--------------------------------------------------------------------------------
							plugins[#plugins+1] = file
						else
							--------------------------------------------------------------------------------
							-- It's a plain folder. Load it as a sub-package:
							--------------------------------------------------------------------------------
							local subPackages = findCustomPlugins(path .. file .. "/")
							for i, v in ipairs(subPackages) do
								plugins[#plugins+1] = file .. "." .. v
						    end
						end
					else
						local name = file:match("(.+)%.lua$")
						if name then
							plugins[#plugins+1] = package .. "." .. name
						end
					end
				end
			end
		end

		return plugins

	end

	--------------------------------------------------------------------------------
	-- GET LIST OF PLUGINS:
	--------------------------------------------------------------------------------
	local function getListOfPlugins()

		local plugins = findPlugins(metadata.pluginPaths[1])

		local customPluginPath = metadata.customPluginPath
		if tools.doesDirectoryExist(customPluginPath) then
			local customPlugins = findCustomPlugins(customPluginPath)
			return fnutils.concat(plugins, customPlugins)
		end
		return plugins

	end

	--------------------------------------------------------------------------------
	-- PLUGIN STATUS:
	--------------------------------------------------------------------------------
	local function pluginStatus(path)



		for i, v in ipairs(failedPlugins) do
			if v == path then
				return [[<span style="font-weight:bold; color: red;">Failed</span>]]
			else
				local disabled = metadata.get(mod.SETTINGS_DISABLED, {})

				if disabled[path] then
					return [[<span style="font-weight:bold;">Disabled</span>]]
				else
					return "Enabled"
				end

			end
		end

		print(path)

		return "Unknown"

	end

	--------------------------------------------------------------------------------
	-- PLUGIN CATEGORY:
	--------------------------------------------------------------------------------
	local function pluginCategory(path)

		local pluginPath = metadata.pluginPaths[1]

		if string.sub(path, 1, string.len(pluginPath)) == pluginPath then
			local removedPluginPath = string.sub(path, string.len(pluginPath) + 2)
			local pluginComponents = fnutils.split(removedPluginPath, ".", nil, true)
			return pluginComponents[1]
		else
			return "custom"
		end

	end

	--------------------------------------------------------------------------------
	-- PLUGIN SHORT NAME:
	--------------------------------------------------------------------------------
	local function pluginShortName(path)

		local pluginPath = metadata.pluginPaths[1]
		if string.sub(path, 1, string.len(pluginPath)) == pluginPath then
			local pluginCategory = pluginCategory(path)
			return string.sub(path, string.len(pluginPath) + string.len(pluginCategory) + 3)
		else
			return path
		end
	end

	--------------------------------------------------------------------------------
	-- GENERATE CONTENT:
	--------------------------------------------------------------------------------
	local function generateContent()

		local listOfPlugins = getListOfPlugins()

		local pluginRows = ""

		local lastCategory = ""

	    for i, v in ipairs(listOfPlugins) do

			local currentCategory = pluginCategory(v)
			local cachedCurrentCategory = currentCategory
			if currentCategory == lastCategory then currentCategory = "" end

			local currentPluginStatus = pluginStatus(v)
     		pluginRows = pluginRows .. [[
				<tr>
					<td class="rowCategory">]] .. currentCategory .. [[</td>
					<td class="rowName">]] .. pluginShortName(v) .. [[</td>
					<td class="rowStatus">]] .. currentPluginStatus .. [[</td>]]

			if string.match(currentPluginStatus, "Failed") then
				pluginRows = pluginRows .. [[
					<td class="rowOption"><a href="#" id="error.]] .. v .. [[">Error Log</a></td>
					<script>
						document.getElementById("error.]] .. v .. [[").onclick = function() {
							try {
								var result = ["openErrorLog"];
								webkit.messageHandlers.]] .. mod._webviewLabel .. [[.postMessage(result);
							} catch(err) {
								alert('An error has occurred. Does the controller exist yet?');
							}
						}
					</script>
				]]
			elseif string.match(currentPluginStatus, "Enabled") then

				pluginRows = pluginRows .. [[
					<td class="rowOption"><a id="]] .. v .. [[" href="#">Disable</></td>
					<script>
						document.getElementById("]] .. v .. [[").onclick = function() {
							try {
								var result = ["]] .. v .. [[", "Disable"];
								webkit.messageHandlers.]] .. mod._webviewLabel .. [[.postMessage(result);
							} catch(err) {
								alert('An error has occurred. Does the controller exist yet?');
							}
						}
					</script>
					]]

			elseif string.match(currentPluginStatus, "Disabled") then

				pluginRows = pluginRows .. [[
					<td class="rowOption"><a id="]] .. v .. [[" href="#">Enable</></td>
					<script>
						document.getElementById("]] .. v .. [[").onclick = function() {
							try {
								var result = ["]] .. v .. [[", "Enable"];
								webkit.messageHandlers.]] .. mod._webviewLabel .. [[.postMessage(result);
							} catch(err) {
								alert('An error has occurred. Does the controller exist yet?');
							}
						}
					</script>
					]]
			end

			pluginRows = pluginRows .. "</tr>"


			lastCategory = cachedCurrentCategory

    	end

		local result = [[
			<style>
				.plugins {
					table-layout: fixed;
					width: 100%;
					white-space: nowrap;

					border: 1px solid #cccccc;
					padding: 8px;
					background-color: #ffffff;
					text-align: left;
				}

				.plugins td {
				  white-space: nowrap;
				  overflow: hidden;
				  text-overflow: ellipsis;
				}

				.rowCategory {
					width:20%;
					font-weight: bold;
				}

				.rowName {
					width:50%;
				}

				.rowStatus {
					width:15%;
				}

				.rowOption {
					width:15%;
				}

				.plugins thead, .plugins tbody tr {
					display:table;
					table-layout:fixed;
					width: calc( 100% - 1.5em );
				}

				.plugins tbody {
					display:block;
					height: 250px;
					font-weight: normal;
					font-size: 10px;

					overflow-x: hidden;
					overflow-y: auto;
				}

				.plugins tbody tr {
					display:table;
					width:100%;
					table-layout:fixed;
				}

				.plugins thead {
					font-weight: bold;
					font-size: 12px;
				}

				.plugins tbody {
					font-weight: normal;
					font-size: 10px;
				}

				.plugins tbody tr:nth-child(even) {
					background-color: #f5f5f5
				}

				.plugins tbody tr:hover {
					background-color: #006dd4;
					color: white;
				}
			</style>
			<h3>Plugins Manager:</h3>
			<table class="plugins">
				<thead>
					<tr>
						<th class="rowCategory">Category</th>
						<th class="rowName">Plugin Name</th>
						<th class="rowStatus">Status</th>
						<th class="rowOption">Control</th>
					</tr>
				</thead>
				<tbody>
					]] .. pluginRows .. [[
				</tbody>
			</table>
			<div style="display: block;">
				<p><span style="font-weight: bold;">Custom Plugins</span> will also be loaded if stored in the following folder:</p>
				<p style="padding-left: 20px;">]] .. metadata.customPluginPath .. [[</p>
			</div>
		]]
		return result
	end

	function mod.init(deps)

		mod._webviewLabel = deps.manager.getLabel()

		local id 			= "plugins"
		local label 		= "Plugins"
		local image			= image.imageFromPath("/System/Library/PreferencePanes/Extensions.prefPane/Contents/Resources/Extensions.icns")
		local priority		= 3
		local tooltip		= "Plugins Panel"
		local contentFn		= generateContent
		local callbackFn 	= controllerCallback

		deps.manager.addPanel(id, label, image, priority, tooltip, contentFn, callbackFn)

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