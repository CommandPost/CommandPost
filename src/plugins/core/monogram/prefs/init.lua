--- === plugins.core.monogram.prefs ===
---
--- Monogram Preferences Panel

local require                   = require

local log                       = require "hs.logger".new "audioSwift"

local image                     = require "hs.image"
local inspect                   = require "hs.inspect"

local html                      = require "cp.web.html"
local i18n                      = require "cp.i18n"
local tools                     = require "cp.tools"

local escapeTilda               = tools.escapeTilda
local imageFromPath             = image.imageFromPath

local mod = {}

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
        maxItems    = mod.monogram.NUMBER_OF_FAVOURITES,
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
    local faves = mod.monogram.favourites()
    local max = mod.monogram.NUMBER_OF_FAVOURITES
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

-- monogramPanelCallback() -> none
-- Function
-- JavaScript Callback for the Preferences Panel
--
-- Parameters:
--  * id - ID as string
--  * params - Table of paramaters
--
-- Returns:
--  * None
local function monogramPanelCallback(id, params)
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
                mod.activator = mod.actionManger.getActivator("monogramPreferences")
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

                    local faves = mod.monogram.favourites()

                    faves[tostring(buttonID)] = {
                        actionTitle = actionTitle,
                        handlerID = handlerID,
                        action = action,
                    }

                    mod.monogram.favourites(faves)

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

            local faves = mod.monogram.favourites()
            faves[tostring(buttonID)] = nil
            mod.monogram.favourites(faves)

            updateUI()
        else
            --------------------------------------------------------------------------------
            -- Unknown Callback:
            --------------------------------------------------------------------------------
            log.df("Unknown Callback in Tangent Preferences Panel:")
            log.df("id: %s", inspect(id))
            log.df("params: %s", inspect(params))
        end
    end
end

local plugin = {
    id              = "core.monogram.prefs",
    group           = "core",
    dependencies    = {
        ["core.monogram.manager"]           = "monogram",
        ["core.controlsurfaces.manager"]    = "manager",
        ["core.action.manager"]             = "actionManager",
        ["core.application.manager"]        = "appManager",

    }
}

function plugin.init(deps, env)
    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    local manager       = deps.manager
    local monogram      = deps.monogram

    mod.actionManger    = deps.actionManager
    mod.appManager      = deps.appManager
    mod.manager         = deps.manager
    mod.monogram        = deps.monogram
    mod.env             = env

    manager.addPanel({
        priority        = 9010,
        id              = "monogram",
        label           = i18n("monogram"),
        image           = imageFromPath(env:pathToAbsolute("/images/Monogram.icns")),
        tooltip         = i18n("monogram"),
        height          = 700,
    })
        :addContent(1, html.style ([[
                .buttonOne {
                    float:left;
                    width: 192px;
                }
                .buttonTwo {
                    float:left;
                    margin-left: 5px;
                    width: 192px;
                }
            ]], true))
        :addHeading(2, i18n("monogramSupport"))
        :addCheckbox(3,
            {
                label = i18n("enableMonogramSupport"),
                id = "enableMonogramSupport",
                onchange = function(_, params)
                    local result = monogram.setEnabled(params.checked)
                    manager.injectScript([[changeCheckedByID("enableMonogramSupport", ]] .. tostring(result) .. ")")
                end,
                checked = monogram.enabled,
            }
        )
        :addParagraph(4, html.br())
        :addButton(5,
            {
                label 	    = i18n("openMonogramCreator"),
                onclick	    = function() monogram.launchCreatorBundle() end,
                class       = "buttonOne",
            }
        )
        :addButton(6,
            {
                label 	    = i18n("downloadMonogramCreator"),
                onclick	    = function() monogram.openDownloadMonogramCreatorURL() end,
                class       = "buttonTwo",
            }
        )
        :addParagraph(7, html.br())
        :addParagraph(8, html.br())
        :addHeading(9, i18n("monogram") .. " " .. i18n("favourites"))
        :addParagraph(10, i18n("monogramFavouriteDescription"), false)

        :addContent(11, generateContent, false)

        --------------------------------------------------------------------------------
        -- Setup Callback Manager:
        --------------------------------------------------------------------------------
        :addHandler("onchange", "monogramPanelCallback", monogramPanelCallback)

    return mod
end

return plugin
