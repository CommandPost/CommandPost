--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                   C  O  M  M  A  N  D  P  O  S  T                          --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.timeline.preferences ===
---
--- Final Cut Pro Timeline Preferences.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog                = require("cp.dialog")
local fcp                   = require("cp.apple.finalcutpro")
local prop                  = require("cp.prop")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------

-- PRIORITY -> number
-- Constant
-- The menubar position priority.
local PRIORITY = 2000

-- BACKGROUND_RENDER -> number
-- Constant
-- The Preferences Key for the Background Render value.
local BACKGROUND_RENDER = "FFAutoStartBGRender"

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.timeline.preferences.backgroundRender <cp.prop: boolean>
--- Variable
--- Is Background Render enabled?
mod.backgroundRender = prop.new(
    function() return fcp:getPreference(BACKGROUND_RENDER, true) end,
    function()
        --------------------------------------------------------------------------------
        -- Make sure it's active:
        --------------------------------------------------------------------------------
        fcp:launch()

        --------------------------------------------------------------------------------
        -- Define FCPX:
        --------------------------------------------------------------------------------
        local panel = fcp:preferencesWindow():playbackPanel()

		--------------------------------------------------------------------------------
		-- Toggle the checkbox:
		--------------------------------------------------------------------------------
		if panel:show():isShowing() then
			panel:backgroundRender():toggle()
		else
			dialog.displayErrorMessage("Failed to toggle 'Enable Background Render'.\n\nError occurred in backgroundRender().")
			return false
		end

        --------------------------------------------------------------------------------
        -- Close the Preferences window:
        --------------------------------------------------------------------------------
        panel:hide()
        return true
    end
)

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
    return tonumber(fcp:getPreference("FFAutoRenderDelay", "0.3"))
end

---------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.timeline.preferences",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.menu.mediaimport"]    = "menu",
        ["finalcutpro.commands"]            = "fcpxCmds",
    }
}

---------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
---------------------------------------------------------------------------------
function plugin.init(deps)
    ---------------------------------------------------------------------------------
    -- Add Menu:
    ---------------------------------------------------------------------------------
    if deps.menu then
        deps.menu:addItems(PRIORITY, function()
            local fcpxRunning = fcp:isRunning()

            return {
                { title = i18n("enableBackgroundRender", {count = mod.getAutoRenderDelay()}),   fn = function() mod.backgroundRender:toggle() end,  checked = mod.backgroundRender(),   disabled = not fcpxRunning },
            }
        end)
    end

    ---------------------------------------------------------------------------------
    -- Add Commands:
    ---------------------------------------------------------------------------------
    if deps.fcpxCmds then
        deps.fcpxCmds:add("cpBackgroundRenderOn")
            :groupedBy("timeline")
            :whenActivated(function() mod.backgroundRender(true) end)
        deps.fcpxCmds:add("cpBackgroundRenderOff")
            :groupedBy("timeline")
            :whenActivated(function() mod.backgroundRender(false) end)
    end

    return mod
end

return plugin
