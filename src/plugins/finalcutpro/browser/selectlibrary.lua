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
    local fcpxCmds = deps.fcpxCmds

    --------------------------------------------------------------------------------
    -- Select Topmost Library in Browser:
    --------------------------------------------------------------------------------
    fcpxCmds
        :add("selectTopmostLibraryInBrowser")
        :whenActivated(function()
            local libraries = fcp:libraries()
            local browser = fcp:browser()
            browser:show()
            local sidebar = libraries:sidebar()
            if not sidebar:isShowing() then
                browser:showLibraries():press()
            end
            sidebar:selectRowAt(1)
            sidebar:showRowAt(1)
            sidebar:focus()
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
            browser:show()
            local sidebar = libraries:sidebar()
            if not sidebar:isShowing() then
                browser:showLibraries():press()
            end
            local scrollArea = sidebar:UI()
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
                                sidebar:focus()
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
