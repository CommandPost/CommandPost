--- === plugins.finalcutpro.tangent.generator ===
---
--- Final Cut Pro Generator Inspector for Tangent

local require = require

--local log                   = require("hs.logger").new("tangentVideo")

local fcp                   = require("cp.apple.finalcutpro")
local i18n                  = require("cp.i18n")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.tangent.generator",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.tangent.common"]  = "common",
        ["finalcutpro.tangent.group"]   = "fcpGroup",
    }
}

function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Setup:
    --------------------------------------------------------------------------------
    local id                            = 0x0F760000

    local common                        = deps.common
    local fcpGroup                      = deps.fcpGroup

    local doShowParameter               = common.doShowParameter

    --------------------------------------------------------------------------------
    -- GENERATOR INSPECTOR:
    --------------------------------------------------------------------------------
    local generator                     = fcp:inspector():generator()
    local generatorGroup                = fcpGroup:group(i18n("generator") .. " " .. i18n("inspector"))

        --------------------------------------------------------------------------------
        -- Show Inspector:
        --------------------------------------------------------------------------------
        id = doShowParameter(generatorGroup, generator, id, i18n("show") .. " " .. i18n("inspector"))

end

return plugin
