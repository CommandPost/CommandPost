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
local log = require("hs.logger").new("renameClip")

--------------------------------------------------------------------------------
-- CommandPost Extensions:
--------------------------------------------------------------------------------
local axutils = require("cp.ui.axutils")
local fcp = require("cp.apple.finalcutpro")
local If = require("cp.rx.go.If")
local tools = require("cp.tools")

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
    -- Rename Clip Rx:
    --------------------------------------------------------------------------------
    local doRenameClip = function()
        return If(function()
            local selectedClip
            local content = fcp:timeline():contents()
            local selectedClips = content:selectedClipsUI()
            if selectedClips and #selectedClips == 1 then
                selectedClip = selectedClips[1]
            end
            return selectedClip
        end)
        :Then(function(selectedClip)
            selectedClip:performAction("AXShowMenu")
            return selectedClip
        end)
        :Then(function(selectedClip)
            local parent = selectedClip:attributeValue("AXParent")
            local menu = axutils.childWithRole(parent, "AXMenu")
            local item = axutils.childWith(menu, "AXTitle", fcp:string("FFRename Bin Object"))
            if item then
                item:performAction("AXPress")
                return
            end
        end)
        :Catch(function(message)
            tools.playErrorSound()
            log.ef("doRenameClip: %s", message)
        end)

    end

    --------------------------------------------------------------------------------
    -- Add Commands:
    --------------------------------------------------------------------------------
    deps.fcpxCmds:add("renameClip")
        :whenActivated(function() doRenameClip():Now() end)
        :titled(fcp:string("FFRename Bin Object"))

end

return plugin
