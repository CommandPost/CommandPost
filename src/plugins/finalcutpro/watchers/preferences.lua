--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                 P R E F E R E N C E S    W A T C H E R                     --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.watchers.preferences ===
---
--- Final Cut Pro Preferences Watcher.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log               = require("hs.logger").new("prefWatcher")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local pathwatcher       = require("hs.pathwatcher")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp               = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.watchers.preferences.init() -> none
--- Function
--- Initialise the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init()

    --------------------------------------------------------------------------------
    -- Cache the last Command Set Path:
    --------------------------------------------------------------------------------
    mod.lastCommandSetPath = fcp:getActiveCommandSetPath()

    --------------------------------------------------------------------------------
    -- Update Preferences Cache when Final Cut Pro Preferences file is modified:
    --------------------------------------------------------------------------------
    fcp:watch({
        preferences = function()
            --log.df("Preferences file change detected. Reload.")
            --------------------------------------------------------------------------------
            -- Update the Preferences Cache:
            --------------------------------------------------------------------------------
            fcp:getPreferences()

            --------------------------------------------------------------------------------
            -- Update the Command Set Cache:
            --------------------------------------------------------------------------------
            local activeCommandSetPath = fcp:getActiveCommandSetPath()
            if activeCommandSetPath and mod.lastCommandSetPath ~= activeCommandSetPath then
                --log.df("Updating Final Cut Pro Command Editor Cache.")
                fcp:getActiveCommandSet(true)
                mod.lastCommandSetPath = activeCommandSetPath
            end
        end,
    })

    --------------------------------------------------------------------------------
    -- Refresh Command Set Cache if a Command Set is modified:
    --------------------------------------------------------------------------------
    local userCommandSetPath = fcp.userCommandSetPath()
    if userCommandSetPath then
        --log.df("Setting up User Command Set Watcher: %s", userCommandSetPath)
        mod.commandSetWatcher = pathwatcher.new(userCommandSetPath .. "/", function()
            --log.df("Updating Final Cut Pro Command Editor Cache.")
            fcp:getActiveCommandSet(true)
        end):start()
    end

end


--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.watchers.preferences",
    group = "finalcutpro",
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init()
    return mod.init()
end

return plugin