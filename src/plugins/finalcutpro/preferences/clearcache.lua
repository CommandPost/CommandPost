--- === plugins.finalcutpro.preferences.clearcache ===
---
--- Adds a "Clear Cache" button to the Final Cut Pro Preferences.

local require = require

local dialog        = require("hs.dialog")

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

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Setup Menubar Preferences Panel:
    --------------------------------------------------------------------------------
    local panel = deps.prefs.panel
    if panel then
        panel
            :addHeading(2008.2, i18n("pluginCache"))
            :addParagraph(2008.3, html.span { class="tbTip" } ( i18n("pluginCacheDescription") .. "<br /><br />", false ).. "\n\n")
            :addButton(2008.4,
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
