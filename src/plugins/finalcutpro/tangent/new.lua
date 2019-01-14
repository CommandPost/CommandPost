--- === plugins.finalcutpro.tangent.new ===
---
--- Final Cut Pro Tangent View Group

local require = require

local fcp                                       = require("cp.apple.finalcutpro")
local i18n                                      = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.tangent.new.group
--- Constant
--- The `core.tangent.manager.group` that collects Final Cut Pro New actions/parameters/etc.
mod.group = nil

--- plugins.finalcutpro.tangent.new.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(fcpGroup)

    local baseID = 0x00110000

    mod.group = fcpGroup:group(i18n("new"))

    mod.group:action(baseID+1, i18n("compoundClip"))
        :onPress(fcp:doSelectMenu({"File", "New", "Compound Clip…"}))

end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.tangent.new",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.group"]   = "fcpGroup",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Initalise the Module:
    --------------------------------------------------------------------------------
    mod.init(deps.fcpGroup)

    return mod
end

return plugin
