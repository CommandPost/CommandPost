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
local tangent                                   = require("hs.tangent")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                                    = require("cp.config")
local tools                                     = require("cp.tools")
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

--- plugins.core.preferences.panels.tangent.enabled <cp.prop: boolean>
--- Field
--- Enable or disables the Tangent Manager.
mod.enabled = config.prop("enableTangent", false)

--- plugins.core.preferences.panels.tangent.init() -> none
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
    -- Setup Tangent Preferences Panel:
    --------------------------------------------------------------------------------
    mod._panel = deps.prefsManager.addPanel({
        priority    = 2032.1,
        id          = "tangent",
        label       = i18n("tangentPanelLabel"),
        image       = image.imageFromPath(env:pathToAbsolute("/tangent.icns")),
        tooltip     = i18n("tangentPanelTooltip"),
        height      = 370,
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
                    if params.checked then
                        --------------------------------------------------------------------------------
                        -- Enable Tangent:
                        --------------------------------------------------------------------------------
                        if not tangent.isTangentHubInstalled() then
                            dialog.webviewAlert(deps.prefsManager.getWebview(), function()
                                mod.enabled(false)
                                deps.prefsManager.injectScript([[
                                    document.getElementById("enableTangentSupport").checked = false;
                                ]])
                            end, i18n("tangentPanelSupport"), i18n("mustInstallTangentMapper"), i18n("ok"))
                        else
                            if deps.tangentManager.areMappingsInstalled() then
                                mod.enabled(true)
                            else
                                dialog.webviewAlert(deps.prefsManager.getWebview(), function()
                                    deps.tangentManager.writeControlsXML()
                                    mod.enabled(true)
                                    dialog.webviewAlert(deps.prefsManager.getWebview(), function() end, i18n("rebuildComplete") .. "!", i18n("rebuildCompleteMessage"), i18n("ok"))
                                end, i18n("existingControlMapDoesNotExist"), i18n("rebuildControlMapTakesTimes"), i18n("ok"))
                            end
                        end
                    else
                        --------------------------------------------------------------------------------
                        -- Disable Tangent:
                        --------------------------------------------------------------------------------
                        mod.enabled(false)
                    end
                end,
                checked = mod.enabled,
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
                    if tools.doesFileExist("/Applications/Tangent/Tangent Mapper.app") then
                        os.execute('open "/Applications/Tangent/Tangent Mapper.app"')
                    else
                        dialog.webviewAlert(deps.prefsManager.getWebview(), function() end, i18n("tangentMapperNotFound"), i18n("tangentMapperNotFoundMessage"), i18n("ok"))
                    end
                end,
                class = "tangentButtonOne",
            }
        )
        --------------------------------------------------------------------------------
        -- Rebuild Control Map:
        --------------------------------------------------------------------------------
        :addButton(7,
            {
                label = i18n("rebuildControlMap"),
                onclick = function()
                    dialog.webviewAlert(deps.prefsManager.getWebview(), function(result)
                        if result == i18n("ok") then
                            --------------------------------------------------------------------------------
                            -- Write Controls XMLs:
                            --------------------------------------------------------------------------------
                            deps.tangentManager.writeControlsXML()
                            if mod.enabled() then
                                --------------------------------------------------------------------------------
                                -- Restart Tangent:
                                --------------------------------------------------------------------------------
                                mod.enabled(false)
                                mod.enabled(true)
                            end

                            dialog.webviewAlert(deps.prefsManager.getWebview(), function() end, i18n("rebuildComplete") .. "!", i18n("rebuildCompleteMessage"), i18n("ok"))
                        end
                    end, i18n("rebuildControlMap"), i18n("rebuildControlMapMessage") .. "\n\n" .. i18n("rebuildControlMapTakesTimes"), i18n("ok"), i18n("cancel"))
                end,
                class = "tangentButtonTwo",
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
    id              = "core.preferences.panels.tangent",
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
    return mod.init(deps, env)
end

return plugin
