--- === plugins.finalcutpro.inspector.info ===
---
--- Final Cut Pro Info Inspector Additions.

local require = require

--local log                   = require "hs.logger".new "videoInspector"

local fcp                   = require "cp.apple.finalcutpro"
local i18n                  = require "cp.i18n"

local plugin = {
    id              = "finalcutpro.inspector.info",
    group           = "finalcutpro",
    dependencies    = {
        ["finalcutpro.commands"]        = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    --------------------------------------------------------------------------------
    -- Set Camera LUT to None:
    --------------------------------------------------------------------------------
    local fcpxCmds = deps.fcpxCmds
    fcpxCmds
        :add("setCameraLUTToNone")
        :whenActivated(function()
            local info = fcp.inspector.info
            info:show()
            info:metadataView("Settings")
            local none = fcp:string("FFCameraLUTControllerNone")
            info:cameraLUT():value(none)
        end)
        :titled(i18n("setCameraLUTToNone"))
end

return plugin
