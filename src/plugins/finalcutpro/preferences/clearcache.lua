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
        ["finalcutpro.preferences.app"] = "prefs",
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
            :addHeading(2, i18n("pluginCache"))

            --------------------------------------------------------------------------------
            -- Add Clear Plugin Cache Button:
            --------------------------------------------------------------------------------
            :addButton(2.1,
                {
                    label = i18n("clearPluginCache"),
                    width = 200,
                    onclick = function()
                        dialog.webviewAlert(deps.manager.getWebview(), function(result)
                            if result == i18n("yes") then

                                --------------------------------------------------------------------------------
                                -- Audio Units Cache:
                                --------------------------------------------------------------------------------
                                config.set("audioUnitsCache", nil)
                                config.set("audioUnitsCacheModification", nil)

                                --------------------------------------------------------------------------------
                                -- User Effects Presets Cache:
                                --------------------------------------------------------------------------------
                                config.set("userEffectsPresetsCacheModification", nil)
                                config.set("userEffectsPresetsCache", nil)

                                --------------------------------------------------------------------------------
                                -- User Motion Templates Cache:
                                --------------------------------------------------------------------------------
                                config.set("userMotionTemplatesCacheSize", nil)
                                config.set("userMotionTemplatesCache", nil)

                                --------------------------------------------------------------------------------
                                -- System Motion Templates Cache:
                                --------------------------------------------------------------------------------
                                config.set("systemMotionTemplatesCacheSize", nil)
                                config.set("systemMotionTemplatesCache", nil)

                                --------------------------------------------------------------------------------
                                -- Clear Caches:
                                --------------------------------------------------------------------------------
                                fcp:plugins().clearCaches()

                                --------------------------------------------------------------------------------
                                -- Restart CommandPost:
                                --------------------------------------------------------------------------------
                                hs.reload()

                            end
                        end, i18n("clearingFinalCutProCacheRestart"), i18n("doYouWantToContinue"), i18n("yes"), i18n("no"))
                    end,
                })
    end
end

return plugin
