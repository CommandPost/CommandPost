--- === plugins.core.tangent.prefs ===
---
--- Tangent Preferences Panel

local require                   = require

local log                       = require "hs.logger".new "tangentPref"

local application               = require "hs.application"
local dialog                    = require "hs.dialog"
local image                     = require "hs.image"
local timer                     = require "hs.timer"

local config                    = require "cp.config"
local cpDialog                  = require "cp.dialog"
local html                      = require "cp.web.html"
local i18n                      = require "cp.i18n"
local tools                     = require "cp.tools"

local chooseFileOrFolder        = dialog.chooseFileOrFolder
local displayChooseFromList     = cpDialog.displayChooseFromList
local doAfter                   = timer.doAfter
local escapeTilda               = tools.escapeTilda
local imageFromPath             = image.imageFromPath
local infoForBundlePath         = application.infoForBundlePath
local spairs                    = tools.spairs
local tableContains             = tools.tableContains
local tableCount                = tools.tableCount
local webviewAlert              = dialog.webviewAlert

local mod = {}

-- TANGENT_WEBSITE -> string
-- Constant
-- Tangent Website URL.
local TANGENT_WEBSITE = "http://www.tangentwave.co.uk/"

-- DOWNLOAD_TANGENT_HUB -> string
-- Constant
-- URL to download Tangent Hub Application.
local DOWNLOAD_TANGENT_HUB = "http://www.tangentwave.co.uk/download/tangent-hub-installer-mac/"

