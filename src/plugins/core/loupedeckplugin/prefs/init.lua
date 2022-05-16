--- === plugins.core.loupedeckplugin.prefs ===
---
--- Loupedeck Plugin Preferences Panel

local require                   = require

local log                       = require "hs.logger".new "ldPlugin"

local application               = require "hs.application"
local image                     = require "hs.image"
local inspect                   = require "hs.inspect"

local html                      = require "cp.web.html"
local i18n                      = require "cp.i18n"
local tools                     = require "cp.tools"

local escapeTilda               = tools.escapeTilda
local execute                   = _G.hs.execute
local imageFromPath             = image.imageFromPath
local launchOrFocusByBundleID   = application.launchOrFocusByBundleID

local mod = {}

-- LOUPEDECK_CONFIG_APP_BUNDLE_ID -> string
-- Constant
-- Loupedeck Config App Bundle Identifier
local LOUPEDECK_CONFIG_APP_BUNDLE_ID = "com.loupedeck.loupedeckconfig"

-- LOUPEDECK_DOWNLOAD_URL -> string
-- Constant
-- Loupedeck Download URL
local LOUPEDECK_DOWNLOAD_URL = "https://loupedeck.com/get-started/"

-- renderPanel(context) -> none
-- Function
-- Generates the Preference Panel HTML Content.
--
-- Parameters:
--  * context - Table of data that you want to share with the renderer
--
-- Returns:
--  * HTML content as string
local function renderPanel(context)
    if not mod._renderPanel then
        local errorMessage
        mod._renderPanel, errorMessage = mod.env:compileTemplate("html/panel.html")
        if errorMessage then
            log.ef(errorMessage)
            return nil
        end
    end
    return mod._renderPanel(context)
end

-- generateContent() -> string
-- Function
-- Generates the Preference Panel HTML Content.
--
-- Parameters:
--  * None
--
-- Returns:
--  * HTML content as string
local function generateContent()
    local context = {
        maxItems    = mod.loupedeckplugin.NUMBER_OF_FAVOURITES,
        i18n        = i18n,
    }
    return renderPanel(context)
end

-- updateUI() -> none
-- Function
-- Updates the preferences panel user interface.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function updateUI()
    local script = ""

    --------------------------------------------------------------------------------
    -- Update the Favourites titles:
    --------------------------------------------------------------------------------
    local faves = mod.loupedeckplugin.favourites()
    local max = mod.loupedeckplugin.NUMBER_OF_FAVOURITES
    for i = 1, max do
        local fave = faves[tostring(i)]
        if fave then
            local actionTitle = fave.actionTitle
            script = script .. [[changeValueByID('label_]] .. i .. [[', `]] .. escapeTilda(actionTitle) .. [[`);]]
        else
            script = script .. [[changeValueByID('label_]] .. i .. [[', `]] .. i18n("none") .. [[`);]]
        end
    end

    --------------------------------------------------------------------------------
    -- Inject the JavaScript:
    --------------------------------------------------------------------------------
    local injectScript = mod.manager.injectScript
    injectScript(script)
end

-- loupedeckPluginPanelCallback() -> none
-- Function
-- JavaScript Callback for the Preferences Panel
--
-- Parameters:
--  * id - ID as string
--  * params - Table of paramaters
--
-- Returns:
--  * None
local function loupedeckPluginPanelCallback(id, params)
    if params and params["type"] then
        if params["type"] == "updateUI" then
            --------------------------------------------------------------------------------
            -- Update the User Interface:
            --------------------------------------------------------------------------------
            updateUI()
        elseif params["type"] == "updateAction" then
            --------------------------------------------------------------------------------
            -- Setup Activators:
            --------------------------------------------------------------------------------
            if not mod.activator then
                --------------------------------------------------------------------------------
                -- Create new Activator:
                --------------------------------------------------------------------------------
                mod.activator = mod.actionManger.getActivator("loupedeckpluginPreferences")
            end

            --------------------------------------------------------------------------------
            -- Setup Activator Callback:
            --------------------------------------------------------------------------------
            mod.activator:onActivate(function(handler, action, text)
                    --------------------------------------------------------------------------------
                    -- Process Stylised Text:
                    --------------------------------------------------------------------------------
                    if text and type(text) == "userdata" then
                        text = text:convert("text")
                    end

                    local actionTitle = text

                    local handlerID = handler:id()
                    local buttonID = params.buttonID

                    local faves = mod.loupedeckplugin.favourites()

                    faves[tostring(buttonID)] = {
                        actionTitle = actionTitle,
                        handlerID = handlerID,
                        action = action,
                    }

                    mod.loupedeckplugin.favourites(faves)

                    updateUI()
                end)

            --------------------------------------------------------------------------------
            -- Setup Search Console Icons:
            --------------------------------------------------------------------------------
            local defaultSearchConsoleToolbar = mod.appManager.defaultSearchConsoleToolbar()
            mod.activator:toolbarIcons(defaultSearchConsoleToolbar)

            --------------------------------------------------------------------------------
            -- Show Activator:
            --------------------------------------------------------------------------------
            mod.activator:show()
        elseif params["type"] == "clearAction" then
            local buttonID = params.buttonID

            local faves = mod.loupedeckplugin.favourites()
            faves[tostring(buttonID)] = nil
            mod.loupedeckplugin.favourites(faves)

            updateUI()
        else
            --------------------------------------------------------------------------------
            -- Unknown Callback:
            --------------------------------------------------------------------------------
            log.df("Unknown Callback in Loupedeck Plugin Panel:")
            log.df("id: %s", inspect(id))
            log.df("params: %s", inspect(params))
        end
    end
