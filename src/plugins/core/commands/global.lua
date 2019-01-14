--- === plugins.core.commands.global ===
---
--- The 'global' command collection.

local require = require

local commands = require("cp.commands")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id              = "core.commands.global",
    group           = "core",
}

function plugin.init()
    return commands.new("global")
end

return plugin
