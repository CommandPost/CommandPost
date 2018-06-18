--- === plugins.finalcutpro.tangent.edit ===
---
--- Final Cut Pro Tangent View Group

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
-- local log                                       = require("hs.logger").new("fcptng_timeline")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local fcp                                       = require("cp.apple.finalcutpro")

--------------------------------------------------------------------------------
--
-- THE MODULE:
--
--------------------------------------------------------------------------------
local mod = {}

--- plugins.finalcutpro.tangent.edit.group
--- Constant
--- The `core.tangent.manager.group` that collects Final Cut Pro View actions/parameters/etc.
mod.group = nil

--- plugins.finalcutpro.tangent.edit.init() -> none
--- Function
--- Initialises the module.
---
--- Parameters:
---  * None
---
--- Returns:
---  * None
function mod.init(fcpGroup)

    local baseID = 0x00090000

    mod.group = fcpGroup:group(i18n("edit"))

    mod.group:action(baseID+1, i18n("undo"))
        :onPress(function()
            fcp:doSelectMenu({"Edit", "Undo"})
        end)

    mod.group:action(baseID+2, i18n("redo"))
        :onPress(function()
            fcp:doSelectMenu({"Edit", "Redo"})
        end)

    mod.group:action(baseID+3, i18n("delete"))
        :onPress(function()
            fcp:doSelectMenu({"Edit", "Delete"})
        end)
end

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.tangent.edit",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.group"]   = "fcpGroup",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Initalise the Module:
    --------------------------------------------------------------------------------
    mod.init(deps.fcpGroup)

    return mod
end

return plugin