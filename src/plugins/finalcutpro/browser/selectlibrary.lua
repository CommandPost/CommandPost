--- === plugins.finalcutpro.browser.selectlibrary ===
---
--- Actions for selecting libraries

local require       = require

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
    local fcpxCmds = deps.fcpxCmds

    --------------------------------------------------------------------------------
    -- Select Topmost Library in Browser:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("selectTopmostLibraryInBrowser")
        :whenActivated(function()
            local libraries = fcp:libraries()
            local browser = fcp:browser()
            local sidebar = libraries:sidebar()
            browser:show()
            if not libraries:sidebar():isShowing() then
                browser:showLibraries():press()
            end
            libraries:sidebar():selectRowAt(1)
            libraries:sidebar():showRowAt(1)
        end)
        :titled(i18n("selectTopmostLibraryInBrowser"))

    --------------------------------------------------------------------------------
    -- Select Active Library in Browser:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("selectActiveLibraryInBrowser")
        :whenActivated(function()
            local libraries = fcp:libraries()
            local browser = fcp:browser()
            local sidebar = libraries:sidebar()
            browser:show()
            if not libraries:sidebar():isShowing() then
                browser:showLibraries():press()
            end

            local scrollArea = libraries:sidebar():UI()
            local outline = scrollArea and scrollArea[1]
            if outline and outline:attributeValue("AXRole") == "AXOutline" then
                local children = outline:attributeValue("AXChildren")
                if children then
                    local foundSelected = false
                    for i=#children, 1, -1 do
                        local child = children[i]
                        if child and child:attributeValue("AXSelected") then
                            foundSelected = true
                        end
                        if foundSelected then
                            if child and child:attributeValue("AXDisclosureLevel") == 0 then
                                outline:setAttributeValue("AXSelectedRows", {child})
                                break
                            end
                        end
                    end
                end
            end
        end)
        :titled(i18n("selectActiveLibraryInBrowser"))

end

return plugin
