--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--                          M I D I     P L U G I N                           --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------

--- === plugins.finalcutpro.midi.manager ===
---
--- MIDI Plugin for Final Cut Pro.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local config                                    = require("cp.config")
local fcp                                       = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.midi.manager.enabled <cp.prop: boolean>
--- Field
--- Enable or disable MIDI Support.
mod.enabled = config.prop("enableMIDI", false):watch(function(enabled)
    if enabled then
        --------------------------------------------------------------------------------
        -- Update MIDI Commands when Final Cut Pro is shown or hidden:
        --------------------------------------------------------------------------------
        mod._fcpWatchID = fcp:watch({
            active      = function() deps.manager.groupStatus("fcpx", true) end,
            inactive    = function() deps.manager.groupStatus("fcpx", false) end,
            show        = function() deps.manager.groupStatus("fcpx", true) end,
            hide        = function() deps.manager.groupStatus("fcpx", false) end,
        })
    else
        --------------------------------------------------------------------------------
        -- Destroy Watchers:
        --------------------------------------------------------------------------------
        if mod._fcpWatchID and mod._fcpWatchID.id then
            fcp:unwatch(mod._fcpWatchID.id)
            mod._fcpWatchID = nil
        end
    end
end)

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.midi.manager",
    group = "finalcutpro",
    dependencies = {
        ["core.midi.manager"]       = "manager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    return mod
end

return plugin