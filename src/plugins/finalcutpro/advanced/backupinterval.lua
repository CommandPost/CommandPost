--- === plugins.finalcutpro.advanced.backupinterval ===
---
--- Change Final Cut Pro's Backup Interval.

local require = require

local fcp               = require("cp.apple.finalcutpro")
local i18n              = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.advanced.backupinterval",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.preferences.manager"] = "prefs",
    }
}

function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    deps.prefs.panel
        :addParagraph(2207, "<br />", false)
        :addSelect(2208,
            {
                required    = true,
                width       = 200,
                label       = i18n("backupInterval"),
                value       = function() return fcp.preferences.FFPeriodicBackupInterval or "15" end,
                options     = function()
                    local options = {}
                    for i=1, 15 do
                        table.insert(options, {
                            value = tostring(i),
                            label = tostring(i) .. " " .. i18n("mins")
                        })
                    end
                    return options
                end,
                onchange = function(_, params)
                    fcp.preferences:set("FFPeriodicBackupInterval", params.value)
                end,
            }
        )

    deps.prefs.panel
        :addSelect(2209,
            {
                required    = true,
                width       = 200,
                label       = i18n("backupMinimumDuration"),
                value       = function() return fcp.preferences.FFPeriodicBackupMinimumDuration or "5" end,
                options     = function()
                    local options = {}
                    for i=1, 15 do
                        table.insert(options, {
                            value = tostring(i),
                            label = tostring(i) .. " " .. i18n("mins")
                        })
                    end
                    return options
                end,
                onchange = function(_, params)
                    fcp.preferences:set("FFPeriodicBackupMinimumDuration", params.value)
                end,
            }
        )

    return mod

end

return plugin
