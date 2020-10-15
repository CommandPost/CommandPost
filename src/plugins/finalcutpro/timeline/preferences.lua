--- === plugins.finalcutpro.timeline.preferences ===
---
--- Final Cut Pro Timeline Preferences.

local require       = require

local dialog        = require "cp.dialog"
local fcp           = require "cp.apple.finalcutpro"
local i18n          = require "cp.i18n"

local mod = {}

--- plugins.finalcutpro.timeline.preferences.backgroundRender <cp.prop: boolean>
--- Variable
--- Is Background Render enabled?
mod.backgroundRender = fcp.preferences:prop("FFAutoStartBGRender", true)

--- plugins.finalcutpro.timeline.preferences.getAutoRenderDelay() -> number
--- Function
--- Gets the 'FFAutoRenderDelay' value from the Final Cut Pro Preferences file.
---
--- Parameters:
---  * None
---
--- Returns:
---  * 'FFAutoRenderDelay' value as number.
function mod.getAutoRenderDelay()
    return tonumber(fcp.preferences.FFAutoRenderDelay or "0.3")
end

local plugin = {
    id = "finalcutpro.timeline.preferences",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.menu.manager"]        = "menu",
        ["finalcutpro.commands"]            = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if Final Cut Pro is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    -- Add Menu:
    deps.menu.mediaImport
        :addItems(2000, function()
            local fcpxRunning = fcp:isRunning()

            return {
                { title = i18n("enableBackgroundRender", {count = mod.getAutoRenderDelay()}),   fn = function() mod.backgroundRender:toggle() end,  checked = mod.backgroundRender(),   disabled = not fcpxRunning },
            }
        end)

    -- Add Commands:
    deps.fcpxCmds
        :add("cpBackgroundRenderOn")
        :groupedBy("timeline")
        :whenActivated(function() mod.backgroundRender(true) end)

    deps.fcpxCmds
        :add("cpBackgroundRenderOff")
        :groupedBy("timeline")
        :whenActivated(function() mod.backgroundRender(false) end)

    return mod
end

return plugin
