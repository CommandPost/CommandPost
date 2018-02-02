--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                             U P D A T E S                                  --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.core.preferences.updates ===
---
--- Updates Module.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local application       = require("hs.application")
local timer             = require("hs.timer")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config            = require("cp.config")

--------------------------------------------------------------------------------
--
-- CONSTANTS:
--
--------------------------------------------------------------------------------
local UPDATE_BANNER_PRIORITY            = 1
local UPDATE_PREFERENCES_PRIORITY       = 5000
local CHECK_FOR_UPDATES_INTERVAL        = 15 * 60

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.core.preferences.updates.toggleCheckForUpdates() -> nil
--- Function
--- Toggles 'Check For Updates'
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.toggleCheckForUpdates()
    local automaticallyCheckForUpdates = hs.automaticallyCheckForUpdates()
    hs.automaticallyCheckForUpdates(not automaticallyCheckForUpdates)
    mod.automaticallyCheckForUpdates = not automaticallyCheckForUpdates

    if not automaticallyCheckForUpdates then
        hs.checkForUpdates(true)
    end
end

--- plugins.core.preferences.updates.checkForUpdates() -> boolean
--- Function
--- Returns the 'Check for Updates' status
---
--- Parameters:
---  * None
---
--- Returns:
---  * `true` or `false`
function mod.checkForUpdates()
    hs.checkForUpdates()
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.preferences.updates",
    group           = "core",
    dependencies    = {
        ["core.menu.top"]                   = "menu",
        ["core.preferences.panels.general"] = "general",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    mod.automaticallyCheckForUpdates = hs.automaticallyCheckForUpdates()

    if hs.automaticallyCheckForUpdates() then
        hs.checkForUpdates(true)
    end

    deps.menu:addItem(UPDATE_BANNER_PRIORITY, function()
        if hs.updateAvailable() and hs.automaticallyCheckForUpdates() then
            return { title = i18n("updateAvailable") .. " (" .. hs.updateAvailable() .. ")",    fn = mod.checkForUpdates }
        end
    end)
    :addSeparator(2)

    if hs.canCheckForUpdates() then
        deps.general:addCheckbox(3,
            {
                label = i18n("checkForUpdates"),
                onchange = mod.toggleCheckForUpdates,
                checked = hs.automaticallyCheckForUpdates,
            }
        )
    end

end

return plugin