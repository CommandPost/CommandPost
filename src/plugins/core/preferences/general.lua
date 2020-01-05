--- === plugins.core.preferences.general ===
---
--- General Preferences Panel.

local require = require

local hs = hs

local config    = require("cp.config")
local i18n      = require("cp.i18n")
local prop      = require("cp.prop")

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

--- plugins.core.preferences.general.dockIcon <cp.prop: boolean>
--- Field
--- Controls whether or not CommandPost should show a dock icon.
mod.dockIcon = config.prop("dockIcon", false):watch(function(value)
    hs.dockIcon(value)
end)

--- plugins.core.preferences.general.openDebugConsoleOnDockClick <cp.prop: boolean>
--- Variable
--- Open Error Log on Dock Icon Click.
mod.openDebugConsoleOnDockClick = config.prop("openDebugConsoleOnDockClick", true)

local plugin = {
    id              = "core.preferences.general",
    group           = "core",
    dependencies    = {
        ["core.preferences.panels.general"] = "general",
    }
}

function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Create Dock Icon Click Callback:
    --------------------------------------------------------------------------------
    config.dockIconClickCallback:new("cp", function()
        if mod.openDebugConsoleOnDockClick() then hs.openConsole() end
    end)

    --------------------------------------------------------------------------------
    -- Cache Values:
    --------------------------------------------------------------------------------
    mod._autoLaunch           = hs.autoLaunch()
    mod._uploadCrashData    = hs.uploadCrashData()

    --------------------------------------------------------------------------------
    -- Setup General Preferences Panel:
    --------------------------------------------------------------------------------
    deps.general
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

        --------------------------------------------------------------------------------
        -- General Section:
        --------------------------------------------------------------------------------
        :addHeading(1, i18n("general"))
        :addCheckbox(3,
            {
                label       = i18n("launchAtStartup"),
                checked     = mod.autoLaunch,
                onchange    = function(_, params) mod.autoLaunch(params.checked) end,
            }
        )

        --------------------------------------------------------------------------------
        -- Privacy Section:
        --------------------------------------------------------------------------------
        :addHeading(10, i18n("privacy"))
        :addCheckbox(11,
            {
                label        = i18n("sendCrashData"),
                checked  = mod.uploadCrashData,
                onchange = function(_, params) mod.uploadCrashData(params.checked) end,
            }
        )
        :addButton(12,
            {
                label   = i18n("openPrivacyPolicy"),
                width       = 200,
                onclick = function() hs.execute("open '" .. config.privacyPolicyURL .. "'") end,
            }
        )

        :addContent(30, [[
                </div>
                <div class="generalPrefsColumn">
        ]], false)

        --------------------------------------------------------------------------------
        -- Dock Icon Section:
        --------------------------------------------------------------------------------
        :addHeading(31, i18n("dockIcon"))
        :addCheckbox(32,
            {
                label       = i18n("enableDockIcon"),
                checked     = mod.dockIcon,
                onchange    = function() mod.dockIcon:toggle() end,
            }
        )
        :addCheckbox(33,
            {
                label = i18n("openDebugConsoleOnDockClick"),
                checked = mod.openDebugConsoleOnDockClick,
                onchange = function() mod.openDebugConsoleOnDockClick:toggle() end
            }
        )

        :addContent(100, [[
                </div>
            </div>
        ]], false)

    return mod

end

function plugin.postInit()
    mod.dockIcon:update()
end

return plugin
