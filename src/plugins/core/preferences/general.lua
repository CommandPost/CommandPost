--- === plugins.core.preferences.general ===
---
--- General Preferences Panel.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log				= require("hs.logger").new("preferences")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local config			= require("cp.config")
local prop				= require("cp.prop")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local i18n        = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.preferences.general.autoLaunch <cp.prop: boolean>
--- Field
--- Controls if CommandPost will automatically launch when the user logs in.
mod.autoLaunch = prop.new(
    function() return hs.autoLaunch() end,
    function(value) hs.autoLaunch(value) end
)

--- plugins.core.preferences.general.autoLaunch <cp.prop: boolean>
--- Field
--- Controls if CommandPost will automatically upload crash data to the developer.
mod.uploadCrashData = prop.new(
    function() return hs.uploadCrashData() end,
    function(value) hs.uploadCrashData(value) end
)

--- plugins.core.preferences.general.openPrivacyPolicy() -> none
--- Function
--- Opens the CommandPost Privacy Policy in your browser.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.openPrivacyPolicy()
    hs.execute("open '" .. config.privacyPolicyURL .. "'")
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id				= "core.preferences.general",
    group			= "core",
    dependencies	= {
        ["core.preferences.panels.general"]	= "general",
    }
}
--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Cache Values:
    --------------------------------------------------------------------------------
    mod._autoLaunch 		= hs.autoLaunch()
    mod._uploadCrashData 	= hs.uploadCrashData()

    --------------------------------------------------------------------------------
    -- Setup General Preferences Panel:
    --------------------------------------------------------------------------------
    local general =  deps.general
    if general then
        general
            :addContent(0.1, [[
                <style>
                    .generalPrefsRow {
                        display: flex;
                    }

                    .generalPrefsColumn {
                        flex: 50%;
                    }
                </style>
                <div class="generalPrefsRow">
                    <div class="generalPrefsColumn">
            ]], false)

            :addHeading(1, i18n("general"))

            :addCheckbox(3,
                {
                    label		= i18n("launchAtStartup"),
                    checked		= mod.autoLaunch,
                    onchange	= function(_, params) mod.autoLaunch(params.checked) end,
                }
            )

            :addHeading(10, i18n("privacy"))

            :addCheckbox(11,
                {
                    label		= i18n("sendCrashData"),
                    checked		= mod.uploadCrashData,
                    onchange	= function(_, params) mod.uploadCrashData(params.checked) end,
                }
            )

            :addButton(12,
                {
                    label 		= i18n("openPrivacyPolicy"),
                    width		= 200,
                    onclick		= mod.openPrivacyPolicy,
                }
            )

            :addContent(30, [[
                    </div>
                    <div class="generalPrefsColumn">
            ]], false)

            :addContent(100, [[
                    </div>
                </div>
            ]], false)

    end

    return mod

end

return plugin
