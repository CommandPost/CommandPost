--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--               T A N G E N T   P R E F E R E N C E S    P A N E L           --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.preferences.panels.tangent ===
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
--local log                                       = require("hs.logger").new("tangentPref")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local dialog                                    = require("hs.dialog")
local image                                     = require("hs.image")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local html                                      = require("cp.web.html")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.preferences.panels.tangent.TANGENT_WEBSITE() -> string
--- Constant
--- Tangent Website URL.
mod.TANGENT_WEBSITE = "http://www.tangentwave.co.uk/"

--- plugins.core.preferences.panels.tangent.DOWNLOAD_TANGENT_HUB() -> string
--- Constant
--- URL to download Tangent Hub Application.
mod.DOWNLOAD_TANGENT_HUB = "http://www.tangentwave.co.uk/download/tangent-hub-installer-mac/"

--- plugins.core.preferences.panels.tangent.init() -> none
--- Function
--- Initialise Module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(prefsManager, tangentManager, env)

    --------------------------------------------------------------------------------
    -- Setup Tangent Preferences Panel:
    --------------------------------------------------------------------------------
    mod._panel = prefsManager.addPanel({
        priority    = 2032.1,
        id          = "tangent",
        label       = i18n("tangentPanelLabel"),
        image       = image.imageFromPath(env:pathToAbsolute("/tangent.icns")),
        tooltip     = i18n("tangentPanelTooltip"),
        height      = 320,
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
        --------------------------------------------------------------------------------
        -- Enable Tangent Support:
        --------------------------------------------------------------------------------
        :addCheckbox(4,
            {
                label = i18n("enableTangentPanelSupport"),
                onchange = function(_, params)
                    if params.checked and not tangentManager.tangentHubInstalled() then
                        dialog.webviewAlert(prefsManager.getWebview(), function()
                            tangentManager.enabled(false)
                            prefsManager.injectScript([[
                                document.getElementById("enableTangentSupport").checked = false;
                            ]])
                        end, i18n("tangentPanelSupport"), i18n("mustInstallTangentMapper"), i18n("ok"))
                    else
                        tangentManager.enabled(params.checked)
                    end
                end,
                checked = tangentManager.enabled,
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
                    if tangentManager.tangentMapperInstalled() then
                        tangentManager.launchTangentMapper()
                    else
                        dialog.webviewAlert(prefsManager.getWebview(), function() end, i18n("tangentMapperNotFound"), i18n("tangentMapperNotFoundMessage"), i18n("ok"))
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
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps, env)
    return mod.init(deps.prefsManager, deps.tangentManager, env)
end

return plugin
