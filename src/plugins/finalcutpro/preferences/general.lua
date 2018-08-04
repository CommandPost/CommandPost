--- === plugins.finalcutpro.preferences.general ===
---
--- Final Cut Pro General Preferences

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local html                      = require("cp.web.html")
local i18n                      = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.preferences.general",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.preferences.app"] = "prefs",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    if deps.prefs.panel then
        deps.prefs.panel
            --------------------------------------------------------------------------------
            -- Two Columns:
            --------------------------------------------------------------------------------
            :addContent(0.1, [[
                <style>
                    .fcpPrefsRow {
                        display: flex;
                    }

                    .fcpPrefsColumn {
                        flex: 50%;
                    }
                </style>
                <div class="fcpPrefsRow">
                    <div class="fcpPrefsColumn">
            ]], false)

            :addHeading(1, i18n("general"))

            :addContent(2100, [[
                    </div>
                    <div class="fcpPrefsColumn">
            ]], false)

            :addHeading(2200, i18n("advancedFeatures"))

            :addParagraph(2201, html.span { class="tbTip" } ( i18n("advancedFeaturesWarning") .. "<br /><br />", false ).. "\n\n")

            :addContent(3100, [[
                    </div>
                </div>
            ]], false)


    end

end

return plugin
