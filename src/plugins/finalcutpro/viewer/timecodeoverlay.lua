--- === plugins.finalcutpro.viewer.timecodeoverlay ===
---
--- Advanced Timecode Overlay.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp               = require("cp.apple.finalcutpro")
local i18n              = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PRIORITY -> number
-- Constant
-- The menubar position priority.
local PRIORITY = 10

-- DEFAULT_VALUE -> boolean
-- Constant
-- The Default Value.
local DEFAULT_VALUE = false

-- PREFERENCES_KEY -> string
-- Constant
-- The Preferences Key.
local PREFERENCES_KEY = "FFEnableGuards"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.viewer.timecodeoverlayenabled <cp.prop: boolean>
--- Variable
--- Advanced Timecode Overlay Enabled?
mod.enabled = fcp.preferences:prop(PREFERENCES_KEY, DEFAULT_VALUE)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "finalcutpro.viewer.timecodeoverlay",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.menu.viewer"] = "menu",
        ["finalcutpro.commands"]        = "fcpxCmds",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup Menus:
    --------------------------------------------------------------------------------
    if deps.menu then
        deps.menu:addItem(PRIORITY, function()
            return { title = i18n("enableTimecodeOverlay"), fn = function() mod.enabled:toggle() end, checked=mod.enabled() }
        end)
    end

    --------------------------------------------------------------------------------
    -- Setup Commands:
    --------------------------------------------------------------------------------
    if deps.fcpxCmds then
        deps.fcpxCmds:add("cpToggleTimecodeOverlays")
            :groupedBy("hacks")
            :activatedBy():ctrl():option():cmd("t")
            :whenActivated(function() mod.enabled:toggle() end)
    end

    return mod
end

return plugin
