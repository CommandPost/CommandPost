--- === plugins.finalcutpro.streamdeck ===
---
--- Stream Deck Plugin for Final Cut Pro.

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp                                       = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.streamdeck",
    group = "finalcutpro",
    dependencies = {
        ["core.streamdeck.manager"]     = "manager",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Update Buttons when FCPX is active:
    --------------------------------------------------------------------------------
    fcp.app.frontmost:watch(function(frontmost) deps.manager.groupStatus("fcpx", frontmost) end)
end

return plugin
