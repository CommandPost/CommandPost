--- === plugins.finalcutpro.timeline.renameclip ===
---
--- Rename Clip

--------------------------------------------------------------------------------
--
-- EXTENSIONS:
--
--------------------------------------------------------------------------------
local require = require

--------------------------------------------------------------------------------
-- Logger:
--------------------------------------------------------------------------------
--local log = require("hs.logger").new("renameClip")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils = require("cp.ui.axutils")
local fcp = require("cp.apple.finalcutpro")
local tools = require("cp.tools")

--------------------------------------------------------------------------------
-- Hammerspoon Extensions:
--------------------------------------------------------------------------------
local eventtap = require("hs.eventtap")
local geometry = require("hs.geometry")

--------------------------------------------------------------------------------
--
-- THE PLUGIN:
--
--------------------------------------------------------------------------------
local plugin = {
    id = "finalcutpro.timeline.renameclip",
    group = "finalcutpro",
    dependencies = {
        ["finalcutpro.commands"]    = "fcpxCmds",
    }
}

--------------------------------------------------------------------------------
-- INITIALISE PLUGIN:
--------------------------------------------------------------------------------
function plugin.init(deps)

    --------------------------------------------------------------------------------
    -- Add Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds:add("renameClip")
        :whenActivated(function()
            local selectedClip
            local content = fcp:timeline():contents()
            local selectedClips = content:selectedClipsUI()
            if selectedClips and #selectedClips == 1 then
                selectedClip = selectedClips[1]
            end
            if selectedClip then
                local frame = selectedClip:attributeValue("AXFrame")
                if frame then
                    local point = geometry.new(frame).center
                    if point then
                        tools.ninjaRightMouseClick(point)
                        local parent = selectedClip:attributeValue("AXParent")
                        local menu = parent and axutils.childWithRole(parent, "AXMenu")
                        local item = menu and axutils.childWith(menu, "AXTitle", fcp:string("FFRename Bin Object"))
                        if item then
                            item:performAction("AXPress")
                            return
                        end
                    end
                end
            end
            --------------------------------------------------------------------------------
            -- Something went wrong:
            --------------------------------------------------------------------------------
            tools.playErrorSound()
        end)
        :titled(fcp:string("FFRename Bin Object"))

end

return plugin