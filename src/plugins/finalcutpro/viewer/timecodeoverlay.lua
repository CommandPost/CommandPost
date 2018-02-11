--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--              T I M E C O D E    O V E R L A Y    P L U G I N               --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

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
local dialog            = require("cp.dialog")
local fcp               = require("cp.apple.finalcutpro")
local prop              = require("cp.prop")

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
mod.enabled = prop.new(
    function()
        return fcp:getPreference(PREFERENCES_KEY, DEFAULT_VALUE)
    end,

    function(value)
        --------------------------------------------------------------------------------
        -- Update plist:
        --------------------------------------------------------------------------------
        if fcp:setPreference(PREFERENCES_KEY, value) == nil then
            dialog.displayErrorMessage(i18n("failedToWriteToPreferences"))
            return
        end

    end
)

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