--- === plugins.core.console.preferences ===
---
--- Preferences for the Search Console.

local require = require

local hs        = _G.hs

local config    = require "cp.config"
local i18n      = require "cp.i18n"

local mod = {}

--- plugins.core.console.preferences.scanRunningApplicationMenubarsOnStartup <cp.prop: boolean>
--- Variable
--- Scan Running Application Menubars on Startup
mod.scanRunningApplicationMenubarsOnStartup = config.prop("scanRunningApplicationMenubarsOnStartup", false)

--- plugins.core.console.preferences.scanTheMenubarsOfTheActiveApplication <cp.prop: boolean>
--- Variable
--- Scan the Menubars of the Active Application
mod.scanTheMenubarsOfTheActiveApplication = config.prop("scanTheMenubarsOfTheActiveApplication", false)

local plugin = {
    id              = "core.console.preferences",
    group           = "core",
    dependencies    = {
        ["core.preferences.panels.general"] = "general",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Setup General Preferences Panel:
    --------------------------------------------------------------------------------
    deps.general
        --------------------------------------------------------------------------------
        -- General Section:
        --------------------------------------------------------------------------------
        :addHeading(6, i18n("searchConsole"))
        :addCheckbox(6.1,
            {
                label       = i18n("scanRunningApplicationMenubarsOnStartup"),
                checked     = mod.scanRunningApplicationMenubarsOnStartup,
                onchange    = function(_, params) mod.scanRunningApplicationMenubarsOnStartup(params.checked) end,
            }
        )
        :addCheckbox(6.2,
            {
                label       = i18n("scanTheMenubarsOfTheActiveApplication"),
                checked     = mod.scanTheMenubarsOfTheActiveApplication,
                onchange    = function(_, params) mod.scanTheMenubarsOfTheActiveApplication(params.checked) end,
            }
        )

    return mod

end

return plugin
