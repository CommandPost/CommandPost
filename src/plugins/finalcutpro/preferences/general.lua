--- === plugins.finalcutpro.preferences.general ===
---
--- Final Cut Pro General Preferences

local require = require

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
        ["finalcutpro.preferences.manager"] = "prefs",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    local panel = deps.prefs.panel
    if panel then
        panel
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

            :addHeading(2200, i18n("hiddenFinalCutProPreferences"))

            :addParagraph(2201, html.span { class="tbTip" } ( i18n("advancedFeaturesWarning") .. "<br /><br />", false ).. "\n\n")

            :addContent(8998, "<br />", false)
            :addButton(8999,
                {
                    label = i18n("moveableMarkers") .. "?",
                    width = 200,
                    onclick = function()
                        os.execute('open "https://help.commandpost.io/getting-started/faq#why-did-you-remove-moveable-markers"')
                    end,
                })

            :addContent(9000, [[
                    </div>
                </div>
            ]], false)
    end
end

return plugin
