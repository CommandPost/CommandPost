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
-- PLUGIN STATUS:
--------------------------------------------------------------------------------
local function pluginStatus(plugin)
	local status = plugin:getStatus()
	return string.format("<span class='status-%s'>%s</span>", status, i18n("plugin_status_" .. status))
end

--------------------------------------------------------------------------------
-- PLUGIN CATEGORY:
--------------------------------------------------------------------------------
local function pluginCategory(plugin)
	local group = plugin:getGroup()
	return i18n("plugin_group_" .. group, {default = group})
end

--------------------------------------------------------------------------------
-- PLUGIN SHORT NAME:
--------------------------------------------------------------------------------
local function pluginShortName(id, plain)

	local result = i18n(string.gsub(id, "%.", "_") .. "_label") or id
	if not plain and result ~= id then
		result = string.format('<div class="tooltip">%s<span class="tooltiptext">%s</span></div>', result, id)
	end
	return result
end

--------------------------------------------------------------------------------
-- DISABLE PLUGIN:
--------------------------------------------------------------------------------
local function disablePlugin(id)
	local result = dialog.displayMessage(i18n("pluginsDisableCheck"), {i18n "yes", i18n "no"})
	if result == i18n "yes" then
		if not plugins.disable(id) then
			dialog.displayMessage(i18n("pluginsUnableToDisable", {pluginName = pluginShortName(id, true)}))
		end
	end
end

--------------------------------------------------------------------------------
-- ENABLE PLUGIN:
--------------------------------------------------------------------------------
local function enablePlugin(id)
	local result = dialog.displayMessage(i18n("pluginsEnableCheck"), {i18n "yes", i18n "no"})
	if result == i18n "yes" then
		if not plugins.enable(id) then
			dialog.displayMessage(i18n("pluginsUnableToEnable", {pluginName = pluginShortName(id, true)}))
		end
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
-- GENERATE CONTENT:
--------------------------------------------------------------------------------
local function generateContent()

	local listOfPlugins = plugins.getPlugins()

	local pluginInfo = {}

	for _,plugin in ipairs(listOfPlugins) do

		local info = {}

		info.id = plugin.id
		info.group = plugin.group
		info.category = pluginCategory(plugin)
		info.currentCategory = currentCategory
		info.status = pluginStatus(plugin)
		info.shortName = pluginShortName(plugin.id)

		local action = nil

		local status = plugin:getStatus()
		if status == plugins.status.error then
			action = "errorLog"
		elseif status == plugins.status.active and not plugin.required then
			action = "disable"
		elseif status == plugins.status.disabled then
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

	table.sort(pluginInfo, function(a, b)
		return a.category < b.category or a.category == b.category and a.shortName < b.shortName
	end)

	-- Add a 'currentCategory' field that only list the category when it's different from the previous one.
	local lastCategory = ""
	for _,info in ipairs(pluginInfo) do
		info.currentCategory = info.category == lastCategory and "" or info.category
		lastCategory = info.category
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
		image		= image.imageFromPath(tools.iconFallback("/System/Library/PreferencePanes/Extensions.prefPane/Contents/Resources/Extensions.icns")),
		tooltip		= i18n("pluginsPanelTooltip"),
		height		= 492,
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
		["core.commands.global"] 				= "global",
	}
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)

	--------------------------------------------------------------------------------
	-- Commands:
	--------------------------------------------------------------------------------
	local global = deps.global
	global:add("cpOpenPluginsFolder")
		:whenActivated(openPluginsFolder)

	return mod.init(deps, env)
end

return plugin