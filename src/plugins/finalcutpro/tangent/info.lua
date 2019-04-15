--- === plugins.finalcutpro.tangent.info ===
---
--- Final Cut Pro Info Inspector for Tangent

local require = require

--local log                   = require("hs.logger").new("tangentVideo")

local fcp                   = require("cp.apple.finalcutpro")
local i18n                  = require("cp.i18n")


local plugin = {
    id = "finalcutpro.tangent.info",
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
    local id                            = 0x0F770000

    local common                        = deps.common
    local fcpGroup                      = deps.fcpGroup

    local doShowParameter               = common.doShowParameter

    --------------------------------------------------------------------------------
    -- INFO INSPECTOR:
    --------------------------------------------------------------------------------
    local info                     = fcp:inspector():info()
    local infoGroup                = fcpGroup:group(i18n("info") .. " " .. i18n("inspector"))

        --------------------------------------------------------------------------------
        -- Show Inspector:
        --------------------------------------------------------------------------------
        doShowParameter(infoGroup, info, id, i18n("show") .. " " .. i18n("inspector"))

end

return plugin