-- DEFAULT_LAST_APPLICATION -> string
-- Constant
-- The default last application.
local DEFAULT_LAST_APPLICATION = "Final Cut Pro"

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
    local applicationNames = mod._tangentManager.applicationNames()
    table.sort(applicationNames)

    local context = {
        applicationNames        = applicationNames,
        webviewLabel            = mod._prefsManager.getLabel(),
        maxItems                = mod._tangentManager.NUMBER_OF_FAVOURITES,
        spairs                  = spairs,
        none                    = i18n("none"),
        i18n                    = i18n,
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
    -- This will only happen if a Custom Application is deleted:
    --------------------------------------------------------------------------------
    local lastApplication = mod.lastApplication()
    local connection = mod._tangentManager.getConnection(lastApplication)
    if not connection then
        lastApplication = DEFAULT_LAST_APPLICATION
        connection = mod._tangentManager.getConnection(lastApplication)
    end

    --------------------------------------------------------------------------------
    -- Enable or Disable the "Add Application" drop down option:
    --------------------------------------------------------------------------------
    local maxConnections = mod._tangentManager.MAXIMUM_CONNECTIONS
    local applicationNames = mod._tangentManager.applicationNames()
    local connectionCount = #applicationNames
    local allowAddApplication = true
    if connectionCount >= maxConnections then
        allowAddApplication = false
    end
    script = script .. [[document.getElementById("addApplication").disabled = ]] .. tostring(not allowAddApplication) .. [[;]]

    --------------------------------------------------------------------------------
    -- Enable or Disable the "Remove Application" drop down option:
    --------------------------------------------------------------------------------
    local customApplications = mod._tangentManager.customApplications()
    local customApplicationsCount = tableCount(customApplications)
    local allowRemoveApplication = true
    if customApplicationsCount == 0 then
        allowRemoveApplication = false
    end
    script = script .. [[document.getElementById("removeApplication").disabled = ]] .. tostring(not allowRemoveApplication) .. [[;]]

    --------------------------------------------------------------------------------
    -- Update the application drop down list:
    --------------------------------------------------------------------------------
    script = script .. [[changeValueByID('application', `]] .. escapeTilda(lastApplication) .. [[`);]]

    --------------------------------------------------------------------------------
    -- Update the enabled button checkbox:
    --------------------------------------------------------------------------------
    local enabled = connection.enabled()
    script = script .. [[changeCheckedByID('enabled', ]] .. tostring(enabled) .. [[);]]

    --------------------------------------------------------------------------------
    -- Update the Favourites titles:
    --------------------------------------------------------------------------------
    local faves = connection.favourites()
    local max = mod._tangentManager.NUMBER_OF_FAVOURITES
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
    local injectScript = mod._prefsManager.injectScript
    injectScript(script)
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
    local injectScript = mod._prefsManager.injectScript
    if params and params["type"] then
        if params["type"] == "updateUI" then
            --------------------------------------------------------------------------------
            -- Update the User Interface:
            --------------------------------------------------------------------------------
            updateUI()
        elseif params["type"] == "changeEnabled" then
            --------------------------------------------------------------------------------
            -- Change the Enabled Checkbox:
            --------------------------------------------------------------------------------
            local enabled = params.enabled
            local lastApplication = mod.lastApplication()
            local connection = mod._tangentManager.getConnection(lastApplication)
            connection.enabled(enabled)
        elseif params["type"] == "changeApplication" then
            local app = params.application
            if app == "Remove Application" then
                --------------------------------------------------------------------------------
                -- Remove Application:
                --------------------------------------------------------------------------------
                local customApplications = mod._tangentManager.customApplications()

                local applicationNames = mod._tangentManager.applicationNames()
                table.sort(applicationNames)

                local result = displayChooseFromList("Please select the application you want to remove:", applicationNames)
                local applicationToRemove = result and result[1]
                if applicationToRemove then
                    mod._tangentManager.removeCustomApplication(applicationToRemove)

                    --------------------------------------------------------------------------------
                    -- Refresh the UI:
                    --------------------------------------------------------------------------------
                    mod._prefsManager.refresh()
                else
                    updateUI()
                end
            elseif app == "Add Application" then
                --------------------------------------------------------------------------------
                -- Add Application:
                --------------------------------------------------------------------------------
                local files = chooseFileOrFolder(i18n("pleaseSelectAnApplication") .. ":", "/Applications", true, false, false, {"app"}, false)
                if files then
                    local path = files["1"]
                    local info = path and infoForBundlePath(path)
                    local applicationName = info and info.CFBundleDisplayName or info.CFBundleName or info.CFBundleExecutable
                    local bundleExecutable = info and info.CFBundleExecutable
                    if applicationName and bundleExecutable then
                        local applicationNames = mod._tangentManager.applicationNames()
                        if not tableContains(applicationNames, applicationName) then
                            mod._tangentManager.registerCustomApplication(applicationName, bundleExecutable)

                            --------------------------------------------------------------------------------
                            -- Refresh the UI:
                            --------------------------------------------------------------------------------
                            mod._prefsManager.refresh()
                        else
                            webviewAlert(mod._prefsManager.getWebview(), function() end, i18n("failedToAddCustomApplication"), i18n("duplicateCustomApplication"), i18n("ok"))
                        end
                    else
                        webviewAlert(mod._prefsManager.getWebview(), function() end, i18n("failedToAddCustomApplication"), i18n("failedToAddCustomApplicationDescription"), i18n("ok"))
                        log.ef("Something went wrong trying to add a custom application.\n\nPath: '%s'\nbundleExecutable: '%s'\napplicationName: '%s'",path, bundleExecutable, applicationName)
                    end
                    updateUI()
                end
            else
                mod.lastApplication(app)
                updateUI()
            end
        elseif params["type"] == "updateAction" then
            --------------------------------------------------------------------------------
            -- Setup Activators:
            --------------------------------------------------------------------------------
            if not mod.activator then
                --------------------------------------------------------------------------------
                -- Create new Activator:
                --------------------------------------------------------------------------------
                mod.activator = mod._actionManager.getActivator("tangentPreferences")
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

                    local lastApplication = mod.lastApplication()
                    local connection = mod._tangentManager.getConnection(lastApplication)
                    local faves = connection.favourites()

                    faves[tostring(buttonID)] = {
                        actionTitle = actionTitle,
                        handlerID = handlerID,
                        action = action,
                    }

                    connection.favourites(faves)

                    --------------------------------------------------------------------------------
                    -- Add a slight delay to give the UI time to update before we rebuild the
                    -- Tangent XML files:
                    --------------------------------------------------------------------------------
                    doAfter(0.5, function() connection:updateControls() end)

                    updateUI()
                end)

            --------------------------------------------------------------------------------
            -- Setup Search Console Icons:
            --------------------------------------------------------------------------------
            local defaultSearchConsoleToolbar = mod._appmanager.defaultSearchConsoleToolbar()
            mod.activator:toolbarIcons(defaultSearchConsoleToolbar)

            --------------------------------------------------------------------------------
            -- Show Activator:
            --------------------------------------------------------------------------------
            mod.activator:show()
        elseif params["type"] == "clearAction" then
            local buttonID = params.buttonID
            local lastApplication = mod.lastApplication()
            local connection = mod._tangentManager.getConnection(lastApplication)
            local faves = connection.favourites()
            faves[tostring(buttonID)] = nil
            connection.favourites(faves)

            --------------------------------------------------------------------------------
            -- Add a slight delay to give the UI time to update before we rebuild the
            -- Tangent XML files:
            --------------------------------------------------------------------------------
            doAfter(0.5, function() connection:updateControls() end)

            updateUI()
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
    mod._appmanager     = deps.appManager
    mod._prefsManager   = deps.prefsManager
    mod._tangentManager = deps.tangentManager
    mod._env            = env

    --- plugins.core.tangent.prefs.lastApplication <cp.prop: string>
    --- Field
    --- Last Application used in the Preferences Panel.
    mod.lastApplication = config.prop("tangent.preferences.lastApplication", DEFAULT_LAST_APPLICATION)

    --------------------------------------------------------------------------------
    -- Setup Tangent Preferences Panel:
    --------------------------------------------------------------------------------
    mod._panel = mod._prefsManager.addPanel({
        priority    = 2032.1,
        id          = "tangent",
        label       = i18n("tangentPanelLabel"),
        image       = imageFromPath(env:pathToAbsolute("/images/tangent.icns")),
        tooltip     = i18n("tangentPanelTooltip"),
        height      = 830,
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
        :addParagraph(3.1, html.br())
        :addParagraph(3.2, html.span {class="tip"} (html(i18n("tangentTip"), false) ) .. "\n\n")
        :addParagraph(3.3, html.br())
        --------------------------------------------------------------------------------
        -- Enable Tangent Support:
        --------------------------------------------------------------------------------
        :addCheckbox(4,
            {
                label = i18n("enableTangentPanelSupport"),
                onchange = function(_, params)
                    if params.checked and not mod._tangentManager.tangentHubInstalled() then
                        webviewAlert(mod._prefsManager.getWebview(), function()
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
                        webviewAlert(mod._prefsManager.getWebview(), function() end, i18n("tangentMapperNotFound"), i18n("tangentMapperNotFoundMessage"), i18n("ok"))
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
                    os.execute('open "' .. DOWNLOAD_TANGENT_HUB .. '"')
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
                    os.execute('open "' .. TANGENT_WEBSITE .. '"')
                end,
                class = "tangentButtonTwo",
            }
        )
        :addParagraph(10, html.br())
        :addParagraph(11, html.br())
        :addHeading(12, i18n("tangent") .. " " .. i18n("favourites"))
        :addParagraph(13, i18n("tangentFavouriteDescription"), false)
        :addContent(14, generateContent, false)

        --------------------------------------------------------------------------------
        -- Setup Callback Manager:
        --------------------------------------------------------------------------------
        :addHandler("onchange", "tangentPanelCallback", tangentPanelCallback)

    return mod
end

local plugin = {
    id              = "core.tangent.prefs",
    group           = "core",
    dependencies    = {
        ["core.controlsurfaces.manager"]        = "prefsManager",
        ["core.tangent.manager"]                = "tangentManager",
        ["core.action.manager"]                 = "actionManager",
        ["core.application.manager"]            = "appManager",
    }
}

function plugin.init(deps, env)
    return mod.init(deps, env)
end

return plugin
