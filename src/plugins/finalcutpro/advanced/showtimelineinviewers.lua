--- === plugins.finalcutpro.advanced.showtimelineinviewers ===
---
--- Show Timeline In Player.

local require = require

local fcp		     = require("cp.apple.finalcutpro")
local i18n       = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.advanced.showtimelineinviewers.enabled <cp.prop: boolean; live>
--- Constant
--- Show Timeline in Player Enabled?
mod.enabled = fcp.preferences:prop("FFPlayerDisplayedTimeline", 0):mutate(
    function(original) return original() == 1 end,
    function(newValue, original) original(newValue and 1 or 0) end
)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id				= "finalcutpro.advanced.showtimelineinviewers",
    group			= "finalcutpro",
    dependencies	= {
        ["finalcutpro.commands"] 		= "fcpxCmds",
        ["finalcutpro.preferences.manager"] = "prefs",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Setup Menubar Preferences Panel:
    --------------------------------------------------------------------------------
    deps.prefs.panel
        :addCheckbox(2204.2,
        {
            label = i18n("showTimelineInViewers"),
            onchange = function(_, params) mod.enabled(params.checked) end,
            checked = function() return mod.enabled() end,
        })

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds
        :add("cpShowTimelineInViewers")
        :whenActivated(function() mod.enabled:toggle() end)

    return mod
end

return plugin
