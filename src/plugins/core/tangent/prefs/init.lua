--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--               T A N G E N T   P R E F E R E N C E S    P A N E L           --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.tangent.prefs ===
---
--- Tangent Preferences Panel

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
local log                                       = require("hs.logger").new("tangentPref")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local dialog                                    = require("hs.dialog")
local image                                     = require("hs.image")
local json	                					= require("hs.json")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local commands                                  = require("cp.commands")
local html                                      = require("cp.web.html")
local tools                                     = require("cp.tools")

--------------------------------------------------------------------------------
-- 3rd Party Extensions:
--------------------------------------------------------------------------------
local _                                         = require("moses")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.tangent.prefs.TANGENT_WEBSITE -> string
--- Constant
--- Tangent Website URL.
mod.TANGENT_WEBSITE = "http://www.tangentwave.co.uk/"

--- plugins.core.tangent.prefs.DOWNLOAD_TANGENT_HUB -> string
--- Constant
--- URL to download Tangent Hub Application.
mod.DOWNLOAD_TANGENT_HUB = "http://www.tangentwave.co.uk/download/tangent-hub-installer-mac/"

--- plugins.core.tangent.prefs.MAX_ITEMS -> number
--- Constant
--- Maximum number of Favourites available in the Tangent Preferences.
mod.MAX_ITEMS = 50

--- plugins.core.tangent.prefs.favourites -> table
--- Variable
--- Table of favourites.
mod.favourites = {}

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
        mod._renderPanel, errorMessage = mod._env:compileTemplate("html/panel.html")
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
        _                       = _,
        webviewLabel            = mod._prefsManager.getLabel(),
        maxItems                = mod.MAX_ITEMS,
        favourites              = mod.favourites,
        none                    = i18n("none"),
    }
    return renderPanel(context)
end

-- loadFromFile() -> table
-- Function
-- Loads the Favourites from JSON file.
--
-- Parameters:
--  * None
--
-- Returns:
--  * A table of favourites.
local function loadFromFile()
    --------------------------------------------------------------------------------
    -- Create folder if it doesn't exist:
    --------------------------------------------------------------------------------
    local configPath = mod._tangentManager.configPath
    if not tools.doesDirectoryExist(configPath) then
        fs.mkdir(configPath)
    end

    --------------------------------------------------------------------------------
    -- Load from file:
    --------------------------------------------------------------------------------
    local filePath = configPath .. "/favourites.json"
    local file = io.open(filePath, "r")
    if file then
        local content = file:read("*all")
        file:close()
        if not _.isEmpty(content) then
            return json.decode(content)
        else
            return {}
        end
    else
        log.ef("Unable to load Favourites file: '%s'", filePath)
        return {}
    end
end

-- saveToFile() -> none
-- Function
-- Saves favourites to JSON file.
--
-- Parameters:
--  * None
--
-- Returns:
--  * None
local function saveToFile()
    --------------------------------------------------------------------------------
    -- Create folder if it doesn't exist:
    --------------------------------------------------------------------------------
    local configPath = mod._tangentManager.configPath
    if not tools.doesDirectoryExist(configPath) then
        fs.mkdir(configPath)
    end

    --------------------------------------------------------------------------------
    -- Save to file:
    --------------------------------------------------------------------------------
    local filePath = configPath .. "/favourites.json"
    local file = io.open(filePath, "w")
    if file then
        file:write(json.encode(mod.favourites))
        file:close()
    else
        log.df("Unable to save Favourites file: '%s'", filePath)
    end
end

-- saveAction(buttonID, actionTitle, handlerID, action) -> none
-- Function
-- Saves an action to Favourites.
--
-- Parameters:
--  * buttonID - The button ID as number.
--  * actionTitle - The action title as string.
--  * handlerID - The handler ID as string.
--  * action - The action table.
--
-- Returns:
--  * None
local function saveAction(buttonID, actionTitle, handlerID, action)
    if not mod.favourites[buttonID] then
        mod.favourites[buttonID] = {}
    end
    mod.favourites[buttonID] = {
        actionTitle = actionTitle,
        handlerID = handlerID,
        action = action,
    }
    saveToFile()
end

-- clearAction(buttonID) -> none
-- Function
-- Clears an Action from Favourites.
--
-- Parameters:
--  * buttonID - The button ID you want to clear.
--
-- Returns:
--  * None
local function clearAction(buttonID)
    if mod.favourites[buttonID] then
        mod.favourites[buttonID] = nil
    end
    saveToFile()
end

-- tangentPanelCallback() -> none
-- Function
-- JavaScript Callback for the Preferences Panel
--
-- Parameters:
--  * id - ID as string
--  * params - Table of paramaters
--
-- Returns:
--  * None
local function tangentPanelCallback(id, params)
    if params and params["type"] then
        if params["type"] == "updateAction" then

            --------------------------------------------------------------------------------
            -- Setup Activators:
            --------------------------------------------------------------------------------
            if not mod.activator then
                --------------------------------------------------------------------------------
                -- Create new Activator:
                --------------------------------------------------------------------------------
                local handlerIds = mod._actionManager.handlerIds()
                mod.activator = mod._actionManager.getActivator("tangentPreferences")
                mod.activator:preloadChoices()
            end

            --------------------------------------------------------------------------------
            -- Setup Activator Callback:
            --------------------------------------------------------------------------------
            mod.activator:onActivate(function(handler, action, text)
                    local actionTitle = text
                    local handlerID = handler:id()
                    local buttonID = params.buttonID
                    saveAction(buttonID, actionTitle, handlerID, action)
                    mod._prefsManager.refresh()
                end)

            --------------------------------------------------------------------------------
            -- Show Activator:
            --------------------------------------------------------------------------------
            mod.activator:show()
        elseif params["type"] == "clearAction" then
            local buttonID = params.buttonID
            clearAction(buttonID)
            mod._prefsManager.refresh()
        else
            --------------------------------------------------------------------------------
            -- Unknown Callback:
            --------------------------------------------------------------------------------
            log.df("Unknown Callback in Tangent Preferences Panel:")
            log.df("id: %s", hs.inspect(id))
            log.df("params: %s", hs.inspect(params))
        end
    end