end

local plugin = {
    id              = "core.loupedeckplugin.prefs",
    group           = "core",
    dependencies    = {
        ["core.loupedeckplugin.manager"]    = "loupedeckplugin",
        ["core.controlsurfaces.manager"]    = "manager",
        ["core.action.manager"]             = "actionManager",
        ["core.application.manager"]        = "appManager",

    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    local manager           = deps.manager
    local loupedeckplugin   = deps.loupedeckplugin

    mod.actionManger        = deps.actionManager
    mod.appManager          = deps.appManager
    mod.manager             = deps.manager
    mod.loupedeckplugin     = deps.loupedeckplugin
    mod.env                 = env

    local icon = imageFromPath(env:pathToAbsolute("/images/loupedeck.icns"))

    manager.addPanel({
        group           = "loupedeck",
        priority        = 1,
        id              = "loupedeckplugin",
        label           = i18n("pluginForOfficialApp"),
        image           = icon,
        tooltip         = i18n("pluginForOfficialApp"),
        height          = 810,
    })
        :addContent(1, html.style ([[
                .buttonOne {
                    float:left;
                    width: 210px;
                }
                .buttonTwo {
                    float:left;
                    margin-left: 5px;
                    width: 210px;
                }
            ]], true))
        :addHeading(2, i18n("loupedeckPlugin"))
        :addParagraph(2.1, i18n("loupedeckPluginPreferencesDescription"), false)
        :addParagraph(2.2, html.br())
        :addParagraph(2.3, html.span {class="tip"} (html(i18n("loupedeckPluginTip"), false) ) .. "\n\n")
        :addParagraph(2.4, html.br())
        :addCheckbox(3,
            {
                label = i18n("enableLoupedeckPlugin"),
                id = "enableLoupedeckPlugin",
                onchange = function(_, params)
                    local result = loupedeckplugin.setEnabled(params.checked)
                    manager.injectScript([[changeCheckedByID("enableLoupedeckPlugin", ]] .. tostring(result) .. ")")
                end,
                checked = loupedeckplugin.enabled,
            }
        )
        :addParagraph(4, html.br())
        :addButton(5,
            {
                label 	    = i18n("openOfficialLoupedeckApp"),
                onclick	    =   function()
                                    launchOrFocusByBundleID(LOUPEDECK_CONFIG_APP_BUNDLE_ID)
                                end,
                class       = "buttonOne",
            }
        )
        :addButton(6,
            {
                label 	    = i18n("downloadOfficialLoupedeckApp"),
                onclick	    =   function()
                                    execute("open " .. LOUPEDECK_DOWNLOAD_URL)
                                end,
                class       = "buttonTwo",
            }
        )
        :addParagraph(7, html.br())
        :addParagraph(8, html.br())
        :addHeading(9, i18n("loupedeckPlugin") .. " " .. i18n("favourites"))
        :addParagraph(10, i18n("loupedeckPluginFavouriteDescription"), false)

        :addContent(11, generateContent, false)

        --------------------------------------------------------------------------------
        -- Setup Callback Manager:
        --------------------------------------------------------------------------------
        :addHandler("onchange", "loupedeckPluginPanelCallback", loupedeckPluginPanelCallback)

    return mod
end

return plugin
