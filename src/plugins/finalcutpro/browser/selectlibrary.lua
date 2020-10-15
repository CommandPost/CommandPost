--- === plugins.finalcutpro.browser.selectlibrary ===
---
--- Actions for selecting libraries

local require       = require

--local log		    = require "hs.logger".new "selectlibrary"

local fcp           = require "cp.apple.finalcutpro"
local i18n          = require "cp.i18n"

local plugin = {
    id = "finalcutpro.browser.selectlibrary",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

function plugin.init(deps)
    --------------------------------------------------------------------------------
    -- Only load plugin if FCPX is supported:
    --------------------------------------------------------------------------------
    if not fcp:isSupported() then return end

    local fcpxCmds = deps.fcpxCmds

    --------------------------------------------------------------------------------
    -- Select Topmost Library in Browser:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("selectTopmostLibraryInBrowser")
        :whenActivated(function()
            fcp.libraries.sidebar:show()
            fcp.libraries.sidebar:selectRowAt(1)
            fcp.libraries.sidebar:showRowAt(1)
            fcp.libraries.sidebar:focus()
        end)
        :titled(i18n("selectTopmostLibraryInBrowser"))

    --------------------------------------------------------------------------------
    -- Select Active Library in Browser:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("selectActiveLibraryInBrowser")
        :whenActivated(function()
            fcp.libraries.sidebar:show()
            fcp.libraries.sidebar:selectActiveLibrary()
            fcp.libraries.sidebar:focus()
        end)
        :titled(i18n("selectActiveLibraryInBrowser"))
end

return plugin