end

--- plugins.core.tangent.prefs.init() -> none
--- Function
--- Initialise Module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(deps, env)

    --------------------------------------------------------------------------------
    -- Inter-plugin Connectivity:
    --------------------------------------------------------------------------------
    mod._actionManager  = deps.actionManager
    mod._prefsManager   = deps.prefsManager
    mod._tangentManager = deps.tangentManager
    mod._env            = env

    --------------------------------------------------------------------------------
    -- Load Favourites from JSON File:
    --------------------------------------------------------------------------------
    mod.favourites = loadFromFile()

    --------------------------------------------------------------------------------
    -- Setup Tangent Preferences Panel:
    --------------------------------------------------------------------------------
    mod._panel = mod._prefsManager.addPanel({
        priority    = 2032.1,
        id          = "tangent",
        label       = i18n("tangentPanelLabel"),
        image       = image.imageFromPath(env:pathToAbsolute("/images/tangent.icns")),
        tooltip     = i18n("tangentPanelTooltip"),
        height      = 650,
    })
        :addContent(1, html.style ([[
            .tangentButtonOne {
                float:left;
                width: 192px;
            }
            .tangentButtonTwo {
                float:left;
                margin-left: 5px;
                width: 192px;
            }
            .tangentButtonThree {
                clear:both;
                float:left;
                margin-top: 5px;
                width: 192px;
            }
            .tangentButtonFour {
                float:left;
                margin-top: 5px;
                margin-left: 5px;
                width: 192px;
            }
        ]], true))
        :addHeading(2, i18n("tangentPanelSupport"))
        :addParagraph(3, i18n("tangentPreferencesInfo"), false)
        :addParagraph(3.2, html.br())
        --------------------------------------------------------------------------------
        -- Enable Tangent Support:
        --------------------------------------------------------------------------------
        :addCheckbox(4,
            {
                label = i18n("enableTangentPanelSupport"),
                onchange = function(_, params)
                    if params.checked and not mod._tangentManager.tangentHubInstalled() then
                        dialog.webviewAlert(mod._prefsManager.getWebview(), function()
                            mod._tangentManager.enabled(false)
                            mod._prefsManager.injectScript([[
                                document.getElementById("enableTangentSupport").checked = false;
                            ]])
                        end, i18n("tangentPanelSupport"), i18n("mustInstallTangentMapper"), i18n("ok"))
                    else
                        mod._tangentManager.enabled(params.checked)
                    end
                end,
                checked = mod._tangentManager.enabled,
                id = "enableTangentSupport",
            }
        )
        :addParagraph(5, html.br())
        --------------------------------------------------------------------------------
        -- Open Tangent Mapper:
        --------------------------------------------------------------------------------
        :addButton(6,
            {
                label = i18n("openTangentMapper"),
                onclick = function()
                    if mod._tangentManager.tangentMapperInstalled() then
                        mod._tangentManager.launchTangentMapper()
                    else
                        dialog.webviewAlert(mod._prefsManager.getWebview(), function() end, i18n("tangentMapperNotFound"), i18n("tangentMapperNotFoundMessage"), i18n("ok"))
                    end
                end,
                class = "tangentButtonOne",
            }
        )
        --------------------------------------------------------------------------------
        -- Download Tangent Hub:
        --------------------------------------------------------------------------------
        :addButton(8,
            {
                label = i18n("downloadTangentHub"),
                onclick = function()
                    os.execute('open "' .. mod.DOWNLOAD_TANGENT_HUB .. '"')
                end,
                class = "tangentButtonTwo",
            }
        )
        --------------------------------------------------------------------------------
        -- Visit Tangent Website:
        --------------------------------------------------------------------------------
        :addButton(9,
            {
                label = i18n("visitTangentWebsite"),
                onclick = function()
                    os.execute('open "' .. mod.TANGENT_WEBSITE .. '"')
                end,
                class = "tangentButtonTwo",
            }
        )
        :addParagraph(10, html.br())
        :addParagraph(11, html.br())
        :addHeading(12, "Tangent Favourites")
        :addParagraph(13, "You can assign any action in CommandPost to a Favourite below, which is then accessible in the Tangent Mapper.", false)
        :addContent(14, generateContent, false)

        --------------------------------------------------------------------------------
        -- Setup Callback Manager:
        --------------------------------------------------------------------------------
        :addHandler("onchange", "tangentPanelCallback", tangentPanelCallback)

    return mod

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.tangent.prefs",
    group           = "core",
    dependencies    = {
        ["core.preferences.manager"]    = "prefsManager",
        ["core.tangent.manager"]        = "tangentManager",
        ["core.action.manager"]         = "actionManager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
    return mod.init(deps, env)
end

return plugin
