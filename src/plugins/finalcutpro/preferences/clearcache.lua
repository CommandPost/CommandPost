--- === plugins.finalcutpro.preferences.clearcache ===
---
--- Adds a "Clear Cache" button to the Final Cut Pro Preferences.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local dialog        = require("hs.dialog")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config        = require("cp.config")
local fcp           = require("cp.apple.finalcutpro")
local html          = require("cp.web.html")
local i18n          = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.preferences.clearcache",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.preferences.manager"] = "prefs",
        ["core.preferences.manager"]    = "manager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup Menubar Preferences Panel:
    --------------------------------------------------------------------------------
    if deps.prefs.panel then
        deps.prefs.panel
            --------------------------------------------------------------------------------
            -- Add Preferences Heading:
            --------------------------------------------------------------------------------
            :addHeading(2500, i18n("pluginCache"))
            :addParagraph(2501, html.span { class="tbTip" } ( i18n("pluginCacheDescription") .. "<br /><br />", false ).. "\n\n")

            --------------------------------------------------------------------------------
            -- Add Clear Plugin Cache Button:
            --------------------------------------------------------------------------------
            :addButton(2502,
                {
                    label = i18n("clearPluginCache"),
                    width = 200,
                    onclick = function()
                        dialog.webviewAlert(deps.manager.getWebview(), function(result)
                            if result == i18n("yes") then
                                --------------------------------------------------------------------------------
                                -- Clear Caches:
                                --------------------------------------------------------------------------------
                                fcp:plugins().clearCaches()

                                --------------------------------------------------------------------------------
                                -- Restart CommandPost:
                                --------------------------------------------------------------------------------
                                hs.reload()
                            end
                        end, i18n("clearingFinalCutProCacheRestart"), i18n("clearingFinalCutProCacheRestartWarning"), i18n("yes"), i18n("no"))
                    end,
                })
    end
end

return plugin
