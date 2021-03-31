--- === plugins.finalcutpro.advanced.backupinterval ===
---
--- Change Final Cut Pro's Backup Interval.

local require       = require

local fcp           = require "cp.apple.finalcutpro"
local i18n          = require "cp.i18n"

local plugin = {
    id              = "finalcutpro.advanced.backupinterval",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.preferences.manager"] = "prefs",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Setup Preferences Panel:
    --------------------------------------------------------------------------------
    local panel = deps.prefs.panel
    if panel then
        panel
            :addContent(2207.1, [[
                <style>
                    .backupInterval select {
                        margin-left: 90px;
                    }
                    .backupMinimumDuration select {
                        margin-left: 25px;
                    }
                </style>
            ]], false)
            :addParagraph(2207.2, "<br />", false)
            :addSelect(2208,
                {
                    class       = "backupInterval",
                    required    = true,
                    width       = 100,
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

        panel
            :addSelect(2209,
                {
                    class       = "backupMinimumDuration",
                    required    = true,
                    width       = 100,
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
    end
end

return plugin
