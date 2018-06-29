--- === plugins.core.preferences.panels.plugins ===
---
--- Plugins Preferences Panel

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                       = require("hs.logger").new("prefsPlugin")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local dialog                                    = require("hs.dialog")
local fs                                        = require("hs.fs")
local image                                     = require("hs.image")
local inspect                                   = require("hs.inspect")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                                    = require("cp.config")
local plugins                                   = require("cp.plugins")
local tools                                     = require("cp.tools")
local i18n                                      = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.preferences.panels.plugins.SETTINGS_DISABLED
--- Constant
--- Plugins Disabled
mod.SETTINGS_DISABLED = "plugins.disabled"

-- pluginStatus(plugin) -> string
-- Function
-- Gets the plugin status from a plugin.
--
-- Parameters:
--  * plugin - The plugin you want to check
--
-- Returns:
--  * The status as a HTML string
local function pluginStatus(plugin)
    local status = plugin:getStatus()
    return string.format("<span class='status-%s'>%s</span>", status, i18n("plugin_status_" .. status))
end

-- pluginCategory(plugin) -> string
-- Function
-- Gets the plugin category from a plugin.
--
-- Parameters:
--  * plugin - The plugin you want to check
--
-- Returns:
--  * The category as a HTML string
local function pluginCategory(plugin)
    local group = plugin:getGroup()
    return i18n("plugin_group_" .. group, {default = group})
end

-- pluginShortName(id, plain) -> string
-- Function
-- Gets the short name of a plugin.
--
-- Parameters:
--  * id - The ID of the plugin
--  * plain - If plain is `true` then it will just return the short name as a string, otherwise it will return HTML as a string.
--
-- Returns:
--  * The category as a HTML string
local function pluginShortName(id, plain)

    local result = i18n(string.gsub(id, "%.", "_") .. "_label") or id
    if not plain and result ~= id then
        result = string.format('<div class="tooltip">%s<span class="tooltiptext">%s</span></div>', result, id)
    end
    return result
end

-- disablePlugin(id) -> none
-- Function
-- Disabled a plugin by ID.
--
-- Parameters:
--  * id - The ID of a plugin.
--
-- Returns:
--  * None
local function disablePlugin(id)
    dialog.webviewAlert(mod._manager.getWebview(), function(result)
        if result == i18n("yes") then
            if not plugins.disable(id) then
                dialog.webviewAlert(mod._manager.getWebview(), function() end, i18n("pluginsUnableToDisable", {pluginName = pluginShortName(id, true)}))
            end
        end
    end, i18n("pluginsDisableCheck"), i18n("pluginsRestart"), i18n("yes"), i18n("no"), "informational")
end

-- enablePlugin(id) -> none
-- Function
-- Enables a plugin by ID.
--
-- Parameters:
--  * id - The ID of a plugin.
--
-- Returns:
--  * None
local function enablePlugin(id)
    dialog.webviewAlert(mod._manager.getWebview(), function(result)
        if result == i18n("yes") then
            if not plugins.enable(id) then
                dialog.webviewAlert(mod._manager.getWebview(), function() end, i18n("pluginsUnableToEnable", {pluginName = pluginShortName(id, true)}))
            end
        end
    end, i18n("pluginsEnableCheck"), i18n("pluginsRestart"), i18n("yes"), i18n("no"), "informational")
end

-- openPluginsFolder() -> none
-- Function
-- Opens the Plugin Folder in Finder.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
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

-- controllerCallback(id, params) -> none
-- Function
-- Controller Callback
--
-- Parameters:
--  * id - The ID
--  * params - A table of parameters
--
-- Returns:
--  * None
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
        log.ef("Unrecognised action: %s %s", id, inspect(params))
    end
end

-- generateContent() -> none
-- Function
-- Generates the HTML content
--
-- Parameters:
--  * None
--
-- Returns:
--  * The HTML as string.
local function generateContent()

    local listOfPlugins = plugins.getPlugins()

    local pluginInfo = {}

    for _,plugin in ipairs(listOfPlugins) do

        local info = {}

        info.id = plugin.id
        info.group = plugin.group
        info.category = pluginCategory(plugin)
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

        pluginInfo[#pluginInfo+1] = info
        mod.panel:addHandler("onclick", info.id, controllerCallback, { "action" })

    end

    table.sort(pluginInfo, function(a, b)
        return a.category < b.category or a.category == b.category and a.shortName < b.shortName
    end)

    --------------------------------------------------------------------------------
    -- Add a 'currentCategory' field that only list the category when it's
    -- different from the previous one.
    --------------------------------------------------------------------------------
    local lastCategory = ""
    for _,info in ipairs(pluginInfo) do
        info.currentCategory = info.category == lastCategory and "" or info.category
        lastCategory = info.category
    end

    --------------------------------------------------------------------------------
    -- Handle the 'Open Plugin Folder' button:
    --------------------------------------------------------------------------------
    mod.panel:addHandler("onclick", "openPluginsFolder", openPluginsFolder)

    local env = {
        i18n        = i18n,
        plugins     = pluginInfo,
    }

    return mod.renderPanel(env)
end

--- plugins.core.preferences.panels.plugins.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * deps - The plugin dependencies.
---  * env  - The plugin environment.
---
--- Returns:
---  * None
function mod.init(deps, env)

    mod._webviewLabel = deps.manager.getLabel()
    mod._manager = deps.manager

    mod.renderPanel = env:compileTemplate("html/panel.html")

    mod.panel = deps.manager.addPanel({
        priority    = 2050,
        id          = "plugins",
        label       = i18n("pluginsPanelLabel"),
        image       = image.imageFromPath(tools.iconFallback("/System/Library/PreferencePanes/Extensions.prefPane/Contents/Resources/Extensions.icns")),
        tooltip     = i18n("pluginsPanelTooltip"),
        height      = 492,
    })

    mod.panel:addContent(10, generateContent, false)

    return mod
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.preferences.panels.plugins",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"]            = "manager",
        ["core.commands.global"]                = "global",
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
        :groupedBy("commandPost")

    return mod.init(deps, env)
end

return plugin
