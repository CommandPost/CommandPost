--- === plugins.finalcutpro.timeline.preferences ===
---
--- Final Cut Pro Timeline Preferences.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local dialog                = require("cp.dialog")
local fcp                   = require("cp.apple.finalcutpro")
local i18n                  = require("cp.i18n")

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
mod.backgroundRender = fcp.preferences:prop(BACKGROUND_RENDER, true):mutate(
    function(original) return original() end,
    function(newValue, original)
        if fcp:isRunning() then
            if newValue ~= original() then
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
        else
            original(newValue)
        end
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
    return tonumber(fcp.preferences.FFAutoRenderDelay or "0.3")
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
        ["finalcutpro.menu.manager"]        = "menu",
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
        deps.menu.mediaImport:addItems(PRIORITY, function()
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
