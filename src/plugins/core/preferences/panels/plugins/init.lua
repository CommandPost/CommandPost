--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--            P L U G I N S    P R E F E R E N C E S    P A N E L            --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === core.preferences.panels.plugins ===
---
--- Plugins Preferences Panel

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local log										= require("hs.logger").new("prefsPlugin")

local fs										= require("hs.fs")
local image										= require("hs.image")

local dialog									= require("cp.dialog")
local config									= require("cp.config")
local tools										= require("cp.tools")
local plugins									= require("cp.plugins")
local html										= require("cp.web.html")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- core.preferences.panels.plugins.SETTINGS_DISABLED
--- Constant
--- Plugins Disabled
mod.SETTINGS_DISABLED = "plugins.disabled"

--------------------------------------------------------------------------------
-- DISABLE PLUGIN:
--------------------------------------------------------------------------------
local function disablePlugin(id)
	local result = dialog.displayMessage("Are you sure you want to disable this plugin?\n\nIf you continue, CommandPost will need to restart.", {"Yes", "No"})
	if result == "Yes" then
		plugins.disable(id)
		hs.reload()
	end
end

--------------------------------------------------------------------------------
-- ENABLE PLUGIN:
--------------------------------------------------------------------------------
local function enablePlugin(id)
	local result = dialog.displayMessage("Are you sure you want to enable this plugin?\n\nIf you continue, CommandPost will need to restart.", {"Yes", "No"})
	if result == "Yes" then
		plugins.enable(id)
		hs.reload()
	end
end

--------------------------------------------------------------------------------
-- CONTROLLER CALLBACK:
--------------------------------------------------------------------------------
local function controllerCallback(id, params)

	local action = params.action

	if action == "errorLog" then
		hs.openConsole()
	elseif action == "pluginsFolder" then
		openPluginsFolder()
	elseif action == "disable" then
		disablePlugin(id)
	elseif action == "enable" then
		enablePlugin(id)
	else
		--log.df("Unrecognised action: ", hs.inspect(message))
	end

end

local function openPluginsFolder()
	if not tools.doesDirectoryExist(config.userPluginsPath) then
		log.df("Creating Plugins directory.")
		local status, err = fs.mkdir(config.userPluginsPath)
		if not status then
			log.ef("Failed to create Plugins directory: %s", err)
			return
		end
	end

	local pathToOpen = fs.pathToAbsolute(config.userPluginsPath)
	if pathToOpen then
		local _, status = hs.execute('open "' .. pathToOpen .. '"')
		if status then return end
	end

	log.df("Failed to Open Plugins Window.")
end

--------------------------------------------------------------------------------
-- PLUGIN STATUS:
--------------------------------------------------------------------------------
local function pluginStatus(id)
	local status = plugins.getPluginStatus(id)
	return string.format("<span class='status-%s'>%s</span>", status, i18n("plugin_status_" .. status))
end

--------------------------------------------------------------------------------
-- PLUGIN CATEGORY:
--------------------------------------------------------------------------------
local function pluginCategory(id)
	local group = plugins.getPluginGroup(id)
	return i18n("plugin_group_" .. group, {default = group})
end

--------------------------------------------------------------------------------
-- PLUGIN SHORT NAME:
--------------------------------------------------------------------------------
local function pluginShortName(path)

	local result = i18n(string.gsub(path, "%.", "_") .. "_label") or path
	if result ~= path then
		result = string.format('<div class="tooltip">%s<span class="tooltiptext">%s</span></div>', result, path)
	end
	return result
end

--------------------------------------------------------------------------------
-- GENERATE CONTENT:
--------------------------------------------------------------------------------
local function generateContent()

	local listOfPlugins = plugins.getPluginIds()

	table.sort(listOfPlugins, function(a, b) return a < b end)

	local pluginRows = ""
	local pluginInfo = {}

	local lastCategory = ""

	for _,id in ipairs(listOfPlugins) do

		local info = {}

		local currentCategory = pluginCategory(id)
		local cachedCurrentCategory = currentCategory
		if currentCategory == lastCategory then currentCategory = "" end

		info.id = id
		info.currentCategory = currentCategory
		info.status = plugins.getPluginStatus(id)
		info.shortName = pluginShortName(id)
		
		
		local action = nil

		if info.status == plugins.status.error then
			action = "errorLog"
		elseif info.status == plugins.status.active then
			action = "disable"
		elseif info.status == plugins.status.disabled then
			action = "enable"
		end
		info.action = action

		if action then
			info.actionLabel = i18n("plugin_action_" .. action,  {default = action})
		end

		lastCategory = cachedCurrentCategory
		pluginInfo[#pluginInfo+1] = info
		mod.panel:addHandler("onclick", info.id, controllerCallback, { "action" })

	end
	
	-- handle 'open plugin folder' buttons
	mod.panel:addHandler("onclick", "openPluginsFolder", openPluginsFolder)
	
	local env = {
		plugins		= pluginInfo,
	}
	
	return mod.renderPanel(env)
end

--- core.preferences.panels.plugins.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * deps - The plugin dependencies.
---  * env	- The plugin environment.
---
--- Returns:
---  * None
function mod.init(deps, env)

	mod._webviewLabel = deps.manager.getLabel()
	
	mod.renderPanel = env:compileTemplate("html/panel.html")

	mod.panel = deps.manager.addPanel({
		priority 	= 2050,
		id			= "plugins",
		label		= i18n("pluginsPanelLabel"),
		image		= image.imageFromPath("/System/Library/PreferencePanes/Extensions.prefPane/Contents/Resources/Extensions.icns"),
		tooltip		= i18n("pluginsPanelTooltip"),
	})
	
	mod.panel:addContent(10, generateContent, true)

	return mod
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
	id				= "core.preferences.panels.plugins",
	group			= "core",
	dependencies	= {
		["core.preferences.manager"]			= "manager",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
	return mod.init(deps, env)
end

return plugin